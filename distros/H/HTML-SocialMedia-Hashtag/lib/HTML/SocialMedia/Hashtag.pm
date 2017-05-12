package HTML::SocialMedia::Hashtag;

use strict;
use warnings;

=head1 NAME

HTML::SocialMedia::Hashtag

=head1 DESCRIPTION

Get #hashtags and @usernames from html

=head1 SYNOPSIS

    use HTML::SocialMedia::Hashtag;
    my $scanner = HTML::SocialMedia::Hashtag -> new( text => 'text with #hashtag and @username' );
    my @hashtags  = $scanner -> hashtags();
    my @usernames = $scanner -> usernames();

=cut

our $VERSION = '0.4';

use Encode qw(decode encode is_utf8);
use HTML::Strip;

use Moose;
use namespace::autoclean;

has 'text' => ( is => 'rw', isa => 'Str', required => 1 );

=head1 METHODS

=head2 hashtags()

Get lowercased and unique hashtags from html

=cut

sub hashtags {
    my ( $self ) = @_;

    my @hashtags = map { _encode_utf( lc( _decode_utf( $_ ) ) ) } $self -> all_hashtags();

    return _uniq_array( @hashtags );
}

=head2 all_hashtags()

Get all hashtags

=cut

sub all_hashtags {
    my ( $self ) = @_;

    my $strip = HTML::Strip -> new();
    $strip -> set_decode_entities( 0 );

    my $parsed_text = $strip -> parse( $self -> text() );

    my @all_hashtags;

    while ( $parsed_text =~ /(^|\s|>)\#(\S+)/gxo ) {
        my $hashtag = $2;

        $hashtag =~ s/(,)*$//g;
        $hashtag =~ s/(!)*!$//g;
        $hashtag =~ s/(\.)*$//g;
        $hashtag =~ s/(\?)*$//g;
        $hashtag =~ s/(<).*$//g;

        push @all_hashtags, $hashtag;
    }

    return @all_hashtags;
}

=head2 nicknames()

Get unique nicknames from html

=cut

sub nicknames {
    my ( $self ) = @_;

    return _uniq_array( $self -> all_nicknames() );
}

=head2 all_nicknames()

Get all nicknames

=cut

sub all_nicknames {
    my ( $self ) = @_;

    my @nicknames;

    my $text = $self -> text();

    while ( $text =~ /\@(\S+)/gxo ) {
            my $nickname = $1;

            $nickname =~ s/(,)*$//g;
            $nickname =~ s/(!)*!$//g;
            $nickname =~ s/(\.)*$//g;
            $nickname =~ s/(\?)*$//g;

            push @nicknames, $nickname;
    }

    return @nicknames;
}

sub _uniq_array {
    my ( @array ) = @_;

    my %seen = ();

    return grep { ! $seen{ $_ } ++ } @array;
}

sub _encode_utf {
    my ( $string ) = @_;

    my $result = is_utf8( $string )
               ? encode( 'UTF-8', $string )
               : $string;

    if( is_utf8( $result ) ) {
        utf8::downgrade( $result );
    }

    return $result;
}

sub _decode_utf {
    my ( $string ) = @_;

    return is_utf8( $string )
         ? $string
         : decode( 'UTF-8', $string );
}

__PACKAGE__ -> meta() -> make_immutable();

1;

__END__

=head1 AUTHOR

German Semenkov
german.semenkov@gmail.com

=cut