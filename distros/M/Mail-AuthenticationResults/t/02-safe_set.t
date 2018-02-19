#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Header;
use Mail::AuthenticationResults::Header::Base;
use Mail::AuthenticationResults::Header::Comment;
use Mail::AuthenticationResults::Header::Entry;
use Mail::AuthenticationResults::Header::Group;
use Mail::AuthenticationResults::Header::SubEntry;

use Mail::AuthenticationResults::Header::Version;
use Mail::AuthenticationResults::Header::AuthServID;

my $Base = Mail::AuthenticationResults::Header::Base->new();
my $Comment = Mail::AuthenticationResults::Header::Comment->new();
my $Entry = Mail::AuthenticationResults::Header::Entry->new();
my $Group = Mail::AuthenticationResults::Header::Group->new();
my $Header = Mail::AuthenticationResults::Header->new();
my $SubEntry = Mail::AuthenticationResults::Header::SubEntry->new();
my $Version = Mail::AuthenticationResults::Header::Version->new();
my $AuthServID = Mail::AuthenticationResults::Header::AuthServID->new();

test_value_dies( $Base );
#test_value_dies( $Comment ); # Tests not yet written
test_value_dies( $Entry );
test_value_dies( $Group );
test_value_dies_header( $Header );
test_value_dies( $SubEntry );
test_value_dies( $AuthServID );
test_value_dies_version( $Version );

sub test_value_dies {
    my ( $class ) = @_;

    if ( ! $class->_HAS_VALUE() ) {
        dies_ok( sub{ $class->set_value() }, ( ref $class ) . ' set value' );
        return;
    }

    my $expectkey = q{};
    if ( $class->_HAS_KEY() ) {
        $class->set_key( 'test' );
        $expectkey = 'test=';
    }

    lives_ok( sub{ $class->safe_set_value() }, ( ref $class ) . ' set null value' );

    if ( ref $class eq 'Mail::AuthenticationResults::Header::AuthServID' ) {
        is( $class->as_string(), $expectkey . '', ( ref $class ) . ' stringify null correctly' );
    }
    else {
        is( $class->as_string(), $expectkey . '""', ( ref $class ) . ' stringify null correctly' );
    }

    lives_ok( sub{ $class->safe_set_value( 'With space' ) }, ( ref $class ) . ' set invalid value spaces' );
    is( $class->as_string(), $expectkey . '"With space"', ( ref $class ) . ' stringifies spaces correctly' );
    lives_ok( sub{ $class->safe_set_value( 'pass;' ) }, ( ref $class ) . ' set invalid value semicolon' );
    is( $class->as_string(), $expectkey . 'pass', ( ref $class ) . ' stringifies semicolon correctly' );
    lives_ok( sub{ $class->safe_set_value( 'with(parens)' ) }, ( ref $class ) . ' set invalid value comment' );
    is( $class->as_string(), $expectkey . '"with parens"', ( ref $class ) . ' stringifies parens correctly' );
    lives_ok( sub{ $class->safe_set_value( "With\nnewline" ) }, ( ref $class ) . ' set invalid value newline' );
    is( $class->as_string(), $expectkey . '"With newline"', ( ref $class ) . ' stringifies newline correctly' );
    lives_ok( sub{ $class->safe_set_value( "With\rreturn" ) }, ( ref $class ) . ' set invalid value return' );
    is( $class->as_string(), $expectkey . '"With return"', ( ref $class ) . ' stringifies return correctly' );
}

sub test_value_dies_version {
    my ( $class ) = @_;
    return unless $class->_HAS_VALUE();
    lives_ok( sub{ $class->safe_set_value() }, ( ref $class ) . ' set null value' );
    is( $class->as_string(), '/ 1', ( ref $class ) . ' stringifies null version correctly' );
    lives_ok( sub{ $class->safe_set_value( 'AString' ) }, ( ref $class ) . ' set invalid value non numeric' );
    is( $class->as_string(), '/ 1', ( ref $class ) . ' stringifies non numeric version correctly' );
    lives_ok( sub{ $class->safe_set_value( 'With space' ) }, ( ref $class ) . ' set invalid value spaces' );
    is( $class->as_string(), '/ 1', ( ref $class ) . ' stringifies spaced version correctly' );
    lives_ok( sub{ $class->set_value( '12345' ) }, ( ref $class ) . ' set valid value' );
    is( $class->as_string(), '/ 12345', ( ref $class ) . ' stringifies version correctly' );
}

sub test_value_dies_header {
    my ( $class ) = @_;
    return unless $class->_HAS_VALUE();
    dies_ok( sub{ $class->safe_set_value() }, ( ref $class ) . ' set null value' );

    dies_ok( sub{ $class->safe_set_value( 'string' ) }, ( ref $class ) . ' set incorrect type value' );

    lives_ok( sub{ $class->safe_set_value( Mail::AuthenticationResults::Header::AuthServID->new()->set_value( 'With space' ) ) }, ( ref $class ) . ' set invalid value spaces' );
    is( $class->as_string(), '"With space"; none', ( ref $class ) . ' stringifies spaces correctly' );
    lives_ok( sub{ $class->safe_set_value( Mail::AuthenticationResults::Header::AuthServID->new()->set_value( 'pass;' ) ) }, ( ref $class ) . ' set invalid value semicolon' );
    is( $class->as_string(), '"pass;"; none', ( ref $class ) . ' stringifies semicolon correctly' );
    lives_ok( sub{ $class->safe_set_value( Mail::AuthenticationResults::Header::AuthServID->new()->set_value( 'with(parens)' ) ) }, ( ref $class ) . ' set invalid value comment' );
    is( $class->as_string(), '"with(parens)"; none', ( ref $class ) . ' stringifies parens correctly' );
}

done_testing();

