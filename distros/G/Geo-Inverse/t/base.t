#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: base.t,v 0.1 2006/02/21 eserte Exp $
# Author: Michael R. Davis
#

=head1 Test Examples

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

sub d {
  my ($d,$m,$s)=@_;
  return($d + ($m + $s/60)/60);
}

BEGIN { plan tests => 12 }

# just check that all modules can be compiled
ok(eval {require Geo::Inverse; 1}, 1, $@);

my $o = Geo::Inverse->new();
ok(ref $o, "Geo::Inverse");

my ($faz, $baz, $dist)=$o->inverse(34.5,-77.5,35,-78);
ok near($faz, d(320,36,23.2945));
ok near($baz, d(140,19,17.2861));
ok near($dist, 71921.4677);

($faz, $baz, $dist)=$o->inverse(34.5,-77.5,d(34,11,11),-1*d(77,45,45));
ok near($faz, d(214,50,44.6531));
ok near($baz, d(34,41,51.5299));
ok near($dist, 42350.9312);

($faz, $baz, $dist) = 
   $o->inverse(d(qw{67 34 54.65443}),-1*d(qw{118 23 54.24523}),
               d(qw{67 45 32.65433}),-1*d(qw{118 34 43.23454}));
ok near($faz, d(qw{338 56  3.2089}));
ok near($baz, d(qw{158 46  2.8840}));
ok near($dist, 21193.2643);

#New in Geo::Inverse->VERISON >= 0.05
$dist = 
   $o->inverse(d(qw{67 34 54.65443}),-1*d(qw{118 23 54.24523}),
               d(qw{67 45 32.65433}),-1*d(qw{118 34 43.23454}));
ok near($dist, 21193.2643);
