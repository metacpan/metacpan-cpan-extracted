#!/usr/bin/perl
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
};

# Smoke test the Error class equality/stringification.

my $E = 'JSON::Schema::Validate::Error';

my $e1 = $E->new( '#/a/b', 'boom' );
my $e2 = $E->new( '#/a/b', 'boom' );
my $e3 = $E->new( '#/x',   'boom' );
my $e4 = $E->new( '#/a/b', 'different' );

ok( $e1 eq $e2, 'two identical errors are eq' );
ok( $e1 ne $e3, 'different path => not equal' );
ok( $e1 ne $e4, 'different message => not equal' );
ok( $e1 == $e2, 'overloaded == also works' );

is( "$e1", '#/a/b: boom', 'stringification shows path: message' );

# Compare to plain string: eq is message-only by design
ok( $e1 eq 'boom', 'error eq "boom" matches message equality' );
ok( $e1 ne 'nope', 'error ne "nope" works' );

done_testing();

__END__
