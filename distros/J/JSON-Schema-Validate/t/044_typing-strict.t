#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib './lib';
use open ':std' => 'utf8';
use Test::More;
use JSON;

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
}

my $js = JSON::Schema::Validate->new(
    { type => 'integer' },
    normalize_instance => 1,
);

ok(  $js->validate( 12 ),   'numeric 12 is integer' ) or diag( $js->error );
ok( !$js->validate( '12' ), 'string "12" is not integer under strict typing' );

done_testing;

__END__

