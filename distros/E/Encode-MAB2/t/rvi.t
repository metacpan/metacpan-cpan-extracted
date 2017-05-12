# -*- coding: utf-8; mode: cperl -*-
use strict;
use Test::More tests => 55;

use_ok "Tie::MAB2::Recno";
use_ok "Tie::MAB2::Id";
use_ok "Tie::MAB2::RecnoViaId";

tie my @tie,     "Tie::MAB2::Recno",      file => "t/kafka.mab";
tie my %tie_id,  "Tie::MAB2::Id",         file => "t/kafka.mab";
tie my %tie_rvi, "Tie::MAB2::RecnoViaId", file => "t/kafka.mab";

for my $i (0..$#tie) {
  my $rec1 = $tie[$i];
  my $id   = $rec1->id;
  my $rec2 = $tie_id{$id};
  ok($rec1->as_string eq $rec2->as_string);
  my $rvi  = $tie_rvi{$id};
  ok($i==$rvi);
}
