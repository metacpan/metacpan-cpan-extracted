#!/usr/bin/env perl

use strict;
# use warnings; # Use just for development, otherwise leave warnings off

use Graphics::Framebuffer;

## Initialize any global variables here

my $device        = '/dev/fb0'; # Change this to your frambuffer device

our $FB; # The framebuffer objects MUST be as global as possible

# $FB = Framebuffer

$FB = Graphics::Framebuffer->new(
    'FB_DEVICE' => $device,
    'SPLASH'    => 0,
);

## Do your stuff here ########################################################


##############################################################################

$FB->cls('ON'); # Restore the cursor
exit(0);

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
