package Math::Utils::XS;

use strict;
use warnings;

use XSLoader;
use parent 'Exporter';

our $VERSION = '0.000005';
XSLoader::load( __PACKAGE__, $VERSION );

our %EXPORT_TAGS = (
    utility => [qw(
        log10 log2
        fsum
        sign floor ceil
    )],
);

our @EXPORT_OK = (
    @{ $EXPORT_TAGS{utility} },
);

1;

__END__

=pod

=encoding utf8

=head1 NAME

Math::Utils::XS - Some math utility functions implemented in XS

=head1 VERSION

Version 0.000005

=head1 SYNOPSIS

    use Math::Utils::XS q(utility);

    my $l10 = log10(100);              # returns 2
    my $l2 = log2(32);                 # returns 5
    my $sum = fsum(1, 1e50, 1, -1e50); # returns 2

    my $sign = sign(-22);              # returns -1
    my $sign = sign(3 - 3);            # returns  0
    my $sign = sign(+22);              # returns +1

    my $f = floor(22/7);               # returns 3
    my $f = floor(2.7182);             # returns 2

    my $c = floor(-22/7);              # returns -4
    my $c = floor(-2.7182);            # returns -3

=head1 FUNCTIONS

Note: functions marked with a (*) simply expose the corresponding function from
the C library.

=head2 log10 (*)

Compute a number's logarithm in base 10.

=head2 log2 (*)

Compute a number's logarithm in base 2.

=head2 floor (*)

Compute the largest integer that is less than or equal than a number.

=head2 ceil (*)

Compute the smallest integer that is greater than or equal than a number.

=head2 sign

Return -1, 0 or +1 depending on whether a number is negative, zero or positive.

=head2 fsum

Compute the sum of all arguments.  It will process each separate argument, and
recurse into any arrays (but not hashes) all the way inside.

The sum is computed in a way that you can safely add floating point numbers,
even if their magnitudes are very different.  This is done using Neumaier's
modification of Kahan's summation algorith, described here:
L<https://en.wikipedia.org/wiki/Kahan_summation_algorithm>.

=head1 SEE ALSO

L<< https://metacpan.org/pod/Math::Utils >>

=head1 LICENSE

Copyright (C) Gonzalo Diethelm.

This library is free software; you can redistribute it and/or modify it under
the terms of the MIT license.

=head1 AUTHOR

=over 4

=item * Gonzalo Diethelm C<< gonzus AT cpan DOT org >>

=back

=head1 THANKS
