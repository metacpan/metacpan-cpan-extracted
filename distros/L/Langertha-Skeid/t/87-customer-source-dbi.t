use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use Mojo::IOLoop;
use Time::HiRes qw(time);
use Langertha::Skeid::CustomerSource::DBI;

# ADR 0026 (k109): the DBI fetcher connects and queries in a child process, so a database that
# does not answer never stalls the event loop. Offline: DBD::SQLite for the rows, a local TCP
# listener that accepts and says nothing for the connect that hangs.

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite is needed';
eval { require DBD::Pg; 1 }     or plan skip_all => 'DBD::Pg is needed for the hanging connect';

my $FETCHER = 'Langertha::Skeid::CustomerSource::DBI';
my $K1 = 'k_' . ('a' x 40);
my $K2 = 'k_' . ('b' x 40);

sub fetch_sync {
  my ($f) = @_;
  my @got;
  $f->fetch(sub { @got = @_; Mojo::IOLoop->stop });
  my $guard = Mojo::IOLoop->timer(15 => sub { @got = ('test guard: no answer'); Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return @got;
}

# --- rows through a child -------------------------------------------------------------------
{
  my $tmp = tempdir(CLEANUP => 1);
  my $db = "$tmp/c.db";
  require DBI;
  my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1 });
  $dbh->do('CREATE TABLE customer_keys (key_id TEXT, name TEXT, policy TEXT, models TEXT, extra TEXT)');
  $dbh->do('INSERT INTO customer_keys VALUES (?,?,?,?,?)', undef, $K1, 'Acme', 'gold', undef, 'x');
  $dbh->do('INSERT INTO customer_keys VALUES (?,?,?,?,?)', undef, $K2, undef, undef, undef, 'y');
  $dbh->disconnect;

  my $f = $FETCHER->new(config => { dsn => "dbi:SQLite:dbname=$db", relation => 'customer_keys',
    connect_timeout_s => 5 });
  my ($err, $rows) = fetch_sync($f);
  ok !defined($err), 'the fetch succeeds' or diag $err;
  is scalar(@{ $rows // [] }), 2, 'one row per key';
  my ($acme) = grep { $_->{key_id} eq $K1 } @$rows;
  is $acme->{name}, 'Acme', 'the columns arrive by name';
  is $acme->{policy}, 'gold', 'with the policy';
  ok !defined($acme->{models}), 'a NULL models stays undef';

  my $bad = $FETCHER->new(config => { dsn => "dbi:SQLite:dbname=$db", relation => 'no_such',
    connect_timeout_s => 5 });
  my ($e2, $r2) = fetch_sync($bad);
  like $e2, qr/no_such|no such table/i, 'a failing query is an error, not rows';
  ok !defined $r2, 'with no rows';
}

# --- the connect that hangs does not block the loop ------------------------------------------
{
  my $srv = IO::Socket::INET->new(Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0, ReuseAddr => 1)
    or die "listen: $!";
  my $port = $srv->sockport;
  my $f = $FETCHER->new(config => { dsn => "dbi:Pg:dbname=console;host=127.0.0.1;port=$port",
    user => 'u', password => 'sekret-pw', relation => 'skeid.customer_keys',
    connect_timeout_s => 2 });
  my $ticks = 0;
  my $tick = Mojo::IOLoop->recurring(0.05 => sub { $ticks++ });
  my $t0 = time;
  my ($err, $rows) = fetch_sync($f);
  my $took = time - $t0;
  Mojo::IOLoop->remove($tick);
  ok defined($err), 'a database that never answers is an error';
  ok !defined $rows, 'without rows';
  unlike $err, qr/sekret-pw/, 'and the error carries no password';
  ok $took < 8, "the fetch ended inside its bounds (${took}s)";
  cmp_ok $ticks, '>=', 10, "the loop kept ticking while the child waited ($ticks ticks)";
}

# --- scrubbing, DSN, release -------------------------------------------------------------------
{
  is Langertha::Skeid::CustomerSource::DBI::_scrub("boom password=hunter2 here", 'x'),
    'boom password=*** here', 'a password in a driver message is masked';
  is Langertha::Skeid::CustomerSource::DBI::_scrub("the secret abc is out", 'abc'),
    'the secret *** is out', 'and so is the configured one, wherever it appears';

  my $f = $FETCHER->new(config => { dsn => 'dbi:Pg:dbname=c;host=h', relation => 'r', connect_timeout_s => 1 });
  is $f->dsn, 'dbi:Pg:dbname=c;host=h;connect_timeout=2', 'libpq counts whole seconds, at least 2';
  my $named = $FETCHER->new(config => { dsn => 'dbi:Pg:dbname=c;connect_timeout=9', relation => 'r' });
  is $named->dsn, 'dbi:Pg:dbname=c;connect_timeout=9', 'a connect_timeout in the DSN is kept';
  my $lite = $FETCHER->new(config => { dsn => 'dbi:SQLite:dbname=x', relation => 'r' });
  is $lite->dsn, 'dbi:SQLite:dbname=x', 'other drivers get nothing added';

  my $srv = IO::Socket::INET->new(Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0)
    or die "listen: $!";
  my $g = $FETCHER->new(config => { dsn => 'dbi:Pg:dbname=c;host=127.0.0.1;port=' . $srv->sockport,
    relation => 'r', connect_timeout_s => 30 });
  $g->fetch(sub { });
  my $pid;
  my $t = Mojo::IOLoop->timer(0.3 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  $pid = $g->_fetch_sub && $g->_fetch_sub->pid;
  ok $pid && kill(0, $pid), 'the fetch child is running';
  $g->release;
  Mojo::IOLoop->timer(0.5 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  ok !kill(0, $pid), 'release killed the child';
  ok !$g->_fetch_sub, 'and let go of it';
}

done_testing;
