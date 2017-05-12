package Media::Info::Mediainfo;

our $DATE = '2016-06-09'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use Capture::Tiny qw(capture);
use IPC::System::Options 'system', -log=>1;
use Perinci::Sub::Util qw(err);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       get_media_info
               );

our %SPEC;

$SPEC{get_media_info} = {
    v => 1.1,
    summary => 'Return information on media file/URL, using the `mediainfo` program',
    args => {
        media => {
            summary => 'Media file',
            schema  => 'str*',
            pos     => 0,
            req     => 1,
        },
    },
    deps => {
        prog => 'mediainfo',
    },
};
sub get_media_info {
    require File::Which;
    no warnings 'numeric';

    my %args = @_;

    File::Which::which("mediainfo")
          or return err(412, "Can't find mediainfo in PATH");
    my $media = $args{media} or return err(400, "Please specify media");

    # make sure user can't sneak in cmdline options to ffmpeg
    $media = "./$media" if $media =~ /\A-/;

    my ($stdout, $stderr, $exit) = capture {
        local $ENV{LANG} = "C";
        system("mediainfo", "--Language=raw", $media);
    };

    return err(500, "Can't execute mediainfo successfully ($exit)") if $exit;

    my $info = {};
    my $cur_section;
    for my $line (split /^/, $stdout) {
        next unless $line =~ /\S/;
        chomp $line;
        unless ($line =~ /:/) {
            $cur_section = $line;
            next;
        }
        my ($key, $val) = $line =~ /(\S+.*?)\s*:\s*(\S.*)/ or next;
        #say "D:section=<$cur_section> key=<$key> val=<$val>";
        if ($cur_section eq 'General') {
            $info->{duration} = $1 * 3600 + $2 * 60 + $3 if $key eq 'DURATION' && $val =~ /(\d+):(\d+):(\d+\.\d+)/;
        } elsif ($cur_section eq 'Video') {
            $info->{video_format} = $val if $key eq 'Format';
            $info->{video_width}  = $val+0 if $key eq 'Width/String';
            $info->{video_height} = $val+0 if $key eq 'Height/String';
            $info->{video_aspect} = $1/$2 if $key eq 'DisplayAspectRatio/String' && $val =~ /(\d+):(\d+)/;
            $info->{video_fps} = $val+0 if $key eq 'FrameRate/String';
            # XXX video_bitrate
        } elsif ($cur_section =~ /^Audio/) {
            # XXX handle multiple audio streams
            $info->{audio_format} //= $val if $key eq 'Format';
            $info->{audio_rate} //= $1*1000 if $key eq 'SamplingRate/String' && $val =~ /(\d+(?:\.\d+)?) KHz/;
            # XXX audio_bitrate
        }
    }

    [200, "OK", $info, {"func.raw_output"=>$stdout}];
}

1;
# ABSTRACT: Return information on media file/URL, using the `mediainfo` program

__END__

=pod

=encoding UTF-8

=head1 NAME

Media::Info::Mediainfo - Return information on media file/URL, using the `mediainfo` program

=head1 VERSION

This document describes version 0.002 of Media::Info::Mediainfo (from Perl distribution Media-Info-Mediainfo), released on 2016-06-09.

=head1 SYNOPSIS

Use directly:

 use Media::Info::Mediainfo qw(get_media_info);
 my $res = get_media_info(media => '/home/steven/celine.avi');

or use via L<Media::Info>.

Sample result:

 [
   200,
   "OK",
   {
     audio_bitrate => 128000,
     audio_format  => "aac",
     audio_rate    => 44100,
     duration      => 2081.25,
   },
   {
     "func.raw_output" => "General\nComplete name   ...",
   },
 ]

=head1 FUNCTIONS


=head2 get_media_info(%args) -> [status, msg, result, meta]

Return information on media file/URL, using the `mediainfo` program.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<media>* => I<str>

Media file.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Media-Info-Mediainfo>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Media-Info-Mediainfo>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Media-Info-Mediainfo>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Media::Info>

L<mediainfo> program (including CLI, GUI, and shared library),
L<http://mediaarea.net/en/MediaInfo>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
