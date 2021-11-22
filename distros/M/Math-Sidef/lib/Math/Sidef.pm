package Math::Sidef;

use utf8;
use 5.016;
use strict;
use warnings;

use Exporter;

our $VERSION = '0.05';

use Sidef;
use Math::AnyNum;

use Sidef::Types::Number::Number;
use Sidef::Types::Number::Gauss;
use Sidef::Types::Number::Quadratic;
use Sidef::Types::Number::Quaternion;
use Sidef::Types::Number::Mod;
use Sidef::Types::Number::Polynomial;
use Sidef::Types::Number::Fraction;

my $sidef_number     = 'Sidef::Types::Number::Number';
my $sidef_gauss      = 'Sidef::Types::Number::Gauss';
my $sidef_quadratic  = 'Sidef::Types::Number::Quadratic';
my $sidef_quaternion = 'Sidef::Types::Number::Quaternion';
my $sidef_mod        = 'Sidef::Types::Number::Mod';
my $sidef_polynomial = 'Sidef::Types::Number::Polynomial';
my $sidef_fraction   = 'Sidef::Types::Number::Fraction';
my $sidef_array      = 'Sidef::Types::Array::Array';
my $sidef_string     = 'Sidef::Types::String::String';
my $sidef_bool       = 'Sidef::Types::Bool::Bool';

my @number_methods     = grep { /^\w+\z/ } keys %{$sidef_number->methods->get_value};
my @gauss_methods      = grep { /^\w+\z/ } keys %{$sidef_gauss->methods->get_value};
my @quadratic_methods  = grep { /^\w+\z/ } keys %{$sidef_quadratic->methods->get_value};
my @quaternion_methods = grep { /^\w+\z/ } keys %{$sidef_quaternion->methods->get_value};
my @mod_methods        = grep { /^\w+\z/ } keys %{$sidef_mod->methods->get_value};
my @polynomial_methods = grep { /^\w+\z/ } keys %{$sidef_polynomial->methods->get_value};
my @fraction_methods   = grep { /^\w+\z/ } keys %{$sidef_fraction->methods->get_value};

my @names = (
             @number_methods, @gauss_methods,      @quadratic_methods, @quaternion_methods,
             @mod_methods,    @polynomial_methods, @fraction_methods
            );

@names = do {    # remove duplicates
    my %seen;
    grep { !$seen{$_}++ } @names;
};

my @constructors = qw(Number Gauss Quadratic Quaternion Mod Poly Polynomial Fraction);

our @ISA       = qw(Exporter);
our @EXPORT_OK = (@names, @constructors);
our %EXPORT_TAGS = (
                    number     => ['Number',     @number_methods],
                    gauss      => ['Gauss',      @gauss_methods],
                    quadratic  => ['Quadratic',  @quadratic_methods],
                    quaternion => ['Quaternion', @quaternion_methods],
                    mod        => ['Mod',        @mod_methods],
                    poly       => ['Poly',       @polynomial_methods],
                    polynomial => ['Polynomial', @polynomial_methods],
                    fraction   => ['Fraction',   @fraction_methods],
                    all        => [@names,       @constructors],
                   );

sub Number {
    _pack_value(@_);
}

sub Gauss {
    $sidef_gauss->new(map { _pack_value($_) } @_);
}

sub Quadratic {
    $sidef_quadratic->new(map { _pack_value($_) } @_);
}

sub Quaternion {
    $sidef_quaternion->new(map { _pack_value($_) } @_);
}

sub Mod {
    $sidef_mod->new(map { _pack_value($_) } @_);
}

sub Polynomial {
    $sidef_polynomial->new(
        map {
            ref($_) eq 'ARRAY'
              ? $sidef_array->new([map { _pack_value($_) } @$_])
              : _pack_value($_)
          } @_
    );
}

*Poly = \&Polynomial;

sub Fraction {
    $sidef_fraction->new(map { _pack_value($_) } @_);
}

sub _unpack_value {
    my ($r) = @_;

    my $ref = ref($r // return undef);

    if ($ref eq $sidef_array) {
        return [map { __SUB__->($_) } @$r];
    }

    if ($ref eq $sidef_number) {
        return Math::AnyNum->new($$_);
    }

    if ($ref eq $sidef_bool) {
        return $$r;
    }

    if ($ref eq $sidef_string) {
        return $$r;
    }

    return $r;
}

sub _pack_value {
    my ($r) = @_;

    my $ref = ref($r // return undef);

    if ($ref eq 'Math::AnyNum') {
        return $sidef_number->new($$r);
    }

    if (   $ref eq $sidef_gauss
        or $ref eq $sidef_quadratic
        or $ref eq $sidef_quaternion
        or $ref eq $sidef_mod
        or $ref eq $sidef_fraction
        or $ref eq $sidef_polynomial
        or $ref eq $sidef_number) {
        return $r;
    }

    return $sidef_number->new($r);
}

{
    no strict 'refs';
    foreach my $name (@names) {

        *{__PACKAGE__ . '::' . $name} = sub {
            my (@args) = @_;

            @args = map {
                ref($_) eq 'Math::AnyNum'
                  ? $sidef_number->new($$_)
                  : ref($_) eq 'CODE' ? Sidef::Types::Block::Block->new(
                    code => do {
                        my $v = $_;
                        sub {
                            _pack_value(scalar $v->(map { _unpack_value($_) } @_));
                        }
                    }
                  )
                  : ref($_) eq 'ARRAY'
                  ? [map { ref($_) eq 'Math::AnyNum' ? $sidef_number->new($$_) : _pack_value($_) } @$_]
                  : _pack_value($_)
            } @args;

            my $self = shift(@args);
            my @r    = $self->$name(@args);

            #my @r = &{$sidef_number . '::' . $name}(@args);

            if (scalar(@r) == 1) {

                my $r = $r[0];

                if (ref($r // return undef) eq $sidef_number) {
                    return Math::AnyNum->new($$r);
                }

                if (ref($r) eq $sidef_bool) {
                    return $$r;
                }

                if (ref($r) eq $sidef_array) {
                    return map { ref($r) eq $sidef_number ? Math::AnyNum->new($$_) : _unpack_value($_) } @$r;
                }

                return _unpack_value($r);
            }

            map { _unpack_value($_) } @r;
        };
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Math::Sidef - Perl interface to Sidef's mathematical library.

=head1 SYNOPSIS

  use 5.018;
  use Math::Sidef qw(factor composite prime ipow);

  say prime(1e7);       # 10^7-th prime number
  say composite(1e7);   # 10^7-th composite number

  # Prime factorization of 2^128 + 1
  say join ' * ', factor(ipow(2, 128) + 1);

  # Iterate over prime numbers in range 50..100
  Math::Sidef::each_prime(50, 100, sub {
     say $_[0];
  });

=head1 DESCRIPTION

B<Math::Sidef> provides an easy interface to the numerical built-in system of L<Sidef>.

It supports all the numerical functions provided by:

=over 4

=item * L<Sidef::Types::Number::Number>

=item * L<Sidef::Types::Number::Mod>

=item * L<Sidef::Types::Number::Gauss>

=item * L<Sidef::Types::Number::Quadratic>

=item * L<Sidef::Types::Number::Quaternion>

=item * L<Sidef::Types::Number::Polynomial>

=item * L<Sidef::Types::Number::Fraction>

=back

The returned numerical values are returned as L<Math::AnyNum> objects.

=head1 IMPORT

Any function can be imported, using the following syntax:

    use Math::Sidef qw(function_name);

Additionally, for importing all the functions, use:

    use Math::Sidef qw(:all);

It's also possible to import only functions for specific uses:

    :number        export Number functions, with Number() constructor
    :gauss         export Gauss functions, with Gauss() constructor
    :quadratic     export Quadratic functions, with Quadratic() constructor
    :quaternion    export Quaternion functions, with Quaternion() constructor
    :mod           export Mod functions, with Mod() constructor
    :poly          export Poly functions, with Poly() constructor
    :fraction      export Fraction functions, with Fraction() constructor

Example:

    use Math::Sidef qw(:gauss :quadratic);

    say pow(Gauss(3,4), 10);
    say powmod(Quadratic(3, 4, 100), 10, 97);

The list of functions available for importing, can be listed with:

    CORE::say join ", ", sort @Math::Sidef::EXPORT_OK;

while the methods for a specific group (e.g.: quadratic), can be listed with:

    CORE::say join ", ", sort @{$Math::Sidef::EXPORT_TAGS{quadratic}};

=head1 SEE ALSO

=over 4

=item * L<Sidef> - The Sidef programming language.

=item * L<Math::AnyNum> - Arbitrary size precision for integers, rationals, floating-points and complex numbers.

=item * L<Math::Prime::Util> - Utilities related to prime numbers, including fast sieves and factoring.

=item * L<Math::Prime::Util::GMP> - Utilities related to prime numbers, using GMP.

=back

=head1 REPOSITORY

L<https://github.com/trizen/Math-Sidef>

=head1 AUTHOR

Daniel "Trizen" Șuteu, E<lt>trizen@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Daniel "Trizen" Șuteu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.32.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
