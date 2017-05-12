
use lib qw(. t);
use strict;
use MLDBM::Sync;
use Fcntl;
use T;
use Carp;
$SIG{__WARN__} = \&Carp::cluck;

my $t = T->new();

eval "use Tie::Cache";
if($@) {
    $t->skip('Tie::Cache not installed');
}

my %db;
my $sync = tie %db, 'MLDBM::Sync', 'test_dbm', O_RDWR|O_CREAT, 0640;

for my $cache_size (10240, '10K', '.01M') {
    eval { $sync->SyncCacheSize($cache_size); };
    $t->eok($sync->{cache}{max_bytes} == 10240, "failed to init cache of 10240 bytes");
}

%db = ();
$t->eok($sync, "can't tie to MLDBM::Sync");
for(1..100) {
    my $key = $_;
    my $value = rand;
    $db{$key} = $value;
    $t->eok($db{$key} eq $value, "can't fetch key $key value $value from db");
}
$t->eok(scalar(keys %db) == 100, "key count not successful");

$db{"DEL"} = "DEL";
$t->eok($db{"DEL"}, "failed to add key to delete");
delete $db{"DEL"};
$t->eok(! $db{"DEL"}, "failed to delete key");
$t->eok(scalar(keys %db) == 100, "key count not successful");

%db = ();
$t->eok(scalar(keys %db) == 0, "CLEAR not successful");
$t->done;
