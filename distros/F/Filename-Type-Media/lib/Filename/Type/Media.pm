package Filename::Type::Media;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-21'; # DATE
our $DIST = 'Filename-Type-Media'; # DIST
our $VERSION = '0.004'; # VERSION

our @EXPORT_OK = qw(check_media_filename);

our $STR_RE = "movie|mpega|aifc|aiff|djvu|flac|jpeg|jpg2|midi|mpeg|mpga|opus|svgz|tiff|wbmp|webm|3gp|aif|amr|art|asf|asx|avi|awb|axa|axv|bmp|cdr|cdt|cpt|cr2|crw|csd|dif|djv|erf|fli|flv|gif|gsm|ico|ief|jng|jp2|jpe|jpf|jpg|jpm|jpx|kar|lsf|lsx|m3u|m4a|mid|mkv|mng|mov|mp2|mp3|mp4|mpe|mpg|mpv|mxu|nef|oga|ogg|ogv|orc|orf|pat|pbm|pcx|pgm|pls|png|pnm|ppm|psd|ram|ras|rgb|sco|sd2|sid|snd|spx|svg|tif|wav|wax|wma|wmv|wmx|wvx|xbm|xpm|xwd|au|dl|dv|gl|qt|ra|rm|ts|wm"; # STR_RE
our $RE = qr(\.(?:$STR_RE)\z)i;

our %SPEC;

$SPEC{check_media_filename} = {
    v => 1.1,
    summary => 'Check whether filename indicates being a media (audio/video/image) file',
    description => <<'MARKDOWN',


MARKDOWN
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
        description => <<'MARKDOWN',

Return false if no archive suffixes detected. Otherwise return a hash of
information.

MARKDOWN
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

Filename::Type::Media - Check whether filename indicates being a media (audio/video/image) file

=head1 VERSION

This document describes version 0.004 of Filename::Type::Media (from Perl distribution Filename-Type-Media), released on 2024-12-21.

=head1 SYNOPSIS

 use Filename::Type::Media qw(check_media_filename);
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

(No description)


=back

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Type-Media>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Type-Media>.

=head1 SEE ALSO

L<Filename::Type::Ebook>. Ebook currently is not included. If you want finer
control of what types constitute a "media", you can use the individual
C<Filename::Type::*> modules.

L<Filename::Type::Audio>

L<Filename::Type::Video>

L<Filename::Type::Image>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Type-Media>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
