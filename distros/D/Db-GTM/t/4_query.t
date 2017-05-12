# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 4;
BEGIN { use_ok('Db::GTM') };
$ENV{'GTMCI'}="/usr/local/gtm/xc/calltab.ci" unless $ENV{'GTMCI'};

#########################

my $db = new GTMDB('SPZ'); my($gv);

$db->set("TEST_QUERY","A","FOO");
$db->set("TEST_QUERY","A","B","C","FOO");
$db->set("TEST_QUERY","A",5,"C","FOO");

$gv = join(":",$db->query("TEST_QUERY","A"));
is($gv,"TEST_QUERY:A:5:C","valid to deeper valid"); 

$gv = join(":",$db->query("TEST_QUERY","A",5,"C"));
is($gv,"TEST_QUERY:A:B:C","valid to higher nested");

$gv = join(":",$db->query("TEST_QUERY","A",1000));
is($gv,"TEST_QUERY:A:B:C","invalid to valid"); 

$db->kill("TEST_QUERY");
system("stty sane"); # gtm_init() screws up the terminal 
