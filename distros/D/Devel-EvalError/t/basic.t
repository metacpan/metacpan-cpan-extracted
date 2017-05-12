#!/usr/bin/perl -w

use Test::More( tests => 12 );

require Devel::EvalError;

ok( 1, "require" );

eval { die "Before it all\n" };
is( $@, "Before it all\n", "our first assumption" );

my $ee= Devel::EvalError->new();
ok( $ee, "new()" );

{
    my $one= $ee->ExpectOne( eval { die "Fail\n";  1; } );
    is( $one, $ee, 'ExpectOne returns $self' );
}

ok( $ee->Failed(), "die Failed" );
is( "Fail\n", $@, '$@ preserved' );
is( "Fail\n", $ee->Reason(), 'Reason set' );
undef $ee;
is( $@, "Before it all\n", '$@ restored' );

$ee= Devel::EvalError->new();
my @return = $ee->ExpectNonEmpty( eval { 1..5 } );
is( "1 2 3 4 5", "@return", 'ExpectNonEmpty returns list' );
ok( $ee->Succeeded(), "Succeeded" );
ok( ! $ee->Reason(), "no Reason" );
undef $ee;
is( $@, "Before it all\n", '$@ restored' );
