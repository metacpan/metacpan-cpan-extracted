# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 7;
BEGIN { use_ok('Db::GTM') };
$ENV{'GTMCI'}="/usr/local/gtm/xc/calltab.ci" unless $ENV{'GTMCI'};

#########################

my $db = new GTMDB('SPZ');

&create_env($db->sub("TEST_KILL"));

sub create_env {
  my($db) = @_;

  $db->set("A","BOO");
  $db->set("A",1,"FOO");
  $db->set("A",2,"BAR");
  $db->set("A",3,"BAZ");
  $db->set("B","BOO");
  $db->set("B",1,"FOO");
  $db->set("B",2,"BAR");
  $db->set("B",3,"BAZ");
  $db->set("C","BOO");
  $db->set("C",1,"FOO");
  $db->set("C",2,"BAR");
  $db->set("C",3,"BAZ");
  return;
}

$db->kv("TEST_KILL","A");   # Only 'A' should be dead
ok(!defined $db->get("TEST_KILL","A"),"killval kills target ");
ok(defined $db->get("TEST_KILL","A",1),"killval ignores subscripts");

$db->ks("TEST_KILL","B");   # 'B' should be OK, but not subs
ok(defined $db->get("TEST_KILL","B"),"killsubs ignores target");
ok(!defined $db->get("TEST_KILL","B",2),"killsubs kills subscripts");

$db->kill("TEST_KILL","C"); # 'C' & subs should be dead
ok(!defined $db->get("TEST_KILL","C"),"kill kills target");
ok(!defined $db->get("TEST_KILL","C",3),"kill kills subscripts");

$db->kill("TEST_KILL");
system("stty sane"); # gtm_init() screws up the terminal 
