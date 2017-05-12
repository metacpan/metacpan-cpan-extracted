#!/usr/bin/perl
use warnings;
use strict;
use lib qw(lib);

my $sp = GD::Sparkline->new({
			     s => q[10,10,10,10,20,50,70,10,100,200,40,50],
			     w => 100,
			     h => 20,
			    });
print $sp->draw();
