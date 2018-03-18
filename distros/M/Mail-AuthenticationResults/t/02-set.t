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

test_key_dies( $Base );
test_key_dies( $Comment );
test_key_dies( $Entry );
test_key_dies( $Group );
#test_key_dies( $Header ); # Header does not have keys
test_key_dies( $SubEntry );
#test_key_dies( $Version ); $AuthServID does not have keys
#test_key_dies( $AuthServID ); #AuthServID does not have keys

test_value_dies( $Base );
#test_value_dies( $Comment ); # Tested elsewhere
test_value_dies( $Entry );
test_value_dies( $Group );
test_value_dies_header( $Header );
test_value_dies( $SubEntry );
test_value_dies( $AuthServID );
test_value_dies_version( $Version );

sub test_key_dies {
    my ( $class ) = @_;

    if ( ! $class->_HAS_KEY() ) {
        dies_ok( sub{ $class->set_key() }, ( ref $class ) . ' set key' );
        return;
    }

    $class->set_value( 'test' );
    dies_ok( sub{ $class->set_key() }, ( ref $class ) . ' set null key' );
    dies_ok( sub{ $class->set_key( '' ) }, ( ref $class ) . ' set empty key' );
    dies_ok( sub{ $class->set_key( '"' ) }, ( ref $class ) . ' set invalid " key' );
    dies_ok( sub{ $class->set_key( "with\nnewline" ) }, ( ref $class ) . ' set invalid newline key' );
    dies_ok( sub{ $class->set_key( "with\rreturn" ) }, ( ref $class ) . ' set invalid return key' );

    delete $class->{ 'value' };
    lives_ok( sub{ $class->set_key( 'none' ) }, ( ref $class ) . ' set key none' );
    is( $class->as_string(), 'none', ( ref $class ) . ' stringifies none correctly' );
    $class->set_value( 'test' );

    lives_ok( sub{ $class->set_key( 'test key!' ) }, ( ref $class ) . ' set key spaces' );
    is( $class->as_string(), '"test key!"=test', ( ref $class ) . ' stringifies spaces correctly' );
    lives_ok( sub{ $class->set_key( 'test;' ) }, ( ref $class ) . ' set key semicolon' );
    is( $class->as_string(), '"test;"=test', ( ref $class ) . ' stringifies semicolon correctly' );
    lives_ok( sub{ $class->set_key( 'test(test)' ) }, ( ref $class ) . ' set key parens' );
    is( $class->as_string(), '"test(test)"=test', ( ref $class ) . ' stringifies parens correctly' );
}

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
    dies_ok( sub{ $class->set_value() }, ( ref $class ) . ' set null value' );
    dies_ok( sub{ $class->set_value( 'has"quote') }, ( ref $class ) . ' set quote value value' );
    dies_ok( sub{ $class->set_value( "with\nnewline" ) }, ( ref $class ) . ' set newline value' );
    dies_ok( sub{ $class->set_value( "with\return" ) }, ( ref $class ) . ' set return value' );

    lives_ok( sub{ $class->set_value( 'With space' ) }, ( ref $class ) . ' set invalid value spaces' );
    is( $class->as_string(), $expectkey . '"With space"', ( ref $class ) . ' stringifies spaces correctly' );
    lives_ok( sub{ $class->set_value( 'pass;' ) }, ( ref $class ) . ' set invalid value semicolon' );
    is( $class->as_string(), $expectkey . '"pass;"', ( ref $class ) . ' stringifies semicolon correctly' );
    lives_ok( sub{ $class->set_value( 'with(parens)' ) }, ( ref $class ) . ' set invalid value comment' );
    is( $class->as_string(), $expectkey . '"with(parens)"', ( ref $class ) . ' stringifies parens correctly' );

    if ( ref $class ne 'Mail::AuthenticationResults::Header::AuthServID' ) {
        lives_ok( sub{ $class->set_value( '' ) }, ( ref $class ) . ' set empty string' );
        is( $class->as_string(), $expectkey . '""', ( ref $class ) . ' stringifies empty correctly' );
    }

    lives_ok( sub{ $class->set_value( 0 ) }, ( ref $class ) . ' set zero' );
    is( $class->as_string(), $expectkey . '0', ( ref $class ) . ' stringifies zero correctly' );

}

sub test_value_dies_version {
    my ( $class ) = @_;
    return unless $class->_HAS_VALUE();
    dies_ok( sub{ $class->set_value() }, ( ref $class ) . ' set null value' );
    dies_ok( sub{ $class->set_value( 'AString' ) }, ( ref $class ) . ' set invalid value non numeric' );
    dies_ok( sub{ $class->set_value( 'With space' ) }, ( ref $class ) . ' set invalid value spaces' );

    lives_ok( sub{ $class->set_value( '12345' ) }, ( ref $class ) . ' set valid value' );
    is( $class->as_string(), '/ 12345', ( ref $class ) . ' stringifies version correctly' );
}

sub test_value_dies_header {
    my ( $class ) = @_;
    return unless $class->_HAS_VALUE();
    dies_ok( sub{ $class->set_value() }, ( ref $class ) . ' set null value' );

    dies_ok( sub{ $class->set_value( 'string' ) }, ( ref $class ) . ' set incorrect type value' );

    lives_ok( sub{ $class->set_value( Mail::AuthenticationResults::Header::AuthServID->new()->set_value( 'With space' ) ) }, ( ref $class ) . ' set invalid value spaces' );
    is( $class->as_string(), '"With space"; none', ( ref $class ) . ' stringifies spaces correctly' );
    lives_ok( sub{ $class->set_value( Mail::AuthenticationResults::Header::AuthServID->new()->set_value( 'pass;' ) ) }, ( ref $class ) . ' set invalid value semicolon' );
    is( $class->as_string(), '"pass;"; none', ( ref $class ) . ' stringifies semicolon correctly' );
    lives_ok( sub{ $class->set_value( Mail::AuthenticationResults::Header::AuthServID->new()->set_value( 'with(parens)' ) ) }, ( ref $class ) . ' set invalid value comment' );
    is( $class->as_string(), '"with(parens)"; none', ( ref $class ) . ' stringifies parens correctly' );
}

done_testing();

