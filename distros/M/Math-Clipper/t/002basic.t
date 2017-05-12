use strict;
use warnings;

use Test::More tests => 1+6+3*2;

use constant EPS => 1.e-9;
sub approx_eq {
  return ($_[0]+EPS() < $_[1] && $_[0]-EPS() > $_[1]);
}

use Math::Clipper qw/:all/;
pass();


foreach my $const (
    qw/CT_INTERSECTION CT_UNION CT_DIFFERENCE CT_XOR/,
    #qw/PT_SUBJECT PT_CLIP/,
    qw/PFT_EVENODD PFT_NONZERO/,
    )
{
  ok(defined eval $const);
}

SCOPE: {
  my $c = Math::Clipper->new;
  isa_ok($c, 'Math::Clipper');
  $c->add_subject_polygon(
    [
      [0, 0],
      [10, 0],
      [10, 10],
      [0, 10],
    ],
  );
  
  $c->add_clip_polygon(
    my $clip = [
      [0, 0],
      [5, 0],
      [5, 10],
      [0, 10],
    ],
  );

  my $ppoly = $c->execute(CT_INTERSECTION);
  ok(ref($ppoly) eq 'ARRAY');
  is area($ppoly->[0]), area($clip);
}

SCOPE: {
  my $c = Math::Clipper->new;
  isa_ok($c, 'Math::Clipper');
  $c->add_subject_polygon(
    [
      [0, 0],
      [10, 0],
      [10, 10],
      [0, 10],
    ],
  );

  $c->add_clip_polygon(
    [
      [50, 0.],
      [55, 0.],
      [55, 10],
      [50, 10],
      [60, 20],
      [80, 30],
      [100, 40],
      [120, 50],
      [140, 60],
      [160, 70],
    ],
  );

  my $ppoly = $c->execute(CT_INTERSECTION);
  ok(ref($ppoly) eq 'ARRAY');
  is_deeply($ppoly, [] );
}

