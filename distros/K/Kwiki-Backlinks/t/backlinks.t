use strict;
use warnings;
use Test::More tests => 2;
use Kwiki::Test;

use lib '../lib';

SKIP: {
    eval {require Kwiki::UserPreferences};
    skip 'we need Kwiki::UserPreferences', 2 if $@;
        
    my $kwiki = Kwiki::Test->new->init(['Kwiki::UserPreferences',
        'Kwiki::Backlinks']);

    # XXX hooks don't get called unless we do this?
    # very strange. Presumably the hooking is not fully
    # registered until after another read of the registry?
    $kwiki = Kwiki::Test->new;
    $kwiki->add_plugins(['Kwiki::UserPreferences', 'Kwiki::Backlinks']);
    my $backlinks = $kwiki->hub->backlinks;
    my $pages = $kwiki->hub->pages;

    # create a new page linking to HomePage
    {
        my $page = $pages->new_from_name('BacklinkSampler');
        $page->content(
            "\nWe link to HomePage because we can\n\nShouldn't you?\n\n"
        );
        $page->store;
    }

    # look for the backlinks by method
    {
        my @backlinks = $backlinks->get_backlinks_for_page('HomePage');

        is($backlinks[0], 'BacklinkSampler',
            "HomePage has a BacklinkSampler backlink");
    }

    # look in the output
    {
        my $display = $kwiki->hub->display;
        $pages->current($pages->new_from_name('HomePage'));
        my $output = $display->display;

        like($output, 
            '/BEGIN backlinks.*BacklinkSampler<\/a>.*END backlinks/s',
            "output has backlinks");
    }

    $kwiki->cleanup;
}
