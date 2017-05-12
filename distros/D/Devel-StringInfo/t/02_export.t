#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
	plan skip_all => "YAML is required for testing" unless eval { require YAML };
	plan "no_plan";
}

use ok 'Devel::StringInfo', string_info => { guess_encoding => 0 };

my $str = string_info("henry");

like( $str, qr/henry/ );
like( $str, qr/valid_utf8/ );

unlike( $str, qr/guessed_encoding/ );
