#!perl -w
use strict;
use Win32::API;
use Imager;
use Imager::Screenshot 'screenshot';

# delay so I can bring the window to the front
sleep 2;

# get the API
my $find_window = Win32::API->new('user32', 'FindWindowA', 'NP', 'N')
  or die "Cannot import FindWindow\n";

# get the window, this requires an exact match on the window title
my $hwnd = $find_window->Call(0, "use Perl: All the Perl that's Practical to Extract and Report - Mozilla Firefox");

$hwnd 
  or die "Mozilla window not found";

# take a picture, including the border and title bar
my $img = screenshot(hwnd => $hwnd, decor=>1)
  or die Imager->errstr;

# and save it
$img->write(file=>'mozilla.ppm')
  or die $img->errstr;

