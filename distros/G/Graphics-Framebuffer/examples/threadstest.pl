#!/usr/bin/perl -w
# This tests the various methods of the Graphics::Framebuffer module
# and shows the only way threads will work with it.

use strict;

use threads;
use threads::shared;
use Graphics::Framebuffer;
use Sys::CPU;
use Term::ANSIScreen qw(:cursor :screen :color);

$| = 1;

my $file = 0;
my $hold : shared = 0;
my @waiting : shared;
my $RUNNING : shared = 1;
my @a = @ARGV;
my $arg = join('', @a);
my $Threads = $arg =~ /(\d+)/ ? $1 : Sys::CPU::cpu_count();

$SIG{'ALRM'} = sub { exec('reset'); };
$SIG{'QUIT'} = \&finish;
$SIG{'INT'}  = \&finish;

$file = 1 if ($arg =~ /file/i);    # File Handle mode

print "\nRunning on a ", Sys::CPU::cpu_type(), " with $Threads threads\n";
sleep 2;

my @framebuffer;
my $splash = 1;
my $two    = 1;
$two = 2 if (-e "/dev/fb0" && -e "/dev/fb1");
my $device = 0;
foreach my $thr (0 .. $Threads) {
    $framebuffer[$thr] = Graphics::Framebuffer->new('FILE_MODE' => $file, 'SPLASH' => $splash, 'FB_DEVICE' => sprintf('/dev/fb%d', $device), 'RESET' => 0);
    if ($two == 2) {
        $device++;
        $device = 0 if ($device == 2);
    }
    $splash = 0 if ($thr >= ($two - 1));
} ## end foreach my $thr (0 .. $Threads)
my ($screen_width, $screen_height) = $framebuffer[0]->screen_dimensions();

my $top = 16 * ($Threads + 1);    # Font height * # of threads
my ($mw, $mh) = $framebuffer[0]->screen_dimensions();
my $clw = $mw / ($Threads / $two);
my $clx : shared = 0;
foreach my $t (0 .. $Threads) {
    $framebuffer[$t]->cls();
}
cls;

my @thrd;
foreach my $page (1 .. $Threads) {
    $waiting[$page] = 0;
    $thrd[$page]    = threads->create(
        sub {
            local $SIG{'QUIT'} = undef;    # sub { return; };
            local $SIG{'INT'}  = undef;    # sub { return; };
            my $Page = shift;
            my $top  = shift;
            my ($screen_width, $screen_height) = $framebuffer[$Page]->screen_dimensions();
            if ($framebuffer[$Page]->{'FB_DEVICE'} eq '/dev/fb0') {
#                $framebuffer[$page]->clip_set({ 'x' => $clx, 'y' => $top, 'xx' => $clx + $clw, 'yy' => $screen_height });
                $framebuffer[$page]->clip_set({ 'x' => 0, 'y' => $top, 'xx' => $screen_width, 'yy' => $screen_height });
                {
                    lock($clx);
                    $clx += $clw;
                }

                #            } else {
                #                $framebuffer[$page]->clip_set({ 'x' => 0, 'y' => $top, 'xx' => $screen_width, 'yy' => $screen_height });
            } ## end if ($framebuffer[$Page...])
            if (defined($framebuffer[$Page]->{'ERROR'})) {
                print locate($Page, 1), clline, "ERROR: Thread $Page, $framebuffer[$Page]->{'ERROR'}";
            }
            while ($RUNNING) {
                attract($Page, $screen_width, $screen_height);
                while ($hold && $RUNNING) {
                    print locate($Page, 1), clline, colored(['white on_yellow'], "Thread $Page"), ' Waiting for other threads to finish drawing ...';
                    threads->yield();
                    $waiting[$Page] = 0;
                    sleep 1;
                    select(STDOUT);
                    $| = 1;
                } ## end while ($hold && $RUNNING)
                $waiting[$Page] = 1;
                select(STDOUT);
                $| = 1;
            } ## end while ($RUNNING)

            #            $framebuffer[$Page]->cls();
            print locate($Page, 1), clline, colored(['black on_green'], "Thread $Page"), ' Finished';
            select(STDOUT);
            $| = 1;
            return;
        },
        $page,
        $top
    );
} ## end foreach my $page (1 .. $Threads)
while (1) {
    $hold = 0;
    sleep 30;
    $hold = 1;
    foreach my $page (1 .. $Threads) {
        while ($waiting[$page] && $thrd[$page]->is_running()) {
            sleep 1;
        }
        $framebuffer[$page]->cls();
    } ## end foreach my $page (1 .. $Threads)

    #    foreach my $c (1 .. $Threads) {
    #        $framebuffer[$c]->cls();
    #    }
} ## end while (1)

##############################################################################
##                             ATTRACT MODE                                 ##
##############################################################################
# Remeniscent of the "Atract Mode" of the old Atari 8 bit computers, this    #
# mode merely puts random patterns on the screen.                            #
##############################################################################

sub attract {
    my $page          = shift;
    my $screen_width  = shift;
    my $screen_height = shift;
    my $red           = int(rand(256));
    my $grn           = int(rand(256));
    my $blu           = int(rand(256));
    my $x             = $framebuffer[$page]->{'X_CLIP'} + int(rand($framebuffer[$page]->{'W_CLIP'}));
    my $y             = int(rand($screen_height));
    my $w             = int(rand($framebuffer[$page]->{'W_CLIP'} / 3));
    my $h             = int(rand($screen_height / 3));
    my $rx            = int(rand($framebuffer[$page]->{'W_CLIP'}));
    my $ry            = int(rand($screen_height / 5));
    my $sd            = int(rand(360));
    my $ed            = int(rand(360));
    my $gr            = (rand(10) / 10);
    my $mode          = 0;                                                                              # int(rand(4));
    my $type          = int(rand(13));
    my $size          = 1;                                                                              # int(rand(6)) + 1;
    my $arc           = int(rand(3));
    my $filled        = int(rand(2));

    $framebuffer[$page]->set_color({ 'red' => $red, 'green' => $grn, 'blue' => $blu });
    $framebuffer[$page]->draw_mode($mode);

    if ($type == 0) {
        print locate($page, 1), clline, colored(['black on_green'], "Thread $page"), colored(['white on_blue'], $framebuffer[$page]->{'FB_DEVICE'}), sprintf(' Plotting point at %04d,%04d with pixel size %02d', $x, $y, $size);
        $framebuffer[$page]->plot({ 'x' => $x, 'y' => $y, 'pixel_size' => $size });
    } elsif ($type == 1) {
        print locate($page, 1), clline, colored(['black on_green'], "Thread $page"), colored(['white on_blue'], $framebuffer[$page]->{'FB_DEVICE'}), sprintf(' Drawing from %04d,%04d to %04d,%04d with pixel size %02d', $x, $y, $w, $h, $size);
        $framebuffer[$page]->plot({ 'x' => $x, 'y' => $y, 'pixel_size' => $size });
        $framebuffer[$page]->drawto({ 'x' => $w, 'y' => $h, 'pixel_size' => $size });
    } elsif ($type == 2) {
        print locate($page, 1), clline, colored(['black on_green'], "Thread $page"), colored(['white on_blue'], $framebuffer[$page]->{'FB_DEVICE'}), sprintf(' Drawing Circle at %04d,%04d with Radius %04d with pixel size %d, filled? %s', $x, $y, $rx, $size, ($filled) ? 'Yes' : 'No');
        $framebuffer[$page]->circle({ 'x' => $x, 'y' => $y, 'radius' => $rx, 'filled' => $filled, 'pixel_size' => $size });
    } elsif ($type == 3) {
        print locate($page, 1), clline, colored(['black on_green'], "Thread $page"), colored(['white on_blue'], $framebuffer[$page]->{'FB_DEVICE'}), sprintf(' Drawing Ellipse at %04d,%04d with Radii %04d,%04d with pixel size %d, filled? %s', $x, $y, $rx, $ry, $size, ($filled) ? 'Yes' : 'No');
        $framebuffer[$page]->ellipse({ 'x' => $x, 'y' => $y, 'xradius' => $rx, 'yradius' => $ry, 'filled' => $filled, 'factor' => 1, 'pixel_size' => $size });
    } elsif ($type == 4) {
        print locate($page, 1), clline, colored(['black on_green'], "Thread $page"), colored(['white on_blue'], $framebuffer[$page]->{'FB_DEVICE'}), sprintf(' Drawing Box at %04d,%04d and %04d,%04d with pixel size %d, filled? %s', $x, $y, $w, $h, $size, ($filled) ? 'Yes' : 'No');
        $framebuffer[$page]->rbox({ 'x' => $x, 'y' => $y, 'width' => $w, 'height' => $h, 'filled' => $filled, 'pixel_size' => $size });
    } elsif ($type == 5) {
        print locate($page, 1), clline, colored(['black on_green'], "Thread $page"), colored(['white on_blue'], $framebuffer[$page]->{'FB_DEVICE'}), sprintf(' Drawing Arc at %04d,%04d with Radius %04d, Start %03d, End %03d with pixel size %d, Type? %s', $x, $y, $ry, $sd, $ed, $size, arctype($arc));
        $framebuffer[$page]->draw_arc({ 'x' => $x, 'y' => $y, 'radius' => $ry, 'start_degrees' => $sd, 'end_degrees' => $ed, 'granularity' => $gr, 'mode' => $arc, 'pixel_size' => $size });
    } elsif ($type == 6) {
        print locate($page, 1), clline, colored(['black on_green'], "Thread $page"), colored(['white on_blue'], $framebuffer[$page]->{'FB_DEVICE'}), sprintf(' Drawing Gradiant Box at %04d,%04d and %04d,%04d', $x, $y, $w, $h);
        $framebuffer[$page]->rbox(
            {
                'x'          => $x,
                'y'          => $y,
                'width'      => $w,
                'height'     => $h,
                'filled'     => 1,
                'pixel_size' => 1,
                'gradient'   => {
                    'start' => {
                        'red'   => rand(256),
                        'green' => rand(256),
                        'blue'  => rand(256)
                    },
                    'end' => {
                        'red'   => rand(256),
                        'green' => rand(256),
                        'blue'  => rand(256)
                    }
                }
            }
        );
    } elsif ($type == 7) {
        my @poly;
        foreach my $count (0 .. int(rand(6))) {
            push(@poly, int(rand($screen_width)));
            push(@poly, int(rand($screen_height)));
        }
        print locate($page, 1), clline, colored(['black on_green'], "Thread $page"), colored(['white on_blue'], $framebuffer[$page]->{'FB_DEVICE'}), sprintf(' Drawing Polygon at points %s with pixel size %d, filled? %s', join(',', @poly), $size, ($filled) ? 'Yes' : 'No');
        $framebuffer[$page]->polygon({ 'pixel_size' => $size, 'coordinates' => \@poly, 'filled' => (int(rand(2))) });
    } elsif ($type == 8) {
        my @poly;
        foreach my $count (0 .. int(rand(6))) {
            push(@poly, int(rand($screen_width)));
            push(@poly, int(rand($screen_height)));
        }
        print locate($page, 1), clline, colored(['black on_green'], "Thread $page"), colored(['white on_blue'], $framebuffer[$page]->{'FB_DEVICE'}), sprintf(' Drawing Gradient Polygon at points %s', join(',', @poly));
        $framebuffer[$page]->polygon(
            {
                'pixel_size'  => 1,
                'coordinates' => \@poly,
                'filled'      => 1,
                'gradient'    => {
                    'start' => {
                        'red'   => rand(256),
                        'green' => rand(256),
                        'blue'  => rand(256)
                    },
                    'end' => {
                        'red'   => rand(256),
                        'green' => rand(256),
                        'blue'  => rand(256)
                    }
                }
            }
        );
    } elsif ($type == 9) {
        print locate($page, 1), clline, colored(['black on_green'], "Thread $page"), colored(['white on_blue'], $framebuffer[$page]->{'FB_DEVICE'}), sprintf(' Drawing Gradient Circle at %04d,%04d with Radius %04d', $x, $y, $rx);
        $framebuffer[$page]->circle(
            {
                'x'        => $x,
                'y'        => $y,
                'radius'   => $rx,
                'filled'   => 1,
                'gradient' => {
                    'start' => {
                        'red'   => rand(256),
                        'green' => rand(256),
                        'blue'  => rand(256)
                    },
                    'end' => {
                        'red'   => rand(256),
                        'green' => rand(256),
                        'blue'  => rand(256)
                    }
                }
            }
        );
    } elsif ($type == 10) {
        print locate($page, 1), clline, colored(['black on_green'], "Thread $page"), colored(['white on_blue'], $framebuffer[$page]->{'FB_DEVICE'}), sprintf(' Drawing Gradient Ellipse at %04d,%04d with Radii %04d,%04d', $x, $y, $rx, $ry);
        $framebuffer[$page]->ellipse(
            {
                'x'        => $x,
                'y'        => $y,
                'xradius'  => $rx,
                'yradius'  => $ry,
                'filled'   => 1,
                'factor'   => 1,
                'gradient' => {
                    'start' => {
                        'red'   => rand(256),
                        'green' => rand(256),
                        'blue'  => rand(256)
                    },
                    'end' => {
                        'red'   => rand(256),
                        'green' => rand(256),
                        'blue'  => rand(256)
                    }
                }
            }
        );
    } elsif ($type == 11) {
        print locate($page, 1), clline, colored(['black on_green'], "Thread $page"), colored(['white on_blue'], $framebuffer[$page]->{'FB_DEVICE'}), sprintf(' Drawing Rounded Box at %04d,%04d and %04d,%04d with pixel size %d, filled? %s', $x, $y, $w, $h, $size, ($filled) ? 'Yes' : 'No');
        $framebuffer[$page]->rbox({ 'x' => $x, 'y' => $y, 'width' => $w, 'height' => $h, 'filled' => $filled, 'radius' => rand(30) + 2, 'pixel_size' => $size });
    } elsif ($type == 12) {
        print locate($page, 1), clline, colored(['black on_green'], "Thread $page"), colored(['white on_blue'], $framebuffer[$page]->{'FB_DEVICE'}), sprintf(' Drawing Rounded Gradiant Box at %04d,%04d and %04d,%04d', $x, $y, $w, $h);
        $framebuffer[$page]->rbox(
            {
                'x'          => $x,
                'y'          => $y,
                'width'      => $w,
                'height'     => $h,
                'filled'     => 1,
                'pixel_size' => 1,
                'radius'     => rand(30) + 2,
                'gradient'   => {
                    'start' => {
                        'red'   => rand(256),
                        'green' => rand(256),
                        'blue'  => rand(256)
                    },
                    'end' => {
                        'red'   => rand(256),
                        'green' => rand(256),
                        'blue'  => rand(256)
                    }
                }
            }
        );
    } else {
        print locate($page, 1), clline, colored(['black on_green'], "Thread $page"), colored(['white on_blue'], $framebuffer[$page]->{'FB_DEVICE'}), sprintf(' Flood Fill starting at %04d,%04d', $x, $y);
        $framebuffer[$page]->fill({ 'x' => $x, 'y' => $y });
    }
} ## end sub attract

sub arctype {
    my $type = shift;
    if ($type == 0) {
        return ('Arc');
    } elsif ($type == 1) {
        return ('Pie');
    } else {
        return ('Poly Arc');
    }
} ## end sub arctype

sub finish {
    $RUNNING = 0;
    alarm 3;
    print locate(1, 1), "SHUTTING DOWN THREADS...";
    while (my @thr = threads->list(threads::running)) {
        sleep 1;
    }
    foreach my $thr (threads->list()) {
        $thr->detach();
    }
    sleep 1;
    cls;
    exec('reset');
} ## end sub finish

__END__

=head1 NAME

Threads Test

=head1 DESCRIPTION

Demonstrates how to use threads with "Graphics::Framebuffer"

=head1 SYNOPSIS

 perl threadstest.pl [file] [# of threads]

=head1 OPTIONS

The options can be passed in any order and all are optional.

=over 2

=item B<file>

Changes the internal logic of Graphics::Framebuffer to instead draw
using a file handle, instead of using a Mmapped variable.

Only use if you are having stability issues, as it is slower.

=item B<number of threads >

This is an integer (yes, just a number) indicating how many threads
to spawn to draw.

Typically this is done automatically with the number of cores the
script detects, but this overrides the detection.

=back

=cut
