#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use lib './lib';
use open ':std' => 'utf8';
use JSON;
use JSON::Schema::Validate;

# oneOf should pass only when exactly one branch validates.

my $js = JSON::Schema::Validate->new({
    oneOf => [
        { type => 'integer', minimum => 0 },
        { type => 'string',  minLength => 3 },
    ],
});

ok(  $js->validate( 5 ),          'integer branch only' ) or diag( $js->error );
ok(  $js->validate( 'cat' ),      'string branch only' ) or diag( $js->error );
ok( !$js->validate( '12' ),       'neither (string too short)' );
ok( !$js->validate( undef ),      'neither (null)' );

# Make a value that matches BOTH branches and ensure it fails oneOf.
# (Impossible here because integer vs string are disjoint; craft a new schema:)
my $js2 = JSON::Schema::Validate->new({
    oneOf => [
        { type => 'number',  minimum => 0 },
        { type => 'integer', minimum => 0 },
    ],
});

ok( !$js2->validate( 7 ),         'fails: matches number and integer (2 branches)' );

done_testing;

__END__
