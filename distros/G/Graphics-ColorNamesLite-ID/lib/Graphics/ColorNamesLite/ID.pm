package Graphics::ColorNamesLite::ID;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-01'; # DATE
our $DIST = 'Graphics-ColorNamesLite-ID'; # DIST
our $VERSION = '0.002'; # VERSION

# note:
our $NAMES_RGB_TABLE = {
  abu        => 808080,
  akua       => "00ffff",
  aqua       => "00ffff",
  biru       => "0000ff",
  birutua    => "000080",
  fuchsia    => "ff00ff",
  hijau      => "008000",
  hitam      => "000000",
  kapur      => "00ff00",
  kuning     => "ffff00",
  merah      => "ff0000",
  merahmarun => 800000,
  perak      => "c0c0c0",
  putih      => "ffffff",
  teal       => "008080",
  ungu       => 800080,
  zaitun     => 808000,
}
;

our $NAMES_SUMMARIES_TABLE = {
  abu        => "from HTML_ID",
  akua       => "from HTML_ID",
  aqua       => "from HTML_ID",
  biru       => "from HTML_ID",
  birutua    => "from HTML_ID",
  fuchsia    => "from HTML_ID",
  hijau      => "from HTML_ID",
  hitam      => "from HTML_ID",
  kapur      => "from HTML_ID",
  kuning     => "from HTML_ID",
  merah      => "from HTML_ID",
  merahmarun => "from HTML_ID",
  perak      => "from HTML_ID",
  putih      => "from HTML_ID",
  teal       => "from HTML_ID",
  ungu       => "from HTML_ID",
  zaitun     => "from HTML_ID",
}
;

1;
# ABSTRACT: Indonesian color names and equivalent RGB values (lite version)

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::ColorNamesLite::ID - Indonesian color names and equivalent RGB values (lite version)

=head1 VERSION

This document describes version 0.002 of Graphics::ColorNamesLite::ID (from Perl distribution Graphics-ColorNamesLite-ID), released on 2023-12-01.

=head1 DESCRIPTION

This is a merge of various Indonesian Graphics::ColorNames::* modules.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Graphics-ColorNamesLite-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Graphics-ColorNamesLite-ID>.

=head1 SEE ALSO

C<Graphics::ColorNames::*>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Graphics-ColorNamesLite-ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
