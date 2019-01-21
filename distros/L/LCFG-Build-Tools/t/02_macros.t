#!/usr/bin/perl
use strict;
use warnings;

use LCFG::Build::PkgSpec;

use Test::More tests => 18;
use Test::Differences;
use IO::File;
use File::Temp;

# When running the tests the data files are in the current directory
$ENV{LCFG_BUILD_TMPLDIR} = q{.};

BEGIN {
        use_ok('LCFG::Build::Utils');
}

my $spec = LCFG::Build::PkgSpec->new( name => 'test', version => '1.2.3' );

my @translate_tests1 = (
   [ 'LCFG_NAME'    => 'test' ],
   [ 'LCFG_VERSION' => '1.2.3' ],
   [ 'LCFG_VENDOR'  => '' ],
   [ 'FOOBAR'       => undef ],
);

for my $test (@translate_tests1) {
    my ( $in, $out ) = @{$test};

    my $string = LCFG::Build::Utils::translate_macro( $spec, $in );

    is( $string, $out, "macro translation test for $in" );

}

my @translate_tests2 = (
   [ 'This is the @LCFG_NAME@ project' => 'This is the test project' ],
   [ '@LCFG_NAME@ project'             => 'test project' ],
   [ '@LCFG_NAME@'                     => 'test' ],
   [ 'project @LCFG_NAME@'             => 'project test' ],
   [ '@LCFG_NAME@-@LCFG_VERSION@'      => 'test-1.2.3' ],
   [ '@FOOBAR@'                        => '@FOOBAR@' ],
);

for my $test (@translate_tests2) {
    my ( $in, $out ) = @{$test};

    my $string = LCFG::Build::Utils::translate_string( $spec, $in );

    is( $string, $out, "autoconf-style translation test for $in" );

}

my @translate_tests3 = (
   [ 'This is the ${LCFG_NAME} project' => 'This is the test project' ],
   [ '${LCFG_NAME} project'             => 'test project' ],
   [ '${LCFG_NAME}'                     => 'test' ],
   [ 'project ${LCFG_NAME}'             => 'project test' ],
   [ '${LCFG_NAME}-${LCFG_VERSION}'     => 'test-1.2.3' ],
   [ '${FOOBAR}'                        => '${FOOBAR}' ],
);

for my $test (@translate_tests3) {
    my ( $in, $out ) = @{$test};

    my $string = LCFG::Build::Utils::translate_string( $spec, $in, 'cmake' );

    is( $string, $out, "CMake-style translation test for $in" );

}

my $template = 't/macros.tmpl';

my $tmp = File::Temp->new( UNLINK => 0 );

LCFG::Build::Utils::translate_file( $spec, $template, $tmp->filename );

my $expfh = IO::File->new( 't/macros.txt', 'r' );
my $tmpfh = IO::File->new( $tmp->filename, 'r' );

my @exp = <$expfh>;

my @got = <$tmpfh>;

eq_or_diff \@got, \@exp, 'translated file', { context => 2 };

unlink $tmp->filename;
