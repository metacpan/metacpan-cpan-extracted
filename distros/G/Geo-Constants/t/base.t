#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: base.t,v 0.1 2006/02/21 eserte Exp $
# Author: Michael R. Davis
#

=head1 NAME

base.t - Good examples concerning how to use this module

=cut

use strict;
use lib q{lib};
use lib q{../lib};
use constant NEAR_DEFAULT => 7;

sub near {
  my $x=shift();
  my $y=shift();
  my $p=shift()||NEAR_DEFAULT;
  if (($x-$y)/$y < 10**-$p) {
    return 1;
  } else {
    return 0;
  }
}

sub dms2dd {
  my $d=shift();
  my $m=shift();
  my $s=shift();
  my $dir=shift()||'N';
  my $val=$d+($m+$s/60)/60;
  if ($dir eq 'W' or $dir eq 'S') {
    return -$val;
  } else {
    return $val;
  }
}

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "1..0 # tests only works with installed Test module\n";
	exit;
    }
}

BEGIN { plan tests => 10 }

# just check that all modules can be compiled
ok(eval {require Geo::Constants; 1}, 1, $@);

my $o = Geo::Constants->new();
ok(ref $o, "Geo::Constants");

ok ($o->PI, 4*atan2(1,1));
ok ($o->DEG, 180/(4*atan2(1,1)));
ok ($o->RAD, 4*atan2(1,1)/180);
ok ($o->KNOTS, 1852/3600);

use Geo::Constants qw{PI DEG RAD KNOTS};
ok (PI(), 4*atan2(1,1));        #Barewords on some machines or perl versions
ok (DEG(), 180/(4*atan2(1,1))); #fail.  So, I do not use them.  You may use
ok (RAD(), 4*atan2(1,1)/180);   #them in your scripts but they may not port.
ok (KNOTS(), 1852/3600);
