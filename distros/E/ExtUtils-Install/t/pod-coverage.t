#!perl -T

BEGIN {
    if( $ENV{PERL_CORE} ) {
        @INC = ('../../lib', '../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}
chdir 't';

use Test::More;
use diagnostics;

# this is organized like this to avoid a "bug" in perls tainting.
# using an elsif throws an insecure dependency error.

my $skip_reason= "Skipping author tests. Set AUTHOR_TESTING=1 to run them.";
if ( $ENV{AUTHOR_TESTING} ) {
    $skip_reason= "";
}
if ( !$skip_reason && ! eval "use Test::Pod::Coverage 1.08; use Pod::Coverage 0.17; 1" ) {
    $skip_reason= "Test::Pod::Coverage 1.08 and Pod::Coverage 0.17 "
                . "required for testing POD coverage";
}

$skip_reason and
    plan skip_all => $skip_reason;

plan tests => 3;
pod_coverage_ok( "ExtUtils::Install");
pod_coverage_ok( "ExtUtils::Installed");
pod_coverage_ok( "ExtUtils::Packlist");