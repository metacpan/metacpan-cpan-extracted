use Image::Grab;
use Cwd;
use Test::Simple tests => 1;

my $page = new Image::Grab;
my $pwd = cwd;

$ENV{DOMAIN} ||= "example.com"; # Net::Domain warnings
$page->search_url("file:" . $pwd . "/t/data/bkgrd.html");

my @url = $page->getAllURLs;
ok($url[0] eq "file:" . $pwd . "/t/data/background.jpg");

