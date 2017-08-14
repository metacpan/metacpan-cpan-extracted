package Filename::Media;

our $DATE = '2017-08-12'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(check_media_filename);

our $RE = qr(\.(?:movie|mpega|aifc|aiff|djvu|flac|jpeg|jpg2|midi|mpeg|mpga|opus|svgz|tiff|wbmp|webm|3gp|aif|amr|art|asf|asx|avi|awb|axa|axv|bmp|cdr|cdt|cpt|cr2|crw|csd|dif|djv|erf|fli|flv|gif|gsm|ico|ief|jng|jp2|jpe|jpf|jpg|jpm|jpx|kar|lsf|lsx|m3u|m4a|mid|mkv|mng|mov|mp2|mp3|mp4|mpe|mpg|mpv|mxu|nef|oga|ogg|ogv|orc|orf|pat|pbm|pcx|pgm|pls|png|pnm|ppm|psd|ram|ras|rgb|sco|sd2|sid|snd|spx|svg|tif|wav|wax|wma|wmv|wmx|wvx|xbm|xpm|xwd|au|dl|dv|gl|qt|ra|rm|ts|wm)\z)i; # RE

sub check_media_filename {
    my %args = @_;

    $args{filename} =~ $RE ? {} : 0;
}

1;
# ABSTRACT: Check whether filename indicates being a media (audio/video/image) file

__END__

=pod

=encoding UTF-8

=head1 NAME

Filename::Media - Check whether filename indicates being a media (audio/video/image) file

=head1 VERSION

This document describes version 0.001 of Filename::Media (from Perl distribution Filename-Media), released on 2017-08-12.

=head1 SYNOPSIS

 use Filename::Media qw(check_media_filename);
 my $res = check_media_filename(filename => "foo.mp3");
 if ($res) {
     printf "File is media";
 } else {
     print "File is not media\n";
 }

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 check_media_filename

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Media>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Media>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Media>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Filename::Audio>

L<Filename::Video>

L<Filename::Image>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
