#!perl -w
use strict;
use Test::More;

use Imager::Screenshot 'screenshot';

++$|;

Imager::Screenshot->have_darwin
  or plan skip_all => "No darwin support";

my $im = screenshot(darwin => 0, right => 1, bottom => 1);
unless ($im) {
  my $err = Imager->errstr;
  $err =~ /No pixel format found/
    or plan skip_all => "Probably an inactive user";
  $err =~ /No main display/
    or plan skip_all => "User doen't have a display";
}

plan tests => 8;

{
  my $im = screenshot(darwin => 0);
  ok($im, "got an image");

  my $variant = $im->tags(name => "ss_variant");
 SKIP:
  {
    # only the older version guarantees 3 channels
    $variant eq "<11"
      or skip "we can't be sure how many channels Lion returns", 1;
    is($im->getchannels, 3, "we have some color");
  }

  like($variant, qr/^(<11|11\+)$/, "check ss_variant tag");
  is($im->tags(name => "ss_window_width"), $im->getwidth,
     "check ss_window_width tag");
  is($im->tags(name => 'ss_window_height'), $im->getheight,
     "check ss_window_height tag");
  is($im->tags(name => 'ss_left'), 0, "check ss_left tag");
  is($im->tags(name => 'ss_top'), 0, "check ss_top tag");
  is($im->tags(name => 'ss_type'), 'Darwin', "check ss_type tag");
}
