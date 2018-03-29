package Locale::Babelfish::Phrase::PluralForms;

# ABSTRACT: Babelfish AST pluralization node.

use utf8;
use strict;
use warnings;
use feature 'state';

use Carp (); # used inside compiled sub.
use Scalar::Util (); # used inside compiled sub.

use Locale::Babelfish::Phrase::Compiler ();

use parent qw( Locale::Babelfish::Phrase::Node );

our $VERSION = '2.004'; # VERSION

__PACKAGE__->mk_accessors( qw( forms name compiled locale ) );

our @sub_data = ();


sub to_perl_sub {
    my ( $self ) = @_;

    unless ( $self->compiled ) {
        state $compiler = Locale::Babelfish::Phrase::Compiler->new;
        my $regular_forms = $self->forms->{regular};
        for ( my $i = scalar(@$regular_forms) - 1; $i >= 0; $i--) {
            $regular_forms->[ $i ] = $compiler->compile( $regular_forms->[ $i ] );
        }
        my $strict_forms = $self->forms->{strict};
        for my $key ( keys %$strict_forms ) {
            $strict_forms->{ $key } = $compiler->compile( $strict_forms->{ $key } );
        }
        $self->compiled( 1 );
    }

    my $rule = Locale::Babelfish::Phrase::Pluralizer::find_rule( $self->locale );

    push @sub_data, [
        $rule,
        $self->{forms}->{strict},
        $self->{forms}->{regular},
    ];

    return $self->_to_perl_sub($self->{name}, scalar(@sub_data) - 1);
}

sub _to_perl_sub {
    my ( $self, $name, $index ) = @_;
    $name = $self->to_perl_escaped_str($name);

    my $text = "#line 49 \"". __FILE__. "\"
    sub { my ( \$params ) = \@_;
        my ( \$value, \$rule, \$strict_forms, \$regular_forms ) = (
            \$params->{ $name },
            \@{ \$Locale::Babelfish::Phrase::PluralForms::sub_data[$index] },
        );
        my \$r;
        unless ( Scalar::Util::looks_like_number(\$value) ) {
            \$value //= 'undef';
            Carp::cluck( \"$name parameter is not numeric: \$value\" );
            \$r = \$regular_forms->[ -1 ];
        }
        else {
            \$r = \$strict_forms->{\$value} // \$regular_forms->[ \$rule->(\$value) ] // \$regular_forms->[ -1 ];
        }
        return ref(\$r) ? \$r->(\$params) : ( \$r // '' );
    }";

    return eval $text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Babelfish::Phrase::PluralForms - Babelfish AST pluralization node.

=head1 VERSION

version 2.004

=head1 METHODS

=head2 to_perl_sub

    $node->to_perl_sub

Return sub that represents current node execution.

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
