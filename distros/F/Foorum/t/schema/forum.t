#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => 'DBD::SQLite is required for this test';
    $ENV{TEST_FOORUM} = 1;
    plan tests => 18;
}

use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );
use Foorum::SUtils qw/schema/;
use Foorum::XUtils qw/cache/;
use Foorum::TestUtils qw/rollback_db/;
use Foorum::Utils qw/encodeHTML/;
my $schema = schema();
my $cache  = cache();

my $forum_res = $schema->resultset('Forum');

# create a new forum
$forum_res->create(
    {   forum_id      => 1,
        forum_code    => 'test1111',
        name          => 'FoorumTest',
        description   => 'desc',
        forum_type    => 'classical',
        policy        => 'public',
        total_members => 1
    }
);
$schema->resultset('ForumSettings')->create(
    {   forum_id => 1,
        type     => 'can_post_threads',
        value    => 'N',
    }
);
$schema->resultset('ForumSettings')->create(
    {   forum_id => 1,
        type     => 'create_time',
        value    => '123456',
    }
);
$cache->remove('forum|forum_id=1');

# test get
my $forum  = $forum_res->get(1);            # by forum_id;
my $forum2 = $forum_res->get('test1111');
is_deeply( $forum, $forum2, 'get by forum_id and forum_code is the same' );
is( $forum->{forum_type}, 'classical',       'forum_type OK' );
is( $forum->{policy},     'public',          'policy OK' );
is( $forum->{name},       'FoorumTest',      'name OK' );
is( $forum->{forum_url},  '/forum/test1111', 'forum_url OK' );

# test forum_settings
is( $forum->{settings}->{can_post_threads},
    'N', 'settings can_post_threads OK' );
is( $forum->{settings}->{create_time},
    undef, 'by default, we do NOT get create_time forum settings' );

# test update
$forum_res->update_forum( 1,
    { name => 'FoorumTest2', forum_code => 'test2222' } );
$forum  = $forum_res->get(1);            # by forum_id;
$forum2 = $forum_res->get('test2222');
is_deeply( $forum, $forum2,
    'get by forum_id and forum_code is the same after update_forum' );
is( $forum->{name}, 'FoorumTest2', 'name OK after update_forum' );
is( $forum->{forum_url}, '/forum/test2222',
    'forum_url OK after update_forum' );

# test remove
$forum_res->remove_forum(1);
my $count = $forum_res->count( { forum_id => 1 } );
is( $count, 0, 'remove OK' );

# test validate_forum_code
my $st = $forum_res->validate_forum_code('5char');
is( $st, 'LENGTH', '5char breaks' );
$st = $forum_res->validate_forum_code('22charsabcdefghijklmno');
is( $st, 'LENGTH', '22chars breaks' );
$st = $forum_res->validate_forum_code('a cdddef');
is( $st, 'HAS_BLANK', 'HAS_BLANK' );
$st = $forum_res->validate_forum_code('a$b@dge');
is( $st, 'REGEX', 'REGEX' );
$st = $forum_res->validate_forum_code('1234567');
is( $st, 'REGEX', 'all num breaks' );

$schema->resultset('FilterWord')->create(
    {   word => 'faylandlam',
        type => 'forum_code_reserved'
    }
);
$cache->remove('filter_word|type=forum_code_reserved');

$st = $forum_res->validate_forum_code('FaylandLam');
is( $st, 'HAS_RESERVED', 'HAS_RESERVED' );
my $v_forum_code = 'faylandforever';
$forum_res->create(
    {   forum_id      => 123,
        forum_code    => $v_forum_code,
        name          => 'FoorumTest',
        description   => 'desc',
        forum_type    => 'classical',
        policy        => 'public',
        total_members => 1
    }
);
$st = $forum_res->validate_forum_code($v_forum_code);
is( $st, 'DBIC_UNIQUE', 'DBIC_UNIQUE' );

END {

    # Keep Database the same from original
    rollback_db();
}

1;
