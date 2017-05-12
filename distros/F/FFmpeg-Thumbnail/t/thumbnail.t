#!perl

use strict;
use warnings;
use Test::More tests=>25;

use_ok( 'FFmpeg::Thumbnail' );
use Imager;
use Image::ExifTool;

my $video_name = '/tmp/test_video.flv';
my $why = "Unable to find test video: '$video_name'";

SKIP: {
    skip $why, 23 unless ( -e $video_name );

    my $video = FFmpeg::Thumbnail->new ( {
        'video'     => $video_name
    });

    my $filename = '/tmp/my_thumb.png';
    my $offset = 5;
    my $fh;
    my $imager;
    my $exiftool = new Image::ExifTool;
    my $exif;

    # Create a thumbnail.
    $video->create_thumbnail( $offset, $filename );

    open $fh, "<$filename";
    ok( $fh, 'Specified output file created')
        or diag "Unable to open specified output file.";
    close $fh;

    $imager = Imager->new( file => $filename );
    ok( $imager, "Specified output file is an image.")
        or diag "Unable to open specified output file with Imager: ".$imager->errstr();

    $exif = $exiftool->ImageInfo( $filename );
    is( $exif->{MIMEType}, 'image/png', "Output image is the correct format.")
        or diag "Output image MIME type does not match expected type of 'image/png'.";

    unlink( $filename );


    # Create a thumbnail without specifying filename.
    $filename = '/tmp/thumbnail.png';
    $video->create_thumbnail( $offset );

    open $fh, "<$filename";
    ok( $fh, 'Output file created with default filename')
        or diag "Unable to open output file.";
    close $fh;

    $imager = Imager->new( file => $filename );
    ok( $imager, "Default output file is an image.")
        or diag "Unable to open default output file with Imager: ".$imager->errstr();

    unlink( $filename );


    # Create a thumbnail without specifiying an offset or a filename
    $filename = '/tmp/thumbnail.png';
    $video->create_thumbnail( );

    open $fh, "<$filename";
    ok( $fh, 'Output file created with default filename')
        or diag "Unable to open output file.";
    close $fh;

    $imager = Imager->new( file => $filename );
    ok( $imager, "Default output file is an image.")
        or diag "Unable to open default output file with Imager: ".$imager->errstr();

    unlink( $filename );


    # Specify output dimensions.
    my $width = 640;
    my $height = 480;
    $filename = '/tmp/'.$width.'_'.$height.'_thumb.png';

    $video->output_width( $width );
    $video->output_height( $height );
    $video->create_thumbnail( $offset, $filename );

    open $fh, "<$filename";
    ok( $fh, 'Sized output file created')
        or diag "Unable to open sized output file.";
    close $fh;

    $imager = Imager->new( file => $filename );
    ok( $imager, "Sized output file is an image.")
        or diag "Unable to open sized output file with Imager: ".$imager->errstr();

    is( $imager->getwidth(), $width, "Sized output file is the correct width.");
    is( $imager->getheight(), $height, "Sized output file is the correct height.");

    unlink( $filename );


    # Specify thumbnail format.
    $filename = '/tmp/format_thumbnail.jpg';
    $video->file_format('mjpeg');

    $video->create_thumbnail( $offset, $filename );

    open $fh, "<$filename";
    ok( $fh, 'Specified output file created')
        or diag "Unable to open specified output file.";
    close $fh;

    $imager = Imager->new( file => $filename );
    ok( $imager, "Specified output file is an image.")
        or diag "Unable to open specified output file with Imager: ".$imager->errstr();

    $exif = $exiftool->ImageInfo( $filename );
    is( $exif->{MIMEType}, 'image/jpeg', "Output image is the correct format.")
        or diag "Output image MIME type does not match expected type of 'image/jpeg'.";

    unlink( $filename );


    # Check hot-swapping video
    $video_name = '/tmp/test_video_2.flv'; #5
    SKIP: {
        skip $why, 5 unless ( -e $video_name );

        $video->video( $video_name );
        $filename = '/tmp/my_second_thumb.jpg';

        $video->create_thumbnail( $offset, $filename );

        open $fh, "<$filename";
        ok( $fh, 'Create thumbnail after source video changes.')
            or diag "Unable to open specified output file after source video changed.";
        close $fh;

        $imager = Imager->new( file => $filename );
        ok( $imager, "Output file is still an image after source video changed.")
            or diag "Unable to open output file with Imager after changing source video: ".$imager->errstr();

        is( $imager->getwidth(), $width, "Width persists when source video changes.");
        is( $imager->getheight(), $height, "Height persists when source video changes.");

        $exif = $exiftool->ImageInfo( $filename );
        is( $exif->{MIMEType}, 'image/jpeg', "Image format persists when source video changes")
            or diag "Output image MIME type does not match expected type of 'image/jpeg' afte changing source video.";

        unlink( $filename );
    };

    # Validate $offset
    # This test will fail unless the test-video length is >= 2 seconds.
    my $num = 2;
    ok( $video->_validate_offset( $num ), '_validate_offset passes a integer.' );

    # This test will fail unless the test-video length is >= 2.2 seconds.
    $num = 2.2;
    ok( $video->_validate_offset( $num ), '_validate_offset passes a float.' );

    $num = '1:03';
    isnt( $video->_validate_offset( $num ), 1, '_validate_offset rejects a "clock" string.' );

    $num = '/my/file/name';
    isnt( $video->_validate_offset( $num ), 1, '_validate_offset rejects a filepath/name.' );

    $num = $video->duration + 12345;
    isnt( $video->_validate_offset( $num ), 1, '_validate_offset rejects a number > video length.' );
};



done_testing;