package Image::CCV::Examples;

###############################################################################
#
# Examples - Image::CCVW examples.
#
# A documentation only module showing the examples that are
# included in the Image::CCV distribution. This
# file was generated automatically via the gen_examples_pod.pl
# program that is also included in the examples directory.
#
# Copyright 2000-2010, John McNamara, jmcnamara@cpan.org
#
# Documentation after __END__
#

use strict;
use vars qw($VERSION);
$VERSION = '0.10';

1;

__END__

=pod

=head1 NAME

Examples - Image::CCV example programs.

=head1 DESCRIPTION

This is a documentation only module showing the examples that are
included in the L<Image::CCV> distribution.

This file was auto-generated via the C<gen_examples_pod.pl>
program that is also included in the examples directory.

=head1 Example programs

The following is a list of the 3 example programs that are included in the Image::CCV distribution.

=over

=item * L<Example: facecrop.pl> Extract faces from images

=item * L<Example: facetest.pl> Draw pretty boxes around detected face areas

=item * L<Example: sifttest.pl> Find commonalities between two images

=back

=head2 Example: facecrop.pl

    #!perl
    use strict;
    use warnings;
    use Getopt::Long;
    use Pod::Usage;
    use List::Util qw(max);
    use Imager;
    use Imager::Fill;
    use Image::CCV qw(detect_faces);
    
    use vars qw($VERSION);
    $VERSION = '0.10';
    
    =head1 NAME
    
    facecrop.pl - create crop from image using the largest face area
    
    =head1 SYNTAX
    
      facecrop.pl filename.png
    
      facecrop.pl filename.png -o thumb_filename.png
    
      facecrop.pl scene.png -o faces_%03d.png
    
    =head1 OPTIONS
    
    =over 4
    
    =item *
    
    C<--output-file> - output file name
    
    The output file name will be used as a template if more than one face
    is detected. Supply a sprintf() template (in other words: include a %s). 
    
    =item *
    
    C<--width> - maximum width of the output image
    
    =item *
    
    C<--height> - maximum height of the output image
    
    =item *
    
    C<--scale> - scale factor for the output area around the face
    
    Default is 1.5 which seems to usually capture the "whole face"
    around the detected area.
    
    =item *
    
    C<--largest> - only output the largest face found
    
    =item *
    
    C<--draw-box> - draw a box around the detection area
    
    =item *
    
    C<--verbose> - output more information during progress
    
    =back
    
    =cut
    
    pod2usage(1) unless @ARGV;
    GetOptions(
        'output-file|o:s'        => \my $out_file,
        'width|w:s'  => \my $max_width,
        'height|h:s' => \my $max_height,
        'scale|s:s'  => \my $scale,
        'largest'    => \my $only_largest,
        'draw-box'   => \my $draw_box,
        'verbose'    => \my $verbose,
    ) or pod2usage();
    
    $scale ||= 1.5; # default chosen by wild guess
    
    for my $scene (@ARGV) {
        my @coords = detect_faces( $scene );
        if(! @coords) {
            die "No face found\n";
        };
    
        if( $only_largest ) {
            # Now, find the largest face (area) in this image
            # We ignore the confidence value
            my $max = $coords[0];
            for (@coords) {
                if( $_->[2] * $_->[3] > $max->[2] * $max->[3] ) {
                    $max = $_
                }
            };
            @coords = ($max);
        };
        
        if( $verbose ) {
            print sprintf "%d Gesichter gefunden\n", 0+@coords;
        };
        
        my $index = 1;
        for my $face (@coords) {
            if( $out_file ) {
                my $out = Imager->new( file => $scene );            
                my ($x,$y,$width,$height,$confidence) = @$face;
                
                if( $draw_box ) {
                    my $color = Imager::Color->new( (1-$confidence/100) *255, $confidence/100 *255, 0 );
                    
                    # Draw a nice box
                    $out->box(
                        color => $color,
                        xmin => $x,
                        ymin => $y,
                        xmax => $x+$width,
                        ymax => $y+$height,
                        aa => 1,
                    );
                };
                
                # Scale the frame a bit up
                my $w = $face->[2] * $scale;
                my $h = $face->[3] * $scale;
                my $l = max( 0, $face->[0] - $face->[2]*(($scale -1) / 2));
                my $t = max( 0, $face->[1] - $face->[3]*(($scale -1) / 2) );
                
                $out = $out->crop( 
                           left => $l, top => $t,
                           width => $w, height => $h
                       );
                if( $max_width || $max_height ) {
                    $max_width  ||= $max_height;
                    $max_height ||= $max_width;
                    $out = $out->scale(
                        xpixels => $max_width,
                        ypixels => $max_height,
                        type => 'nonprop'
                    );
                };
                
                my $out_name = sprintf $out_file, $index++;
                $out->write( file => $out_name )
                    or die $out->errstr;
                print "$out_name\n";   
            } else {
                my ($x,$y,$width,$height,$confidence) = @$face;
                print "($x,$y): ${width}x$height @ $confidence\n";
            }
        }
    }


Download this example: L<http://cpansearch.perl.org/src/CORION/Image-CCV-0.10/examples/facecrop.pl>

=head2 Example: facetest.pl

    #!perl
    use strict;
    use warnings;
    use Getopt::Long;
    use Pod::Usage;
    use Imager;
    use Imager::Fill;
    use Image::CCV qw(detect_faces);
    
    use vars qw($VERSION);
    $VERSION = '0.10';
    
    =head1 NAME
    
    facetest.pl - simple face detection
    
    =head1 SYNTAX
    
      facetest.pl filename.png
    
    =cut
    
    GetOptions(
        'd|draw:s' => \my $draw_file,
    ) or pod2usage();
    
    for my $scene (@ARGV) {
        my @coords = detect_faces( $scene );
    
        if( $draw_file ) {
            my $out = Imager->new( file => $scene );
    
            for (@coords) {
                my ($x,$y,$width,$height,$confidence) = @$_;
                my $color = Imager::Color->new( (1-$confidence/100) *255, $confidence/100 *255, 0 );
                
                # Draw a nice box
                $out->box(
                    color => $color,
                    xmin => $x,
                    ymin => $y,
                    xmax => $x+$width,
                    ymax => $y+$height,
                    aa => 1,
                );
            };
    
            $out->write( file => $draw_file )
                or die $out->errstr;
        } else {
            for (@coords) {
                my ($x,$y,$width,$height,$confidence) = @$_;
                print "($x,$y): ${width}x$height @ $confidence\n";
            };
        }
    }

Download this example: L<http://cpansearch.perl.org/src/CORION/Image-CCV-0.10/examples/facetest.pl>

=head2 Example: sifttest.pl

paste the two input images side by side
$out->rubthrough(
    #!perl
    use strict;
    use warnings;
    use Getopt::Long;
    use Pod::Usage;
    use Imager;
    use Imager::Fill;
    use List::Util qw(max);
    use Image::CCV qw(sift);
    
    use vars qw($VERSION);
    $VERSION = '0.10';
    
    =pod
    
    Command-line options are:
    
    =over 2
    
    =item *
    
    C<--scene> - image of a scene to use
    
    =item *
    
    C<--object> - image of an object to use
    
    =item *
    
    C<--object> - filename of output file, defaults to out.png
    
    =cut
    
    pod2usage(1) unless @ARGV;
    GetOptions(
        'scene|s:s'   => \my $scene,
        'object|t:s'  => \my $object, # t=thing
        'output|o:s'  => \my $output,
    ) or pod2usage();
    
    die "scene image-file: $scene not found!" unless -f $scene;
    die "object image-file: $object not found!" unless -f $object;
    
    $output ||= 'out.png';
    print "output file: $output \n";
    
    my @coords = sift( $object, $scene, );
    print "@$_\n" for @coords;
    
    my $scene_image = Imager->new( file => $scene );
    my $object_image = Imager->new( file => $object );
    
    my $xsize = $scene_image->getwidth + $object_image->getwidth;
    my $ysize = max( $scene_image->getheight, $object_image->getheight);
    
    my $out = Imager->new(
        xsize => $xsize,
        ysize => $ysize,
    );
    
    # paste the two input images side by side
    $out->rubthrough(
        src => $scene_image,
        tx => 0, ty => 0,
        src_minx => 0,
        src_maxx => $scene_image->getwidth-1,
        src_miny => 0,
        src_maxy => $scene_image->getheight-1,
    );
    
    my $obj_ofs_x = $scene_image->getwidth;
    my $obj_ofs_y = 0;
    
    $out->rubthrough(
        src => $object_image,
        tx => $obj_ofs_x, ty => $obj_ofs_y,
        src_minx => 0,
        src_maxx => $object_image->getwidth-1,
        src_miny => 0,
        src_maxy => $object_image->getheight-1,
    );
    
    my @points = @coords;
    
    my $green = Imager::Color->new( 0, 255, 0 );
    for (@points) {
        $out->line(
            color => $green,
            x1 => $_->[0]+$obj_ofs_x,
            y1 => $_->[1]+$obj_ofs_y,
            x2 => $_->[2],
            y2 => $_->[3],
        );
    };
    
    $out->write( file => $output )
        or die $out->errstr;


Download this example: L<http://cpansearch.perl.org/src/CORION/Image-CCV-0.10/examples/sifttest.pl>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

Contributed examples contain the original author's name.

=head1 COPYRIGHT

Copyright 2012 by Max Maischein C<corion@cpan.org>.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.

=cut
