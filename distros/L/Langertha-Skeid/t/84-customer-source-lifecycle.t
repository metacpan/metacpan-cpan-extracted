use strict;
use warnings;
use Test::More;
use Mojo::IOLoop;
use Time::HiRes ();
use Langertha::Skeid;

# The customer source's fetcher on the event loop (ADR 0026): the poll, the reload a changed
# snapshot triggers and the no-op an unchanged one is, keep-last-good with back-off, max_stale_s,
# restart on a changed section, drop on a removed one, a degraded fail-closed start, and the
# NOTIFY debounce. The fetcher is a fake on loop timers; nothing here talks to a database.

delete @ENV{qw( SKEID_ADMIN_API_KEY SKEID_TRUST_KEY_ID_HEADER )};

my @WARN;
$SIG{__WARN__} = sub { push @WARN, $_[0] };

sub id_of { Langertha::Skeid->key_id_for_key($_[0]) }
my $A    = id_of('sk-customer-a');
my $B    = id_of('sk-customer-b');
my $FILE = id_of('sk-file-only');

{
  package FakeFetcher;
  # Answers its rows (or its error) on a loop timer; silent answers nothing at all. Every fetch
  # is counted and timed.
  sub new { my ($class, %a) = @_; return bless { rows => [], error => undef, silent => 0, at => [], %a }, $class }
  sub fetch {
    my ($self, $cb) = @_;
    push @{$self->{at}}, Time::HiRes::time();
    $self->{pending} = $cb;
    return if $self->{silent};
    my ($error, $rows) = ($self->{error}, [ map { {%$_} } @{$self->{rows}} ]);
    Mojo::IOLoop->timer(0.001 => sub { $error ? $cb->($error) : $cb->(undef, $rows) });
    return;
  }
  sub fetches { scalar @{$_[0]{at}} }
  sub on_notify { $_[0]{notify} = $_[1] }
  sub notify { $_[0]{notify}->() }
  sub release { $_[0]{released}++ }
}

sub wait_until {
  my ($cond, $max) = @_;
  my $end  = Time::HiRes::time() + ($max // 3);
  my $tick = Mojo::IOLoop->recurring(0.005 => sub { });
  Mojo::IOLoop->one_tick until $cond->() || Time::HiRes::time() > $end;
  Mojo::IOLoop->remove($tick);
  return $cond->() ? 1 : 0;
}

sub settle { my ($s) = @_; wait_until(sub { 0 }, $s) }

sub row { my ($id, %r) = @_; return { key_id => $id, name => undef, policy => undef, models => undef, %r } }

sub source { return { dsn => 'dbi:Pg:dbname=console', relation => 'skeid.customer_keys',
  refresh_interval_s => 0.1, connect_timeout_s => 0.5, @_ } }

sub cfg {
  my (%source) = @_;
  return {
    nodes           => [ { id => 'n1', url => 'http://n1/v1', model => 'm' } ],
    policies        => { standard => {}, narrow => { models => ['m'] } },
    client_auth     => { keys => [ $FILE ] },
    customer_source => source(%source),
  };
}

sub skeid_with {
  my ($cfg, @fakes) = @_;
  my $current = $cfg;
  my ($built, $loads) = (0, 0);
  my $skeid = Langertha::Skeid->new(
    config_reload_interval  => 0,
    config_loader           => sub { $loads++; $current },
    customer_source_fetcher => sub { $built++; return $fakes[$built - 1] // $fakes[-1] },
  );
  return ($skeid, sub { $current = $_[0] }, \$built, \$loads);
}

# --- first snapshot, unchanged snapshot, changed snapshot ---
{
  my $fake = FakeFetcher->new(rows => [ row($A) ]);
  my ($skeid, undef, undef, $loads) = skeid_with(cfg(), $fake);
  $skeid->start_customer_source;
  ok wait_until(sub { $skeid->client_key_allowed($A) }), 'the first snapshot is applied';

  my $print = $skeid->_config_fingerprint;
  my $gen   = $skeid->_inventory_generation;
  my $seen  = $fake->fetches;
  my $read  = $$loads;
  ok wait_until(sub { $fake->fetches >= $seen + 2 }), 'the poll keeps fetching';
  is $skeid->_config_fingerprint, $print, 'an unchanged snapshot changes no fingerprint';
  is $skeid->_inventory_generation, $gen, 'and bumps no inventory';
  is $$loads, $read, 'and triggers no reload: the config is not even read';

  # The same rows in another order are the same snapshot.
  $fake->{rows} = [ row($B), row($A) ];
  ok wait_until(sub { $skeid->client_key_allowed($B) }), 'a changed snapshot reloads';
  isnt $skeid->_config_fingerprint, $print, 'with a new fingerprint';
  is $skeid->_inventory_generation, $gen, 'an unchanged nodes section keeps the node list';
  $print = $skeid->_config_fingerprint;
  $fake->{rows} = [ row($A), row($B) ];
  $seen = $fake->fetches;
  wait_until(sub { $fake->fetches >= $seen + 2 });
  is $skeid->_config_fingerprint, $print, 'row order is no change';

  $fake->{rows} = [ row($B) ];
  ok wait_until(sub { !$skeid->client_key_allowed($A) }), 'a row that disappears revokes its key';
  ok $skeid->client_key_allowed($FILE), 'the file\'s entries stay';
  $skeid->stop_customer_source;
}

# --- a failing fetch keeps the last good snapshot, backs off, logs a new reason once ---
{
  @WARN = ();
  my $fake = FakeFetcher->new(rows => [ row($A) ]);
  my ($skeid) = skeid_with(cfg(), $fake);
  $skeid->start_customer_source;
  wait_until(sub { $skeid->client_key_allowed($A) });
  my $last_ok = $skeid->customer_source_status->{last_success_at};
  ok $last_ok, 'last success is recorded';

  $fake->{error} = 'connection refused';
  my $from = $fake->fetches;
  ok wait_until(sub { $fake->fetches >= $from + 4 }, 4), 'it keeps retrying';
  ok $skeid->client_key_allowed($A), 'the last good snapshot stays in force';
  my $status = $skeid->customer_source_status;
  is $status->{ok}, 0, 'status: not ok';
  cmp_ok $status->{failures}, '>=', 3, 'consecutive failures are counted';
  like $status->{error}, qr/connection refused/, 'the error is reported';
  ok $status->{failed_at}, 'with when';
  is $status->{last_success_at}, $last_ok, 'and when it last succeeded';

  my @at = @{$fake->{at}}[$from - 1 .. $from + 3];
  my @gap = map { $at[$_ + 1] - $at[$_] } 0 .. $#at - 1;
  cmp_ok $gap[3], '>', $gap[1] * 1.5, 'the retries back off (doubling from refresh_interval_s)';
  cmp_ok $gap[3], '>=', 0.35, 'the fourth retry waits 0.1 * 2**2 = 0.4s';

  my @logged = grep { /customer_source/ && /connection refused/ } @WARN;
  is scalar(@logged), 1, 'the failure is logged once, not per retry';

  $fake->{error} = 'timeout expired';
  my $now = $fake->fetches;
  wait_until(sub { $fake->fetches > $now });
  wait_until(sub { 0 }, 0.05);
  is scalar(grep { /timeout expired/ } @WARN), 1, 'a new reason is logged';

  $fake->{error} = undef;
  $fake->{rows}  = [ row($A), row($B) ];
  ok wait_until(sub { $skeid->client_key_allowed($B) }, 3), 'it recovers';
  is $skeid->customer_source_status->{ok}, 1, 'status ok again';
  is $skeid->customer_source_status->{failures}, 0, 'failures reset';
  $skeid->stop_customer_source;
}

# --- max_stale_s: the rows go after the limit, and come back on success ---
{
  my $fake = FakeFetcher->new(rows => [ row($A) ]);
  my ($skeid) = skeid_with(cfg(max_stale_s => 0.3), $fake);
  $skeid->start_customer_source;
  wait_until(sub { $skeid->client_key_allowed($A) });
  $fake->{error} = 'down';
  my $t0 = Time::HiRes::time();
  settle(0.15);
  ok $skeid->client_key_allowed($A), 'within max_stale_s the last good set holds';
  ok wait_until(sub { !$skeid->client_key_allowed($A) }, 2), 'past it the source rows are dropped';
  cmp_ok Time::HiRes::time() - $t0, '>=', 0.15, 'not before the limit';
  is $skeid->customer_source_status->{stale}, 1, 'status says stale';
  ok $skeid->client_key_allowed($FILE), 'the file\'s config stays';
  $fake->{error} = undef;
  ok wait_until(sub { $skeid->client_key_allowed($A) }, 3), 'a successful fetch brings them back';
  is $skeid->customer_source_status->{stale}, 0, 'not stale any more';
  $skeid->stop_customer_source;
}

# --- max_stale_s 0 (the default): kept indefinitely ---
{
  my $fake = FakeFetcher->new(rows => [ row($A) ]);
  my ($skeid) = skeid_with(cfg(), $fake);
  $skeid->start_customer_source;
  wait_until(sub { $skeid->client_key_allowed($A) });
  $fake->{error} = 'down';
  settle(0.6);
  ok $skeid->client_key_allowed($A), 'max_stale_s 0 keeps the last good set';
  $skeid->stop_customer_source;
}

# --- a changed customer_source restarts the fetcher; the old rows stay until the new fetch ---
{
  my $old = FakeFetcher->new(rows => [ row($A) ]);
  my $new = FakeFetcher->new(rows => [ row($B) ], silent => 1);
  my $third = FakeFetcher->new(rows => [ row($B) ], silent => 1);
  my ($skeid, $set, $built) = skeid_with(cfg(), $old, $new, $third);
  $skeid->start_customer_source;
  wait_until(sub { $skeid->client_key_allowed($A) });
  is $$built, 1, 'one fetcher';

  $set->(cfg(relation => 'skeid.customer_keys_v2', connect_timeout_s => 30));
  $skeid->maybe_reload_config;
  is $$built, 2, 'a changed section builds a new fetcher';
  is $old->{released}, 1, 'and lets the old one go';
  ok wait_until(sub { $new->fetches >= 1 }), 'the new one fetches';
  my $old_fetches = $old->fetches;
  ok $skeid->client_key_allowed($A), 'the old snapshot stays until the new source answered';
  $new->{pending}->(undef, [ row($B) ]);
  ok wait_until(sub { $skeid->client_key_allowed($B) }), 'the new snapshot replaces it';
  ok !$skeid->client_key_allowed($A), 'the old rows are gone';
  settle(0.3);
  is $old->fetches, $old_fetches, 'the old fetcher fetches no more';

  # An unchanged section keeps the fetcher.
  $set->({ %{cfg(relation => 'skeid.customer_keys_v2', connect_timeout_s => 30)}, pricing => {} });
  $skeid->maybe_reload_config;
  is $$built, 2, 'another section changing keeps the fetcher';
  ok $skeid->client_key_allowed($B), 'and the snapshot';

  # Removed from the file: the rows go at that reload.
  my $removed = cfg();
  delete $removed->{customer_source};
  $set->($removed);
  $skeid->maybe_reload_config;
  ok !$skeid->client_key_allowed($B), 'a removed section drops the source rows';
  ok $skeid->client_key_allowed($FILE), 'the file\'s stay';
  ok !defined $skeid->customer_source_status, 'no status for a source that is not configured';
  is $new->{released}, 1, 'the fetcher is let go';
  my $after = $new->fetches;
  settle(0.3);
  is $new->fetches, $after, 'and fetches no more';

  # Back in the file: the dropped rows do not come back before the source answered again.
  $set->(cfg(connect_timeout_s => 30));
  $skeid->maybe_reload_config;
  is $$built, 3, 'a source added again gets a fetcher';
  ok !$skeid->client_key_allowed($B), 'and starts from no snapshot';
}

# --- startup with a failing fetch: degraded, fail-closed, recovering with back-off ---
{
  @WARN = ();
  my $fake = FakeFetcher->new(rows => [ row($A) ], error => 'could not connect');
  my ($skeid) = skeid_with(cfg(), $fake);
  $skeid->start_customer_source;
  my $t0 = Time::HiRes::time();
  ok !$skeid->customer_source_startup_fetch, 'the startup fetch reports its failure';
  cmp_ok Time::HiRes::time() - $t0, '<', 1, 'without waiting longer than it has to';
  ok !$skeid->client_key_allowed($A), 'fail-closed: no source key is let in';
  ok $skeid->client_key_allowed($FILE), 'the file\'s customers are served';
  is $skeid->reload_status->{ok}, 1, 'the config itself loaded';
  is $skeid->customer_source_status->{ok}, 0, 'the source is reported failing';
  ok scalar(grep { /could not connect/ } @WARN), 'and logged';
  $fake->{error} = undef;
  ok wait_until(sub { $skeid->client_key_allowed($A) }, 3), 'the retry brings the rows in';
  $skeid->stop_customer_source;
}

# --- a fetch that never answers is timed out, its late answer ignored ---
{
  my $fake = FakeFetcher->new(rows => [ row($A) ], silent => 1);
  my ($skeid) = skeid_with(cfg(connect_timeout_s => 0.1, refresh_interval_s => 30), $fake);
  $skeid->start_customer_source;
  my $t0 = Time::HiRes::time();
  ok !$skeid->customer_source_startup_fetch, 'a silent startup fetch fails';
  cmp_ok Time::HiRes::time() - $t0, '<', 1, 'after connect_timeout_s';
  like $skeid->customer_source_status->{error}, qr/timed out/, 'as a timeout';
  $fake->{pending}->(undef, [ row($A) ]);
  settle(0.05);
  ok !$skeid->client_key_allowed($A), 'the late answer is ignored';
  $skeid->stop_customer_source;
}

# --- NOTIFY: a fetch after the debounce, a burst coalesces, the poll runs without it ---
{
  my $fake = FakeFetcher->new(rows => [ row($A) ]);
  my ($skeid) = skeid_with(cfg(refresh_interval_s => 30, listen => 'skeid_customer_keys'), $fake);
  $skeid->start_customer_source;
  wait_until(sub { $skeid->client_key_allowed($A) });
  ok $fake->{notify}, 'the fetcher was given a notification callback';
  my $n = $fake->fetches;

  $fake->{rows} = [ row($A), row($B) ];
  $fake->notify;
  settle(0.1);
  is $fake->fetches, $n, 'no fetch before the debounce';
  ok wait_until(sub { $fake->fetches == $n + 1 }, 1), 'one fetch after it';
  ok wait_until(sub { $skeid->client_key_allowed($B) }), 'and its snapshot is applied';

  $n = $fake->fetches;
  $fake->notify for 1 .. 10;
  settle(0.15);
  $fake->notify for 1 .. 10;
  settle(0.6);
  is $fake->fetches, $n + 1, 'a burst of notifications costs one fetch';
  $skeid->stop_customer_source;
}
{
  my $fake = FakeFetcher->new(rows => [ row($A) ]);
  my ($skeid) = skeid_with(cfg(refresh_interval_s => 0.1, listen => 'skeid_customer_keys'), $fake);
  $skeid->start_customer_source;
  wait_until(sub { $skeid->client_key_allowed($A) });
  my $n = $fake->fetches;
  ok wait_until(sub { $fake->fetches >= $n + 2 }, 1), 'without notifications the poll still runs';
  $skeid->stop_customer_source;
}

# --- prefork: a released source fetches again at once, in the worker (found against PostgreSQL)
# `skeid serve --workers N` releases the fetcher before forking; the workers inherit the poll
# timer, which is refresh_interval_s away. Without an immediate fetch no worker has a LISTEN
# connection until then, and a revocation waits the whole poll interval.
{
  my $fake = FakeFetcher->new(rows => [ row($A) ]);
  my ($skeid) = skeid_with(cfg(refresh_interval_s => 3600, listen => 'skeid_customer_keys'), $fake);
  $skeid->start_customer_source;
  ok wait_until(sub { $skeid->client_key_allowed($A) }), 'first fetch';
  my $n = $fake->fetches;
  $skeid->customer_source_release;
  is $fake->{released}, 1, 'the fetcher was released';
  ok wait_until(sub { $fake->fetches == $n + 1 }, 1),
    'a fetch runs as soon as the loop runs (the worker), not one poll interval later';
  $skeid->stop_customer_source;
}

done_testing;
