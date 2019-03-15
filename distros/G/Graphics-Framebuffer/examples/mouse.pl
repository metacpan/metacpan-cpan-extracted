#!/usr/bin/env perl

use strict;

use Graphics::Framebuffer;

our $FB = Graphics::Framebuffer->new('SPLASH'=>0);
$SIG{'KILL'} = $SIG{'INT'} = $SIG{'HUP'} = sub { exec('reset'); };

$FB->cls('OFF');

$FB->initialize_mouse(1);
my ($B,$X,$Y) = (0,0,0);

while(1){
    my ($b,$x,$y) = $FB->get_mouse();
    print STDERR sprintf('BUTTON=%08B  X=%d  Y=%d     ', $b, $x, $y),"\r";
}

$FB->cls('ON');    # Turn the console cursor back on
exit(0);

__END__

=head1 NAME

Template file for writing scripts that use Graphics::Framebuffer

=head1 SYNOPIS

First, copy this file, and name the copy whatever you want (using "yourscript"
for this example):

 cp template.pl yourscript.pl

Now edit "yourscript.pl" from now on.  Please do not directly edit "template.pl".

=head1 DESCRIPTION

Use this file as a starting point for writing your scripts.  Copy it so as to
not destroy the original template, then edit the copy.

=cut
