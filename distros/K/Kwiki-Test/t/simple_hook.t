use Kwiki::Test;
use Test::More tests => 3;

# relative to test install dir
use lib '../t/lib';

my $kwiki = Kwiki::Test->new->init(['Kwiki::SimpleHook']);

# create a page and store it
{
    my $pages = $kwiki->hub->pages;
    my $page = $pages->new_from_name('TestPage');

    $page->content("This is our content\n\n");
    $page->store;
}

# check for hook's edits
{
    my $pages = $kwiki->hub->pages;
    my $page = $pages->new_from_name('TestPage');
    
    ok($page->exists, "page exists");
    isnt($page->content, '', "page has content");

    like($page->content, qr{Simple Hook Hooks Again},
        "page has right content");
}

$kwiki->cleanup;
