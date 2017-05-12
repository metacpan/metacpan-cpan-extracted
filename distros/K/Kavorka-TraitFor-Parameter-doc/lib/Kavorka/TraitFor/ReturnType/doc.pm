use 5.14.0;
use strict;
use warnings;

package Kavorka::TraitFor::ReturnType::doc;

our $VERSION = '0.1104'; # VERSION
# ABSTRACT: Document return types in the signature

use Moo::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kavorka::TraitFor::ReturnType::doc - Document return types in the signature

=head1 VERSION

Version 0.1104, released 2016-01-26.

=head1 SYNOPSIS

    # The class
    use Moops;

    class My::Class using Moose {

        method square(Int $integer --> Int does doc('The squared integer.')) {

            return $integer * $integer;

        }

    }

    # Elsewhere
    my $return_type = My::Class->meta->get_method('square')->signature->return_types->[0];
    say sprintf 'Returns an %s. %s', $return_type->type->name, $return_type->traits->{'doc'}[0];

    # says 'Returns an Int. The squared integer.'

=head1 DESCRIPTION

Kavorka::TraitFor::ReturnType::doc adds a trait (C<doc>) that is useful for documenting in L<Moops> classes created using L<Moose>.

=head1 SEE ALSO

=over 4

=item *

L<Kavorka::TraitFor::Parameter::doc>

=item *

L<Moops>

=item *

L<Kavorka>

=item *

L<Moose>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Kavorka-TraitFor-Parameter-doc>

=head1 HOMEPAGE

L<https://metacpan.org/release/Kavorka-TraitFor-Parameter-doc>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
