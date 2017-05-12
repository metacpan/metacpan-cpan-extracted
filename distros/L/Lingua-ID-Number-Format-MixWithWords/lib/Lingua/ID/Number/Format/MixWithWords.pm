package Lingua::ID::Number::Format::MixWithWords;

our $DATE = '2016-06-14'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(Lingua::Base::Number::Format::MixWithWords);
require Lingua::EN::Number::Format::MixWithWords;

use Math::Round qw(nearest);
use Number::Format;
use POSIX qw(floor log10);
use Perinci::Sub::Util qw(gen_modified_sub);

use Exporter qw(import);
our @EXPORT_OK = qw(format_number_mix);

our %SPEC;

gen_modified_sub(
    output_name => 'format_number_mix',
    summary => 'Format number to a mixture of numbers and words (e.g. "12,3 juta")',
    base_name => 'Lingua::EN::Number::Format::MixWithWords::format_number_mix',
    remove_args => ['scale'],
    output_code => sub {
        my %args = @_;

        my $f = __PACKAGE__->new(
            num_decimal   => $args{num_decimal},
            min_format    => $args{min_format},
            min_fraction  => $args{min_fraction},
        );
        $f->_format($args{num});
    }
);

my $id_names = {
    #2   => 'ratus',
    3   => 'ribu',
    6   => 'juta',
    9   => 'miliar',
    12   => 'triliun',
    15   => 'kuadriliun',
    18   => 'kuintiliun',
    21   => 'sekstiliun',
    24   => 'septiliun',
    27   => 'oktiliun',
    30   => 'noniliun',
    33   => 'desiliun',
    36   => 'undesiliun',
    39   => 'duodesiliun',
    42   => 'tredesiliun',
    45   => 'kuatuordesiliun',
    48   => 'kuindesiliun',
    51   => 'seksdesiliun',
    54   => 'septendesiliun',
    57   => 'oktodesiliun',
    60   => 'novemdesiliun',
    63   => 'vigintiliun',
    100  => 'googol',
    303  => 'sentiliun',
};

sub new {
    my ($class, %args) = @_;
    $args{decimal_point} //= ",";
    $args{thousands_sep} //= ".";
    $args{names}         //= $id_names;

    # XXX should use "SUPER"
    my $self = Lingua::Base::Number::Format::MixWithWords->new(%args);
    bless $self, $class;
}

1;
# ABSTRACT: Format number to a mixture of numbers and words (e.g. "12,3 juta")

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::ID::Number::Format::MixWithWords - Format number to a mixture of numbers and words (e.g. "12,3 juta")

=head1 VERSION

This document describes version 0.07 of Lingua::ID::Number::Format::MixWithWords (from Perl distribution Lingua-ID-Number-Format-MixWithWords), released on 2016-06-14.

=head1 SYNOPSIS

 use Lingua::ID::Number::Format::MixWithWords qw(format_number_mix);

 print format_number_mix(num => 1.23e7); # prints "12,3 juta"

=head1 DESCRIPTION

This module formats number with Indonesian names of large numbers (ribu, juta,
miliar, triliun, and so on), e.g. 1.23e7 becomes "12,3 juta". If number is too
small or too large so it does not have any appropriate names, it will be
formatted like a normal number.

=head1 FUNCTIONS


=head2 format_number_mix(%args) -> any

Format number to a mixture of numbers and words (e.g. "12,3 juta").

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<min_format> => I<float> (default: 1000000)

Number must be larger than this to be formatted as mixture of number and word.

=item * B<min_fraction> => I<float> (default: 1)

Whether smaller number can be formatted with 0,x.

If min_fraction is 1 (the default) or 0.9, 800000 won't be formatted as 0.9
omillion but will be if min_fraction is 0.8.

=item * B<num> => I<float>

The input number to format.

=item * B<num_decimal> => I<int>

Number of decimal points to round.

Can be negative, e.g. -1 to round to nearest 10, -2 to nearest 100, and so on.

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Lingua-ID-Number-Format-MixWithWords>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Lingua-ID-Number-Format-MixWithWords>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Lingua-ID-Number-Format-MixWithWords>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Lingua::ID::Nums2Words>

L<Lingua::EN::Number::Format::MixWithWords>

L<Number::Format>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
