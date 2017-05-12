use Kwiki::Test;
use Test::More tests => 6;
use Spiffy;

# relative to test install dir
use lib '../t/lib';
use lib '../lib';

my $kwiki = Kwiki::Test->new->init(['Kwiki::PageStats']);
my $count = 0;

test_it();
test_it();
test_it();

$kwiki->cleanup;

sub test_it {
    $count++;

    my $display = $kwiki->hub->display;
    my $pages = $kwiki->hub->pages;

    my $page = $pages->new_from_name('HomePage');
    $pages->current($page);
    my $output = $display->display;
    isnt($output, '', "we got some output");
    like($output, qr{$count hits? since}, "output contains $count hits text");

    # XXX this is to make sure we have a different Template Stash next
    # time through
    $kwiki = Kwiki::Test->new;
    $kwiki->add_plugins(['Kwiki::PageStats']);
}

