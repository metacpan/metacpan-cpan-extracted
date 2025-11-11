#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib './lib';
use open ':std' => 'utf8';
use Test::More;
use JSON ();

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
}

my $schema =
{
    type => 'number',
    exclusiveMinimum => 0,
    maximum => 10,
    multipleOf => 0.5,
};

my $js = JSON::Schema::Validate->new( $schema );

ok(  $js->validate( 9.5 ),    '9.5 ok' ) or diag( $js->error );
ok( !$js->validate( 0 ),      'exclusiveMinimum 0: 0 not allowed' );
ok( !$js->validate( 10.25 ),  '10.25 exceeds maximum' );
ok( !$js->validate( 3.3 ),    '3.3 not multiple of 0.5' );

done_testing;

__END__
