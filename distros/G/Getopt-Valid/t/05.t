#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;
use FindBin qw/ $Bin /;
use lib "$Bin/../lib";
use Data::Dumper;

# check module
use_ok( 'Getopt::Valid' );

# validator definition
my %validator = (
    name    => 'Test',
    version => '0.1.0',
    struct  => [
        'somestring|s=s!' => undef,
        'otherstring|o=s' => {
            constraint  => qr/^a/,
            required    => 1,
            description => 'This is the description for str'
        },
        'yadda|y=s' => {
            constraint  => qr/^a/,
            required    => 1,
            description => [ 'And we have a multiline', 'description', 'yeah' ]
        },
        'someint|i=i!' => 'This is the description for int',
        'somebool|b' => undef
    ]
);

my $validator = Getopt::Valid->new( \%validator );
my $expected = <<USAGE;
Program: Test
Version: 0.1.0

Usage: t/05.t <parameters>

Parameter:
  --somestring | -s : string [REQ]
    somestring value

  --otherstring | -o : string [REQ]
    This is the description for str

  --yadda | -y : string [REQ]
    And we have a multiline
    description
    yeah

  --someint | -i : integer [REQ]
    This is the description for int

  --somebool | -b : bool
    somebool value

  --help | -h : bool
    Show this help

USAGE

ok( $expected eq $validator->usage, 'Usage generation with multiline' );
