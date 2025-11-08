#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use lib './lib';
use open ':std' => 'utf8';
use JSON ();
use JSON::Schema::Validate;

my $schema =
{
    type => [
        'string',
        { type => 'integer', minimum => 100 },
    ],
};

my $js = JSON::Schema::Validate->new( $schema );

ok(  $js->validate( 'hello' ), 'string alt passes' ) or diag $js->error;
ok(  $js->validate( 150 ),     'inline integer schema passes' ) or diag $js->error;
ok( !$js->validate( 50 ),      'integer alt fails min; string alt not matched' );

done_testing;

__END__
