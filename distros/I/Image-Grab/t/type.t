print "1..1\n";
use Image::Grab;
use Cwd;

my $image = new Image::Grab;

my $pwd = cwd;
$ENV{DOMAIN} ||= "example.com"; # Net::Domain warnings
$image->url("file:" . $pwd . "/t/data/perl.gif");

$image->grab;

if($image->type eq "image/gif"){
   print "ok 1\n";
} else {
   print "not ok 1\n";
}

