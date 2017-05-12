#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

### test that we pass/fail the same specs as Getopt::Long

#<<<
my @GOOD_SPECS = (
    'foo|f!',
    'foo|f+',
    'foo|f=i',
    'foo|f:i',
    'foo|f:+',
    'foo|f:5',
    'foo|f|g|h',
    'bar|b=s@{1,5}',
    'bar|b=s@{1,}',
    'bar|b=s@{1}',
    'bar|b=s@{1}',
    'bar|b=s@{,5}',
);

my @BAD_SPECS = (
    'foo=',
    'foo:',
);
#>>>
# one for each spec in each list, plus each use_ok()
plan( tests => @GOOD_SPECS + @BAD_SPECS + 2 );

my $CLASS = 'Getopt::Long::Spec::Parser';

use_ok( $CLASS ) or die "Couldn't compile [$CLASS]\n";

use_ok( 'Getopt::Long' ) or die "couldn't use [Getopt::Long]!\n";

# combining both sets in one loop 'cause I'm lazy...
# will separate if/when somebody needs it.
for my $spec ( @GOOD_SPECS, @BAD_SPECS ) {

    # if ! defined $name, err msg is in $orig.
    # May throw warning if a duplicate opt names are already in %opctl.
    my ( $name, $orig, @other )
        = Getopt::Long::ParseOptionSpec( $spec, \( my %opctl ) );

    my $valid_test_descr   = "valid spec parses: [$spec]";
    my $invalid_test_descr = "invalid spec causes die(): [$spec]";
    defined $name
        ? lives_ok( sub { $CLASS->parse( $spec ) }, $valid_test_descr )
        : dies_ok( sub { $CLASS->parse( $spec ) }, $invalid_test_descr );
}

