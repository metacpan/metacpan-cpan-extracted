package Graphics::ColorNames::HTML_ID;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-07'; # DATE
our $DIST = 'Graphics-ColorNames-HTML_ID'; # DIST
our $VERSION = '3.3.1.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub NamesRgbTable() {
    use integer;
    return {
        'hitam'   => 0x000000,
        'biru'    => 0x0000ff,
        'akua'    => 0x00ffff,
        # alt: sian?
        'aqua'    => 0x00ffff, # orig spelling
        'kapur'   => 0x00ff00, # google translate
        'fuchsia' => 0xff00ff,
        'merah'   => 0xff0000,
        'kuning'  => 0xffff00,
        'putih'   => 0xffffff,
        'birutua' => 0x000080, # google translate
        'teal'    => 0x008080, # id.wikipedia
        'hijau'   => 0x008000,
        'ungu'    => 0x800080,
        'merahmarun' => 0x800000, # id.wikipedia, google translate
        'zaitun'  => 0x808000, # google translate
        'abu'     => 0x808080,
        'perak'   => 0xc0c0c0,
    };
}

1;
# ABSTRACT: HTML color names and equivalent RGB values (Indonesian translation)

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::ColorNames::HTML_ID - HTML color names and equivalent RGB values (Indonesian translation)

=head1 VERSION

This document describes version 3.3.1.001 of Graphics::ColorNames::HTML_ID (from Perl distribution Graphics-ColorNames-HTML_ID), released on 2020-06-07.

=head1 SYNOPSIS

  require Graphics::ColorNames::HTML_ID;

  $NameTable = Graphics::ColorNames::HTML->NamesRgbTable();
  $RgbBlack  = $NameTable->{hitam};

=head1 DESCRIPTION

This is an Indonesian translation for L<Graphics::ColorNames::HTML>.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Graphics-ColorNames-HTML_ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Graphics-ColorNames-HTML_ID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Graphics-ColorNames-HTML_ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Graphics::ColorNames::HTML>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
