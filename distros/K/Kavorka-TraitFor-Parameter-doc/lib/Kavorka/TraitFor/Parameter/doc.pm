use 5.14.0;
use strict;
use warnings;

package Kavorka::TraitFor::Parameter::doc;

our $VERSION = '0.1104'; # VERSION
# ABSTRACT: Document method parameters in the signature

use Moo::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kavorka::TraitFor::Parameter::doc - Document method parameters in the signature



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.14+-brightgreen.svg" alt="Requires Perl 5.14+" /> <a href="https://travis-ci.org/Csson/p5-Kavorka-TraitFor-Parameter-doc"><img src="https://api.travis-ci.org/Csson/p5-Kavorka-TraitFor-Parameter-doc.svg?branch=master" alt="Travis status" /></a> <img src="https://img.shields.io/badge/coverage-100.0%-brightgreen.svg" alt="coverage 100.0%" /></p>

=end HTML


=begin markdown

![Requires Perl 5.14+](https://img.shields.io/badge/perl-5.14+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Kavorka-TraitFor-Parameter-doc.svg?branch=master)](https://travis-ci.org/Csson/p5-Kavorka-TraitFor-Parameter-doc) ![coverage 100.0%](https://img.shields.io/badge/coverage-100.0%-brightgreen.svg)

=end markdown

=head1 VERSION

Version 0.1104, released 2016-01-26.

=head1 SYNOPSIS

    # The class
    use Moops;

    class My::Class using Moose {

        method square(Int $integer does doc('The integer to square.')) {

            return $integer * $integer;

        }

    }

    # Elsewhere
    my $param = My::Class->meta->get_method('square')->signature->params->[1];
    say sprintf '%s %s. %s', $param->optional ? 'Optional' : 'Required',
                             $param->type->name,
                             $param->traits->{'doc'}[0];

    # says 'Required Int. The integer to square.'

=head1 DESCRIPTION

Kavorka::TraitFor::Parameter::doc adds a trait (C<doc>) that is useful for documenting in L<Moops> classes created using L<Moose>.

=head1 SEE ALSO

=over 4

=item *

L<Kavorka::TraitFor::ReturnType::doc>

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
