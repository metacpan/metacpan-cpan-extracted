package Locale::Babelfish::Phrase::ParserBase;

# ABSTRACT: Babelfish abstract parser.

use utf8;
use strict;
use warnings;

use parent qw( Class::Accessor::Fast );

our $VERSION = '2.004'; # VERSION

__PACKAGE__->mk_accessors( qw( phrase index length prev piece escape ) );


sub new {
    my ( $class, $phrase ) = @_;
    my $parser = bless {}, $class;
    $parser->init( $phrase )  if defined $phrase;
    return $parser;
}


sub init {
    my ( $self, $phrase ) = @_;
    $self->phrase( $phrase );
    $self->index( -1 );
    $self->prev( undef );
    $self->length( length( $phrase ) );
    $self->piece( '' );
    $self->escape( 0 );
    return $self;
}


sub trim {
    my ( $self, $str ) = @_;
    $str =~ s/\A\p{PerlSpace}+//;
    $str =~ s/\p{PerlSpace}+\z//;
    return $str;
}


sub char {
    my ( $self ) = @_;
    return substr( $self->phrase, $self->index, 1 ) // '';
}


sub next_char {
    my ( $self ) = @_;
    return ''  if $self->index >= $self->length - 1;
    return substr( $self->phrase, $self->index + 1, 1 ) // '';
}


sub to_next_char {
    my ( $self ) = @_;
    if ( $self->index >= 0 ) {
        $self->prev( $self->char );
    }
    $self->index( $self->index + 1 );
    return ''  if $self->index eq $self->length;
    return $self->char();
}


sub throw {
    my ( $self, $message ) = @_;
    die "Cannot parse phrase \"". ( $self->phrase // 'undef' ). "\" at ". ( $self->index // '-1' ). " index: $message";
}


sub add_to_piece {
    my ( $self, @chars ) = @_;
    $self->piece( join('', $self->piece, @chars ) );
}


sub backward {
    my ( $self ) = @_;
    $self->index( $self->index - 1 );
    if ( $self->index > 0 ) {
        $self->prev( substr( $self->phrase, $self->index - 1, 1 ) );
    }
    else {
        $self->prev( undef );
    }
}


sub parse {
    my ( $self, $phrase ) = @_;

    if ( defined $phrase ) {
        $self->init( $phrase );
    }

    $self->throw( "No phrase given" )  unless defined $self->phrase;

    return $self->phrase;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Babelfish::Phrase::ParserBase - Babelfish abstract parser.

=head1 VERSION

version 2.004

=head1 METHODS

=head2 new

    $class->new()
    $class->new( $phrase )

Instantiates parser.

=head2 init

Initializes parser. Should not be called directly.

=head2 trim

    $self->trim( $str )

Removes space characters from start and end of specified string.

=head2 char

    $self->char

Gets character on current cursor position.

Will return empty string if no character.

=head2 next_char

    $self->next_char

Gets character on next cursor position.

Will return empty string if no character.

=head2 to_next_char

    $self->to_next_char

Moves cursor to next position.

Return new current character.

=head2 throw

    $self->throw( $message )

Throws given message in phrase context.

=head2 add_to_piece

    $parser->add_to_piece( @chars )

Adds given chars to current piece.

=head2 backward

    $parser->backward

Moves cursor backward.

=head2 parse

    $parser->parse()
    $parser->parse( $phrase )

Parses specified phrase.

=head1 AUTHORS

=over 4

=item *

Akzhan Abdulin <akzhan@cpan.org>

=item *

Igor Mironov <grif@cpan.org>

=item *

Victor Efimov <efimov@reg.ru>

=item *

REG.RU LLC

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by REG.RU LLC.

This is free software, licensed under:

  The MIT (X11) License

=cut
