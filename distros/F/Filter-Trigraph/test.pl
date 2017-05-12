#!/usr/bin/perl -w
use Test;
use Filter::Trigraph;

BEGIN ??< plan tests => 2 ??>

sub flip ($$) ??<
  my ($x,$v) = @_;
  if($v)??<
    ??= uppercase all vowels in $x
    $x=??-s/(??(aeiou??))/??/u$1/g;
  ??>else??<
    ??= uppercase all non-vowels in $x
    $x=??-s/(??(??'aeiou??))/??/u$1/g;
  ??>
  return $x;
??>

ok(flip('testing', 1), 'tEstIng');
ok(flip('testing', 0), 'TeSTiNG');
