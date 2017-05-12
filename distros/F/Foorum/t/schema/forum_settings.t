#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => 'DBD::SQLite is required for this test';
    $ENV{TEST_FOORUM} = 1;
    plan tests => 9;
}

use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );
use Foorum::SUtils qw/schema/;
use Foorum::XUtils qw/cache/;
use Foorum::TestUtils qw/rollback_db/;
my $schema = schema();
my $cache  = cache();

my $forum_settings_res = $schema->resultset('ForumSettings');

# create a new forum
$forum_settings_res->create(
    {   forum_id => 1,
        type     => 'can_post_threads',
        value    => 'N',
    }
);
$forum_settings_res->create(
    {   forum_id => 2,
        type     => 'can_post_threads',
        value    => 'Y',
    }
);
$forum_settings_res->create(
    {   forum_id => 1,
        type     => 'create_time',
        value    => '123456',
    }
);
$forum_settings_res->create(
    {   forum_id => 1,
        type     => 'forum_link1',
        value    => 'http://www.fayland.org/ Fayland',
    }
);
$forum_settings_res->create(
    {   forum_id => 1,
        type     => 'forum_link2',
        value    => 'http://www.foorumbbs.com/ FoorumBBS site',
    }
);

$cache->remove('forum_settings|forum_id=1');

# get_all
my $settings = $forum_settings_res->get_all(1);
is( scalar keys %$settings, 4, 'get 4 settings' );
is_deeply(
    $settings,
    {   can_post_threads => 'N',
        create_time      => 123456,
        forum_link1      => 'http://www.fayland.org/ Fayland',
        forum_link2      => 'http://www.foorumbbs.com/ FoorumBBS site'
    },
    'get_all OK'
);

$settings = $forum_settings_res->get_basic(1);
is( $settings->{can_post_threads}, 'N', 'can_post_threads is N' );
is( $settings->{can_post_replies}, 'Y', 'can_post_replies is Y by default' );

my @links = $forum_settings_res->get_forum_links(1);
is( scalar @links,     2,                           'get 2 links' );
is( $links[0]->{url},  'http://www.fayland.org/',   'get_forum_links 1 OK' );
is( $links[1]->{url},  'http://www.foorumbbs.com/', 'get_forum_links 2 OK' );
is( $links[0]->{text}, 'Fayland',                   'get_forum_links 3 OK' );
is( $links[1]->{text}, 'FoorumBBS site',            'get_forum_links 4 OK' );

END {

    # Keep Database the same from original
    rollback_db();
}

1;
