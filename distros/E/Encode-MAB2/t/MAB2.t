# -*- coding: utf-8; mode: cperl -*-
use strict;
# Adjust the number here!
use Test::More tests => 12;

use_ok('Encode');
use_ok('Encode::MAB2');
# Add more test here!

use Tie::MAB2::Recno;
use utf8;
binmode STDOUT, ":utf8";

my @tie;
tie @tie, "Tie::MAB2::Recno", file => "t/kafka.mab";
ok(scalar @tie == 26);

like(urec( 0),qr/Schweppenhäuser/);
like(urec( 2),qr/Ángel/);
like(urec( 8),qr/Künstler/);
like(urec(11),qr/Jesenská/);
like(urec(14),qr/Küng/);
like(urec(17),qr/Tröndle/);
like(urec(21),qr/littérature/);
like(urec(22),qr/l'irréductible espoir/);
like(urec(24),qr/abendländisch/);

#  my $rand = int rand scalar @tie;
#  print "rand[$rand]\n";
#  my $unicode = urec($rand);
#  print $unicode, "\n---\n";

sub urec {
  my($n) = shift;
  my $ret = $tie[$n]->readable;
  #use Devel::Peek;
  #Dump $ret;
  $ret;
}
