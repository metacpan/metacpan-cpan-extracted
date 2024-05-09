package Graphics::ColorNamesLite;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'Graphics-ColorNamesLite'; # DIST
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: Define RGB values for common color names (lite version)

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::ColorNamesLite - Define RGB values for common color names (lite version)

=head1 VERSION

This document describes version 0.002 of Graphics::ColorNamesLite (from Perl distribution Graphics-ColorNamesLite), released on 2024-05-06.

=head1 DESCRIPTION

B<Graphics::ColorNamesLite> is a light version of L<Graphics::ColorNames>.
Modules under C<Graphics::ColorNamesLite::*> are only required to provide a
package variable called C<$NAMES_RGB_TABLE> which must contain a hashref mapping
of color names and RGB values. RGB value is an integer (e.g. C<0x80ffff>) and
not a hexdigit string (e.g. C<"80ffff">).

Another package variable is optional: C<$NAMES_SUMMARIES_TABLE>. It must contain
a hashref mapping of color names to a short description string, e.g. "a darker
red used for blah".

No inheritance, no functional or OO interface is provided.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Graphics-ColorNamesLite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Graphics-ColorNamesLite>.

=head1 SEE ALSO

L<Graphics::ColorNames>

L<Graphics::ColorNamesCMYK>

L<Bencher::ScenarioBundle::Graphics::ColorNames>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Graphics-ColorNamesLite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
