package Getopt::Long::Any;

our $DATE = '2016-12-23'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

require Getopt::Long;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
                    GetOptions
               );

*Configure = \&Getopt::Long::Configure;

sub GetOptions {
    if (eval { require Getopt::Long::More; 1 }) {
        goto \&Getopt::Long::More::GetOptions;
    } elsif (eval { require Getopt::Long::Complete; 1 }) {
        goto \&Getopt::Long::Complete::GetOptions;
    } else {
        goto \&Getopt::Long::GetOptions;
    }
}

1;
# ABSTRACT: Use Getopt::Long::More, or Getopt::Long::Complete, or fallback to Getopt::Long

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Long::Any - Use Getopt::Long::More, or Getopt::Long::Complete, or fallback to Getopt::Long

=head1 VERSION

This document describes version 0.002 of Getopt::Long::Any (from Perl distribution Getopt-Long-Any), released on 2016-12-23.

=head1 SYNOPSIS

 use Getopt::Long::Any;

 # will first try to use Getopt::Long::More, if unsuccessful then will try
 # Getopt::Long::Complete, finally will fall back to Getopt::Long
 GetOptions(
     'opt1=s' => sub { ... },
     'opt2=i' => \$opt2,
 );

=head1 DESCRIPTION

B<This is an experiment module.>

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Getopt-Long-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Getopt-Long-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Getopt-Long-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Getopt::Long::More>

L<Getopt::Long::Complete>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
