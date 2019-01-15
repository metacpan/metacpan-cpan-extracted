#!/usr/bin/env perl

use strict;
# use warnings; # Use just for development, otherwise leave warnings off

# We use Time::HiRes for the alarm, and we need fractions of a second.
use Time::HiRes qw(alarm time sleep);
use Graphics::Framebuffer;

## Initialize any global variables here

my $device        = '/dev/fb0'; # Change this to your frambuffer device
my $double_buffer = FALSE;      # Make this TRUE, if you have a 16 bit display
my $delay         = 1/20;       # For double-buffering, use smaller numbers
                                # for slower machines

our ($PFB,$DFB); # The framebuffer objects MUST be as global as possible

# $PFB = Physical framebuffer
# $DFB = Double-buffered framebuffer
# We will always draw to $DFB

unless ($double_buffer) {
    $DFB = Graphics::Framebuffer->new(
        'FB_DEVICE' => $device,
        'SPLASH'    => 0,
    );
} else { # This is best used in this way for 16 bit mode only
    ($PFB,$DFB) = Graphics::Framebuffer->new(
        'FB_DEVICE'     => $device,
        'DOUBLE_BUFFER' => TRUE,
        'SPLASH'        => 0,
    );
}


if ($double_buffer) { # We are in 16 bit mode and are double-buffering
    $PFB->cls('OFF'); # Turn off the cursor with the physical framebuffer
    $SIG{'ALRM'} = \&flip_it; # We use 'alarm' to act as a frame flipper
    alarm($delay);
}

## Do your stuff here ########################################################


##############################################################################

alarm(0); # Turn this off as soon as possible to prevent weirdness.
$PFB->cls('ON'); # Restore the cursor
exit(0);

sub flip_it { # This does the double-buffering magic for 16 bit mode
    alarm(0); # Prevent call stacking.  So temporarily shut off alarms
    $PFB->blit_flip($DFB); # Convert and move the 32 bit virtual screen to the
                           # physical 16 bit screen
    alarm($delay); # Turn the alarm handler back on
}

__END__

=head1 NAME

Template file for writing scripts that use Graphics::Framebuffer

=head1 SYNOPIS

First, copy this file, and name the copy whatever you want (using "yourscript" for this example):

 cp template.pl yourscript.pl

Now edit "yourscript.pl" from now on.  Please do not directly edit "template.pl".

=head1 DESCRIPTION

Use this file as a starting point for writing your scripts.  Copy it so as to not destroy the original template, then edit the copy.

=cut
