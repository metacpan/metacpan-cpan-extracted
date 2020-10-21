package Filename::Audio;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-21'; # DATE
our $DIST = 'Filename-Audio'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(check_audio_filename);

# sorted by length then asciibetical
our $STR_RE = "mpega|aifc|aiff|flac|midi|mpga|opus|aif|amr|awb|axa|csd|gsm|kar|m3u|m4a|mid|mp2|mp3|oga|ogg|orc|pls|ram|sco|sd2|sid|snd|spx|wav|wax|wma|au|ra|rm"; # STR_RE
our $RE = qr(\.(?:$STR_RE)\z)i;

our %SPEC;

$SPEC{check_audio_filename} = {
    v => 1.1,
    summary => 'Check whether filename indicates being an audio file',
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

Filename::Audio - Check whether filename indicates being an audio file

=head1 VERSION

This document describes version 0.004 of Filename::Audio (from Perl distribution Filename-Audio), released on 2020-10-21.

=head1 SYNOPSIS

 use Filename::Audio qw(check_audio_filename);
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


=back

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Audio>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Audio>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Audio>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Filename::Video>

L<Filename::Image>

L<Filename::Ebook>

L<Filename::Media>

Other Filename::*

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
