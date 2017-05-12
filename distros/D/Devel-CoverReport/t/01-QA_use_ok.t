#!/usr/bin/perl
# Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://bs502.pl/
use strict; use warnings;

# DEBUG on
use FindBin qw( $Bin );
use lib $Bin .'/../lib';
# DEBUG off

BEGIN {
    $|  = 1;
    $^W = 1;
}

my @MODULES = (
    'Perl::Critic::Utils 1.105',
);

# Don't run tests during end-user installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Load the testing module
eval "use Perl::Critic::Utils 1.105";
if ( $@ ) {
	$ENV{RELEASE_TESTING}
	? die( "Failed to load required release-testing module Perl::Critic::Utils" )
	: plan( skip_all => "Perl::Critic::Utils not available for testing" );
}

my @perl_files = Perl::Critic::Utils::all_perl_files($Bin .q{/../lib/});

plan tests => scalar @perl_files;

foreach my $file (@perl_files) {
    require_ok($file);
}

# vim: fdm=marker
