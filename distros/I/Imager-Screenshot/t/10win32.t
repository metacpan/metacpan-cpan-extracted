#!perl -w
use strict;
use Test::More;

# you might be looking at this test code and wondering why it doesn't
# try to check the images themselves - the reason is that in many
# cases the build and tests are being done in an automated build, and
# it may be possible that the user is running a screensaver, which
# will be what's returned instead of what we expect.
#
# this applies for the sub-image tests too, since the screen saver may
# have changed the screen between the two grabs

use Imager::Screenshot 'screenshot';

Imager::Screenshot->have_win32
    or plan skip_all => "No Win32 support";

plan tests => 15;

{
  my $im = screenshot(hwnd => 0);
  
  ok($im, "got a screenshot");

  # check the size matches the tags
  is($im->tags(name => 'ss_window_width'), $im->getwidth,
     "check ss_window_width tag");
  is($im->tags(name => 'ss_window_height'), $im->getheight,
     "check ss_window_height tag");
  is($im->tags(name => 'ss_left'), 0, "check ss_left tag");
  is($im->tags(name => 'ss_top'), 0, "check ss_top tag");
  is($im->tags(name => 'ss_type'), 'Win32', "check ss_type tag");
}

{ # as a method
  my $im = Imager::Screenshot->screenshot(hwnd => 0);

  ok($im, "call as a method");
}

{ # try our subimage options
  my $im = screenshot(hwnd => 0, left => 70, top => 30, 
		      right => -35, bottom => -17);
  ok($im, "call with left, top, etc");

  # make sure tags set as expected
  is($im->tags(name => 'ss_left'), 70, "check left value");
  is($im->tags(name => 'ss_top'), 30, "check top value");
  is($im->tags(name => 'ss_type'), 'Win32', "check ss_type");
  is($im->tags(name => 'ss_window_width'), 70 + $im->getwidth + 35,
     "check image width against window size");
  is($im->tags(name => 'ss_window_height'), 30 + $im->getheight + 17,
     "check image height against window size");
}

{ # full multi-monitor desktop
  my $im = screenshot(hwnd => 0, monitor => -1);
  ok($im, "full desktop");
  is($im->getchannels, 4, "should have an alpha channel");
}
