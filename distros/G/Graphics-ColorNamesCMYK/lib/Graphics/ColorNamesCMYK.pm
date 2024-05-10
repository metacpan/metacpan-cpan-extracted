package Graphics::ColorNamesCMYK;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'Graphics-ColorNamesCMYK'; # DIST
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: Define CMYK values for common color names

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::ColorNamesCMYK - Define CMYK values for common color names

=head1 VERSION

This document describes version 0.002 of Graphics::ColorNamesCMYK (from Perl distribution Graphics-ColorNamesCMYK), released on 2024-05-06.

=head1 DESCRIPTION

B<Graphics::ColorNamesCMYK> is the CMYK counterpart of
L<Graphics::ColorNamesLite> (and thus, L<Graphics::ColorNames>). Modules under
C<Graphics::ColorNamesLite::*> are only required to provide a package variable
called C<$NAMES_CMYK_TABLE> which must contain a hashref mapping of color names
and CMYK values. A CMYK value is a 4-byte integer (e.g. C<0x64000000> for pure
cyan) and not a hexdigit string (e.g. C<"64000000">). Each byte represent a
C/M/Y/K value from 0-100.

Another package variable is optional: C<$NAMES_SUMMARIES_TABLE>. It must contain
a hashref mapping of color names to a short description string, e.g. "A darker
red used for blah".

No inheritance, no functional or OO interface is provided.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Graphics-ColorNamesCMYK>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Graphics-ColorNamesCMYK>.

=head1 SEE ALSO

L<Graphics::ColorNamesLite>

L<Graphics::ColorNames>

L<Bencher::ScenarioBundle::Graphics::ColorNames>

C<Graphics::ColorNamesCMYK::*> modules

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Graphics-ColorNamesCMYK>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
