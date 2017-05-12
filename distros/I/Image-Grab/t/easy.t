use Image::Grab;
use Cwd;
print "1..1\n";
my $image = new Image::Grab;

my $pwd = cwd;
$ENV{DOMAIN} ||= "example.com"; # Net::Domain warnings
$image->url("file:" . $pwd . "/t/data/perl.gif");

if(defined $image->grab){
  print "ok 1\n";
} else {
  print "not ok 1\n";
}
