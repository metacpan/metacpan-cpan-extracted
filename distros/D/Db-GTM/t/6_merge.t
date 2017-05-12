# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 8;
BEGIN { use_ok('Db::GTM') };
$ENV{'GTMCI'}="/usr/local/gtm/xc/calltab.ci" unless $ENV{'GTMCI'};

#########################

my $db = new GTMDB('SPZ');

&create_env($db->sub("TEST_MERGE"));

sub create_env {
  my($db) = @_;

  $db->kill();
  $db->set("A","FOO");
  $db->set("A",3,"FOO");
  $db->set("A",4,"FOO");
  $db->set("A",5,9,"FOO");
  $db->set("B",1,"BAR");
  $db->set("B",2,"BAR");
  $db->set("B",3,"BAR");
  $db->set("C",6,"BAZ");
}

ok(! $db->clobber("TEST_MERGE","B",undef,"TEST_MERGE","C"),"copy method 1");

# Copy method 2
my($from) = $db->sub("TEST_MERGE","A");
my($to)   = $db->node("TEST_MERGE","C");
ok(! $db->copy($from,$to), "copy method 2");

ok(! $db->get("TEST_MERGE","C",6),"Clobber deletes things from target");
is($db->get("TEST_MERGE","C"),"FOO",   "Merge sets direct target OK");
is($db->get("TEST_MERGE","C",1),"BAR", "Merge sets subscripts OK");
is($db->get("TEST_MERGE","C",3),"FOO", "2nd Merge clobbers first"); 
is($db->get("TEST_MERGE","C",5,9),"FOO", "Merge copies depth");

$db->kill("TEST_MERGE");
system("stty sane"); # gtm_init() screws up the terminal 
