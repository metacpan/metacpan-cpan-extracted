package Langertha::Skeid::UsageStore;
our $VERSION = '0.003';
# ABSTRACT: Usage event sink — config normalization and backend factory
use strict;
use warnings;
use Carp qw(croak);


sub normalize_config {
  my ($class, $cfg, %opts) = @_;
  $cfg ||= {};
  croak 'usage_store must be a hashref' unless ref($cfg) eq 'HASH';

  my $backend = lc($cfg->{backend} // '');
  $backend = 'sqlite' if !$backend && (defined($cfg->{sqlite_path}) || defined($cfg->{path}) || defined($cfg->{db_path}));
  $backend = 'postgresql' if !$backend && defined($cfg->{dsn}) && $cfg->{dsn} =~ /^dbi:Pg:/i;
  $backend = 'jsonlog' if !$backend && defined($cfg->{log_path});
  $backend = 'sqlite' unless length $backend;
  $backend = 'postgresql' if $backend =~ /^postgres/;
  $backend = 'jsonlog' if $backend =~ /^json/;

  if ($backend eq 'sqlite') {
    my $path = $cfg->{sqlite_path} // $cfg->{path} // $cfg->{db_path} // $opts{default_sqlite_path};
    if (!defined($path) || !length($path)) {
      croak 'usage_store.sqlite_path (or path/db_path) is required for sqlite backend';
    }
    return {
      backend      => 'sqlite',
      path         => $path,
      dsn          => "dbi:SQLite:dbname=$path",
      user         => '',
      password     => '',
      schema_file  => ($cfg->{schema_file} // ''),
      auto_migrate => exists($cfg->{auto_migrate}) ? ($cfg->{auto_migrate} ? 1 : 0) : 1,
      flush_interval_ms => $class->_flush_interval_ms($cfg),
    };
  }

  if ($backend eq 'postgresql') {
    my $dsn = $cfg->{dsn};
    if (!defined($dsn) || !length($dsn)) {
      my $host = $cfg->{host} // '127.0.0.1';
      my $port = $cfg->{port} // 5432;
      my $name = $cfg->{dbname} // $cfg->{database} // 'skeid';
      $dsn = "dbi:Pg:dbname=$name;host=$host;port=$port";
    }
    my $password = defined($cfg->{password}) ? $cfg->{password} : '';
    if (!length($password) && defined($cfg->{password_env}) && length($cfg->{password_env})) {
      $password = $ENV{$cfg->{password_env}} // '';
    }
    return {
      backend      => 'postgresql',
      path         => '',
      dsn          => $dsn,
      user         => ($cfg->{user} // ''),
      password     => $password,
      schema_file  => ($cfg->{schema_file} // ''),
      auto_migrate => exists($cfg->{auto_migrate}) ? ($cfg->{auto_migrate} ? 1 : 0) : 1,
      flush_interval_ms => $class->_flush_interval_ms($cfg),
    };
  }

  if ($backend eq 'jsonlog') {
    my $path = $cfg->{log_path} // $cfg->{path} // '';
    croak 'usage_store.log_path (or path) is required for jsonlog backend' unless length $path;
    my $mode = $cfg->{mode} // '';
    if (!length($mode)) {
      $mode = (-d $path || $path =~ m{/$}) ? 'dir' : 'file';
    }
    return {
      backend => 'jsonlog',
      path    => $path,
      mode    => $mode,
      fsync   => ($cfg->{fsync} ? 1 : 0),
    };
  }

  croak "unsupported usage_store backend '$backend'";
}

# Write-behind for the DBI backends (skeid k78). 0 -- the default -- is the synchronous write
# every deployment had before; anything else widens the loss window, so it has to be asked for
# with a number that means what it says.
sub _flush_interval_ms {
  my ($class, $cfg) = @_;
  my $ms = $cfg->{flush_interval_ms} // 0;
  croak 'usage_store.flush_interval_ms must be a whole number of milliseconds (0 = write each event at once)'
    unless $ms =~ /\A\d+\z/;
  return 0 + $ms;
}


sub for_config {
  my ($class, $cfg) = @_;
  return unless ref($cfg) eq 'HASH';
  my $backend = $cfg->{backend} // '';
  return unless length $backend;

  if ($backend eq 'jsonlog') {
    require Langertha::Skeid::UsageStore::JsonLog;
    return Langertha::Skeid::UsageStore::JsonLog->new(
      path  => ($cfg->{path} // ''),
      mode  => ($cfg->{mode} // 'dir'),
      fsync => ($cfg->{fsync} ? 1 : 0),
    );
  }

  require Langertha::Skeid::UsageStore::DBI;
  return Langertha::Skeid::UsageStore::DBI->new(
    backend      => $backend,
    dsn          => ($cfg->{dsn} // ''),
    user         => ($cfg->{user} // ''),
    password     => ($cfg->{password} // ''),
    path         => ($cfg->{path} // ''),
    schema_file  => ($cfg->{schema_file} // ''),
    auto_migrate => (exists($cfg->{auto_migrate}) ? ($cfg->{auto_migrate} ? 1 : 0) : 1),
    flush_interval_ms => ($cfg->{flush_interval_ms} // 0),
  );
}


sub num {
  my ($v) = @_;
  return 0 unless defined $v;
  return 0 + $v;
}


sub read_text_file {
  my ($path) = @_;
  open my $fh, '<', $path or die "Cannot open $path: $!";
  local $/;
  my $text = <$fh>;
  close $fh;
  return $text;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::UsageStore - Usage event sink — config normalization and backend factory

=head1 VERSION

version 0.003

=head1 DESCRIPTION

A usage store is where a L<Langertha::Skeid> usage event goes to become durable. One event is
written per forwarded request, including failures, and it is the billing unit — which is why
swapping the backend must never change what an event I<means>. See
F<docs/adr/0004-usage-events-are-the-billing-unit.md>.

This module owns the config shape and hands back the object that implements it:
L<Langertha::Skeid::UsageStore::JsonLog> or L<Langertha::Skeid::UsageStore::DBI>.

=head2 The store contract

A store object answers C<backend> (its name), C<prepare> (create what it needs; called once
when the store is configured, may croak), C<store($event)>, C<report(\%filters)> and
C<disconnect>. A store that can hold events back also answers C<flush> (write what it holds,
answer like C<store> with C<written> and C<lost> counts) and C<disconnect> flushes before it lets
go; L<Langertha::Skeid::UsageStore::DBI> with C<flush_interval_ms> is one. C<store> and
C<report> report failure in their answer rather than dying: the request an event describes has
already been served. The proxy logs a failed C<store> at
C<error> level as a lost usage event, with the request id and the backend name -- never a DSN,
a path or a key. An error text must not carry a secret either; the DBI store masks a
C<password=> from its DSN.

C<store> returns C<< { ok => 1 } >> (with an C<id> where the backend has one),
C<< { ok => 1, queued => 1 } >> for an event held for a later C<flush> -- whose failures the store
reports itself, the proxy's answer having gone out by then -- or
C<< { ok => 0, error => $message } >>. C<report> takes the filters C<since> (an ISO 8601 UTC
timestamp, compared as a string), C<api_key_id>, C<model> (the served model) and C<limit>, and
returns

  {
    ok => 1, enabled => 1, backend => 'jsonlog', since => '...',
    db_path  => '...',                  # DBI stores: the SQLite file, '' for postgresql
    log_path => '...',                  # jsonlog: the event directory or file
    totals   => { requests, input_tokens, output_tokens, total_tokens, cached_tokens,
                  cache_write_tokens, tool_calls, total_cost_usd },
    by_key   => [ { api_key_id, requests, total_tokens, total_cost_usd }, ... ],
    by_model => [ { model, requests, total_tokens, total_cost_usd }, ... ],
    recent   => [ { id, created_at, api_format, endpoint, api_key_id, model, requested_model,
                    node_id, status_code, ok, input_tokens, output_tokens, total_tokens,
                    cached_tokens, cache_write_tokens, tool_calls, cost_total_usd }, ... ],
  }

or C<< { ok => 0, enabled => 0, error => $message } >>. The breakdowns are ordered by cost,
highest first; C<recent> is newest first.

=head2 normalize_config

  my $normalized = Langertha::Skeid::UsageStore->normalize_config($cfg, %opts);

Turns a user-supplied C<usage_store> config into the canonical hashref Skeid keeps on its
C<usage_store> attribute. Backend selection is inference-first, because most configs name only
one thing: an explicit C<backend> wins, otherwise a sqlite path key, a C<dbi:Pg:> DSN or a
C<log_path> decides. C<password_env> reads the password from the environment so it never has
to sit in the file.

C<default_sqlite_path> supplies the path for a sqlite config that names none.

The keys it reads, per backend:

=over 4

=item * C<backend> -- C<jsonlog>, C<sqlite> or C<postgresql> (anything starting with C<json> or
C<postgres> counts). Absent: C<sqlite_path>, C<path> or C<db_path> means sqlite, a C<dbi:Pg:>
C<dsn> means postgresql, C<log_path> means jsonlog, and nothing at all means sqlite -- which then
needs a path. A C<path> alone is therefore a sqlite file; a jsonlog store must say so.

=item * jsonlog -- C<log_path> (or C<path>), required; C<mode> C<dir> or C<file>, default C<dir>
when the path is an existing directory or ends in C</>, else C<file>; C<fsync> (default off).

=item * sqlite -- C<sqlite_path> (or C<path>, C<db_path>), required; C<schema_file> (default:
the shipped one); C<auto_migrate> (default on); C<flush_interval_ms> (default C<0>, write each
event at once; see L<Langertha::Skeid::UsageStore::DBI/flush_interval_ms>).

=item * postgresql -- C<dsn>, else one built from C<host> (default C<127.0.0.1>), C<port> (5432)
and C<dbname> or C<database> (C<skeid>); C<user>; C<password>, or C<password_env> naming the
variable that holds it; C<schema_file>; C<auto_migrate> (default on); C<flush_interval_ms>, as
for sqlite.

=back

Croaks on a config that is not a hashref, a missing path, an unknown backend, or a
C<flush_interval_ms> that is not a whole number of milliseconds.

=head2 for_config

  my $store = Langertha::Skeid::UsageStore->for_config($normalized);

Builds the store object for a normalized config, or returns nothing when no backend is
configured. Does not touch the filesystem or connect — call C<prepare> for that, so that
constructing a Skeid object never has a side effect on disk.

=head2 num

  my $n = Langertha::Skeid::UsageStore::num($row->{total_tokens});

Numeric coercion that treats undef as zero. Reports sum columns that may be C<NULL> on an empty
table, so this is the one place that is allowed to be lax about it.

=head2 read_text_file

  my $sql = Langertha::Skeid::UsageStore::read_text_file($path);

Slurps a file, dying with the path on failure.

=head1 SEE ALSO

=over 4

=item * L<Langertha::Skeid::UsageStore::JsonLog>, L<Langertha::Skeid::UsageStore::DBI>

=item * L<Langertha::Skeid/record_usage>, L<Langertha::Skeid/usage_report> -- what writes and reads a store

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
