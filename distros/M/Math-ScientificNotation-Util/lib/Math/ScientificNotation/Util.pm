package Math::ScientificNotation::Util;

our $DATE = '2016-06-17'; # DATE
our $VERSION = '0.003'; # VERSION

use Exporter qw(import);
our @EXPORT_OK = qw(sci2dec);

sub sci2dec {
    my $num = shift;
    die "Please specify a number" unless defined $num;

    if ($num =~ /\A(?:[+-]?)(?:\d+\.?|\d*\.(\d+))[eE]([+-]?\d+)\z/) {
        my $num_digs_after_dec = length($1 || "") - $2;
        $num_digs_after_dec = 0 if $num_digs_after_dec < 0;
        return sprintf("%.${num_digs_after_dec}f", $num);
    } elsif ($num =~ /\A[+-]?(?:\d+\.?|\d*\.\d+)\z/) {
        # already in decimal notation
        return $num;
    } else {
        die "Not a decimal number: $num";
    }
}

1;
# ABSTRACT: Utilities related to scientific notation

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::ScientificNotation::Util - Utilities related to scientific notation

=head1 VERSION

This document describes version 0.003 of Math::ScientificNotation::Util (from Perl distribution Math-ScientificNotation-Util), released on 2016-06-17.

=head1 SYNOPSIS

 use Math::ScientificNotation::Util qw(sci2dec);

 say sci2dec("1.2e-6"); # => 0.0000012

=head1 DESCRIPTION

=head1 FUNCTIONS

None exported by default, but they are exportable.

=head2 sci2dec($sci) => $dec

Convert scientific notation number to decimal number.

Note that if you are sure that your number is not too large or small, you can
just let Perl convert it for you:

 "1.2e-4"+0    # 0.00012
 1*"1.2e8"     # 120000000

but:

 "1.2e-5"+0    # => 1.2e-5
 1*"1.2e20"    # 1.2e+20

=head1 FAQ

=head2 Where is dec2sci?

To convert to scientific notation, you can use C<sprintf()> with the C<%e>,
C<%E>, C<%g>, or C<%G> format, for example:

 sprintf("%.2e", 1234)   # => 1.23e+03

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Math-ScientificNotation-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Math-ScientificNotation-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-ScientificNotation-Util>

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
