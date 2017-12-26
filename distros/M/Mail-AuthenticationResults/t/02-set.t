#!perl
use 5.006;
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

my $Header = Mail::AuthenticationResults::Header->new();
my $Base = Mail::AuthenticationResults::Header::Base->new();
my $Comment = Mail::AuthenticationResults::Header::Comment->new();
my $Entry = Mail::AuthenticationResults::Header::Entry->new();
my $Group = Mail::AuthenticationResults::Header::Group->new();
my $SubEntry = Mail::AuthenticationResults::Header::SubEntry->new();

test_key_dies( $Header );
test_key_dies( $Base );
test_key_dies( $Comment );
test_key_dies( $Entry );
test_key_dies( $Group );
test_key_dies( $SubEntry );

test_value_dies( $Header );
test_value_dies( $Base );
#test_value_dies( $Comment ); # Tested elsewhere
test_value_dies( $Entry );
test_value_dies( $Group );
test_value_dies( $SubEntry );

sub test_key_dies {
    my ( $class ) = @_;
    dies_ok( sub{ $class->set_key() }, ( ref $class ) . ' set null key' );
    dies_ok( sub{ $class->set_key( '' ) }, ( ref $class ) . ' set empty key' );
    dies_ok( sub{ $class->set_key( 'test key!' ) }, ( ref $class ) . ' set invalid key' );
}

sub test_value_dies {
    my ( $class ) = @_;
    dies_ok( sub{ $class->set_value() }, ( ref $class ) . ' set null value' );
    dies_ok( sub{ $class->set_value( 'With space' ) }, ( ref $class ) . ' set invalid value spaces' );
    dies_ok( sub{ $class->set_value( 'pass;' ) }, ( ref $class ) . ' set invalid value semicolon' );
    dies_ok( sub{ $class->set_value( 'with(parens)' ) }, ( ref $class ) . ' set invalid value comment' );
}

done_testing();

