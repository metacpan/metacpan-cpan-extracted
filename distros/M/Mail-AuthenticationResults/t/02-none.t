#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $Parsed;

lives_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( 'example.com;none' ) }, 'Simple none parses' );
is( $Parsed->as_string, "example.com; none", 'as string is as expected' );
is( scalar @{ $Parsed->children() }, 0, 'no children' );

lives_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( 'example.com;' ) }, 'Missing none parses' );
is( $Parsed->as_string, "example.com; none", 'as string is as expected' );
is( scalar @{ $Parsed->children() }, 0, 'no children' );

lives_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( 'example.com; (Nothing here) none' ) }, 'Commented none parses' );
is( $Parsed->as_string, "example.com; (Nothing here) none", 'as string is as expected' );
is( scalar @{ $Parsed->children() }, 1, '1 child' );

# The following is against RFC, but we parse it anyway.
lives_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( 'example.com; none (Nothing here)' ) }, 'Commented none wrong way around parses' );
is( $Parsed->as_string, "example.com; (Nothing here) none", 'as string is as expected' );
is( scalar @{ $Parsed->children() }, 1, '1 child' );

dies_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( 'example.com; none dkim=pass' ) }, 'none with subentry dies' );
dies_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( 'example.com; none none' ) }, 'double none dies' );

done_testing();

