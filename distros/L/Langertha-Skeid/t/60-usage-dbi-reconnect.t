use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Test::File::ShareDir -share => {
  -dist => { 'Langertha-Skeid' => 'share' },
};
use Langertha::Skeid;
use Langertha::Skeid::UsageStore::DBI;

# A usage event is the billing unit (ADR 0004). When the database connection drops under a
# running store, the store used to keep the dead handle, and every later event was lost until
# restart (skeid k71). A failed write on a dead handle now reconnects once and retries that one
# event; a write that fails on a live handle is not retried, and a reconnect that fails is
# reported like any other lost event -- never a die, never a loop.

eval { require DBI; require DBD::SQLite; 1 } or plan skip_all => 'DBI/DBD::SQLite not available';

sub event {
  my ($request_id) = @_;
  return {
    created_at   => '2026-09-29T00:00:00Z',
    request_id   => $request_id,
    api_format   => 'openai',
    endpoint     => '/v1/chat/completions',
    api_key_id   => 'k_test',
    model        => 'm1',
    node_id      => 'n1',
    status_code  => 200,
    ok           => 1,
    input_tokens => 7, output_tokens => 3, total_tokens => 10, tool_calls => 0,
    cost_input_usd => 0, cost_output_usd => 0, cost_total_usd => 0,
  };
}

sub rows_for {
  my ($store, $request_id) = @_;
  my ($count) = $store->dbh->selectrow_array(
    'SELECT COUNT(*) FROM usage_events WHERE request_id = ?', undef, $request_id);
  return $count;
}

sub new_store {
  my $dir = tempdir(CLEANUP => 1);
  my $store = Langertha::Skeid::UsageStore::DBI->new(
    backend => 'sqlite',
    dsn     => "dbi:SQLite:dbname=$dir/usage.sqlite",
    path    => "$dir/usage.sqlite",
  );
  $store->prepare;
  return $store;
}

# --- The connection drops under the store: the next event reconnects and is written ----------
{
  my $store = new_store();
  ok $store->store(event('req-before'))->{ok}, 'an event is written while connected';

  my $dead = $store->dbh;
  $dead->disconnect;

  my $res = $store->store(event('req-after-drop'));
  ok $res->{ok}, 'after the connection dropped, the next event is still written'
    or diag explain $res;
  ok $res->{id}, 'with the row id of the retried insert';
  isnt $store->dbh, $dead, 'on a new handle';
  is rows_for($store, 'req-after-drop'), 1, 'the event is in the table exactly once';
  is rows_for($store, 'req-before'), 1, 'and the earlier event is still there';

  ok $store->store(event('req-later'))->{ok}, 'later events use the new handle';
  is rows_for($store, 'req-later'), 1, 'and land in the table';
}

# --- report survives a dropped connection the same way ---------------------------------------
{
  my $store = new_store();
  ok $store->store(event('req-report'))->{ok}, 'an event to report on';
  $store->dbh->disconnect;

  my $report = $store->report({});
  ok $report->{ok}, 'report reconnects after the connection dropped' or diag explain $report;
  is $report->{totals}{requests}, 1, 'and reports what the table holds';
}

# --- A statement that fails on a live handle is not retried and does not reconnect -----------
{
  my $store = new_store();
  my $live = $store->dbh;
  $live->do('DROP TABLE usage_events');

  my $res = $store->store(event('req-no-table'));
  ok !$res->{ok}, 'a failed statement on a live handle is reported';
  like $res->{error} // '', qr/usage_events/, 'with the database error';
  is $store->dbh, $live, 'the live handle is kept, no reconnect';
}

# --- The reconnect itself fails: a clean { ok => 0 }, no die, no secret ----------------------
{
  my $store = new_store();
  $store->dbh->disconnect;

  my $connects = 0;
  my $res = do {
    no warnings 'redefine';
    local *DBI::connect = sub {
      $connects++;
      die "DBI connect('dbname=skeid;host=db;password=hunter2','skeid',...) failed: "
        . "could not connect to server: Connection refused\n";
    };
    eval { $store->store(event('req-reconnect-fails')) };
  };
  is $@, '', 'a failing reconnect does not die';
  ok $res && !$res->{ok}, 'it is reported as a failed store';
  is $connects, 1, 'the reconnect is tried exactly once';
  like $res->{error} // '', qr/reconnect/i, 'the error says the reconnect failed';
  like $res->{error} // '', qr/Connection refused/, 'and why';
  unlike $res->{error} // '', qr/hunter2/, 'with no password in it';

  my $report = do {
    no warnings 'redefine';
    local *DBI::connect = sub { die "could not connect to server: Connection refused\n" };
    $store->report({});
  };
  ok !$report->{ok} && !$report->{enabled}, 'report answers a failed reconnect the same way';

  # The database comes back: the store recovers without a restart.
  my $again = $store->store(event('req-db-back'));
  ok $again->{ok}, 'once the database answers again, the next event is written'
    or diag explain $again;
  is rows_for($store, 'req-db-back'), 1, 'and is in the table';
}

done_testing;
