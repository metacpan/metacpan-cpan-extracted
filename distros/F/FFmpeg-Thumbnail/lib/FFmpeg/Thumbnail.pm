package FFmpeg::Thumbnail;

use warnings;
use strict;
use Moose;

use FFmpeg::Command;
use Capture::Tiny qw/ capture / ;
use Regexp::Common;
use Scalar::Util qw/looks_like_number/;

=head1 NAME

FFmpeg::Thumbnail - Create a thumbnail from a video

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 DESCRIPTION

A wrapper for FFmpeg::Command specifically for creating video thumbnails.  Grabs a frame at
a specific point in the video and stores it as an image using ffmpeg ( L<http://ffmpeg.org> ).

Provides the ability to set specific output paramaters, such as file-type and file size, and use them
across multiple video files.


=head1 SYNOPSIS

    use FFmpeg::Thumbnail;

    # Create a thumbnail 20 seconds into the video.
    my $foo = FFmpeg::Thumbnail->new( { video => '/my/video/file.flv' } );
    my $offset = 20;
    my $output_filname = "/my/output/image.png";
    $foo->create_thumbnail( $offset, $output_filename );


    # Create five evenly-spaced jpeg's
    my $bar = FFmpeg::Thumbnail->new( { video => '/my/video/file.flv' } );
    $bar->file_format( 'mjpeg');
    my $filename( '/my/default/filename_' );
    my $num_thumbs = 5;
    for ( my $i=0; $i <= $bar->duration; $i+=$bar->duration / $num_thumbs ){
        $bar->create_thumbnail( $i, $filename.$i."_.jpeg" );
    }


    # Create 640x480 thumbnails at 21 seconds for two separate videos
    my $baz = FFmpeg::Thumbnail->new( { video => '/my/video/file.flv' } );
    $baz->output_width( 640 );
    $baz->output_height( 480 );
    $baz->offset( 21 );
    $baz->create_thumbnail( undef, '/my/first/thumbnail.png');

    $baz->video( '/my/video/second_file.flv' );
    $baz->create_thumbnail( undef, '/my/second/thumbnail.png');


=head1 ATTRIBUTES

=head2 video

Complete path and filename for the source video.  It can be changed after instantiantion if you wish
to use the same output settings for different videos.

=cut

has 'video' => (
    is => 'rw',
    isa => 'Str',
    trigger => sub { my $self = shift; $self->_reset; },
);

=head2 ffmpeg

FFmpeg::Command object with handles to all of the FFmepg::Command methods. Automatically set
when the 'video' attribute is set.  (Readonly)

=cut

has 'ffmpeg' => (
    is => 'ro',
    isa => 'FFmpeg::Command',
    lazy => 1,
    builder => '_build_ffmpeg',
    clearer => 'clear_ffmpeg',
    handles => {
        undef => 'input_options',
        undef => 'input_file',
        output_options => 'output_options',
        output_file => 'output_file',
        options =>  'options',
        stdout  => 'stdout',
        stderr  => 'stderr',
        execute => 'execute',
    },
);

=head2 duration

The length of the video, stored in seconds. It is automatically calculated and set from the 'ffmpeg'
attribue.
(Readonly)

=cut

has 'duration' => (
    is => 'ro',
    isa => 'Int',
    lazy => 1,
    predicate => 'has_ffmpeg',
    builder => '_build_duration',
    clearer => 'clear_duration',
);


=head2 filename

Output filename. The filename extension, here, has no bearing on the actual output format.
That is set by the 'file_format' attribute, so it is possible to create a thumbnail named "thumbnail.jpg"
that actually has an 'image/png' MIME type.  Defaults to "/tmp/thumbnail.png"

=cut

has 'filename' => (
    is => 'rw',
    isa => 'Str',
    default => '/tmp/thumbnail.png',
);

=head2 default_offset

The time in the video (in seconds) at which to grab the thumbnail

=cut

has 'offset' => (
    is => 'rw',
    isa => 'Num',
    default => 0,
);

=head2 file_format

Ffmpeg output file format, used by the '-f' argument. Defaults to 'image2' (png). 'mjpeg' (jpeg) is also known to work.

=cut
has 'file_format' => (
    is => 'rw',
    isa => 'Str',
    default => 'image2',
);

=head2 output_width

Width of the output thumnbail.  Default output image size is 320x240.

=cut

has 'output_width' => (
    is => 'rw',
    isa => 'Int',
    default => '320',
);

=head2 output_width

Height of the output thumbnail.  Default output image size is 320x240.

=cut

has 'output_height' => (
    is => 'rw',
    isa => 'Int',
    default => '240',
);

=head2 hide_log_output

Turns off ffmpeg's log output.  You can still access this through the stdout() and
stderr() handles.  Log output is suppressed by default ( ->hide_log_output == 1 ).

=cut

has 'hide_log_output' => (
    is => 'rw',
    isa => 'Int',
    default => 1,
);


=head1 METHODS

=head2 create_thumbnail

Creats a thumbnail image using a specified offset and specified filename, or, if not specified, defaults. Will overwrite if a file already exists with that filename.

Usage:

    # Create a thumbnail from $offset and store it at $output_filename:
    $foo->create_thumbnail( $offset, $output_filename );

    # Create a thumbnail from $offset and store it at the default location:
    $foo->create_thumbnail( $offset );

    # Create a thumbnail from the video's beginning and store it at $filename:
    $foo->create_thumbnail( undef, $output_filename);

    # Create a thumbnail from the video's beginning and store it at the default location:
    $foo->create_thumbnail();

=cut

sub create_thumbnail {
    my ( $self, $offset, $filename ) = @_;

    my $off_val = $self->_validate_offset( $offset ) ? $offset : $self->offset;

    $self->output_file( $filename || $self->filename );
    $self->options(
        '-y',                       # overwrite files
        '-f'       => $self->file_format,     # force format
        '-vframes' => 1,            # number of frames to record
        '-ss'      => $off_val,     # position
        '-s'       => $self->output_width.'x'.$self->output_height,    # sets frame size
        '-loglevel'=> 'quiet',      # tones down log output
    );
    return $self->hide_log_output ? capture { $self->ffmpeg->exec() } : $self->ffmpeg->exec() ;
}


=head2 _build_ffmpeg

Creats a new FFmpeg::Command object, sets $self->video as the input_options, and executes to populate
$self->ffmpeg->stderr with the input video's meta data.

=cut
sub _build_ffmpeg {
    my ( $self ) = @_;
    my $fmc = FFmpeg::Command->new() ;
    $fmc->input_file( $self->video );
    $fmc->execute();
    return $fmc;
}

=head2 _build_duration

Builder for the "duration" attribute.  Reads the length of the video from $self->ffmpeg->stderr
and converts it seconds.

/Duration:\s+(\d+):(\d+):(\d+)(?:\.\d+)?\s*,/

=cut

sub _build_duration {
    my ( $self ) = @_;;
    my ( $h, $m, $s ) = $self->stderr() =~ /Duration:\s+(\d+):(\d+):(\d+)(?:\.\d+)?\s*,/s;
    return $h * 3600 + $m * 60 + $s;
}

=head2 _reset

Clear the 'ffmpeg' and 'duration' attributes.

=cut
sub _reset {
    my ( $self ) = @_;
    $self->clear_ffmpeg;
    $self->clear_duration;
    return 1;
};

=head2 _validate_offset

Checks $offset to make sure that it is numeric and <= $self->duration.

=cut
sub _validate_offset {
    my ($self, $offset ) = @_;
    return $offset && looks_like_number( $offset ) and $offset <= $self->duration  ;
}


=head1 SEE ALSO

=over 4

=item Video::Framegrab

A frame-grabber / thumbnail-creator built around mplayer.

=back


=head1 AUTHOR

Brian Sauls, C<< <bbqsauls at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-video-thumbnail at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Video-Thumbnail>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FFmpeg::Thumbnail


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Video-Thumbnail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Video-Thumbnail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Video-Thumbnail>

=item * Search CPAN

L<http://search.cpan.org/dist/Video-Thumbnail/>

=back



=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brian Sauls, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

1; # End of FFmpeg::Thumbnail
