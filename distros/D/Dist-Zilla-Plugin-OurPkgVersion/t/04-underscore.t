#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::DZil;
use Test::Version qw( version_ok );
use Path::Tiny qw( path );

my $tzil = Builder->from_config({ dist_root => 'corpus/eDZT' });

$tzil->build;

version_ok( path($tzil->tempdir)->child('build/lib/DZT0.pm'));

my $lib_0 = $tzil->slurp_file('build/lib/DZT0.pm');

# e short for expected files
# -------------------------------------------------------------------
my $elib_0 = <<'END LIB0';
use strict;
use warnings;
package DZT0;
our $VERSION = '0.01_02'; # TRIAL VERSION
$VERSION = eval $VERSION;
# ABSTRACT: my abstract
1;
END LIB0

# -------------------------------------------------------------------

is ( $lib_0, $elib_0, 'check DZT0.pm' );

done_testing;
