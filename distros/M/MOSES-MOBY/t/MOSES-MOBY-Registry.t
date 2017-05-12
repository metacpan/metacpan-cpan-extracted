# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MOSES-MOBY.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More 'no_plan';

BEGIN { 
	use_ok('MOSES::MOBY::Cache::Registries');
};

#########################

my $registry;

# test constructor
$registry = new MOSES::MOBY::Cache::Registries;

# are list, get, add, remove and all available to me?
can_ok($registry, ("get", "list", "add", "remove", "all"));

# get should return default registry details
ok($registry->get->{endpoint} eq 'http://moby.ucalgary.ca/moby/MOBY-Central.pl', "Check the 'get' method returns the default registry") or diag("'" . $registry->get->{endpoint} . "' was not expected.");

# shouldnt be able to add to persistent store, but should be in memory (0).
my $ret = $registry->add(
               endpoint  => 'http://localhost/cgi-bin/MOBY/MOBY-Central.pl',
               namespace => 'http://localhost/MOBY/Central',
               name      => 'My Localhost registry',
               contact   => 'Edward Kawas (edward.kawas@gmail.com)',
               public    => 'no',
               text      => 'A curated private registry hosted right here on this cpu',
               synonym   => 'my_new_reg',
);
ok(($ret == 0 or $ret == 1), 'Check the add method') or diag("Couldnt add a registry: ($ret)");

# get recently added registry
ok($registry->get('my_new_reg')->{endpoint} eq 'http://localhost/cgi-bin/MOBY/MOBY-Central.pl', "Check the 'get' method returns my new endpoint") or diag("'" . $registry->get('my_new_reg')->{endpoint} . "' was not the expected value.");
ok($registry->get('my_new_reg')->{namespace} eq 'http://localhost/MOBY/Central', "Check the 'get' method returns my new namespace") or diag("'" . $registry->get('my_new_reg')->{namespace} . "' was not the expected value.");
ok($registry->get('my_new_reg')->{name} eq 'My Localhost registry', "Check the 'get' method returns my new name") or diag("'" . $registry->get('my_new_reg')->{name} . "' was not the expected value.");
ok($registry->get('my_new_reg')->{contact} eq 'Edward Kawas (edward.kawas@gmail.com)', "Check the 'get' method returns my new contact") or diag("'" . $registry->get('my_new_reg')->{contact} . "' was not the expected value.");
ok($registry->get('my_new_reg')->{public} eq 'no', "Check the 'get' method returns my new public") or diag("'" . $registry->get('my_new_reg')->{public} . "' was not the expected value.");
ok($registry->get('my_new_reg')->{text} eq 'A curated private registry hosted right here on this cpu', "Check the 'get' method returns my new text") or diag("'" . $registry->get('my_new_reg')->{text} . "' was not the expected value.");

# we can remove any of default, irri, icapture, testing, etc from memory
$ret = $registry->remove('my_new_reg');
ok(($ret == 0 or $ret == 1 ), 'Check the remove method') or diag("Couldnt remove the registry: ($ret)");

#make sure that remove really removed the one of interest
my @regs = $registry->list;
for my $i (@regs) {
ok($i ne 'my_new_reg', "Confirm removal via 'remove'") or diag("Removal verification failed!");
}

