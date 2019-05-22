#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::DZil;
use Test::Version qw( version_ok );
use Path::Tiny qw( path );

my $package = 'semanticDZT';
my $module  = "$package.pm";
my $tzil    = Builder->from_config( { dist_root => "corpus/$package" } );
$tzil->build;
version_ok( path( $tzil->tempdir )->child("build/lib/$module") );
my $lib_0 = $tzil->slurp_file("build/lib/$module");

# e short for expected files
# -------------------------------------------------------------------
my $elib_0 = <<"END LIB0";
package $package;
use warnings;
use strict;
use version;
our \$VERSION = 'v0.0.1'; # VERSION
# ABSTRACT: my abstract
1;
END LIB0

# -------------------------------------------------------------------

is( $lib_0, $elib_0, "check $module" );
done_testing;
