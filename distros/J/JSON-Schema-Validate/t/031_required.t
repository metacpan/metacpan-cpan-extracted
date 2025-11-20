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

# Testing required versus optional properties.

my $js1 = JSON::Schema::Validate->new({
    type => 'object',
    properties => 
    {
        mynumber => { required => 1 }
    },
	 additionalProperties => {},
});

my $js2 = JSON::Schema::Validate->new({
    type => 'object',
    properties => 
    {
        mynumber => { required => 0 }
    },
	 additionalProperties => {},
});

my $js3 = JSON::Schema::Validate->new({
    type => 'object',
    properties => 
    {
        mynumber => { optional => 1 }
    },
	 additionalProperties => {},
});

my $js4 = JSON::Schema::Validate->new({
    type => 'object',
    properties => 
    {
        mynumber => { optional => 0 }
    },
	 additionalProperties => {},
});

my $data1 = { mynumber => 1 };
my $data2 = { mynumbre => 1 };

my $result = $js1->validate( $data1 );
ok( $result, 'A' ) or diag( $js1->error );

$result = $js1->validate( $data2 );
ok( !$result, 'B' ) or diag( $js1->error );

$result = $js2->validate( $data1 );
ok( $result, 'C' ) or diag( $js2->error );

$result = $js2->validate( $data2 );
ok( $result, 'D' ) or diag( $js2->error );

$result = $js3->validate( $data1 );
ok( $result, 'E' ) or diag( $js3->error );

$result = $js3->validate( $data2 );
ok( $result, 'F' ) or diag( $js3->error );

$result = $js4->validate( $data1 );
ok( $result, 'G' ) or diag( $js3->error );

$result = $js4->validate( $data2 );
ok( !$result, 'H' ) or diag( $js3->error );

done_testing;

__END__
