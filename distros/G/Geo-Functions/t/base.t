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

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "1..0 # tests only works with installed Test module\n";
	exit;
    }
}

BEGIN { plan tests => 2239 }

# just check that all modules can be compiled
ok(eval {require Geo::Functions; 1}, 1, $@);

my $o = Geo::Functions->new();
ok(ref $o, "Geo::Functions");

ok ($o->deg_rad(atan2(1,1)), 45);
ok ($o->deg_dms(40,42,46.5,"N"), 40+(42+46.5/60)/60);
ok ($o->rad_dms(40,42,46.5,"N"), $o->rad_deg(40+(42+46.5/60)/60));
ok ($o->rad_deg(45), atan2(1,1));
ok ($o->round(45.9), 46);
foreach (qw{5 10 25 50}) {
  ok($_, $o->mps_knots($o->knots_mps($_)));
}

use Geo::Functions qw{deg_rad deg_dms rad_deg round rad_dms dms_deg dm_deg mps_knots knots_mps};

ok (deg_rad(atan2(1,1)), 45);
ok (deg_dms(40,42,46.5,"s"), -1*(40+(42+46.5/60)/60));
ok (deg_dms(40,42,46.5,"S"), -1*(40+(42+46.5/60)/60));
ok (deg_dms(40,42,46.5,"w"), -1*(40+(42+46.5/60)/60));
ok (deg_dms(40,42,46.5,"W"), -1*(40+(42+46.5/60)/60));
ok (deg_dms(40,42,46.5,-1), -1*(40+(42+46.5/60)/60));
ok (deg_dms(40,42,46.5,-40), -1*(40+(42+46.5/60)/60));
ok (deg_dms(40,42,46.5,"N"), 1*(40+(42+46.5/60)/60));
ok (deg_dms(40,42,46.5,"n"), 1*(40+(42+46.5/60)/60));
ok (deg_dms(40,42,46.5,""), 1*(40+(42+46.5/60)/60));
ok (deg_dms(40,42,46.5,undef), 1*(40+(42+46.5/60)/60));
ok (deg_dms(40,42,46.5), 1*(40+(42+46.5/60)/60));
ok (rad_deg(45), atan2(1,1));
ok (rad_deg(90), atan2(1,0));
ok (rad_deg(180), atan2(0,-1));
ok (rad_deg(-90), atan2(-1,0));
ok (round(0), 0);
ok (round(5.1), 5);
ok (round(5.5), 6);
ok (round(5.6), 6);
ok (round(-5.1), -5);
ok (round(-5.5), -6);
ok (round(-5.6), -6);
ok (rad_dms(55, 34, 76, "N"), rad_deg(deg_dms(55, 34, 76, "N")));
foreach my $d1 (0,5,15,67,88) {
  foreach my $m1 (0,3,43,57) {
    foreach my $s1 (5,15,34,45,56) {
      foreach my $sign1 (qw{N S}) {
        my ($d2,$m2,$s2,$sign2)=dms_deg(deg_dms($d1,$m1,$s1,$sign1), qw{N S});
        my ($d3,$m3,$sign3)=dm_deg(deg_dms($d1,$m1,$s1,$sign1), qw{N S});
        ok ($d1, $d2);
        ok ($m1, $m2);
        ok (near $s1, $s2);
        ok ($sign1, $sign2);
        ok ($d1, $d3);
        ok (near $m1+$s1/60, $m3);
        ok ($sign1, $sign3);
      }
      foreach my $sign1 (qw{E W}) {
        my ($d2,$m2,$s2,$sign2)=dms_deg(deg_dms($d1,$m1,$s1,$sign1), qw{E W});
        ok ($d1, $d2);
        ok ($m1, $m2);
        ok (near $s1, $s2);
        ok ($sign1, $sign2);
      }
    }
  }
}
foreach (qw{5 10 25 50}) {
  ok($_, mps_knots(knots_mps($_)));
}
