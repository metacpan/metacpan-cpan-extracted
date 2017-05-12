use strict;
use Image::Grab qw(grab);
use Cwd;
use Test::Simple tests => 2;

my $pwd = cwd;
$ENV{DOMAIN} ||= "example.com"; # Net::Domain warnings
my $image = Image::Grab->grab(URL=>"file://" . $pwd . "/t/data/perl.gif");

ok(defined $image);

my $image2 = grab(URL=>"file://" . $pwd . "/t/data/perl.gif");
ok(defined $image2);
