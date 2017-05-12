use Kwiki::Test;
use Test::More tests => 7;

my $kwiki = Kwiki::Test->new->init;
my $hub = $kwiki->hub;

# make sure we can do normal operations on pages
{
    my $pages = $hub->pages;
    my $page = $pages->new_from_name('HomePage');
    
    ok($page->exists, "page exists");
    isnt($page->content, '', "page has content");
    is($page->uri, 'HomePage', "page has correct uri");
}

# edit pages
{
    my $pages = $hub->pages;
    my $page = $pages->new_from_name('HomePage');
    
    ok($page->exists, "page exists");
    isnt($page->content, '', "page has content");

    $page->content("== Our new content\n\nIs the best\n");
    $page->store;

    $page = $pages->new_from_name('HomePage');
    like($page->content, qr{== Our new content}, "page has right content");

    my $html = $page->to_html;
    like($html, qr{<h2>Our new content</h2>}, "page formats to html");
}


$kwiki->cleanup;
