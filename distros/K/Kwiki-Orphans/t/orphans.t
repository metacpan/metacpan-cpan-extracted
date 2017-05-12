use strict;
use warnings;
use Test::More tests => 4;
use Kwiki::Test;

use lib '../lib';

my $kwiki;

SKIP: {
    eval {require Kwiki::Test};
    skip 'we need Kwiki::Test', 2 if $@;
        
    $kwiki = Kwiki::Test->new->init(['Kwiki::UserPreferences',
        'Kwiki::Backlinks', 'Kwiki::Orphans']);

    # XXX hooks don't get called unless we do this?
    # very strange. Presumably the hooking is not fully
    # registered until after another read of the registry?
    $kwiki = Kwiki::Test->new;
    $kwiki->add_plugins(['Kwiki::UserPreferences', 'Kwiki::Backlinks',
        'Kwiki::Orphans']);
    my $orphans = $kwiki->hub->orphans;
    my $pages = $kwiki->hub->pages;
    my $backlinks = $kwiki->hub->backlinks;

    # create a new page linking to HomePage
    {
        my $page = $pages->new_from_name('BacklinkSampler');
        $page->content(
            "\nWe link to HomePage because WeCan\n\nShouldn't you?\n\n"
        );
        $page->store;
    }

    {
        my $orphan_pages = $orphans->get_orphaned_pages;

        my @backlinks = $backlinks->get_backlinks_for_page('BacklinkSampler');

        ok(scalar(@backlinks) == 0, 'no backlinks for BacklinkSampler');
        ok(grep(/^BacklinkSampler$/, map {$_->id} @$orphan_pages),
            "The orphan pages contains BacklinkSampler");
    }

    {
        my $incipient_pages = $orphans->get_incipient_pages;

        ok(grep(/^WeCan$/, map {$_->id} @$incipient_pages),
            "The incipient pages contains WeCan");
    }

    {
        my @calling_pages = $backlinks->get_backlinks_for_page('WeCan');

        ok(grep(/^BacklinkSampler$/, @calling_pages),
            "The WeCan page has a caller of BacklinkSampler");
    }


}

sub END {
    $kwiki->cleanup;
}
