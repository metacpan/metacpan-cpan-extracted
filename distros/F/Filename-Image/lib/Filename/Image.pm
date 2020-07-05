package Filename::Image;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-01'; # DATE
our $DIST = 'Filename-Image'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(check_image_filename);

our $STR_RE = "djvu|jpeg|jpg2|svgz|tiff|wbmp|art|bmp|cdr|cdt|cpt|cr2|crw|djv|erf|gif|ico|ief|jng|jp2|jpe|jpf|jpg|jpm|jpx|nef|orf|pat|pbm|pcx|pgm|png|pnm|ppm|psd|ras|rgb|svg|tif|xbm|xpm|xwd"; # STR_RE

our $RE = qr(\.(?:$STR_RE)\z)i;

sub check_image_filename {
    my %args = @_;

    $args{filename} =~ $RE ? {} : 0;
}

1;
# ABSTRACT: Check whether filename indicates being an image file

__END__

=pod

=encoding UTF-8

=head1 NAME

Filename::Image - Check whether filename indicates being an image file

=head1 VERSION

This document describes version 0.002 of Filename::Image (from Perl distribution Filename-Image), released on 2020-04-01.

=head1 SYNOPSIS

 use Filename::Image qw(check_image_filename);
 my $res = check_image_filename(filename => "foo.jpg");
 if ($res) {
     printf "File is image";
 } else {
     print "File is not image\n";
 }

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 check_image_filename

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Image>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Image>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Image>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Filename::Audio>

L<Filename::Video>

L<Filename::Media>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
