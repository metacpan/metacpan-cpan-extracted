#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 35, noinit => 1;

# $Id$

my $rectangle_one = Gtk2::Gdk::Rectangle -> new(23, 42, 10, 10);
my $rectangle_two = Gtk2::Gdk::Rectangle -> new(23, 42, 15, 15);

isa_ok($rectangle_one -> intersect($rectangle_two), "Gtk2::Gdk::Rectangle");
isa_ok($rectangle_one -> union($rectangle_two), "Gtk2::Gdk::Rectangle");

{
  my $pspec = Glib::ParamSpec->boxed ('bb','bb','blurb',
				      'Gtk2::Gdk::Rectangle',
				      Glib::G_PARAM_READWRITE);
  my $rect = Gtk2::Gdk::Rectangle->new (1,2,3,4);
  my ($flag, $new) = $pspec->value_validate($rect);
  undef $rect;
  ok (! $flag, 'value_validate() rectangle unchanged');
  is ($new->x, 1, );
  is ($new->y, 2);
  is ($new->width, 3);
  is ($new->height, 4);
}

my $region = Gtk2::Gdk::Region -> new();
isa_ok($region, "Gtk2::Gdk::Region");
ok($region -> empty());

$region = Gtk2::Gdk::Region -> polygon([ 5,  5,
                                        10,  5,
                                         5, 10,
                                        10, 10],
                                       "winding-rule");
isa_ok($region, "Gtk2::Gdk::Region");
is($region -> rect_in(Gtk2::Gdk::Rectangle -> new(7, 7, 1, 1)), "in");
is($region -> rect_in(Gtk2::Gdk::Rectangle -> new(0, 0, 3, 3)), "out");
is($region -> rect_in(Gtk2::Gdk::Rectangle -> new(5, 5, 6, 6)), "part");

$region = Gtk2::Gdk::Region -> rectangle($rectangle_one);
isa_ok($region, "Gtk2::Gdk::Region");

isa_ok($region -> get_clipbox(), "Gtk2::Gdk::Rectangle");
{
  my $empty = Gtk2::Gdk::Region->new;
  ok (eq_array ([$empty->get_clipbox->values],
		[0, 0, 0, 0]),
		'$empty->get_clipbox returns valid rectangle');
}

isa_ok(($region -> get_rectangles())[0], "Gtk2::Gdk::Rectangle");
ok($region -> equal($region));
ok($region -> point_in(30, 50));

$region -> spans_intersect_foreach([24, 43, 5,
                                    24, 43, 5],
                                   1,
                                   sub {
  my ($x, $y, $width, $data) = @_;

  is($x, 24);
  is($y, 43);
  is($width, 5);
  is($data, "bla");
}, "bla");

{
  my $callback = 0;
  $region -> spans_intersect_foreach([], 1, sub { $callback = 1; });
  is($callback, 0, 'spans_intersect_foreach() 0 coords - no callback');
}

ok (! eval { $region->spans_intersect_foreach([1], 1, sub {}); 1 },
      'spans_intersect_foreach() 1 coord - expect error');
ok (! eval { $region->spans_intersect_foreach([1,2], 1, sub {}); 1 },
      'spans_intersect_foreach() 2 coords - expect error');
ok (  eval { $region->spans_intersect_foreach([1,2,3], 1, sub {}); 1 },
      'spans_intersect_foreach() 3 coords - expect good');
ok (! eval { $region->spans_intersect_foreach([1,2,3,4], 1, sub {}); 1 },
      'spans_intersect_foreach() 4 coords - expect error');
ok (! eval { $region->spans_intersect_foreach([1,2,3,4,5], 1, sub {}); 1 },
      'spans_intersect_foreach() 5 coords - expect error');
ok (  eval { $region->spans_intersect_foreach([1,2,3,4,5,6], 1, sub {}); 1 },
      'spans_intersect_foreach() 6 coords - expect good');

$region -> offset(5, 5);
$region -> shrink(5, 5);
$region -> union_with_rect($rectangle_two);

my $region_two = Gtk2::Gdk::Region -> rectangle($rectangle_two);

$region -> intersect($region_two);
$region -> union($region_two);
$region -> subtract($region_two);
$region -> xor($region_two);

SKIP: {
  skip "new 2.18 stuff", 1
	unless Gtk2 -> CHECK_VERSION(2, 18, 0);
	my $region= Gtk2::Gdk::Region -> rectangle($rectangle_one);
	ok(!$region->rect_equal($rectangle_two), 'rect_equal');
}


__END__

Copyright (C) 2003, 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
