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
    type     => 'array',
    contains => { type => 'integer', minimum => 10 },
    minContains => 2,
    maxContains => 3,
};

my $js = JSON::Schema::Validate->new( $schema );

ok(  $js->validate( [ 9, 10, 11, '12', 13 ] ), 'matches at indices 1,2,4 (three integers >=10)' ) or diag $js->error;
ok( !$js->validate( [ 10 ] ),                  'fails: fewer than minContains (1 < 2)' );
ok( !$js->validate( [ 10, 11, 12, 13 ] ),      'fails: more than maxContains (4 > 3)' );

done_testing;

__END__
