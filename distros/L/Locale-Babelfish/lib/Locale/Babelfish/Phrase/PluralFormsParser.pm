package Locale::Babelfish::Phrase::PluralFormsParser;

# ABSTRACT: Babelfish plurals syntax parser.

use utf8;
use strict;
use warnings;
use feature 'state';

use Locale::Babelfish::Phrase::Parser ();


our $VERSION = '2.003'; # VERSION

use parent qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors( qw( phrase strict_forms regular_forms ) );


sub new {
    my ( $class, $phrase ) = @_;
    my $parser = bless {}, $class;
    $parser->init( $phrase )  if defined $phrase;
    return $parser;
}


sub init {
    my ( $self, $phrase ) = @_;
    $self->phrase( $phrase );
    $self->regular_forms( [] );
    $self->strict_forms( {} );
    return $self;
}


sub parse {
    my ( $self, $phrase ) = @_;

    $self->init( $phrase )  if defined $phrase;
    state $phrase_parser = Locale::Babelfish::Phrase::Parser->new();

    # тут проще регуляркой
    my @forms = split( m/(?<!\\)\|/s, $phrase );

    for my $form ( @forms ) {
        my $value = undef;
        if ( $form =~ m/\A=([0-9]+)\p{PerlSpace}*(.+)\z/s ) {
            ( $value, $form ) = ( $1, $2 );
        }
        $form = $phrase_parser->parse( $form );

        if ( defined $value ) {
            $self->strict_forms->{$value} = $form;
        }
        else {
            push @{ $self->regular_forms }, $form;
        }
    }

    return {
        strict => $self->strict_forms,
        regular => $self->regular_forms,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Babelfish::Phrase::PluralFormsParser - Babelfish plurals syntax parser.

=head1 VERSION

version 2.003

=head1 DESCRIPTION

Returns { script_forms => {}, regular_forms = [] }

Every plural form represented as AST.

=head1 METHODS

=head2 new

    $class->new()
    $class->new( $phrase )

Instantiates parser.

=head2 init

Initializes parser. Should not be called directly.

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
