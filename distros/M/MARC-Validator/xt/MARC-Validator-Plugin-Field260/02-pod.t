use strict;
use warnings;

use English qw(-no_match_vars);
use File::Object;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
SKIP: {
	if ($PERL_VERSION lt v5.8.0) {
		skip 'Perl version lesser then 5.8.0.', 1;
	}
	require Test::Pod;
	Test::Pod::pod_file_ok(File::Object->new->up(2)->file('Validator', 'Plugin', 'Field260.pm')->s);
};
