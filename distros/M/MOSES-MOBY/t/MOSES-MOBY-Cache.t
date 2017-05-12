# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MOSES-MOBY.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 9;

BEGIN { 
	use_ok('MOSES::MOBY::Cache::Central');
};

#########################

my $cachedir = "/usr/local/cache/";
my $registry = "testing";
my $endpoint = "http://mobytest.biordf.net/MOBY-Central.pl";
my $namespace = "http://mobytest.biordf.net/MOBY/Central";


my $cache;

# test parameterized constructor
$cache = new MOSES::MOBY::Cache::Central
	( cachedir => $cachedir,
      registry => $registry
    );
ok($cachedir eq $cache->cachedir, "cachedir - set during constructor") 
	or diag('cachedir was not set properly.');
ok($registry eq $cache->registry, "registry - set during constructor") 
	or diag('registry was not set properly.');
ok($namespace eq $cache->_namespace, "namespace - set during constructor") 
	or diag($cache->_namespace . " is not the same as $namespace");
ok($endpoint eq $cache->_endpoint, "endpoint - set during constructor") 
	or diag($cache->_endpoint . " is not the same as $endpoint");

# test parameterized constructor
$cache = new MOSES::MOBY::Cache::Central( );
ok($cachedir ne $cache->cachedir, "cachedir - default during constructor") 
	or diag('cachedir was not set properly.');
ok('' ne $cache->registry, "registry - default during constructor") 
	or diag('registry was not set properly.');
ok('' ne $cache->_namespace, "namespace - set during default constructor") 
	or diag($cache->_namespace . " is not the same as $namespace");
ok('' ne $cache->_endpoint, "endpoint - set during default constructor") 
	or diag($cache->_endpoint . " is not the same as $endpoint");


