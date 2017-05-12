package MixWithWords::ID;

use Lingua::ID::Number::Format::MixWithWords;
use Package::Rename qw(link_package);

link_package "Lingua::ID::Number::Format::MixWithWords", "MixWithWords::ID";

our $VERSION = '0.07'; # VERSION
1;
# ABSTRACT: Alias for Lingua::ID::Number::Format::MixWithWords

__END__

=pod

=encoding UTF-8

=head1 NAME

MixWithWords::ID - Alias for Lingua::ID::Number::Format::MixWithWords

=head1 VERSION

This document describes version 0.07 of MixWithWords::ID (from Perl distribution Lingua-ID-Number-Format-MixWithWords), released on 2016-06-14.

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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
