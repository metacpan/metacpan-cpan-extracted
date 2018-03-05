package Float::Util;

our $DATE = '2018-03-04'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Config;

use Exporter qw(import);
our @EXPORT_OK = qw(is_exact);

my $numsigfdigs = ($Config{usequadmath} ? 36 : 17)+1;
my $fmt = "%.${numsigfdigs}f";

sub is_exact {
    my $strdec = shift;

    $strdec =~ /\A-?[0-9]+(?:\.[0-9]+)?\z/
        or die "Invalid input '$strdec', please supply a decimal number string";

    my $fmtnum = sprintf $fmt, $strdec;
    for ($strdec, $fmtnum) { s/\.?0+\z// }
    #say "D: strdec=<$strdec>, fmtnum=<$fmtnum>";
    $strdec eq $fmtnum;
}

1;
# ABSTRACT: Utilities related to floating point numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Float::Util - Utilities related to floating point numbers

=head1 VERSION

This document describes version 0.001 of Float::Util (from Perl distribution Float-Util), released on 2018-03-04.

=head1 SYNOPSIS

 use Float::Util qw(is_exact);

 is_exact("1.5"); # => true
 is_exact("0.1"); # => false

=head1 DESCRIPTION

=head1 FUNCTIONS

None exported by default, but they are exportable.

=head2 is_exact

Usage: is_exact($strdec) => bool

Test that a decimal number (a string) can be represented exactly as a floating
point number.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Float-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Float-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Float-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
