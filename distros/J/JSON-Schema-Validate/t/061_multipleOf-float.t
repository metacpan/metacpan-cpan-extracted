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
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( 'Cannot load JSON::Schema::Validate' );
}

sub js
{
    my( $schema ) = @_;
    return JSON::Schema::Validate->new( $schema );
}

# Basic float multiples that are notoriously tricky
my $schema = 
{
    type       => 'number',
    multipleOf => 0.1,
};

my $v = js( $schema );
ok( $v->validate( 0.3 ),  '0.3 is a multiple of 0.1' ) or diag( $v->error );
ok( $v->validate( 1.2 ),  '1.2 is a multiple of 0.1' ) or diag( $v->error );
ok( $v->validate( 0.0 ),  '0.0 is a multiple of 0.1' ) or diag( $v->error );
ok( !$v->validate( 0.11 ), '0.11 is NOT a multiple of 0.1' );

# Tiny magnitude
my $tiny = js({ type => 'number', multipleOf => 1e-12 });
ok( $tiny->validate( 2e-12 ), '2e-12 is multiple of 1e-12' ) or diag( $tiny->error );
ok( !$tiny->validate( 1.5e-12 ), '1.5e-12 is NOT multiple of 1e-12' );

# Large magnitude
my $big = js({ type => 'number', multipleOf => 1e6 });
ok( $big->validate( 3_000_000 ), '3,000,000 is multiple of 1e6' ) or diag( $big->error );
ok( !$big->validate( 3_500_000 ), '3,500,000 is NOT multiple of 1e6' );

# Guard: multipleOf must be > 0
my $bad = js({ type => 'number', multipleOf => 0 });
ok( !$bad->validate( 10 ), 'multipleOf == 0 should be rejected' );
like( $bad->error->as_string, qr/multipleOf must be > 0/, 'error mentions the guard' );

done_testing();

__END__
