package HTML::SocialMedia::Hashtag::SearchForHashtags;

use strict;
use warnings;

use Test::More;
use base qw(Test::Class);

use HTML::SocialMedia::Hashtag;

sub find_hashtags {
    my ( $text ) = @_;

    my $scanner = HTML::SocialMedia::Hashtag -> new( text => $text );

    return [ $scanner -> hashtags() ];
}

sub check {
    my ( $text, @expected ) = @_;

    is_deeply( find_hashtags( $text ), \@expected, sprintf "Check: %s", $text );

    return;
}

sub test_01_simple_hashtag :Test( 5 ) {
    my ( $self ) = @_;

    my $text = '#hashtag';
    my @expected = qw(hashtag);
    check( $text, @expected );

    $text = 'Hooray, #hashTag!';
    @expected = qw(hashtag);
    check( $text, @expected );

    $text = 'What, #HashTag?';
    @expected = qw(hashtag);
    check( $text, @expected );

    $text = '#One, #TWo #tres. #Cinco y #diez';
    @expected = qw(one two tres cinco diez);
    check( $text, @expected );

    $text = 'Hey, #HashTag, #hashtag!!!';
    @expected = qw(hashtag);
    check( $text, @expected );

    return;
}

sub test_02_russian_hashtag :Test( 5 ) {
    my ( $self ) = @_;

    my $text = '#хештег';
    my @expected = qw(хештег);
    check( $text, @expected );

    $text = 'Hooray, #ХешТег!';
    @expected = qw(хештег);
    check( $text, @expected );

    $text = 'What, #хешТег?';
    @expected = qw(хештег);
    check( $text, @expected );

    $text = '#раз, #Два #Три. #ПяТЬ y #Десять';
    @expected = qw(раз два три пять десять);
    check( $text, @expected );

    $text = 'Эй, #хештег, #хеШтег!!!';
    @expected = qw(хештег);
    check( $text, @expected );

    return;
}

sub test_03_spanish_hashtags :Test( 5 ) {
    my ( $self ) = @_;

    my $text = '#etiqueta';
    my @expected = qw(etiqueta);
    check( $text, @expected );

    $text = 'Arre, #etiqueta!';
    @expected = qw(etiqueta);
    check( $text, @expected );

    $text = 'Que, #etiqueta?';
    @expected = qw(etiqueta);
    check( $text, @expected );

    $text = '#uNo, #dos #TreS. #CinCO y #número';
    @expected = qw(uno dos tres cinco número);
    check( $text, @expected );

    $text = 'Aqui el #numero y #número!!!';
    @expected = qw(numero número);
    check( $text, @expected );

    return;
}

sub test_04_tags :Test( 2 ) {
    my ( $self ) = @_;

    my $text = '<p>#tag</p>';
    my @expected = qw(tag);
    check( $text, @expected );

    $text = '<p>#uno #dos #tres</p>';
    @expected = qw(uno dos tres);
    check( $text, @expected );

    return;
}

sub test_05_anchor :Test( 5 ) {
    my ( $self ) = @_;

    my $text = 'text <a href="/path/?query#anchor">';
    my @expected = qw();
    check( $text, @expected );

    $text = 'http://example.com/?query#anchor #tag';
    @expected = qw(tag);
    check( $text, @expected );

    $text = '#tag text <a href="http://example.com/?query#anchor">';
    @expected = qw(tag);
    check( $text, @expected );

    $text = 'text /path/?query#anchor ';
    @expected = qw();
    check( $text, @expected );

    $text = '<p>#número /path/?query#año #tres<p>';
    @expected = qw(número tres);
    check( $text, @expected );

    return;
}

sub test_06_punctuation :Test( 3 ) {
    my ( $self ) = @_;

    my $text = '#uno.dos';
    my @expected = qw(uno.dos);
    check( $text, @expected );

    $text = '#uno-dos';
    @expected = qw(uno-dos);
    check( $text, @expected );

    $text = '#uno+dos';
    @expected = qw(uno+dos);
    check( $text, @expected );

    return;
}

sub test_07_html_tags :Test( 4 ) {
    my ( $self ) = @_;

    my $text = '<p id="#uno">#dos</p>';
    my @expected = qw(dos);
    check( $text, @expected );

    $text = '<img alt="#tres"> #cinco';
    @expected = qw(cinco);
    check( $text, @expected );

    $text = '<p alt="#раз"> #два</p> #три';
    @expected = qw(два три);
    check( $text, @expected );

    $text = "&mdash; #android #банкер #мобильный";
    @expected = qw(android банкер мобильный);
    check( $text, @expected );

    return;
}

1;
