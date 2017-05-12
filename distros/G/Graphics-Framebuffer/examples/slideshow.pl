#!/usr/bin/perl

# This shows a slide show on ALL available framebuffers

# The last item on the command line should be the path to the pictures
# other options are "file" for file handle mode, "error" for show
# errors, and 'auto' for autolevel.

use strict;
use threads;
use threads::shared;

use Graphics::Framebuffer;
use Time::HiRes qw(sleep time);
use List::Util qw(shuffle);

# use Data::Dumper::Simple;
my (@a,$path,$args);
if (scalar(@ARGV)) {
    @a    = @ARGV;
    $path = pop(@a);
    $args = join('', @a);
} else {
    $path = (-d "images/") ? 'images/' : 'examples/images/';
    $args = 'full';
}

my $errors = 0;
$errors = 1 if ($args =~ /errors/i);
my $auto = 0;
$auto = 1 if ($args =~ /auto/i);
my $fullscreen = 0;
$fullscreen = 1 if ($args =~ /full/i);

my @fbs;

# We show images on all devices
foreach my $p (qw(/dev/graphics/fb /dev/fb)) {
    foreach my $b (0 .. 31) {
        push(@fbs, "$p$b") if (-e "$p$b");
    }
}

my @thr;
my $RUNNING : shared = 1;
$SIG{'QUIT'} = sub {
    print STDERR "\nExiting..\n";
    $RUNNING = 0;
    sleep 1;
    exec('reset');
};
$SIG{'INT'} = sub {
    print STDERR "\nExiting..\n";
    $RUNNING = 0;
    sleep 1;
    exec('reset');
};

our @pics;

my @f;
foreach my $fb (@fbs) {
    push(
        @f,
        Graphics::Framebuffer->new(
            'FB_DEVICE'   => $fb,
            'SPLASH'      => 0,
            'SHOW_ERRORS' => $errors,
            'RESET'       => 0,
        )
    );
} ## end foreach my $fb (@fbs)

gather($path);

# print STDERR Dumper(\@pics);exit;

foreach my $F (@f) {
    push(
        @thr,
        threads->create(
            sub {
                local $SIG{'INT'}  = undef;
                local $SIG{'QUIT'} = undef;
                my $FB = shift;
                my $p  = shift;
                system('clear');
                $FB->cls('OFF');

                show($FB, $p);
                $FB->cls('ON');
            },
            $F,
            scalar(@pics)
        )
    );
} ## end foreach my $F (@f)
while ($RUNNING) {
    sleep 1;
}
# map { $_->cls('ON') } @f;

foreach my $t (@thr) {
    $t->detach();
}

exit(0);

sub gather {
    my $path = shift;
    chop($path) if ($path =~ /\/$/);
    opendir(my $DIR, $path);
    chomp(my @dir = readdir($DIR));
    closedir($DIR);
    return if (grep(/\.nopmedia/, @dir));
    foreach my $file (@dir) {
        next if ($file =~ /^\.+/);
        if (-d "$path/$file") {
            gather("$path/$file");
        } elsif (-f "$path/$file" && $file =~ /\.(jpg|jpeg|gif|tiff|bmp|png)$/i) {
            push(@pics, "$path/$file");
        }
    }
}

sub show {
    my $FB  = shift;
    my $p   = shift;
    my $idx = 0;
    @pics = shuffle(@pics);
    while ($RUNNING) {
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
        last unless ($RUNNING);
        if (defined($image)) {
            $FB->cls();
            if (ref($image) eq 'ARRAY') {
                my $s = time + 8;
                while (time <= $s) {
                    last unless ($RUNNING);
                    foreach my $frame (0 .. (scalar(@{$image}) - 1)) {
                        last unless ($RUNNING);
                        my $begin = time;
                        $FB->blit_write($image->[$frame]);
                        my $delay = ($image->[$frame]->{'tags'}->{'gif_delay'} / 100) - (time - $begin);
                        sleep $delay if ($delay > 0);
                    } ## end foreach my $frame (0 .. (scalar...))
                } ## end while (time <= $s)
            } else {
                $FB->cls();
                $FB->blit_write($image);
                sleep 3;
            }
        } ## end if (defined($image))
        $idx++;
        $idx = 0 if ($idx >= $p);
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
                'y'            => 20,
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

Multi-threaded, multi-framebuffer Slide Show

This automatically detects all of the framebuffer devices in your system, and shows the images in the images path, in a random order, on all devices.

=head1 SYNOPSIS

 perl slideshow [file] [auto] [full] [errors] "path to images"

=head2 OPTIONS

=over 2

=item C<auto>

Turns on auto color level mode.  Sometimes this yields great results... and sometimes it totally ugly's things up

=item C<errors>

Allows the module to print errors to STDERR

=item C<file>

Makes the module render in file handle mode instead of memory mapped string mode.

=item C<full>

Scales all images (and animations) to full screen (proportionally).

=back

=cut
