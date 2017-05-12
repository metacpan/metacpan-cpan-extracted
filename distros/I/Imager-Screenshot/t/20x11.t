#!perl -w
use strict;
use Test::More;

use Imager::Screenshot 'screenshot';

Imager::Screenshot->have_x11
    or plan skip_all => "No X11 support";

# can we connect to a display
my $display = Imager::Screenshot::x11_open()
  or plan skip_all => "Cannot connect to a display: ".Imager->errstr;

plan tests => 16;

{
  # should automatically connect and grab the root window
  my $im = screenshot(id => 0)
    or print "# ", Imager->errstr, "\n";
  
  ok($im, "got a root screenshot, no display");

  # check the size matches the tags
  is($im->tags(name => 'ss_window_width'), $im->getwidth,
     "check ss_window_width tag");
  is($im->tags(name => 'ss_window_height'), $im->getheight,
     "check ss_window_height tag");
  is($im->tags(name => 'ss_left'), 0, "check ss_left tag");
  is($im->tags(name => 'ss_top'), 0, "check ss_top tag");
  is($im->tags(name => 'ss_type'), 'X11', "check ss_type tag");
}

{
  # use our supplied display
  my $im = screenshot(display => $display, id => 0);
  ok($im, "got a root screenshot, supplied display");
}

{
  # use our supplied display - as a method
  my $im = Imager::Screenshot->screenshot(display => $display, id => 0);
  ok($im, "got a root screenshot, supplied display (method)");
}

{
  # supply a junk window id
  my $im = screenshot(display => $display, id => 0xFFFFFFF)
    or print "# ", Imager->errstr, "\n";
  ok(!$im, "should fail to get screenshot");
  cmp_ok(Imager->errstr, '=~', 'BadWindow',
         "check error");
}


{ # try our subimage options
  my $im = screenshot(display => $display, id => 0, 
		      left => 70, top => 30, right => -35, bottom => -17);
  ok($im, "call with left, top, etc");

  # make sure tags set as expected
  is($im->tags(name => 'ss_left'), 70, "check left value");
  is($im->tags(name => 'ss_top'), 30, "check top value");
  is($im->tags(name => 'ss_type'), 'X11', "check ss_type");
  is($im->tags(name => 'ss_window_width'), 70 + $im->getwidth + 35,
     "check image width against window size");
  is($im->tags(name => 'ss_window_height'), 30 + $im->getheight + 17,
     "check image height against window size");
}

Imager::Screenshot::x11_close($display);
