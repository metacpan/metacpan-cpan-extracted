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

# Testing minimum, and maximum value for integers
my $js = JSON::Schema::Validate->new({
    type => 'object',
    properties => 
    {
        mynumber => { type => 'integer', minimum => 1, maximum=>4 }
    }
});

subtest 'maximum minimum integer' => sub
{
    my $data = { mynumber => 1 };
    my $result = $js->validate( $data );
    ok( $result, 'min' ) or diag( $js->error );

    $data = { mynumber => 4 };
    $result = $js->validate( $data );
    ok( $result, 'max' ) or diag( $js->error );

    $data = { mynumber => 2 };
    $result = $js->validate( $data );
    ok( $result, 'in the middle' ) or diag( $js->error );

    $data = { mynumber => 0 };
    $result = $js->validate( $data );
    ok( !$result, 'too small' ) or diag( $js->error );

    $data = { mynumber => -1 };
    $result = $js->validate( $data );
    ok( !$result, 'too small and neg' ) or diag( $js->error );

    $data = { mynumber => 5 };
    $result = $js->validate( $data );
    ok( !$result, 'too big' ) or diag( $js->error );
};

done_testing;

__END__

