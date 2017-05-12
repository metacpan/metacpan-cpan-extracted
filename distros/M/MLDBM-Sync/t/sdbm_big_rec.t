
use lib qw(. t);
use strict;
use MLDBM::Sync;
use MLDBM qw(MLDBM::Sync::SDBM_File);
use Fcntl;
use T;
use Carp;
$SIG{__DIE__}  = \&Carp::confess;
$SIG{__WARN__} = \&Carp::cluck;

my $t = T->new();

my %db;
my $sync = tie %db, 'MLDBM::Sync', 'test_dbm', O_RDWR|O_CREAT, 0640;
%db = ();
$t->eok($sync, "can't tie to MLDBM::Sync");
for(1..10) {
    my $key = $_;
    my $value = ('G}'.rand().'*%**') x 200;
    $db{$key} = $value;
    $t->eok($db{$key} eq $value, "can't fetch key $key value $value from db, got $db{$key}");
}
$t->eok(scalar(keys %db) == 10, "key count not successful");

my $del_value = "DELETED".join('', map { rand() } 1..100);
$db{"DEL"} = $del_value;
$t->eok($db{"DEL"} eq $del_value, "failed to add key to delete");
$t->eok(delete $db{"DEL"} eq $del_value, "failed to get right delete return value");

my $short_del = substr($del_value,0,100);
$db{"DEL"} = $del_value;
$db{"DEL"} = $short_del;
$t->eok($db{"DEL"} eq $short_del, "failed to add short value to delete");
$t->eok(delete $db{"DEL"} eq $short_del, "failed to get right short delete return value");

$t->eok(! $db{"DEL"}, "failed to delete key");
$t->eok(scalar(keys %db) == 10, "key count not successful");

%db = ();
$t->eok(scalar(keys %db) == 0, "CLEAR not successful");
$t->done;
