package HTML::SocialMedia::Hashtag::SearchForNicknames;

use strict;
use warnings;

use Test::More;
use base qw(Test::Class);

use HTML::SocialMedia::Hashtag;

sub find_nicknames {
    my ( $text ) = @_;

    my $scanner = HTML::SocialMedia::Hashtag -> new( text => $text );

    return [ $scanner -> nicknames() ];
}

sub check {
    my ( $text, @expected ) = @_;

    is_deeply( find_nicknames( $text ), \@expected, sprintf "Check: '%s'", $text );

    return;
}

sub test_01_simple_username :Test( 6 ) {
    my ( $self ) = @_;

    my $text     = '@GermanS';
    my @expected = qw(GermanS);
    check( $text, @expected );

    $text     = 'Hey, @GermanS!';
    @expected = qw(GermanS);
    check( $text, @expected );

    $text     = 'Hey, @GermanS?';
    @expected = qw(GermanS);
    check( $text, @expected );

    $text     = 'CU @GermanS.';
    @expected = qw(GermanS);
    check( $text, @expected );

    $text     = 'Hey, @GermanS, @Sidorov!';
    @expected = qw(GermanS Sidorov);
    check( $text, @expected );

    $text     = 'Hey, @GermanS, @Sidorov!!!!';
    @expected = qw(GermanS Sidorov);
    check( $text, @expected );

    return;
}

sub test_01_username_with_dot :Test( 3 ) {
    my ( $self ) = @_;

    my $text     = '@German.S!';
    my @expected = qw(German.S);
    check( $text, @expected );

    $text     = 'Hey @German.S and @G.ermanS!!!';
    @expected = qw(German.S G.ermanS);
    check( $text, @expected );

    $text     = 'Hey @GermanS... and @Ge...rmanS!!!';
    @expected = ( 'GermanS',  'Ge...rmanS' );
    check( $text, @expected );

    return;
}

sub test_02_username_with_comma :Test( 3 ) {
    my ( $self ) = @_;

    my $text     = '@German,S!';
    my @expected = ( 'German,S' );
    check( $text, @expected );

    $text     = 'Hey @German,S and @G,.ermanS!!!';
    @expected = ( 'German,S',  'G,.ermanS' );
    check( $text, @expected );

    $text     = 'Hey @GermanS,,, and @Ge,,,rmanS!!!';
    @expected = ( 'GermanS',  'Ge,,,rmanS' );
    check( $text, @expected );

    return;
}

sub test_03_username_with_question :Test( 3 ) {
    my ( $self ) = @_;

    my $text     = '@German?S!';
    my @expected = qw(German?S);
    check( $text, @expected );

    $text     = 'Hey @German?S and @G?,.ermanS!!!';
    @expected = ( 'German?S', 'G?,.ermanS' );
    check( $text, @expected );

    $text     = 'Hey @GermanS??? and @Ge???rmanS!!!';
    @expected = ( 'GermanS',  'Ge???rmanS' );
    check( $text, @expected );

    return;
}

sub test_04_username_with_exclamation :Test( 3 ) {
    my ( $self ) = @_;

    my $text     = '@German!S!';
    my @expected = qw(German!S);
    check( $text, @expected );

    $text     = 'Hey @German!S and @G!?,.ermanS!!!';
    @expected = ( 'German!S', 'G!?,.ermanS' );
    check( $text, @expected );

    $text     = 'Hey @GermanS!!! and @Ge!!!rmanS!!!';
    @expected = ( 'GermanS',  'Ge!!!rmanS' );
    check( $text, @expected );

    return;
}

sub test_05_russian_usernames :Test( 4 ) {
    my ( $self ) = @_;

    my $text = '@привет';
    my @expected = qw(привет);
    check( $text, @expected );

    $text = '@привет @мир';
    @expected = qw(привет мир);
    check( $text, @expected );

    $text = '@п...т @мир';
    @expected = ('п...т', 'мир' );
    check( $text, @expected );

    $text = '@п...т, @мир,';
    @expected = ( 'п...т', 'мир' );
    check( $text, @expected );

    return;
}

sub test_06_username_with_arroba :Test( 4 ) {
    my ( $self ) = @_;

    my $text = '@germ@ns';
    my @expected = ( 'germ@ns' );
    check( $text, @expected );

    $text = 'hey, @la@folle???';
    @expected = ( 'la@folle' );
    check( $text, @expected );

    $text = 'hey, @гер_м@н, how are you???';
    @expected = ( 'гер_м@н' );
    check( $text, @expected );

    $text = 'hey, @гер_м_@н, how are you???';
    @expected = ( 'гер_м_@н' );
    check( $text, @expected );

    return;
}

1;