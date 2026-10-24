package Langertha::Skeid::CustomerSource;
our $VERSION = '0.004';
# ABSTRACT: Customer keys from a database relation - the section, the row contract, the fetch loop
use Moo;
use strict;
use warnings;
use Carp qw(croak);
use Digest::SHA qw(sha256_hex);
use JSON::MaybeXS ();
use POSIX qw(strftime);
use Scalar::Util qw(weaken);
use Time::HiRes ();
use Mojo::IOLoop;
use Langertha::Skeid::UsageStore;


my @COLUMNS = qw( key_id name policy models );

# An SQL identifier Skeid quotes itself: letters, digits and underscores, not starting with a
# digit, at most 63 bytes (PostgreSQL's NAMEDATALEN). Nothing a quote could break out of.
my $IDENT = qr/[A-Za-z_][A-Za-z0-9_]{0,62}/;

my %KNOWN_KEYS = map { $_ => 1 } qw(
  backend dsn host port dbname database user password_env from_usage_store
  relation refresh_interval_s listen max_stale_s connect_timeout_s
);

# The connection keys from_usage_store takes from the usage store instead.
my @OWN_CONNECTION = qw( dsn host port dbname database );

# Longest wait between two retries of a failing fetch, as for a failing config reload.
my $BACKOFF_MAX = 60;


sub normalize_config {
  my ($class, $section, %opts) = @_;
  croak 'customer_source must be a hash: backend, dsn (or host/port/dbname), user, '
    . 'password_env, relation, ...' unless ref($section) eq 'HASH';
  for my $key (sort keys %$section) {
    croak 'customer_source.password is not allowed: name the variable that holds it in '
      . 'password_env (ADR 0003)' if $key eq 'password';
    croak "customer_source: unknown key '$key' (known: " . join(', ', sort keys %KNOWN_KEYS) . ')'
      unless $KNOWN_KEYS{$key};
  }

  my $backend = lc($section->{backend} // 'postgresql');
  croak "customer_source.backend '$backend' is not supported (only postgresql)"
    unless !ref($backend) && $backend =~ /\Apostgres/;

  my $relation = $section->{relation};
  croak 'customer_source.relation is required: the table or view to read, schema-qualified '
    . 'allowed' unless defined($relation) && !ref($relation) && length($relation);
  $class->statement($relation);

  my %conn;
  if (_true($section->{from_usage_store})) {
    my @own = grep { exists $section->{$_} } @OWN_CONNECTION;
    croak 'customer_source.from_usage_store takes the usage store\'s connection; leave out '
      . join(', ', @own) . ' (only user and password_env may override it)' if @own;
    my $usage = $opts{usage_store};
    croak 'customer_source.from_usage_store needs a usage_store section with backend postgresql'
      unless ref($usage) eq 'HASH';
    my $store = Langertha::Skeid::UsageStore->normalize_config($usage);
    croak 'customer_source.from_usage_store needs the usage store to be postgresql, not '
      . $store->{backend} unless $store->{backend} eq 'postgresql';
    %conn = (dsn => $store->{dsn}, user => $store->{user}, password => $store->{password});
    $conn{user} = $section->{user} if defined $section->{user};
    $conn{password} = $ENV{$section->{password_env}} // ''
      if defined($section->{password_env}) && length($section->{password_env});
  } else {
    my $store = Langertha::Skeid::UsageStore->normalize_config({
      backend => 'postgresql',
      map { exists($section->{$_}) ? ($_ => $section->{$_}) : () }
        qw( dsn host port dbname database user password_env ),
    });
    %conn = (dsn => $store->{dsn}, user => $store->{user}, password => $store->{password});
  }
  croak 'customer_source.dsn must be a dbi:Pg: DSN' unless $conn{dsn} =~ /\Adbi:Pg:/i;

  my $listen = $section->{listen};
  if (defined $listen) {
    croak 'customer_source.listen must be a channel name: letters, digits and underscores'
      unless !ref($listen) && $listen =~ /\A$IDENT\z/;
  }

  return {
    backend            => 'postgresql',
    %conn,
    relation           => "$relation",
    refresh_interval_s => _seconds($section, 'refresh_interval_s', 30, 0),
    listen             => $listen,
    max_stale_s        => _seconds($section, 'max_stale_s', 0, 1),
    connect_timeout_s  => _seconds($section, 'connect_timeout_s', 5, 0),
  };
}

sub _true {
  my ($value) = @_;
  return 0 unless defined $value;
  return $value ? 1 : 0 if ref $value;
  return "$value" =~ /\A(1|true|yes|on)\z/i ? 1 : 0;
}

# A number of seconds; fractions allowed. $zero_ok: 0 is a value (max_stale_s), else it must be
# above 0.
sub _seconds {
  my ($section, $key, $default, $zero_ok) = @_;
  return $default unless exists $section->{$key};
  my $value = $section->{$key};
  my $ok = defined($value) && !ref($value) && $value =~ /\A[0-9]+(?:\.[0-9]+)?\z/
    && ($zero_ok ? $value >= 0 : $value > 0);
  croak "customer_source.$key must be a number of seconds " . ($zero_ok ? 'of at least 0' : 'above 0')
    unless $ok;
  return 0 + $value;
}


sub statement {
  my ($class, $relation) = @_;
  croak 'customer_source.relation must be a table or view name, schema-qualified allowed '
    . '(letters, digits and underscores: schema.relation)'
    unless defined($relation) && !ref($relation) && $relation =~ /\A$IDENT(?:\.$IDENT)?\z/;
  my $quoted = join '.', map { qq{"$_"} } split /\./, $relation;
  return 'SELECT ' . join(', ', @COLUMNS) . " FROM $quoted";
}


sub check_rows {
  my ($class, $rows, %opts) = @_;
  my $policies = ref($opts{policies}) eq 'HASH' ? $opts{policies} : {};
  $rows = [] unless ref($rows) eq 'ARRAY';

  # Duplicates are counted over every row that has a key_id string at all: a key_id shared with
  # a row that is wrong for another reason is still not one row per key id.
  my %seen;
  for my $row (@$rows) {
    next unless ref($row) eq 'HASH';
    my $id = $row->{key_id};
    $seen{$id}++ if defined($id) && !ref($id);
  }

  my (@accepted, @rejected);
  my $position = 0;
  for my $row (@$rows) {
    $position++;
    my $label = _label($row, $position);
    my $reason = _row_problem($row, $policies, \%seen);
    if (defined $reason) {
      push @rejected, { row => $label, reason => $reason };
      next;
    }
    push @accepted, {
      key_id => $row->{key_id},
      name   => (defined($row->{name}) && !ref($row->{name}) ? "$row->{name}" : undef),
      policy => $row->{policy},
      models => (defined($row->{models}) ? [ map { "$_" } @{$row->{models}} ] : undef),
      label  => $label,
    };
  }
  return { accepted => \@accepted, rejected => \@rejected };
}

# What is wrong with a row, without any of its values, or undef.
sub _row_problem {
  my ($row, $policies, $seen) = @_;
  return 'the row is not a row of key_id, name, policy, models' unless ref($row) eq 'HASH';
  my $id = $row->{key_id};
  return 'key_id is not a full key id (k_ + 40 lowercase hex digits, from `skeid keyid`)'
    unless defined($id) && !ref($id) && $id =~ /\Ak_[0-9a-f]{40}\z/;
  return 'key_id appears in more than one row' if ($seen->{$id} // 0) > 1;
  my $policy = $row->{policy};
  if (defined $policy) {
    return 'policy names no profile in the file\'s policies:'
      unless !ref($policy) && length($policy) && exists $policies->{$policy};
  }
  my $models = $row->{models};
  if (defined $models) {
    return 'models is not a list of model names' unless ref($models) eq 'ARRAY';
    return 'models is not a list of model names'
      if grep { !defined($_) || ref($_) || !length($_) } @$models;
  }
  return undef;
}

# A row's label in a report: its name, else its position. A name is a display label the owning
# application chose; it is printed with control characters replaced and cut to a sane length,
# so one row cannot forge log lines.
sub _label {
  my ($row, $position) = @_;
  my $name = ref($row) eq 'HASH' ? $row->{name} : undef;
  return "row $position" unless defined($name) && !ref($name) && length($name);
  (my $clean = "$name") =~ s/[^\x20-\x7e]/?/g;
  $clean = substr($clean, 0, 80) . '...' if length($clean) > 80;
  $clean =~ s/'/"/g;
  return "'$clean'";
}


my $JSON = JSON::MaybeXS->new(canonical => 1, allow_nonref => 1, allow_blessed => 1, utf8 => 1);

sub snapshot_digest {
  my ($class, $rows) = @_;
  my @encoded = map {
    my $row = $_;
    my $text = eval { $JSON->encode($row) };
    defined($text) ? $text : 'unencodable:' . (ref($row) || 'scalar');
  } @{ ref($rows) eq 'ARRAY' ? $rows : [] };
  return sha256_hex(join "\n", sort @encoded);
}


sub merge_into {
  my ($class, $cfg, $rows) = @_;
  my $checked = $class->check_rows($rows,
    policies => (ref($cfg->{policies}) eq 'HASH' ? $cfg->{policies} : {}));

  my %names = ref($cfg->{names}) eq 'HASH' ? %{$cfg->{names}} : ();
  my %file_ids;
  if (ref($cfg->{keys}) eq 'HASH') {
    for my $label (keys %{$cfg->{keys}}) {
      my $mapped = $names{$label};
      $file_ids{ (defined($mapped) && !ref($mapped)) ? $mapped : $label } = 1;
    }
  }

  my (@allow, @shadowed, %entries, %display);
  for my $row (@{$checked->{accepted}}) {
    my $id = $row->{key_id};
    push @allow, $id;
    # The row's display name, as its sanitized label: a report shows who a key id belongs to.
    if (defined($row->{name}) && length($row->{name})) {
      (my $shown = $row->{label}) =~ s/\A'(.*)'\z/$1/s;
      $display{$id} = $shown;
    }
    if ($file_ids{$id} || $file_ids{substr($id, 0, 14)} || exists $names{$id}) {
      push @shadowed, $row->{label};
      next;
    }
    next unless defined($row->{policy}) || defined($row->{models});
    $entries{$id} = {
      (defined($row->{policy}) ? (policy => $row->{policy}) : ()),
      (defined($row->{models}) ? (models => $row->{models}) : ()),
    };
  }

  my %merged = %$cfg;
  $merged{keys} = { (ref($cfg->{keys}) eq 'HASH' ? %{$cfg->{keys}} : ()), %entries } if %entries;
  return {
    config   => \%merged,
    allow    => \@allow,
    accepted => scalar(@{$checked->{accepted}}),
    rejected => $checked->{rejected},
    shadowed => \@shadowed,
    names    => \%display,
  };
}


has config            => (is => 'ro', required => 1);
has fetcher           => (is => 'ro', required => 1);
has on_rows           => (is => 'ro', default => sub { sub { } });
has on_failure        => (is => 'ro', default => sub { sub { } });
has notify_debounce_s => (is => 'ro', default => sub { 0.25 });

has last_success_at => (is => 'rw', default => sub { undef });
has last_failure_at => (is => 'rw', default => sub { undef });
has failures        => (is => 'rw', default => sub { 0 });
has last_error      => (is => 'rw', default => sub { undef });
has completed       => (is => 'rw', default => sub { 0 });

has _timer     => (is => 'rw');
has _timeout   => (is => 'rw');
has _debounce  => (is => 'rw');
has _in_flight => (is => 'rw', default => sub { 0 });
has _pending   => (is => 'rw', default => sub { 0 });
has _serial    => (is => 'rw', default => sub { 0 });
has _started   => (is => 'rw', default => sub { 0 });
has _stopped   => (is => 'rw', default => sub { 0 });


sub start {
  my ($self) = @_;
  return $self if $self->_started;
  $self->_started(1);
  my $weak = $self;
  weaken($weak);
  if ($self->fetcher->can('on_notify')) {
    $self->fetcher->on_notify(sub { $weak->_notified if $weak });
  }
  $self->_schedule(0);
  return $self;
}


sub stop {
  my ($self) = @_;
  return if $self->_stopped;
  $self->_stopped(1);
  $self->_in_flight(0);
  for my $timer (qw(_timer _timeout _debounce)) {
    my $id = $self->$timer;
    Mojo::IOLoop->remove($id) if defined $id;
    $self->$timer(undef);
  }
  $self->release;
  return;
}


sub release {
  my ($self) = @_;
  my $fetcher = $self->fetcher;
  eval { $fetcher->release; 1 } if $fetcher->can('release');
  return;
}


sub fetch_now {
  my ($self) = @_;
  return if $self->_stopped;
  if ($self->_in_flight) {
    $self->_pending(1);
    return;
  }
  my $timer = $self->_timer;
  Mojo::IOLoop->remove($timer) if defined $timer;
  $self->_timer(undef);

  $self->_in_flight(1);
  my $serial = $self->_serial + 1;
  $self->_serial($serial);
  my $weak = $self;
  weaken($weak);
  my $limit = $self->config->{connect_timeout_s};
  $self->_timeout(Mojo::IOLoop->timer($limit => sub {
    $weak->_done($serial, "fetch timed out after ${limit}s") if $weak;
  }));
  eval {
    $self->fetcher->fetch(sub {
      my ($err, $rows) = @_;
      $weak->_done($serial, $err, $rows) if $weak;
    });
    1;
  } or $self->_done($serial, $@ || 'fetch failed');
  return;
}

sub _done {
  my ($self, $serial, $err, $rows) = @_;
  # A late answer -- after its timeout, or after a stop -- belongs to nobody any more.
  return unless $self->_in_flight && $serial == $self->_serial && !$self->_stopped;
  $self->_in_flight(0);
  my $timeout = $self->_timeout;
  Mojo::IOLoop->remove($timeout) if defined $timeout;
  $self->_timeout(undef);
  $self->completed($self->completed + 1);

  $err = 'the fetch answered no row list' if !defined($err) && ref($rows) ne 'ARRAY';
  if (defined $err) {
    $err = _clean_error($err);
    my $previous = $self->last_error;
    $self->failures($self->failures + 1);
    $self->last_failure_at(Time::HiRes::time());
    $self->last_error($err);
    warn "skeid: customer_source fetch failed, keeping the last good snapshot: $err\n"
      if !defined($previous) || $previous ne $err;
    eval { $self->on_failure->($err); 1 } or warn "skeid: customer_source: $@";
    $self->_schedule($self->retry_delay);
  } else {
    warn "skeid: customer_source fetch succeeded again\n" if $self->failures;
    $self->failures(0);
    $self->last_error(undef);
    $self->last_success_at(Time::HiRes::time());
    eval { $self->on_rows->($rows); 1 } or warn "skeid: customer_source: $@";
    $self->_schedule($self->config->{refresh_interval_s});
  }

  if ($self->_pending && !$self->_stopped) {
    $self->_pending(0);
    $self->_schedule(0);
  }
  return;
}


sub retry_delay {
  my ($self) = @_;
  my $failures = $self->failures || 1;
  my $delay = $self->config->{refresh_interval_s} * 2 ** ($failures - 1);
  return $delay > $BACKOFF_MAX ? $BACKOFF_MAX : $delay;
}

sub _schedule {
  my ($self, $delay) = @_;
  return if $self->_stopped;
  my $timer = $self->_timer;
  Mojo::IOLoop->remove($timer) if defined $timer;
  my $weak = $self;
  weaken($weak);
  $self->_timer(Mojo::IOLoop->timer($delay => sub {
    return unless $weak;
    $weak->_timer(undef);
    $weak->fetch_now;
  }));
  return;
}

# A notification: one fetch after the debounce, however many more arrive before it runs.
sub _notified {
  my ($self) = @_;
  return if $self->_stopped || defined $self->_debounce;
  my $weak = $self;
  weaken($weak);
  $self->_debounce(Mojo::IOLoop->timer($self->notify_debounce_s => sub {
    return unless $weak;
    $weak->_debounce(undef);
    $weak->fetch_now;
  }));
  return;
}

# A driver error names the DSN it failed on, and a DSN may carry a password.
sub _clean_error {
  my ($err) = @_;
  $err = "$err";
  $err =~ s/\b(password|pwd)=[^;'"\s)]*/$1=***/gi;
  $err =~ s/\s+\z//;
  return length($err) ? $err : 'fetch failed';
}


sub status {
  my ($self) = @_;
  my $iso = sub { defined($_[0]) ? strftime('%Y-%m-%dT%H:%M:%SZ', gmtime(int $_[0])) : undef };
  my $ok = defined($self->last_success_at) && !$self->failures ? 1 : 0;
  return {
    ok              => $ok,
    last_success_at => $iso->($self->last_success_at),
    failed_at       => ($self->failures ? $iso->($self->last_failure_at) : undef),
    failures        => 0 + $self->failures,
    error           => ($ok ? undef : ($self->last_error // 'no fetch has finished yet')),
  };
}

sub DEMOLISH {
  my ($self, $global) = @_;
  return if $global;
  $self->stop;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::CustomerSource - Customer keys from a database relation - the section, the row contract, the fetch loop

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  # In the Skeid config file:
  customer_source:
    dsn: dbi:Pg:dbname=console;host=db
    user: skeid_reader
    password_env: SKEID_CUSTOMER_DB_PASSWORD
    relation: skeid.customer_keys
    listen: skeid_customer_keys

  # What Skeid runs against it, and nothing else:
  my $sql = Langertha::Skeid::CustomerSource->statement('skeid.customer_keys');
  # SELECT key_id, name, policy, models FROM "skeid"."customer_keys"

=head1 DESCRIPTION

The caller side of the config -- which customer key ids may come in (C<client_auth>) and which
policy each takes (C<keys:>) -- can come from a database relation as well as from the file, so
that an application that issues and revokes customer keys does not have to write Skeid's YAML
(ADR 0026). This module holds the parts of that which do not depend on the rest of the config:
the C<customer_source> section, the statement, the row contract, the merge into the file's
config, and the loop that fetches on L<Mojo::IOLoop>.

The fetch itself sits behind a B<fetcher>: an object with C<fetch($cb)>, which calls
C<< $cb->($error) >> or C<< $cb->(undef, \@rows) >> later, from the event loop, and optionally
C<on_notify($cb)> (call C<$cb> when the source says something changed) and C<release> (let go of
every connection). L<Langertha::Skeid::CustomerSource::DBI> is the implementation, on DBI in child processes;
tests give L<Langertha::Skeid/customer_source_fetcher> a fake.

=head2 The row contract

Skeid runs one statement, L</statement>, and reads four columns per row: C<key_id> (C<k_> + 40
lowercase hex, unique in the relation), C<name> (a label, may be C<NULL>), C<policy> (a profile
in the file's C<policies:>; C<NULL> takes C<default_policy>) and C<models> (C<text[]>; C<NULL>
keeps the profile's list, C<'{}'> is no models). A row present means the key is active. See
L</check_rows> for what is rejected.

=head2 normalize_config

  my $cfg = Langertha::Skeid::CustomerSource->normalize_config($section,
    usage_store => $config->{usage_store});

Checks a C<customer_source> section and returns it normalized: C<backend> (C<postgresql>, the
only one), C<dsn>, C<user>, C<password>, C<relation>, C<refresh_interval_s> (default 30),
C<listen> (default none), C<max_stale_s> (default 0) and C<connect_timeout_s> (default 5).

The connection is normalized by L<Langertha::Skeid::UsageStore/normalize_config>, so C<dsn>, or
C<host> / C<port> / C<dbname> (C<database>), C<user> and C<password_env> mean what they mean in
C<usage_store>. With C<from_usage_store: true> the connection is the usage store's, which must
be C<postgresql>; C<user> and C<password_env> given here override its own.

Croaks on a section that is not a hash, an unknown key, a C<password> (only C<password_env>: a
password never sits in the file, ADR 0003), a backend other than PostgreSQL, a C<dsn> that is
not C<dbi:Pg:>, a missing or malformed C<relation>, a C<listen> that is not an identifier,
C<from_usage_store> without a PostgreSQL usage store or together with connection keys of its
own, a C<refresh_interval_s> or C<connect_timeout_s> that is not a number above 0, and a
C<max_stale_s> below 0. No message carries a password.

=head2 statement

  my $sql = Langertha::Skeid::CustomerSource->statement('skeid.customer_keys');

The one statement Skeid runs against the relation: its four columns by name, the relation
quoted as an identifier (each part of a schema-qualified name on its own). Quoting keeps the
case as written: C<Skeid.Keys> reads C<"Skeid"."Keys">, not C<skeid.keys>. Croaks on a relation
that is not one identifier or two joined by a dot -- letters, digits and underscores, not
starting with a digit -- so nothing in it is ever read as SQL.

=head2 check_rows

  my $checked = Langertha::Skeid::CustomerSource->check_rows(\@rows, policies => \%policies);
  # { accepted => [ { key_id, name, policy, models, label }, ... ],
  #   rejected => [ { row => "'alice'" | 'row 3', reason => '...' }, ... ] }

Validates a snapshot on its own, before anything is merged. A row is rejected when it is not a
hash, when its C<key_id> is not a full key id (C<k_> + 40 lowercase hex: a short id, uppercase,
or anything else -- a key pasted where its id belongs among them), when another row has the
same C<key_id> (both are rejected), when C<policy> is not C<NULL> and names no key of
C<%policies>, or when C<models> is not C<NULL> and not a list of non-empty names. A rejected row
grants nothing.

A row is labelled by its C<name> when it has one, else by its position in C<@rows> (from 1).
Neither a label nor a reason carries any other value of the row.

=head2 snapshot_digest

  my $digest = Langertha::Skeid::CustomerSource->snapshot_digest(\@rows);

A digest of a snapshot that does not depend on row order: what decides whether a fetch changed
anything. Two fetches of the same rows in another order digest alike.

=head2 merge_into

  my $merge = Langertha::Skeid::CustomerSource->merge_into($config, \@rows);
  # { config => \%merged, allow => [ key ids ], accepted => N,
  #   rejected => [ { row, reason }, ... ], shadowed => [ labels ] }

Merges a snapshot into a file's config (ADR 0026, decision 3). The rows are checked first
(L</check_rows>, against the file's C<policies>). The file wins per key id: an accepted row
whose id the file's C<keys:> names -- directly, through C<names:>, or by a short id that is its
prefix -- or that is itself a C<names:> name, is B<shadowed>: its C<policy> and C<models> are
ignored. Every other accepted row with a C<policy> or C<models> becomes a C<keys:> entry of the
returned config, which is a shallow copy; the file's own config is not changed.

C<allow> lists the id of every accepted row, shadowed ones included, for the C<client_auth>
allowlist; the caller adds them only when the file declares C<client_auth>. Nothing a row
contains can make the merged config fail to load.

=head1 THE FETCH LOOP

An object of this class runs one fetcher on L<Mojo::IOLoop>: a fetch at start, then one every
C<refresh_interval_s>; after a failure the next one waits C<refresh_interval_s> doubled per
failure in a row, at most 60 seconds. A fetch that has not answered within C<connect_timeout_s>
counts as failed, and its answer, should it still come, is ignored. A notification from the
fetcher schedules a fetch C<notify_debounce_s> later (default 0.25), however many arrive in
between. Only one fetch is in flight at a time. Nothing here ever blocks: every wait is a loop
timer.

=head2 config

The normalized section (L</normalize_config>). Required.

=head2 fetcher

The fetcher object. Required.

=head2 on_rows

Called with the rows of every successful fetch, unchanged or not.

=head2 on_failure

Called with the error of every failed fetch.

=head2 notify_debounce_s

How long after a notification the fetch runs (default 0.25).

=head2 last_success_at

=head2 last_failure_at

=head2 failures

=head2 last_error

When the last fetch succeeded, when the last one failed (epoch seconds), how many have failed in
a row, and why the last one did (undef after a success). The error never carries a
C<password=>.

=head2 completed

How many fetches have finished, either way.

=head2 start

Schedules the first fetch for the next loop turn and hands the fetcher its notification
callback. Returns the object.

=head2 stop

Stops for good: no fetch is scheduled any more, an answer still in flight is ignored, and the
fetcher is released.

=head2 release

Lets the fetcher close its connections (its C<release>, when it has one) without stopping the
loop: the next fetch opens them again. C<skeid serve> calls it before the prefork manager forks,
so no worker inherits a connection.

=head2 fetch_now

Runs a fetch at once, unless one is in flight -- then one more runs when it finished.

=head2 retry_delay

The wait before the next fetch after the failures so far: C<refresh_interval_s> doubled per
failure in a row after the first, at most 60 seconds -- the back-off of a failing config reload.

=head2 status

  my $status = $source->status;

The loop's own state, for L<Langertha::Skeid/customer_source_status>: C<ok>, C<last_success_at>,
C<failed_at> (both ISO 8601 UTC or undef), C<failures> and C<error>. C<ok> is true once a fetch
succeeded and the last one did.

=head1 SEE ALSO

=over 4

=item * L<Langertha::Skeid/customer_source> -- the section in the config, and how its rows merge

=item * L<Langertha::Skeid::CustomerSource::DBI> -- the fetcher: DBI in a child process

=item * ADR 0026 in the distribution repository

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
