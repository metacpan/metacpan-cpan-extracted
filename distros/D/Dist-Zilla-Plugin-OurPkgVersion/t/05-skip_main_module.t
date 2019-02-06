#!/usr/bin/perl

# test that skip_main_module ignores the main module (DZT0.pm in this case)

use strict;
use warnings;
use Test::More;
use Test::DZil;
use Test::Version qw( version_ok );
use Path::Tiny qw( path );

my $tzil = Builder->from_config({ dist_root => 'corpus/sDZT' });

$tzil->build;

version_ok( path($tzil->tempdir)->child('build/lib/DZT1.pm'));

my $lib_0 = $tzil->slurp_file('build/lib/DZT0.pm');
my $lib_1 = $tzil->slurp_file('build/lib/DZT1.pm');

# e short for expected files
# -------------------------------------------------------------------
my $elib_0 = <<'END LIB0';
use strict;
use warnings;
package DZT0;
# VERSION
# ABSTRACT: my abstract
1;
END LIB0

my $elib_1 = <<'END LIB1';
use strict;
use warnings;
package DZT1;
BEGIN {
	our $VERSION = '0.1.0'; # VERSION
}
# ABSTRACT: my abstract
1;
END LIB1
# -------------------------------------------------------------------

is ( $lib_0, $elib_0, 'check DZT0.pm' );
is ( $lib_1, $elib_1, 'check DZT1.pm' );

done_testing;
