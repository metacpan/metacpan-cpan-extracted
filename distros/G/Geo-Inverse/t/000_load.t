#!/usr/bin/perl
use strict;
use warnings;
use Test::Number::Delta relative => 1e-7;
use Test::More tests => 20;

BEGIN{use_ok 'Geo::Inverse'};

my $o = Geo::Inverse->new;
ok(ref $o, 'Geo::Inverse');

{
  my ($faz, $baz, $dist)=$o->inverse(34.5,-77.5,35,-78);
  delta_ok($faz, d(320,36,23.2945));
  delta_ok($baz, d(140,19,17.2861));
  delta_ok($dist, 71921.4677);
}

{
  my ($faz, $baz, $dist)=$o->inverse(34.5,-77.5,d(34,11,11),-1*d(77,45,45));
  delta_ok($faz, d(214,50,44.6531));
  delta_ok($baz, d(34,41,51.5299));
  delta_ok($dist, 42350.9312);
}

{
  my ($faz, $baz, $dist) = $o->inverse(d(qw{67 34 54.65443}),-1*d(qw{118 23 54.24523}),
                                       d(qw{67 45 32.65433}),-1*d(qw{118 34 43.23454}));
  delta_ok($faz, d(qw{338 56  3.2089}));
  delta_ok($baz, d(qw{158 46  2.8840}));
  delta_ok($dist, 21193.2643);
}

{
  my $dist = $o->inverse(d(qw{67 34 54.65443}),-1*d(qw{118 23 54.24523}),
                         d(qw{67 45 32.65433}),-1*d(qw{118 34 43.23454}));
  delta_ok($dist, 21193.2643);
}

{
  local $@;
  my $dist  = eval{$o->inverse(undef,1,1,1)};
  my $error = $@;
  ok($error);
  like($error, qr/\ASyntax Error: function inverse lat1/);
}

{
  local $@;
  my $dist = eval{$o->inverse(1,undef,1,1)};
  my $error = $@;
  ok($error);
  like($error, qr/\ASyntax Error: function inverse lon1/);
}

{
  local $@;
  my $dist  = eval{$o->inverse(1,1,undef,1)};
  my $error = $@;
  ok($error);
  like($error, qr/\ASyntax Error: function inverse lat2/);
}

{
  local $@;
  my $dist  = eval{$o->inverse(1,1,1,undef)};
  my $error = $@;
  ok($error);
  like($error, qr/\ASyntax Error: function inverse lon2/);
}

sub d {my ($d,$m,$s)=@_; return($d + ($m + $s/60)/60)};
