#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw(no_plan);
use JSON::Assert;
use JSON;
use FindBin qw($Bin);
use lib "$Bin";

$JSON::Assert::VERBOSE = 1;

require 'data.pl';

my $json = decode_json( json() );

my $tests_ok = [
   {
       jpath => q{$..cd[?($_->{genre} eq 'Country')].artist},
       match => qr{Dolly Parton},
       name  => q{The Country CD is Dolly Parton},
   },
   {
       jpath => q{$..year},
       match => qr{\d{4}},
       name  => q{All years are \d\d\d\d},
   },
];

my $json_assert = JSON::Assert->new();

foreach my $t ( @$tests_ok ) {
    ok( $json_assert->do_jpath_values_match($json, $t->{jpath}, $t->{match}), $t->{name} )
	    or diag($json_assert->error);
}
