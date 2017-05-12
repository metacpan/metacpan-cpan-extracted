# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 7;
BEGIN { use_ok('Db::GTM') };
$ENV{'GTMCI'}="/usr/local/gtm/xc/calltab.ci" unless $ENV{'GTMCI'};

#########################

my $db = new GTMDB('SPZ');

$db->kill("TEST_TXN");
$db->set("TEST_TXN","PREDEF",50);
$db->set("TEST_TXN","PREDEF","KILL",50);

$db->txnstart();
$db->set("TEST_TXN","NEWDEF",1000);
$db->set("TEST_TXN","PREDEF",100);
$db->kill("TEST_TXN","PREDEF","KILL");
$db->txnabort();

is($db->get("TEST_TXN","NEWDEF"),undef,"Aborted txn shouldn\'t set things");
is($db->get("TEST_TXN","PREDEF"),50,"Aborted txn should preserve old values");
ok($db->get("TEST_TXN","PREDEF","KILL"),"Aborted txn shouldn\'t kill things");

$db->txnstart();
$db->set("TEST_TXN","NEWDEF",1000);
$db->set("TEST_TXN","PREDEF",100);
$db->kill("TEST_TXN","PREDEF","KILL");
$db->txncommit();

is($db->get("TEST_TXN","NEWDEF"),1000,"Committed txn should set OK");
is($db->get("TEST_TXN","PREDEF"),100,"Committed txn clobbers old values");
ok(!$db->get("TEST_TXN","PREDEF","KILL"),"Committed txn can kill things");

$db->kill("TEST_TXN");
system("stty sane"); # gtm_init() screws up the terminal 
