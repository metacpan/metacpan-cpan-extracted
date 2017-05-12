#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 17;
use Devel::Leak::Module ();





#####################################################################
# Test The Support Functions

SCOPE: {

	is_deeply(
		[ Devel::Leak::Module::_names('Devel::Leak') ],
		[ 'Module' ],
		'Got subnamespaces',
	);

	is_deeply(
		[ Devel::Leak::Module::_namespaces('Devel::Leak') ],
		[ 'Devel::Leak::Module' ],
		'Got namespaces',
	);

	# Get the raw quantity of things
	my @names1    = Devel::Leak::Module::all_namespaces();
	my @packages1 = Devel::Leak::Module::all_packages();
	my @modules1  = Devel::Leak::Module::all_modules();

	# There should be around 70+ namespaces, with 50 packages, and around 15 modules
	ok( scalar(@names1)    > 40, 'Found enough namespaces' );
	unless ( scalar(@names1) > 40 ) {
		diag("Found " . scalar(@names1) . " namespaces");
	}
	ok( scalar(@packages1) > 20, 'Found enough packages'   );
	unless ( scalar(@packages1) > 20 ) {
		diag("Found " . scalar(@packages1) . " namespaces");
	}
	ok( scalar(@modules1)  > 10, 'Found enough modules'    );
	unless ( scalar(@modules1) > 10 ) {
		diag("Found " . scalar(@modules1) . " modules");
	}
	ok( scalar(@packages1) < scalar(@names1),    'Less packages than namespaces' );
	ok( scalar(@modules1)  < scalar(@packages1), 'Less modules than packages'    );

	# Until we do a checkpoint, new_whatever should match
	my @names2    = Devel::Leak::Module::new_namespaces();
	my @packages2 = Devel::Leak::Module::new_packages();
	my @modules2  = Devel::Leak::Module::new_modules();
	is_deeply( \@names1,    \@names2,    'all_namespaces and new_namespaces match' );
	is_deeply( \@packages2, \@packages2, 'all_packages and new_packages match'     );
	is_deeply( \@modules1,  \@modules2,  'all_modules and new_modules match'       );
}

SCOPE: {
	# Set a checkpoint and verify that nothing new is created
	ok( Devel::Leak::Module::checkpoint(), 'checkpoint created' );
	
	# Get the raw quantity of things
	my @names    = Devel::Leak::Module::new_namespaces();
	my @packages = Devel::Leak::Module::new_packages();
	my @modules  = Devel::Leak::Module::new_modules();
	is( scalar(@names),    0, 'No namespaces after checkpoint' );
	is( scalar(@packages), 0, 'No packages after checkpoint'   );
	is( scalar(@modules),  0, 'No modules after checkpoint'    );
}

SCOPE: {
	# Add a sub-package
	eval "\@Foo::Bar::Baz::ISA = 'IO::Handle';";

	# Get the raw quantity of things
	my @names    = Devel::Leak::Module::new_namespaces();
	my @packages = Devel::Leak::Module::new_packages();
	my @modules  = Devel::Leak::Module::new_modules();
	is( scalar(@names),    3, 'No namespaces after checkpoint' );
	is( scalar(@packages), 1, 'No packages after checkpoint'   );
	is( scalar(@modules),  0, 'No modules after checkpoint'    );
}
