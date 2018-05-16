#!/usr/bin/perl

use strict;

use Graphics::Framebuffer;
use Time::HiRes qw(sleep time);
use List::Util qw(shuffle);
use Getopt::Long;
use Pod::Usage;

# use Data::Dumper::Simple;

my $path;
my $errors     = 0;
my $auto       = 0;
my $fullscreen = 0;
my $showall    = 0;
my $help       = 0;
my $delay      = 3;
my $nosplash   = 0;

GetOptions(
    'auto'        => \$auto,
    'errors'      => \$errors,
    'full'        => \$fullscreen,
    'showall|all' => \$showall,
    'help'        => \$help,
    'delay=i'     => \$delay,
    'nosplash'    => \$nosplash,
);

if (scalar(@ARGV) && ! $help) {
    $path = $ARGV[-1];
} else {
    $help = 2;
}

if ($help) {
    pod2usage('-exitstatus' => 0,'-verbose' => $help);
}

my $splash = ($nosplash) ? 0 : 2;

my $FB = Graphics::Framebuffer->new(
    'SHOW_ERRORS' => $errors,
    'RESET'       => 1,
    'SPLASH'      => $splash,
);

system('clear');
$FB->cls('OFF');

my $p = gather($FB,$path);

$FB->cls();


show($FB, $p);

exit(0);

sub gather {
    my $FB = shift;
    my $path = shift;
    my @pics;
    chop($path) if ($path =~ /\/$/);
    $FB->rbox({'x' => 0, 'y' => 0, 'width' => $FB->{'XRES'}, 'height' => 32, 'filled' => 1, 'gradient' => {'direction' => 'vertical', 'colors' => {'red' => [0,0], 'green' => [0,0], 'blue' => [64,128]}}});
    print_it($FB,"Scanning - $path");
    opendir(my $DIR, "$path") || die "Problem reading $path directory";
    chomp(my @dir = readdir($DIR));
    closedir($DIR);

    return if (! $showall && grep(/^\.nomedia$/, @dir));
    foreach my $file (@dir) {
        next if ($file =~ /^\.+/);
        if (-d "$path/$file") {
            my $r = gather($FB,"$path/$file");
            if (defined($r)) {
                @pics = (@pics,@{$r});
            }
        } elsif (-f "$path/$file" && $file =~ /\.(jpg|jpeg|gif|tiff|bmp|png)$/i) {
            push(@pics, "$path/$file");
        }
    }
    return(\@pics);
}

sub show {
    my $FB  = shift;
    my $ps  = shift;
    my @pics = shuffle(@{$ps});
    my $p = scalar(@pics);
    my $idx = 0;
    my $halfw = int($FB->{'XRES'} / 2);
    my $halfh = int($FB->{'YRES'} / 2);

    while ($idx < $p) {
        my $name = $pics[$idx];
        print_it($FB, "Loading image $name");
        my $image;
        unless ($fullscreen) {
            $image = $FB->load_image(
                {
                    'file'       => $name,
                    'center'     => CENTER_XY,
                    'autolevels' => $auto
                }
            );
        } else {
            $image = $FB->load_image(
                {
                    'width'      => $FB->{'XRES'},
                    'height'     => $FB->{'YRES'},
                    'file'       => $name,
                    'center'     => CENTER_XY,
                    'autolevels' => $auto
                }
            );
        } ## end else

        #        warn Dumper($image);exit;
        if (defined($image)) {
            $FB->cls();
            if (ref($image) eq 'ARRAY') {
                my $s = time + ($delay * 2);
                while (time <= $s) {
                    $FB->play_animation($image,1);
                } ## end while (time <= $s)
            } else {
                $FB->cls();
                if ($fullscreen) {
                    if ($image->{'width'} <= $halfw) {
                        $image->{'x'} = int(($halfw - $image->{'width'}) / 2);
                        $FB->blit_write($image);
                        $image->{'x'} += $halfw;
                        $FB->blit_write($image);
                    } elsif ($image->{'height'} <= $halfh) {
                        $image->{'y'} = int(($halfh - $image->{'height'}) / 2);
                        $FB->blit_write($image);
                        $image->{'y'} += $halfh;
                        $FB->blit_write($image);
                    } else {
                        $FB->blit_write($image);
                    }
                } else {
                    $FB->blit_write($image);
                }
                sleep $delay;
            }
        } ## end if (defined($image))
        $idx++;
#        $idx = 0 if ($idx >= $p);
    } ## end while ($RUNNING)
} ## end sub show

sub print_it {
    my $fb      = shift;
    my $message = shift;

    unless ($fb->{'XRES'} < 256) {
        $fb->xor_mode();

        my $b = $fb->ttf_print(
            {
                'x'            => 5,
                'y'            => 32,
                'height'       => 20,
                'color'        => 'FFFFFFFF',
                'text'         => $message,
                'bounding_box' => 1,
                'center'       => CENTER_X,
                'antialias'    => 1
            }
        );
        $fb->ttf_print($b);
    } else {
        print "$message\n";
    }
    $fb->normal_mode();
} ## end sub print_it

=head1 NAME

Slide Show

=head1 DESCRIPTION

Framebuffer Slide Show

This automatically detects all of the framebuffer devices in your system, and shows the images in the images path, in a random order, on the primary framebuffer device (the first it finds).

=head1 SYNOPSIS

 perl slideshow [options] "/path/to/scan"

=head2 OPTIONS

=over 2

=item B<--auto>

Turns on auto color level mode.  Sometimes this yields great results... and sometimes it totally ugly's things up

=item B<--errors>

Allows the module to print errors to STDERR

=item B<--full>

Scales all images (and animations) to full screen (proportionally).  Images are always scaled down, if they are too big for the screen, regardless of this option.

=item B<--delay>=seconds

Number of seconds to wait before loading the next image.  It can take longer to load animated GIFs.

Default is 3 seconds.

=item B<--showall>

Ignores any ".nomedia" files in subdirectories, and shows the images in them anyway.

=back

=cut
