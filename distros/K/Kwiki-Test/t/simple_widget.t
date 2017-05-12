use Kwiki::Test;
use Test::More tests => 2;

# relative to test install dir
use lib '../t/lib';

my $kwiki = Kwiki::Test->new->init(['Kwiki::SimpleWidget']);

my $display = $kwiki->hub->display;
my $pages = $kwiki->hub->pages;

my $page = $pages->new_from_name('HomePage');
$pages->current($page);

my $output = $display->display;

isnt($output, '', "we got some output");
like($output, qr{Simple Widget Is Gonna Get You Every Time},
    "output contains widget text");

$kwiki->cleanup;
