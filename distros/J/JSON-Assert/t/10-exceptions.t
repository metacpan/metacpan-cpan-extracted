#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;
use JSON::Assert;
use JSON;
use FindBin qw($Bin);
use lib "$Bin";

# $JSON::Compare::VERBOSE = 1;

require 'data.pl';

my $json = decode_json( json() );

my $exceptions_count = [
   {
       jpath => q{$..cd},
       count => 2,
       name  => q{Should be 3 CDs not 2},
       error => qr{has 3 values},
   },
   {
       jpath => q{$..cd[?($_->{genre} eq 'Country')]},
       count => 2,
       name  => q{Should be one Country album, not 2},
       error => qr{has 1 value},
   },
];

my $exceptions_match = [
   {
       jpath => q{$..cd},
       match => qr{Shouldn't even get to this match},
       name  => q{Can't match on multiple nodes},
       error => qr{matched 3 values},
   },
   {
       jpath => q{$..cd[?($_->{genre} eq 'Country')]},
       match => qr{Bonnie Tyler},
       name  => q{The Country CD is Dolly Parton},
       error => qr{doesn't match},
   },
];

foreach my $t ( @$exceptions_count ) {
    throws_ok(
        sub { JSON::Assert->assert_jpath_count( $json, $t->{jpath}, $t->{count}) },
        $t->{error},
        $t->{name},
    );
}

foreach my $t ( @$exceptions_match ) {
    throws_ok(
        sub { JSON::Assert->assert_jpath_value_match( $json, $t->{jpath}, $t->{match}) },
        $t->{error},
        $t->{name},
    );
}
