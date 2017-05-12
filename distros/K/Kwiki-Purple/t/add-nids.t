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

# check it for nids
{
    my $page = $pages->new_from_name('PurplePage');
    my $content = $page->content;

    like($content, qr/== This is header one {nid 1}/,
        'header has nid 1');
    like($content, qr/This is paragraph two {nid 2}/,
        'paragraph has nid 2');
    like($content, qr/\* this is list one {nid 3}/,
        'list one has nid 3');
    like($content, qr/\* this is list two {nid 4}/,
        'list one has nid 4');
}

$kwiki->cleanup;
