
use lib qw(. t);
use strict;
use MLDBM::Sync;
use Fcntl;
use T;
use Carp;
$SIG{__WARN__} = \&Carp::cluck;

my $t = T->new();

my %db;
my $sync = tie %db, 'MLDBM::Sync', 'test_dbm', O_RDWR|O_CREAT, 0640;
$sync->SyncKeysChecksum(1);
%db = ();
$t->eok($sync, "can't tie to MLDBM::Sync");

my %keys;
$sync->Lock;
for(1..100) {
    my $key = $_ x 1000; # only checksumming will work for this
    my $value = rand;
    $db{$key} = $value;
    $keys{$key} = $value;
}
$sync->UnLock;

my @keys = eval { keys %db; };
my $error = $@;
$t->eok(! scalar(@keys), "keys should return undef");
$t->eok($error, "keys should return an error on a SyncKeysChecksum(1) database");

# test for all in read block
$sync->ReadLock;
for my $key (keys %keys) {
    $t->eok($keys{$key} eq $db{$key}, "can't fetch right value for key $key");
}
$sync->UnLock;

%db = ();
$t->eok($sync->SyncSize == 0, 'dbm size should be 0 bytes after clear');
$t->done;
