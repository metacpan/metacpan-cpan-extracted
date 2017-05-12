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
use Foorum::TestUtils qw/rollback_db/;

my $schema = schema();

use Foorum::Search;

my $search = new Foorum::Search;

#######################################
# Test with Foorum::Search::Database
#######################################

# use database
$search->{sphinx}       = undef;
$search->{use_sphinx}   = 0;
$search->{db}->{schema} = $schema;

# insert data first
my $create = {
    topic_id        => 1,
    forum_id        => 1,
    title           => 'test title',
    closed          => 0,
    author_id       => 1,
    last_updator_id => 1,
};
$schema->resultset('Topic')->create_topic($create);
$create = {
    topic_id        => 2,
    forum_id        => 2,
    title           => 'test again',
    closed          => 0,
    author_id       => 1,
    last_updator_id => 2,
};
$schema->resultset('Topic')->create_topic($create);

my $ret = $search->query( 'topic', { author_id => 1 } );
is( $ret->{error},                undef, '[0]no error in database' );
is( scalar @{ $ret->{matches} },  2,     '[0]get 2 results' );
is( $ret->{pager}->total_entries, 2,     '[0]pager OK' );

$ret = $search->query( 'topic', { title => 'test' } );
is( $ret->{error},                undef, '[1]no error in database' );
is( scalar @{ $ret->{matches} },  2,     '[1]get 2 results' );
is( $ret->{pager}->total_entries, 2,     '[1]pager OK' );

$ret = $search->query( 'topic', { author_id => 1, forum_id => 1 } );
is( $ret->{error},                undef, '[2]no error in database' );
is( scalar @{ $ret->{matches} },  1,     '[2]get 1 results' );
is( $ret->{pager}->total_entries, 1,     '[2]pager OK' );

END {

    # Keep Database the same from original
    rollback_db();
}

#######################################
# XXX? TODO, Test with Foorum::Search::Sphinx
#######################################

1;
