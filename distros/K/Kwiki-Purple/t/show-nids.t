use strict;
use warnings;
use Test::More tests => 4;
use Kwiki::Test;

use lib '../lib';

# so init in Kwiki::Purple is followed
$ENV{GATEWAY_INTERFACE} = 1;

my $kwiki = Kwiki::Test->new->init(['Kwiki::Purple::Sequence',
    'Kwiki::Purple']);

# do it again to active hooks
$kwiki = Kwiki::Test->new;
$kwiki->add_plugins(['Kwiki::Purple::Sequence', 'Kwiki::Purple']);
my $pages = $kwiki->hub->pages;

# store a page
{
    my $page = $pages->new_from_name('PurplePage');
    $page->content("\n\n== This is header one\n\nThis is paragraph two\n\n" .
        "* this is list one\n* this is list two\n\n");
    $page->store;
}

# check the formatted it for nids
{
    my $page = $pages->new_from_name('PurplePage');
    my $content = $page->to_html;

    # this extra space before the non breaking space is a 
    # less than good thing...but is necessary for the time
    # being for a variety of reasons
    like($content,
        qr{<h2 id="nid1">This is header one &nbsp;<a class="nid" href="#nid1">1</a></h2>},
        'header has nid 1');
    like($content, qr{<p id="nid2">This is paragraph two &nbsp;<a class="nid" href="#nid2">2</a></p>},
        'paragraph has nid 2');
    like($content, qr{<li id="nid3">this is list one &nbsp;<a class="nid" href="#nid3">3</a></li>},
        'list one has nid 3');
    like($content, qr{<li id="nid4">this is list two &nbsp;<a class="nid" href="#nid4">4</a></li>},
        'list one has nid 4');
}

$kwiki->cleanup;
