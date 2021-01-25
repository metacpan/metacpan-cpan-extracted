package Math::Sidef;

use utf8;
use 5.016;
use strict;
use warnings;

use Exporter;

our $VERSION = '0.03';

use Sidef;
use Math::AnyNum;

my $sidef_number = 'Sidef::Types::Number::Number';
my $sidef_array  = 'Sidef::Types::Array::Array';
my $sidef_string = 'Sidef::Types::String::String';
my $sidef_bool   = 'Sidef::Types::Bool::Bool';

my @names = grep { /^\w+\z/ } keys %{$sidef_number->methods->get_value};

our @ISA         = qw(Exporter);
our @EXPORT_OK   = @names;
our %EXPORT_TAGS = (all => \@names);

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
                  ? [map { ref($_) eq 'Math::AnyNum' ? $sidef_number->new($$_) : $sidef_number->new($_) } @$_]
                  : $sidef_number->new($_)
            } @args;

            my $r = &{$sidef_number . '::' . $name}(@args);

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

  say prime(1e9);       # 10^9-th prime number
  say composite(1e9);   # 10^9-th composite number

  # Prime factorization of 2^128 + 1
  say join ' * ', factor(ipow(2, 128) + 1);

  # Iterate over prime numbers in range 1..100
  Math::Sidef::each_prime(1, 100, sub {
     say $_[0];
  });

=head1 DESCRIPTION

B<Math::Sidef> provides an easy interface to the numerical built-in system of L<Sidef>.

It supports all the numerical functions provided by L<Sidef::Types::Number::Number>.

The returned values are L<Math::AnyNum> objects.

=head1 IMPORT

Any function can be imported, using the following syntax:

    use Math::Sidef qw(function_name);

Additionally, for importing all the functions, use:

    use Math::Sidef qw(:all);

The list of functions available for importing, can be listed with:

    CORE::say join ", ", sort @Math::Sidef::EXPORT_OK;

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

Copyright (C) 2020 by Daniel "Trizen" Șuteu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.32.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
