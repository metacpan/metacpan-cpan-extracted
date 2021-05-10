package Filename::Media;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-20'; # DATE
our $DIST = 'Filename-Media'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(check_media_filename);

our $STR_RE = "movie|mpega|aifc|aiff|djvu|flac|jpeg|jpg2|midi|mpeg|mpga|opus|svgz|tiff|wbmp|webm|3gp|aif|amr|art|asf|asx|avi|awb|axa|axv|bmp|cdr|cdt|cpt|cr2|crw|csd|dif|djv|erf|fli|flv|gif|gsm|ico|ief|jng|jp2|jpe|jpf|jpg|jpm|jpx|kar|lsf|lsx|m3u|m4a|mid|mkv|mng|mov|mp2|mp3|mp4|mpe|mpg|mpv|mxu|nef|oga|ogg|ogv|orc|orf|pat|pbm|pcx|pgm|pls|png|pnm|ppm|psd|ram|ras|rgb|sco|sd2|sid|snd|spx|svg|tif|wav|wax|wma|wmv|wmx|wvx|xbm|xpm|xwd|au|dl|dv|gl|qt|ra|rm|ts|wm"; # STR_RE
our $RE = qr(\.(?:$STR_RE)\z)i;

our %SPEC;

$SPEC{check_media_filename} = {
    v => 1.1,
    summary => 'Check whether filename indicates being a media (audio/video/image) file',
    description => <<'_',


_
    args => {
        filename => {
            schema => 'filename*',
            req => 1,
            pos => 0,
        },
        # XXX recurse?
        #ci => {
        #    summary => 'Whether to match case-insensitively',
        #    schema  => 'bool',
        #    default => 1,
        #},
    },
    result_naked => 1,
    result => {
        schema => ['any*', of=>['bool*', 'hash*']],
        description => <<'_',

Return false if no archive suffixes detected. Otherwise return a hash of
information.

_
    },
    examples => [
        {
            args => {filename => 'foo.txt'},
            naked_result => 0,
        },
        {
            args => {filename => 'foo.DOC'},
            naked_result => 0,
        },
        {
            args => {filename => 'foo.webm'},
            naked_result => {},
        },
        {
            args => {filename => 'foo.MP3'},
            naked_result => {},
        },
        {
            args => {filename => 'foo.Jpeg'},
            naked_result => {},
        },
    ],
};
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

This document describes version 0.003 of Filename::Media (from Perl distribution Filename-Media), released on 2020-10-20.

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

Usage:

 check_media_filename(%args) -> bool|hash

Check whether filename indicates being a media (audioE<sol>videoE<sol>image) file.

Examples:

=over

=item * Example #1:

 check_media_filename(filename => "foo.txt"); # -> 0

=item * Example #2:

 check_media_filename(filename => "foo.DOC"); # -> 0

=item * Example #3:

 check_media_filename(filename => "foo.webm"); # -> {}

=item * Example #4:

 check_media_filename(filename => "foo.MP3"); # -> {}

=item * Example #5:

 check_media_filename(filename => "foo.Jpeg"); # -> {}

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>


=back

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information.

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

L<Filename::Ebook>. Ebook currently is not included.

L<Filename::Audio>

L<Filename::Video>

L<Filename::Image>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
