#!/usr/bin/env perl -T

use strict;
use warnings;

use Time::HiRes qw(sleep);
use POSIX qw(geteuid :sys_wait_h);
use Test::More;

# Taint mode path scrubbing for external executions
$ENV{'PATH'} = '/bin:/usr/bin:/usr/local/bin';
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

BEGIN {
    our $VERSION = '2.05';
}

my $b  = "\e[34m";
my $bb = "\e[94m";
my $g  = "\e[32m";
my $gg = "\e[92m";
my $r  = "\e[31m";
my $rr = "\e[91m";
my $rs = "\e[0m";
my $c  = "\e[36m";
my $bk = "\e[40m";
my $y  = "\e[33m";

diag("\n\r$b$bk" . ' ' x 66 . $rs);
diag("\r$b$bk" . ' ' x 11 . q{   ,ad8888ba,   } . ' ' x 40 . $rs );
diag("\r$b$bk" . ' ' x 11 . q{  d8"'    `"8b } . ' ' x 40 . $rs );
diag("\r$b$bk" . ' ' x 11 . q{ d8'           } . ' ' x 40 . $rs );
diag("\r$b$bk" . ' ' x 11 . q{ 88            } . ' ' x 40 . $rs );
diag("\r$b$bk" . ' ' x 11 . q{ 88      88888 } . ' ' x 40 . $rs );
diag("\r$b$bk" . ' ' x 11 . q{ Y8,        88 } . ' ' x 40 . $rs );
diag("\r$b$bk" . ' ' x 11 . q{  Y8a.    .a88 } . ' ' x 40 . $rs );
diag("\r$b$bk" . ' ' x 11 . q{   `"Y88888P"  } . ' ' x 40 . $rs );

sleep 0.2;

diag("\r$bk  \r\e[8A\e[26C$g$bk" , q{ 88888888888 } . $rs );
diag("\r$bk  \r\e[26C$g$bk"      . q{ 88          } . $rs );
diag("\r$bk  \r\e[26C$g$bk"      . q{ 88          } . $rs );
diag("\r$bk  \r\e[26C$g$bk"      . q{ 88aaaaa     } . $rs );
diag("\r$bk  \r\e[26C$g$bk"      . q{ 88"""""     } . $rs );
diag("\r$bk  \r\e[26C$g$bk"      . q{ 88          } . $rs );
diag("\r$bk  \r\e[26C$g$bk"      . q{ 88          } . $rs );
diag("\r$bk  \r\e[26C$g$bk"      . q{ 88          } . $rs );

sleep 0.2;

diag("\r$bk  \r\e[8A\e[38C$r$bk" . q{ 88888888ba  } . ' ' x 15 . $rs );
diag("\r$bk  \r\e[38C$r$bk"      . q{ 88      "8b } . ' ' x 15 . $rs );
diag("\r$bk  \r\e[38C$r$bk"      . q{ 88      ,8P } . ' ' x 15 . $rs );
diag("\r$bk  \r\e[38C$r$bk"      . q{ 88aaaaaa8P' } . ' ' x 15 . $rs );
diag("\r$bk  \r\e[38C$r$bk"      . q{ 88""""""8b, } . ' ' x 15 . $rs );
diag("\r$bk  \r\e[38C$r$bk"      . q{ 88      `8b } . ' ' x 15 . $rs );
diag("\r$bk  \r\e[38C$r$bk"      . q{ 88      a8P } . ' ' x 15 . $rs );
diag("\r$bk  \r\e[38C$r$bk"      . q{ 88888888P"  } . ' ' x 15 . $rs );
diag("\r$c$bk" . ' ' x 66 . $rs);

sleep 0.2;

diag("\r$c$bk" .             q{ 888888888888                         88                          } . $rs);
diag("\r$c$bk" .             q{      88                        ,d    ""                          } . $rs);
diag("\r$c$bk" .             q{      88                        88                                } . $rs);
diag("\r$c$bk" .             q{      88  ,adPPYba, ,adPPYba, MM88MMM 88 8b,dPPYba,   ,adPPYb,d8  } . $rs);
diag("\r$c$bk" .             q{      88 a8P_____88 I8[    ""   88    88 88P'   `"8a a8"    `Y88  } . $rs);
diag("\r$c$bk" .             q{      88 8PP"""""""  `"Y8ba,    88    88 88       88 8b       88  } . $rs);
diag("\r$c$bk" .             q{      88 "8b,   ,aa aa    ]8I   88,   88 88       88 "8a,   ,d88  } . $rs);
diag("\r$c$bk" .             q{      88  `"Ybbd8"' `"YbbdP"'   "Y888 88 88       88  `"YbbdP"Y8  } . $rs);
diag("\r$c$bk" .             q{                                                      aa,    ,88  } . $rs);
diag("\r$y$bk" . q{ Graphics::Framebuffer CPAN Module } . $c . q{                    "Y8bbdP"   } . $rs);
diag("\r$c$bk" . ' ' x 66 . $rs);
diag("\r ");

if ( $^O ne 'linux' ) {
    plan skip_all => "${r}Testable only on Linux$rs";
    exit(0);
}

# Plan our two assertions
plan tests => 2;

my $shm_fb   = '/dev/shm/gfb_screen';
my $shm_info = '/dev/shm/gfb_screen.info';
my $viewer_pid;

# If in a GUI desktop, spawn emulation and viewer
if ( defined($ENV{'DISPLAY'}) || defined($ENV{'WAYLAND_DISPLAY'}) ) {
    diag("${y}Detected GUI environment. Initializing shared memory emulator...$rs");

    # Discover available viewer binary in priority order
    my $player_bin;
    my $player_type; # 'mplayer' or 'mpplay_ffplay'

    for my $candidate (qw(mpplay ffplay mplayer)) {
        if (my $path = find_bin($candidate)) {
            $player_bin  = $path;
            $player_type = ($candidate eq 'mplayer') ? 'mplayer' : 'mpplay_ffplay';
            last;
        }
    }

    if (!$player_bin) {
        diag("${r}Warning: No viewer binary found (checked mpplay, mplayer, ffplay). Test will proceed headless on /dev/shm.$rs");
    }

    my ($w, $h, $bpp) = (1280, 720, 32);
    my $buffer_size   = $w * $h * int($bpp / 8);

    # Create & truncate the virtual fb memory
    open(my $fh_fb, '>', $shm_fb) or die "Cannot create $shm_fb: $!\n";
    truncate($fh_fb, $buffer_size) or die "Cannot truncate $shm_fb: $!\n";
    close($fh_fb);

    # Create the config file
    open(my $fh_info, '>', $shm_info) or die "Cannot create $shm_info: $!\n";
    print $fh_info "$w $h $bpp\n";
    close($fh_info);

    if ($player_bin) {
        diag("${g}Launching viewer using: $player_bin$rs");

        # Fork to launch the detected player asynchronously
        $viewer_pid = fork();
        if (!defined $viewer_pid) {
            die "Fork failed: $!\n";
        } elsif ($viewer_pid == 0) {
            # Child: Silence stdout/stderr
            open(STDOUT, '>', '/dev/null');
            open(STDERR, '>', '/dev/null');

            if ($player_type eq 'mplayer') {
                # MPlayer syntax for raw byte streams
                # Note: mplayer uses bgra / bgr32 for 32-bit framebuffer pixel formats
                exec(
                    $player_bin,
                    '-demuxer', 'rawvideo',
                    '-rawvideo', "w=$w:h=$h:format=bgr0:fps=30",
                    '-title', 'Graphics::Framebuffer Test Window',
                    $shm_fb
                );
            } else {
                # mpplay / ffplay syntax
                exec(
                    $player_bin,
                    '-f', 'rawvideo',
                    '-pixel_format', 'bgr0',
                    '-video_size', "${w}x${h}",
                    '-framerate', '30',
                    '-loop', '0',
                    '-window_title', 'Graphics::Framebuffer Test Window',
                    '-i', $shm_fb
                );
            }
            exit(1); # Exec failed
        }

        # Give player a moment to claim the window surface and map the buffer
        sleep 0.5;
    }
}

# Load module and verify class instance
use_ok('Graphics::Framebuffer');

our $F;
eval {
    $F = Graphics::Framebuffer->new('RESET' => 0, 'SPLASH' => 0);
};

if ($@ || !defined($F)) {
    cleanup_viewer();
    BAIL_OUT("Failed to instantiate Graphics::Framebuffer: $@");
}

isa_ok($F, 'Graphics::Framebuffer');

# Run the test rendering passes
$F->acceleration(0);
$F->splash(2);

$F->acceleration(1);
$F->splash(2);

# Allow developer to see the rendered splash briefly before tearing down
if ($viewer_pid) {
    sleep 1.5;
    cleanup_viewer();
}

exit(0);
# Helper to find a binary in safe PATH without external modules
sub find_bin {
    my ($bin) = @_;
    for my $dir (split(/:/, $ENV{'PATH'})) {
        my $target = "$dir/$bin";
        return $target if (-x $target && !-d $target);
    }
    return undef;
}

# Guaranteed cleanup wrapper
sub cleanup_viewer {
    if ($viewer_pid) {
        kill('TERM', $viewer_pid);
        waitpid($viewer_pid, 0);
        undef $viewer_pid;
    }
    unlink($shm_fb)   if -e $shm_fb;
    unlink($shm_info) if -e $shm_info;
}

END {
    cleanup_viewer();
}

__END__