package Filename::Type::Audio;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(check_audio_filename);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-20'; # DATE
our $DIST = 'Filename-Type-Audio'; # DIST
our $VERSION = '0.005'; # VERSION

# sorted by length then asciibetical
our $STR_RE = "mpega|aifc|aiff|flac|midi|mpga|opus|aif|amr|awb|axa|csd|gsm|kar|m3u|m4a|mid|mp2|mp3|oga|ogg|orc|pls|ram|sco|sd2|sid|snd|spx|wav|wax|wma|au|ra|rm"; # STR_RE
our $RE = qr(\.(?:$STR_RE)\z)i;

our %SPEC;

$SPEC{check_audio_filename} = {
    v => 1.1,
    summary => 'Check whether filename indicates being an audio file',
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
            args => {filename => 'foo.mp4'},
            naked_result => 0,
        },
        {
            args => {filename => 'foo.wav'},
            naked_result => {},
        },
        {
            args => {filename => 'foo.MP3'},
            naked_result => {},
        },
    ],
};
sub check_audio_filename {
    my %args = @_;

    $args{filename} =~ $RE ? {} : 0;
}

1;
# ABSTRACT: Check whether filename indicates being an audio file

__END__

=pod

=encoding UTF-8

=head1 NAME

Filename::Type::Audio - Check whether filename indicates being an audio file

=head1 VERSION

This document describes version 0.005 of Filename::Type::Audio (from Perl distribution Filename-Type-Audio), released on 2024-12-20.

=head1 SYNOPSIS

 use Filename::Type::Audio qw(check_audio_filename);
 my $res = check_audio_filename(filename => "foo.mp3");
 if ($res) {
     printf "File is audio";
 } else {
     print "File is not audio\n";
 }

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 check_audio_filename

Usage:

 check_audio_filename(%args) -> bool|hash

Check whether filename indicates being an audio file.

Examples:

=over

=item * Example #1:

 check_audio_filename(filename => "foo.txt"); # -> 0

=item * Example #2:

 check_audio_filename(filename => "foo.mp4"); # -> 0

=item * Example #3:

 check_audio_filename(filename => "foo.wav"); # -> {}

=item * Example #4:

 check_audio_filename(filename => "foo.MP3"); # -> {}

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

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Type-Audio>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Type-Audio>.

=head1 SEE ALSO

L<Filename::Type::Video>

L<Filename::Type::Image>

L<Filename::Type::Ebook>

L<Filename::Type::Media>

Other Filename::Type::*

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Type-Audio>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
