# This xt/citation.t file was generated with /Users/brian/bin/bmt
# Mon Jun  6 20:19:41 2022


use strict;

use Test::More;

my $file = 'CITATION.cff';

SKIP: {
		my $rc = eval { require YAML; YAML->VERSION('1.26'); 1 };
		skip "Need YAML to test $file", 1 unless $rc;

		subtest citations => sub {
				ok( -e $file, "$file exists" );
				my $data = eval { YAML::LoadFile( $file ) };
				my $error = $@;
				ok( defined $data, "Loaded data from $file" ) or diag( "Error loading $file: $@" );
				};
		}

done_testing();

