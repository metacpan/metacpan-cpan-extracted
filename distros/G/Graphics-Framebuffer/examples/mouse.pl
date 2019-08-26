#!/usr/bin/env perl

use strict;

use Graphics::Framebuffer;

our $FB = Graphics::Framebuffer->new('SPLASH'=>0);
our $RUNNING = 1;
$SIG{'KILL'} = $SIG{'INT'} = $SIG{'HUP'} = $SIG{'TERM'} = sub { $RUNNING = 0; };

$FB->cls('OFF');

$FB->initialize_mouse(1);
my ($B,$X,$Y) = (0,0,0);

while($RUNNING){
    my ($b,$x,$y) = $FB->get_mouse();
    print STDERR sprintf('BUTTON=%08B  X=%d  Y=%d     ', $b, $x, $y),"\r";
}
$FB->initialize_mouse(0);
$FB->cls('ON');    # Turn the console cursor back on
exit(0);

__END__

=head1 NAME

Mouse functionality sample

=head1 SYNOPIS

./mouse.pl

=head1 DESCRIPTION

This file just shows a rudimentary method to handle the mouse.  It is not
guaranteed to even work.  I do not recommend using the mouse.

If you really want mouse functionality, then you likely are using the
wrong module.  Try SDL or other X-Windows based library instead.

=cut
