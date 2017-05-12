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