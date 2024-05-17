package Graphics::ColorNamesCMYK::BannersCom;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'Graphics-ColorNamesCMYK-BannersCom'; # DIST
our $VERSION = '0.001'; # VERSION

our $NAMES_CMYK_TABLE = {
    'navy blue' => 0x64320041, # 100,50,0,65
    'dark blue' => 0x644b0000, # 100,75,0,0
    'light blue' => 0x46250d00, # 70,37,13,0
    'dark gray' => 0x0000004b, # 0,0,0,75
    'medium gray' => 0x0000003c, # 0,0,0,60
    'light gray' => 0x0000002d, # 0,0,0,45
    'dark green' => 0x64196419, # 100,25,100,25
    'green' => 0x4b006419, # 75,0,100,25
    'orange' => 0x0048bc00, # 0,70,700,0
    'red' => 0x00645a05, # 0,100,90,5
    'deep red' => 0x19646419, # 25,100,100,25
    'magenta' => 0x00640000, # 0,100,0,0
    'purple' => 0x55640000, # 85,100,0,0
    'violet' => 0x2a320000, # 42,50,0,0
    'pink' => 0x00320000, # 0,50,0,0
    'teal' => 0x64193219, # 100,25,50,25
    'brown' => 0x1d4e614b, # 29,78,97,75
    'white' => 0x00000000, # 0,0,0,0
};

1;
# ABSTRACT: Basic CMYK colors from banners.com

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::ColorNamesCMYK::BannersCom - Basic CMYK colors from banners.com

=head1 VERSION

This document describes version 0.001 of Graphics::ColorNamesCMYK::BannersCom (from Perl distribution Graphics-ColorNamesCMYK-BannersCom), released on 2024-05-06.

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Graphics-ColorNamesCMYK-BannersCom>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Graphics-ColorNamesCMYK-BannersCom>.

=head1 SEE ALSO

L<https://www.banners.com/resources/basic-cmyk-colors-for-printing-banners>

Other C<Graphics::ColorNamesCMYK::*> modules.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Graphics-ColorNamesCMYK-BannersCom>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
