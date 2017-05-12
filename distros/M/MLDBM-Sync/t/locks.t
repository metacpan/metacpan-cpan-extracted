
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
%db = ();
$t->eok($sync, "can't tie to MLDBM::Sync");

my %keys;
$sync->Lock;
for(1..100) {
    my $key = $_;
    my $value = rand;
    $db{$key} = $value;
    $keys{$key} = $value;
}
$sync->UnLock;

# test for all in read block
$sync->ReadLock;
for my $key (keys %keys) {
    $t->eok($keys{$key} eq $db{$key}, "can't fetch right value for key $key");
    $t->eok(exists $keys{$key}, "can't exists for key $key in ReadLock() section");
}
$sync->UnLock;

# mix write/read locks
$sync->Lock;
$t->eok(scalar(keys %db) == 100, "key count not successful");
$sync->UnLock;

# read lock then write, should cause error
eval {
    $sync->ReadLock;
    $db{"DEL"} = "DEL"; # should error here
    $sync->UnLock;
};
$t->eok($@, "no error thrown for Read... Write");
$sync->UnLock; # clear the read lock record

%db = ();
$t->eok(scalar(keys %db) == 0, "CLEAR not successful");
$t->done;
