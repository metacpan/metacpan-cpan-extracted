package Filename::Video;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-12'; # DATE
our $DIST = 'Filename-Video'; # DIST
our $VERSION = '0.006'; # VERSION

our @EXPORT_OK = qw(check_video_filename);

our $STR_RE = "movie|mpeg|webm|3gp|asf|asx|avi|axv|dif|fli|flv|lsf|lsx|mkv|mng|mov|mp4|mpe|mpg|mpv|mxu|ogv|wmv|wmx|wvx|dl|dv|gl|qt|ts|wm"; # STR_RE

our $RE = qr(\A(.+)\.($STR_RE)\z)i;

our %SPEC;

$SPEC{check_video_filename} = {
    v => 1.1,
    summary => 'Check whether filename indicates being a video file',
    description => <<'_',


_
    args => {
        filename => {
            schema => 'filename*',
            req => 1,
            pos => 0,
        },
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
            naked_result => {filename=>'foo.webm', filename_without_suffix=>"foo", suffix=>"webm"},
        },
        {
            args => {filename => 'foo.MP4'},
            naked_result => {filename=>'foo.MP4', filename_without_suffix=>"foo", suffix=>"MP4"},
        },
    ],
};
sub check_video_filename {
    my %args = @_;

    $args{filename} =~ $RE ? {filename=>"$1.$2", filename_without_suffix=>$1, suffix=>$2} : 0;
}

1;
# ABSTRACT: Check whether filename indicates being a video file

__END__

=pod

=encoding UTF-8

=head1 NAME

Filename::Video - Check whether filename indicates being a video file

=head1 VERSION

This document describes version 0.006 of Filename::Video (from Perl distribution Filename-Video), released on 2024-01-12.

=head1 SYNOPSIS

 use Filename::Video qw(check_video_filename);
 my $res = check_video_filename(filename => "foo.mp3");
 if ($res) {
     printf "File is video";
 } else {
     print "File is not video\n";
 }

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 check_video_filename

Usage:

 check_video_filename(%args) -> bool|hash

Check whether filename indicates being a video file.

Examples:

=over

=item * Example #1:

 check_video_filename(filename => "foo.txt"); # -> 0

=item * Example #2:

 check_video_filename(filename => "foo.DOC"); # -> 0

=item * Example #3:

 check_video_filename(filename => "foo.webm");

Result:

 {
   filename => "foo.webm",
   filename_without_suffix => "foo",
   suffix => "webm",
 }

=item * Example #4:

 check_video_filename(filename => "foo.MP4");

Result:

 {
   filename => "foo.MP4",
   filename_without_suffix => "foo",
   suffix => "MP4",
 }

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

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Video>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Video>.

=head1 SEE ALSO

L<Filename::Audio>

L<Filename::Image>

L<Filename::Ebook>

L<Filename::Media>

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

This software is copyright (c) 2024, 2020, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Video>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
