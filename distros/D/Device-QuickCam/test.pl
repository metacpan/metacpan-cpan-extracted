#!/usr/bin/perl
use Test;
BEGIN { plan tests => 1 };
use Device::QuickCam;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $cam = Device::QuickCam->new();
$cam->set_debug(1);
$cam->set_quality(50);
$cam->set_bpp(24);
$cam->set_width(320);
$cam->set_height(240);
for(1..10)
{ $cam->set_file("foo-$_.jpg");
  $cam->grab();
}