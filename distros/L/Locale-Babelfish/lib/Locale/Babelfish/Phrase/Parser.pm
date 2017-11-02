package Locale::Babelfish::Phrase::Parser;

# ABSTRACT: Babelfish syntax parser.

use utf8;
use strict;
use warnings;

use Locale::Babelfish::Phrase::Literal ();
use Locale::Babelfish::Phrase::Variable ();
use Locale::Babelfish::Phrase::PluralForms ();
use Locale::Babelfish::Phrase::PluralFormsParser ();

use parent qw( Locale::Babelfish::Phrase::ParserBase );

our $VERSION = '2.003'; # VERSION

__PACKAGE__->mk_accessors( qw( locale mode pieces escape pf0 ) );

use constant {
    LITERAL_MODE  => 'Locale::Babelfish::Phrase::Literal',
    VARIABLE_MODE => 'Locale::Babelfish::Phrase::Variable',
    PLURALS_MODE  => 'Locale::Babelfish::Phrase::PluralForms',
    VARIABLE_RE   => qr/^[a-zA-Z0-9_\.]+$/,
};


sub new {
    my ( $class, $phrase, $locale ) = @_;
    my $self = $class->SUPER::new( $phrase );
    $self->locale( $locale )  if $locale;
    return $self;
}


sub init {
    my ( $self, $phrase ) = @_;
    $self->SUPER::init( $phrase );
    $self->mode( LITERAL_MODE );
    $self->pieces( [] );
    $self->pf0( undef ); # plural forms without name yet
    return $self;
}


sub finalize_mode {
    my ( $self ) = @_;
    if ( $self->mode eq LITERAL_MODE ) {
        push @{ $self->pieces }, LITERAL_MODE->new( text => $self->piece )
            if length($self->piece) || scalar(@{ $self->pieces }) == 0;
    }
    elsif ( $self->mode eq VARIABLE_MODE ) {
        $self->throw( "Variable definition not ended with \"}\": ". $self->piece );
    }
    elsif ( $self->mode eq PLURALS_MODE ) {
        $self->throw( "Plural forms definition not ended with \"))\": ". $self->piece )
            unless defined $self->pf0;
        push @{ $self->pieces }, PLURALS_MODE->new( forms => $self->pf0, name => $self->piece, locale => $self->locale, );
    }
    else {
        $self->throw( "Logic broken, unknown parser mode: ". $self->mode );
    }
}


sub parse {
    my ( $self, $phrase, $locale ) = @_;

    $self->SUPER::parse( $phrase );
    $self->locale( $locale )  if $locale;

    my $plurals_parser = Locale::Babelfish::Phrase::PluralFormsParser->new();

    while ( 1 ) {
        my $char = $self->to_next_char;

        unless ( length $char ) {
            $self->finalize_mode;
            return $self->pieces;
        }

        if ( $self->mode eq LITERAL_MODE ) {
            if ( $self->escape ) {
                $self->add_to_piece( $char );
                $self->escape(0);
                next;
            }

            if ( $char eq "\\" ) {
                $self->escape( 1 );
                next;
            }

            if ( $char eq '#' && $self->next_char eq '{' ) {
                if ( length $self->piece ) {
                    push @{ $self->pieces }, LITERAL_MODE->new( text => $self->piece );
                    $self->piece('');
                }
                $self->to_next_char; # skip "{"
                $self->mode( VARIABLE_MODE );
                next;
            }

            if ( $char eq '(' && $self->next_char eq '(' ) {
                if ( length $self->piece ) {
                    push @{ $self->pieces }, LITERAL_MODE->new( text => $self->piece );
                    $self->piece('');
                }
                $self->to_next_char; # skip second "("
                $self->mode( PLURALS_MODE );
                next;
            }
        }

        if ( $self->mode eq VARIABLE_MODE ) {
            if ( $self->escape ) {
                $self->add_to_piece( $char );
                $self->escape(0);
                next;
            }

            if ( $char eq "\\" ) {
                $self->escape( 1 );
                next;
            }

            if ( $char eq '}' ) {
                my $name = $self->trim( $self->piece );
                unless ( length $name ) {
                    $self->throw( "No variable name given." );
                }
                if ( $name !~ VARIABLE_RE ) {
                    $self->throw( "Variable name doesn't meet conditions: $name." );
                }
                push @{ $self->pieces }, VARIABLE_MODE->new( name => $name );
                $self->piece('');
                $self->mode( LITERAL_MODE );
                next;
            }
        }

        if ( $self->mode eq PLURALS_MODE ) {
            if ( defined $self->pf0 ) {
                if ( $char =~ VARIABLE_RE && ($char ne '.' || $self->next_char =~ VARIABLE_RE) ) {
                    $self->add_to_piece( $char );
                    next;
                }
                else {
                    push @{ $self->pieces }, PLURALS_MODE->new( forms => $self->pf0, name => $self->piece, locale => $self->locale, );
                    $self->pf0( undef );
                    $self->mode( LITERAL_MODE );
                    $self->piece('');
                    $self->backward;
                    next;
                }
            }
            if ( $char eq ')' && $self->next_char eq ')' ) {
                $self->pf0( $plurals_parser->parse( $self->piece ) );
                $self->piece('');
                $self->to_next_char; # skip second ")"
                if ( $self->next_char eq ':' ) {
                    $self->to_next_char; # skip ":"
                    next;
                }
                push @{ $self->pieces }, PLURALS_MODE->new( forms => $self->pf0, name => 'count', locale => $self->locale, );
                $self->pf0( undef );
                $self->mode( LITERAL_MODE );
                next;
            }
        }
        $self->add_to_piece( $char );
    } # while ( 1 )
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Babelfish::Phrase::Parser - Babelfish syntax parser.

=head1 VERSION

version 2.003

=head1 METHODS

=head2 new

    $class->new()
    $class->new( $phrase )

Instantiates parser.

=head2 init

Initializes parser. Should not be called directly.

=head2 finalize_mode

Finalizes all operations after phrase end.

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
