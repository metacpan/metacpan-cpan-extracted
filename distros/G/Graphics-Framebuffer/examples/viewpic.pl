#!/usr/bin/perl

# A simple utility to view a picture from the command line
#
# The first option should be the file name to show

use strict;

use Graphics::Framebuffer;
use Time::HiRes qw(sleep time);

# use Data::Dumper::Simple;$Data::Dumper::Sortkeys=1;

my @a    = @ARGV;
my $file = pop(@a);

my $args = join('', @a);
my $full = 0;
$full = 1 if ($args =~ /full/i);

my $dev = 0;
if ($args =~ /(\d+)/) {
    ($dev) = $1;
}

my $f = Graphics::Framebuffer->new(
    'FB_DEVICE'   => "/dev/fb$dev",
    'SPLASH'      => 0,
    'SHOW_ERRORS' => 1,
);

system('clear');
$f->cls('OFF');

# This centers and shows the picture by proportionally scaling the height and width
my %p = (
    'file'   => $ARGV[-1],
    'center' => CENTER_XY
);
if ($full) {
    $p{'width'}  = $f->{'XRES'};
    $p{'height'} = $f->{'YRES'};
}

# $p{'noscale'} = 1 if ($ARGV[0] =~ /\.gif$/i);
my $image = $f->load_image(\%p);

# warn ref($image),"\n\n",Dumper($image->[0]->{'tags'}),"\n\n";exit;
if (ref($image) eq 'ARRAY') {
    while (1) {
        foreach my $frame (0 .. (scalar(@{$image}) - 1)) {
            my $begin = time;
            $f->blit_write($image->[$frame]);
            print STDERR sprintf('FRAME: %04d', $frame), "\r";
            my $delay = (($image->[$frame]->{'tags'}->{'gif_delay'} * .01)) - (time - $begin);
            if ($delay > 0) {
                sleep $delay;
            }
        } ## end foreach my $frame (0 .. (scalar...))
    } ## end while (1)
} else {
    $f->blit_write($image);
}
sleep 3;
$f->cls('ON');

=head1 NAME

Picture View

=head1 DESCRIPTION

Single image (or animation) viewer

=head1 SYNOPISIS

 perl viewpic.pl [file] [device number] [full] "path to image"

=head1 OPTIONS

Like the name implies, these are all optional, and can be entered in any order, EXCEPT for the file path.

=over 2

=item C<device Number> (just the number)

A number from 0 - 31 indicating which framebuffer device to render to

=item C<file>

Tells it to render in file handle mode instead of memory mapped string mode.

=item C<full>

Tells it to scale (proportionally) all images (and animations) to full screen.

=back

=cut
