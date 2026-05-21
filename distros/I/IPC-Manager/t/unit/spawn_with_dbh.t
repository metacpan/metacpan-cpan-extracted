use Test2::V0;
use File::Temp qw/tempdir/;
use DBI;

use IPC::Manager qw/ipcm_spawn ipcm_connect/;

# SQLite has no system-binary dep so always testable.
skip_all "DBD::SQLite not installed" unless eval { require DBD::SQLite; 1 };

my $dir    = tempdir(CLEANUP => 1);
my $dbfile = "$dir/ipcm.sqlite";

# Pre-create + open a DBI handle.  ipcm_spawn(dbh => $dbh) must
# detect SQLite, run init_db on the supplied handle, and return a
# Spawn object whose route is the bare file path.
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", undef, undef, {
    RaiseError => 1,
    PrintError => 0,
    AutoCommit => 1,
}) or die "connect: $DBI::errstr";

my $spawn = ipcm_spawn(dbh => $dbh);
isa_ok($spawn, ['IPC::Manager::Spawn'], 'spawn object built from dbh');
is($spawn->protocol, 'IPC::Manager::Client::SQLite', 'auto-detected SQLite protocol');
is($spawn->route, $dbfile, 'route reassembled to bare db file');

# Tables exist on the supplied dbh.
my @tables = sort @{$dbh->selectcol_arrayref(
    "SELECT name FROM sqlite_master WHERE type='table'",
)};
is(\@tables, [qw/ipcm_messages ipcm_peers/], 'init_db ran on supplied dbh');

# connect-with-dbh: pass a dbh in lieu of cinfo + verify the bus
# round-trips a message between two clients sharing the same db file.
my $con1 = ipcm_connect('con1', undef, dbh => $dbh);
isa_ok($con1, ['IPC::Manager::Client::SQLite'], 'con1 connected via dbh');

my $dbh2 = DBI->connect("dbi:SQLite:dbname=$dbfile", undef, undef, {
    RaiseError => 1,
    PrintError => 0,
    AutoCommit => 1,
}) or die "connect: $DBI::errstr";
my $con2 = ipcm_connect('con2', undef, dbh => $dbh2);
isa_ok($con2, ['IPC::Manager::Client::SQLite'], 'con2 connected via second dbh');

$con1->send_message('con2' => {hello => 'world'});
my @msgs = $con2->get_messages;
is(scalar(@msgs), 1, 'got one message');
is($msgs[0]->content, {hello => 'world'}, 'content round-tripped');

$con1->disconnect;
$con2->disconnect;

# Info string from spawn must still be usable for a fresh
# (no-dbh) ipcm_connect — that path reconnects via the route.
my $con3 = ipcm_connect('con3', $spawn->info);
isa_ok($con3, ['IPC::Manager::Client::SQLite'], 'con3 connected via info string');
$con3->disconnect;

done_testing;
