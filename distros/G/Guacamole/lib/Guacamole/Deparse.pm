package Guacamole::Deparse;
our $AUTHORITY = 'cpan:XSAWYERX';
# ABSTRACT: A Gaucamole-based Deparser
$Guacamole::Deparse::VERSION = '0.007';
use strict;
use warnings;
use parent 'Exporter';
use experimental qw< postderef signatures >;
use Guacamole;
use Data::Visitor::Tiny qw< visit >;
use Ref::Util qw< is_hashref >;

our @EXPORT_OK = qw< deparse >;

my $var_names_re = qr/^Var(Scalar|Array|Hash|Code|Glob|ArrayTop)$/;

sub deparse ($string) {
    my @results = Guacamole->parse($string);
    foreach my $result (@results) {
        my @elements;

        visit( $result, sub ( $key, $valueref, $ctx ) {
            # Fold some stuff
            if ( is_hashref( $valueref->$* ) ) {
                my $name = $valueref->$*->{'name'} || '';

                if ( $name =~ $var_names_re ) {
                    fold_var_name($valueref);
                }

                if ( $name =~ m/^(Interpol|Literal)String$/ ) {
                    fold_string($valueref);
                }
            }

            # Take lexeme as a string element
            if (
                is_hashref( $valueref->$* )
             && $valueref->$*->{'type'} eq 'lexeme'
            ) {
                push @elements, $valueref->$*->{'value'};
            }
        });

        print join( ' ', @elements ), "\n";
    }
}

sub fold_var_name ($valueref) {
    # Merge children
    my $sigil_elem = shift $valueref->$*->{'children'}->@*;
    my $sigil      = $sigil_elem->{'value'};

    $valueref->$*->{'children'}[0]{'children'}[0]{'value'}
        = $sigil . $valueref->$*->{'children'}[0]{'children'}[0]{'value'};
}

sub fold_string ($valueref) {
    my $value = join '', map $_->{'value'}, $valueref->$*->{'children'}->@*;

    $valueref->$*->{'children'} = [
        {
            'type'  => 'lexeme',
            'value' => $value,
        }
    ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Guacamole::Deparse - A Gaucamole-based Deparser

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use Guacamole::Deparse;
    deparse($string); # prints all lexemes with a some folding rules

=head1 WHERE'S THE REST?

Soon.

=head1 SEE ALSO

L<Guacamole>

=head1 AUTHORS

=over 4

=item *

Sawyer X

=item *

Vickenty Fesunov

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Sawyer X.

This is free software, licensed under:

  The MIT (X11) License

=cut
