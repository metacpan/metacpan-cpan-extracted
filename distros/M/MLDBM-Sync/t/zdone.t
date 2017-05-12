
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
$t->eok(! glob('test_dbm*'), "can't use %db = () to delete files!");
$t->done;
