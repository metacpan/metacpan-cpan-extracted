use strict;
use warnings;
use Test::More;
use Mojo::IOLoop;
use JSON::MaybeXS ();
use Time::HiRes ();
use Langertha::Skeid;
use Langertha::Skeid::CustomerSource;
use Langertha::Skeid::CustomerSource::DBI;

# Customer keys from a database view (ADR 0026): the section, the statement Skeid would run, the
# rows it accepts, and how they merge into the file's config. No database: the fetcher is a fake
# that answers on loop timers, and the snapshot reaches the config through the same startup fetch
# `skeid serve` runs.

delete @ENV{qw( SKEID_ADMIN_API_KEY SKEID_TRUST_KEY_ID_HEADER )};

my $CS = 'Langertha::Skeid::CustomerSource';

my @WARN;
$SIG{__WARN__} = sub { push @WARN, $_[0] };

sub id_of { Langertha::Skeid->key_id_for_key($_[0]) }

my $A = id_of('sk-customer-a');
my $B = id_of('sk-customer-b');
my $C = id_of('sk-customer-c');
my $D = id_of('sk-customer-d');          # also in the file, via names:
my $E = id_of('sk-customer-e');          # its short id is in the file's keys:
my $G = id_of('sk-customer-g');          # names a policy the file does not have
my $FILE = id_of('sk-file-only');        # only in the file
my $RAW = 'sk-live-0123456789abcdef-pasted-where-its-id-belongs';

# --- statement shape ---
{
  is $CS->statement('skeid.customer_keys'),
    'SELECT key_id, name, policy, models FROM "skeid"."customer_keys"',
    'schema-qualified relation: each part quoted as an identifier, the four columns by name';
  is $CS->statement('customer_keys'),
    'SELECT key_id, name, policy, models FROM "customer_keys"',
    'a plain relation is quoted too';
  for my $hostile ('customer_keys; DROP TABLE usage_events', 'a"b', 'a.b.c', '', '1keys',
    'keys --', "keys\n", 'a .b', '"skeid"."keys"') {
    ok !eval { $CS->statement($hostile); 1 }, "relation '" . ($hostile =~ s/\n/\\n/r) . "' is rejected";
  }

  # The statement the DBI fetcher sends, read without a driver: building the fetcher loads
  # nothing.
  my $dbi = Langertha::Skeid::CustomerSource::DBI->new(config => { relation => 'skeid.customer_keys' });
  is $dbi->statement, 'SELECT key_id, name, policy, models FROM "skeid"."customer_keys"',
    'the DBI fetcher sends exactly that statement';
  ok !exists $INC{'DBD/Pg.pm'}, 'and building it did not load DBD::Pg';
}

# --- the section ---
{
  my %base = (dsn => 'dbi:Pg:dbname=console;host=db', user => 'skeid_reader',
    relation => 'skeid.customer_keys');
  my $n = $CS->normalize_config({ %base });
  is $n->{backend}, 'postgresql', 'backend defaults to postgresql';
  is $n->{refresh_interval_s}, 30, 'refresh_interval_s defaults to 30';
  is $n->{max_stale_s}, 0, 'max_stale_s defaults to 0: keep the last good set during an outage';
  is $n->{connect_timeout_s}, 5, 'connect_timeout_s defaults to 5';
  ok !defined $n->{listen}, 'no listen: poll only';
  is $n->{dsn}, 'dbi:Pg:dbname=console;host=db', 'the dsn as given';
  is $n->{user}, 'skeid_reader', 'the user';

  local $ENV{T_K108_PW} = 'hunter2-from-env';
  is $CS->normalize_config({ %base, password_env => 'T_K108_PW' })->{password}, 'hunter2-from-env',
    'password_env reads the password from the environment';

  my $built = $CS->normalize_config({ host => 'db', port => 6543, dbname => 'console',
    relation => 'keys' });
  is $built->{dsn}, 'dbi:Pg:dbname=console;host=db;port=6543',
    'host / port / dbname build the dsn as usage_store does';

  my $err = eval { $CS->normalize_config({ %base, password => 'hunter2-in-the-file' }); 1 } ? '' : "$@";
  like $err, qr/password_env/, 'a password in the file is refused, pointing at password_env';
  unlike $err, qr/hunter2/, 'and the refusal does not repeat it';

  like eval { $CS->normalize_config({ %base, refresh_s => 5 }); 1 } ? '' : "$@",
    qr/unknown key 'refresh_s'/, 'an unknown key fails the section';
  like eval { $CS->normalize_config({ %base, backend => 'mysql' }); 1 } ? '' : "$@",
    qr/postgresql/, 'only postgresql';
  like eval { $CS->normalize_config({ %base, dsn => 'dbi:SQLite:dbname=x' }); 1 } ? '' : "$@",
    qr/dbi:Pg:/, 'a dsn that is not dbi:Pg: is refused';
  like eval { $CS->normalize_config({ dsn => $base{dsn} }); 1 } ? '' : "$@",
    qr/relation/, 'relation is required';
  for my $bad (0, -1, 'soon', [], '') {
    ok !eval { $CS->normalize_config({ %base, refresh_interval_s => $bad }); 1 },
      'refresh_interval_s ' . (ref $bad ? 'list' : "'$bad'") . ' is refused';
    ok !eval { $CS->normalize_config({ %base, connect_timeout_s => $bad }); 1 },
      'connect_timeout_s ' . (ref $bad ? 'list' : "'$bad'") . ' is refused';
  }
  ok !eval { $CS->normalize_config({ %base, max_stale_s => -1 }); 1 }, 'max_stale_s below 0 is refused';
  is $CS->normalize_config({ %base, max_stale_s => 120 })->{max_stale_s}, 120, 'max_stale_s above 0';
  is $CS->normalize_config({ %base, listen => 'skeid_customer_keys' })->{listen},
    'skeid_customer_keys', 'listen names a channel';
  ok !eval { $CS->normalize_config({ %base, listen => 'chan; select 1' }); 1 },
    'a listen channel that is not an identifier is refused';
  ok !eval { $CS->normalize_config('postgresql'); 1 }, 'the section is a hash';

  # from_usage_store: the usage store's normalized connection, with user/password_env on top.
  local $ENV{T_K108_READER_PW} = 'reader-secret';
  my $usage = { backend => 'postgresql', host => 'db', dbname => 'skeid', user => 'writer',
    password => 'writer-secret' };
  my $shared = $CS->normalize_config({ from_usage_store => 1, relation => 'keys' }, usage_store => $usage);
  is $shared->{dsn}, 'dbi:Pg:dbname=skeid;host=db;port=5432', 'from_usage_store: the store\'s dsn';
  is $shared->{user}, 'writer', 'its user';
  is $shared->{password}, 'writer-secret', 'its password';
  my $own_role = $CS->normalize_config({ from_usage_store => 1, relation => 'keys', user => 'reader',
    password_env => 'T_K108_READER_PW' }, usage_store => $usage);
  is $own_role->{user}, 'reader', 'user in customer_source overrides the store\'s';
  is $own_role->{password}, 'reader-secret', 'so does password_env';
  like eval { $CS->normalize_config({ from_usage_store => 1, relation => 'keys' },
    usage_store => { backend => 'jsonlog', log_path => '/tmp/x/' }); 1 } ? '' : "$@",
    qr/postgresql/, 'from_usage_store needs a postgresql usage store';
  like eval { $CS->normalize_config({ from_usage_store => 1, relation => 'keys' }); 1 } ? '' : "$@",
    qr/usage_store/, 'from_usage_store needs a usage_store section';
  like eval { $CS->normalize_config({ from_usage_store => 1, dsn => $base{dsn}, relation => 'keys' },
    usage_store => $usage); 1 } ? '' : "$@",
    qr/from_usage_store/, 'from_usage_store and connection parameters of its own do not mix';
}

# --- rows on their own ---
{
  my %policies = (standard => {}, wide => {});
  my $checked = $CS->check_rows([
    { key_id => $A, name => 'alice', policy => 'wide',  models => undef },
    { key_id => $B, name => undef,   policy => undef,   models => ['m2'] },
    { key_id => $C, name => 'carol', policy => undef,   models => [] },
    { key_id => substr($A, 0, 14), name => 'short', policy => undef, models => undef },
    { key_id => uc($B) =~ s/^K_/k_/r, name => undef, policy => undef, models => undef },
    { key_id => $RAW, name => undef, policy => undef, models => undef },
    { key_id => $G, name => 'gina', policy => 'platinum', models => undef },
    { key_id => $D, name => 'dup-1', policy => undef, models => undef },
    { key_id => $D, name => 'dup-2', policy => undef, models => undef },
    { key_id => $E, name => 'eve', policy => undef, models => 'm1' },
    { key_id => $E =~ s/.$/0/r, name => 'empty-model', policy => undef, models => [''] },
    { key_id => $FILE, name => 'blank-policy', policy => '', models => undef },
    undef,
    'not a row',
  ], policies => \%policies);

  is_deeply [ map { $_->{key_id} } @{$checked->{accepted}} ], [ $A, $B, $C ],
    'valid rows are accepted: a policy, a NULL policy with models, NULL vs empty models';
  is_deeply $checked->{accepted}[1]{models}, ['m2'], 'models kept as a list';
  ok !defined $checked->{accepted}[0]{models}, 'NULL models stays NULL (keeps the profile\'s)';
  is_deeply $checked->{accepted}[2]{models}, [], "'{}' stays an empty list (no models)";

  my %why = map { $_->{row} => $_->{reason} } @{$checked->{rejected}};
  is scalar(@{$checked->{rejected}}), 11, 'every other row is rejected';
  like $why{"'short'"}, qr/full key id/, 'a short id is rejected';
  like $why{'row 5'}, qr/full key id/, 'an uppercase id is rejected, reported by position';
  like $why{'row 6'}, qr/full key id/, 'a raw key in key_id is rejected, reported by position';
  like $why{"'gina'"}, qr/policy/, 'an unknown policy is rejected';
  like $why{"'dup-1'"}, qr/more than one row/, 'a duplicated key_id rejects the first row';
  like $why{"'dup-2'"}, qr/more than one row/, 'and the second';
  like $why{"'eve'"}, qr/models/, 'models that are not a list are rejected';
  like $why{"'empty-model'"}, qr/models/, 'models with an empty name are rejected';
  like $why{"'blank-policy'"}, qr/policy/, 'an empty policy names no profile';
  like $why{'row 13'}, qr/row/, 'a row that is no row is rejected';
  like $why{'row 14'}, qr/row/, 'whatever it is';

  my $dump = JSON::MaybeXS->new(canonical => 1)->encode($checked->{rejected});
  for my $value ($RAW, 'platinum', substr($A, 0, 14), $G, $D, 'm1') {
    unlike $dump, qr/\Q$value\E/, "a rejection does not carry the value '$value'";
  }
}

# --- merged into the file ---

{
  package FakeFetcher;
  sub new { my ($class, %a) = @_; return bless { rows => [], error => undef, fetches => 0, %a }, $class }
  sub fetch {
    my ($self, $cb) = @_;
    $self->{fetches}++;
    my ($error, $rows) = ($self->{error}, [ map { ref $_ eq 'HASH' ? {%$_} : $_ } @{$self->{rows}} ]);
    Mojo::IOLoop->timer(0.001 => sub { $error ? $cb->($error) : $cb->(undef, $rows) });
    return;
  }
}

my $SOURCE = { dsn => 'dbi:Pg:dbname=console', relation => 'skeid.customer_keys' };

sub skeid_with {
  my ($cfg, $fake) = @_;
  my $current = $cfg;
  my $skeid = Langertha::Skeid->new(
    config_reload_interval  => 0,
    config_loader           => sub { $current },
    customer_source_fetcher => sub { $fake },
  );
  return ($skeid, sub { $current = $_[0] });
}

sub fetch_once {
  my ($skeid) = @_;
  $skeid->start_customer_source;
  return $skeid->customer_source_startup_fetch;
}

my %FILE_CFG = (
  policies       => { standard => { models => ['m1'] }, wide => {}, narrow => { models => ['m3'] } },
  default_policy => 'standard',
  names          => { fileguy => $D },
  keys           => { fileguy => 'narrow', substr($E, 0, 14) => 'narrow' },
  client_auth    => { keys => [ $FILE ] },
  customer_source => $SOURCE,
);

{
  @WARN = ();
  my $fake = FakeFetcher->new(rows => [
    { key_id => $A, name => 'alice', policy => 'wide',     models => undef },
    { key_id => $B, name => 'bob',   policy => undef,      models => ['m2'] },
    { key_id => $C, name => 'carol', policy => undef,      models => undef },
    { key_id => $D, name => 'dora',  policy => 'standard', models => undef },
    { key_id => $E, name => 'eve',   policy => 'wide',     models => undef },
    { key_id => $RAW, name => undef, policy => 'wide',     models => undef },
    { key_id => $G, name => 'gina',  policy => 'platinum', models => undef },
  ]);
  my ($skeid) = skeid_with({ %FILE_CFG }, $fake);

  ok !$skeid->client_key_allowed($A), 'before the first fetch no source key is let in';
  ok fetch_once($skeid), 'the first fetch succeeds';
  is $fake->{fetches}, 1, 'one fetch';

  ok !defined $skeid->policy_for_key($A)->{allow_models}, 'a row\'s policy applies (wide)';
  is_deeply $skeid->policy_for_key($B)->{allow_models}, { m2 => 1 },
    'NULL policy with models: default_policy narrowed to the row\'s models';
  is $skeid->policy_for_key($C), $skeid->default_policy, 'NULL policy, NULL models: default_policy';
  is_deeply $skeid->policy_for_key($D)->{allow_models}, { m3 => 1 },
    'the file wins over a row for an id it names through names:';
  is_deeply $skeid->policy_for_key($E)->{allow_models}, { m3 => 1 },
    'and for an id whose short id it lists';
  is $skeid->policy_for_key($G), $skeid->default_policy, 'a rejected row gets no policy entry';
  ok !exists $skeid->key_policies->{$G}, 'not even an empty one';

  ok $skeid->client_key_allowed($_), "accepted row is on the allowlist" for $A, $B, $C;
  ok $skeid->client_key_allowed($D), 'a shadowed row is still on the allowlist';
  ok $skeid->client_key_allowed($FILE), 'the file\'s own entry stays: the allowlist is a union';
  ok !$skeid->client_key_allowed($G), 'a rejected row is not let in';
  ok !$skeid->client_key_allowed(id_of($RAW)), 'nor the key a raw key_id belongs to';
  ok !$skeid->client_key_allowed($RAW), 'nor the raw value itself';

  my $status = $skeid->customer_source_status;
  is $status->{ok}, 1, 'status ok';
  is_deeply [ @{$status->{rows}}{qw(accepted rejected shadowed)} ], [ 5, 2, 2 ],
    'rows accepted, rejected and shadowed are counted';
  is $status->{relation}, 'skeid.customer_keys', 'the relation is named';

  my $out = join('', @WARN) . JSON::MaybeXS->new(canonical => 1)->encode($status);
  like $out, qr/row 6/, 'the raw key_id row is reported by position';
  like $out, qr/'gina'/, 'a named row by its name';
  unlike $out, qr/\Q$RAW\E/, 'the raw key never appears in a warning or the status';
  unlike $out, qr/platinum/, 'nor does any other rejected value';
  unlike $out, qr/dbi:Pg|password/, 'nor the connection';
  like join('', @WARN), qr/'dora'.*shadowed|shadowed.*'dora'/s, 'a shadowed row is reported';
}

# --- the file cannot revoke through the database, nor refer to its names ---
{
  my $fake = FakeFetcher->new(rows => [ { key_id => $A, name => 'db-alice', policy => undef, models => undef } ]);
  my ($skeid, $set) = skeid_with({ %FILE_CFG }, $fake);
  fetch_once($skeid);
  ok !defined $skeid->key_id_for_name('db-alice'), 'a database name is not a names: entry';
  $set->({ %FILE_CFG, client_auth => { keys => [ $FILE, 'db-alice' ] } });
  my $err = eval { $skeid->reload_config; 1 } ? '' : "$@";
  like $err, qr/client_auth\.keys entry 2/, 'the file cannot name a customer by its database name';
  ok $skeid->client_key_allowed($A), 'and the failed reload kept the merged config in force';
}

# --- without client_auth: a warning, and no gate ---
{
  @WARN = ();
  my %cfg = %FILE_CFG;
  delete $cfg{client_auth};
  my $fake = FakeFetcher->new(rows => [ { key_id => $A, name => 'alice', policy => 'wide', models => undef } ]);
  my ($skeid, $set) = skeid_with(\%cfg, $fake);
  fetch_once($skeid);
  ok !$skeid->client_auth_enabled, 'the source adds no gate of its own';
  ok !defined $skeid->policy_for_key($A)->{allow_models}, 'the row\'s policy still applies';
  $set->({ %cfg, pricing => {} });
  $skeid->reload_config;
  my @gate = grep { /client_auth/ && /customer_source/ } @WARN;
  is scalar(@gate), 1, 'the missing client_auth is warned once, not per reload';
  like $gate[0] // '', qr/revoked/, 'saying what it means for a revoked key';
}

# --- no row content can fail a reload ---
{
  my $fake = FakeFetcher->new(rows => [
    undef, 'x', [], { key_id => [] }, { key_id => { a => 1 } }, { key_id => $A, models => { a => 1 } },
    { key_id => $B, policy => [] }, { key_id => $C, name => [], policy => 'wide', models => [ [] ] },
    { key_id => $A, policy => 'standard' },
  ]);
  my ($skeid) = skeid_with({ %FILE_CFG }, $fake);
  ok fetch_once($skeid), 'a snapshot full of junk is still a successful fetch';
  is $skeid->reload_status->{ok}, 1, 'and the reload it triggered applied';
  ok $skeid->client_key_allowed($FILE), 'the file\'s config is in force';
  ok !$skeid->client_key_allowed($_), 'no junk row let anyone in' for $A, $B, $C;
}

# --- the driver is loaded only for a configured source, and named when missing ---
{
  my $hide = sub { die "Can't locate DBD/Pg.pm in \@INC (hidden by the test)\n" if $_[1] eq 'DBD/Pg.pm'; return };
  local @INC = ($hide, @INC);
  local $INC{'DBD/Pg.pm'};
  delete $INC{'DBD/Pg.pm'};
  my $err = eval {
    Langertha::Skeid->new(config_loader => sub { { customer_source => $SOURCE } });
    1;
  } ? '' : "$@";
  like $err, qr/DBD::Pg/, 'a configured source without DBD::Pg fails the load, naming the module';
  ok eval { Langertha::Skeid->new(config_loader => sub { { nodes => [] } }); 1 },
    'without a source nothing needs it';
  ok eval {
    Langertha::Skeid->new(config_loader => sub { { customer_source => $SOURCE } },
      customer_source_fetcher => sub { FakeFetcher->new });
    1;
  }, 'an injected fetcher needs no driver';
  like eval {
    Langertha::Skeid->new(config_loader => sub { { customer_source => { %$SOURCE,
      relation => 'keys; DROP TABLE usage_events' } } },
      customer_source_fetcher => sub { FakeFetcher->new });
    1;
  } ? '' : "$@", qr/relation/, 'a hostile relation fails the load';
}

done_testing;
