#!/usr/bin/perl

# A simple utility to view a picture from the command line
#
# The first option should be the file name to show

use strict;

use Graphics::Framebuffer;
use Time::HiRes qw(sleep time);
use Getopt::Long;

# use Data::Dumper::Simple;$Data::Dumper::Sortkeys=1;

my $file = $ARGV[-1];

my $full = 0;

GetOptions(
    'full' => \$full,
);

my $f = Graphics::Framebuffer->new(
    'SPLASH'      => 0,
    'SHOW_ERRORS' => 0,
    'RESET'       => 1,
);

system('clear');
$f->cls('OFF');

# This centers and shows the picture by proportionally scaling the height and width
my %p = (
    'file'   => $file,
    'center' => CENTER_XY
);
if ($full) {
    $p{'width'}  = $f->{'XRES'};
    $p{'height'} = $f->{'YRES'};
}

my $image = $f->load_image(\%p);

if (ref($image) eq 'ARRAY') {
    my $s = time + 10;
    while (time < $s) {
        $f->play_animation($image,1);
    }
} else {
    $f->blit_write($image);
    sleep 10;
}

=head1 NAME

Picture View

=head1 DESCRIPTION

Single image (or animation) viewer

=head1 SYNOPISIS

 perl viewpic.pl [--full] "path to image"

=head1 OPTIONS

=over 2

=item C<--full>

Tells it to scale (proportionally) all images (and animations) to full screen.

=back

=cut
