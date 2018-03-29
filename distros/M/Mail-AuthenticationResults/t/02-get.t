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

#test_get( $Base );
subtest 'comment' => sub{
    test_get( $Comment );
    is ( $Comment->as_string(), '()', 'Comment stringifies as expected' );
};
subtest 'entry' => sub{
    test_get( $Entry );
    is ( $Entry->as_string(), '', 'Entry stringifies as expected' );
};
subtest 'group' => sub{
    test_get( $Group );
    is ( $Group->as_string(), '', 'Group stringifies as expected' );
};
subtest 'header' => sub{
    test_get( $Header );
    is ( $Header->as_string(), "unknown; none", 'Header stringifies as expected' );
};
subtest 'subentry' => sub{
    test_get( $SubEntry );
    is ( $SubEntry->as_string(), '', 'SubEntrystringifies as expected' );
};
subtest 'version' => sub{
    test_get( $Version );
    is ( $Version->as_string(), '', 'Version stringifies as expected' );
};
subtest 'authservid' => sub{
    test_get( $AuthServID );
    is ( $AuthServID->as_string(), '', 'AuthServID stringifies as expected' );
};

sub test_get {
    my ( $class ) = @_;

    is ( $class->stringify(), q{}, 'Null stringifies correctly' );

    if ( $class->_HAS_KEY() ) {
        is ( $class->key(), q{}, ( ref $class ) . ' key returns empty string' );
    }
    else {
        dies_ok( sub{ $class->key() }, ( ref $class ) . ' key dies' );
    }

    if ( $class->_HAS_VALUE() ) {
        is ( $class->value(), q{}, ( ref $class ) . ' value returns empty string' );
    }
    else {
        dies_ok( sub{ $class->value() }, ( ref $class ) . ' value dies' );
    }

}

done_testing();

