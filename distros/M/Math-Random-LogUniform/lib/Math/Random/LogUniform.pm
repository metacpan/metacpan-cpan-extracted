package Math::Random::LogUniform;

use strict;
use warnings;

use Exporter qw(import);
use POSIX qw(floor);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-28'; # DATE
our $DIST = 'Math-Random-LogUniform'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(logrand);

sub logrand {
    my ($min, $max) = @_;

    exp(log($min) + rand()*(log($max) - log($min)));
}

sub logirand {
    my ($min, $max) = @_;

    floor(exp(log($min) + rand()*(log($max) - log($min))));
}

1;
# ABSTRACT: Generate log-uniform random numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::Random::LogUniform - Generate log-uniform random numbers

=head1 VERSION

This document describes version 0.001 of Math::Random::LogUniform (from Perl distribution Math-Random-LogUniform), released on 2023-12-28.

=head1 SYNOPSIS

 use Math::Random::LogUniform qw(logrand logirand);

 say logrand (1, 10); # generate floating number random numbers [1, 10)
 say logirand(1, 10); # generate integer         random numbers [1, 10) (1 to 9)

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 logrand

=head2 logirand

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Math-Random-LogUniform>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Math-Random-LogUniform>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-Random-LogUniform>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
