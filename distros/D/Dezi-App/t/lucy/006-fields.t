#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 18;
use Data::Dump qw( dump );
use Search::Tools::UTF8;

#binmode Test::More->builder->output,         ":utf8";
#binmode Test::More->builder->failure_output, ":utf8";

use_ok('Dezi::App');
use_ok('Dezi::Lucy::InvIndex');
use_ok('Dezi::Lucy::Searcher');

ok( my $invindex = Dezi::Lucy::InvIndex->new(
        clobber => 0,                     # Lucy handles this
        path    => 't/lucy/dezi.index',
    ),
    "new invindex"
);

my $program = make_program();

ok( $program->run('t/lucy/fields.xml'), "run program" );

is( $program->count, 1, "indexed test docs" );

ok( my $searcher = Dezi::Lucy::Searcher->new(
        invindex             => $invindex,
        find_relevant_fields => 1,
    ),
    "new searcher"
);

# case-sensitive search
ok( my $results = $searcher->search('GLOWER'), "search()" );

#diag( dump $results );

is( $results->hits, 1, "1 hit" );

ok( my $result = $results->next, "next result" );

#diag( dump $result->property_map );

is( $result->uri, 't/lucy/fields.xml', 'get uri' );

is( $result->relevant_fields->[0],
    "tokenizecasesensitive", "relevant field == tokenizecasesensitive" );

# test partial match against stored-only field
#diag( dump $searcher );
ok( $results = $searcher->search('bar:small'),
    "search in non-tokenized field" );
is( $results->hits, 0, "no hits" );

#show_results_by_uri($results);

# multi-value fields
ok( $results = $searcher->search('multivaluestore:"Chinese restaurants"'),
    "multi-value field search" );
is( $results->hits, 1, "1 multivalue hit" );
is_deeply(
    $results->next->get_property_array('multivaluestore'),
    [ 'Chinese restaurants', 'Russian bars' ],
    "multi-value store is case sensitive"
);

###################################
## helper functions

sub make_program {
    ok( my $program = Dezi::App->new(
            invindex     => $invindex,
            aggregator   => 'fs',
            indexer      => 'lucy',
            config       => 't/lucy/fields.conf',
            indexer_opts => { highlightable_fields => 1, },

            #verbose    => 1,
            #debug      => 1,
        ),
        "new program"
    );

    # skip the index dir every time
    # the '1' arg indicates to append the value, not replace.
    $program->config->FileRules( 'dirname is dezi.index',                1 );
    $program->config->FileRules( 'filename is config.xml',               1 );
    $program->config->FileRules( 'filename is config-nostemmer.xml',     1 );
    $program->config->FileRules( 'filename contains \.t',                1 );
    $program->config->FileRules( 'filename is test.html',                1 );
    $program->config->FileRules( 'filename is test.xml',                 1 );
    $program->config->FileRules( 'dirname contains (testindex|\.index)', 1 );
    $program->config->FileRules( 'filename contains \.conf',             1 );
    $program->config->FileRules( 'dirname contains mailfs',              1 );

    return $program;
}

sub show_results_by_uri {
    my ($results) = @_;
    while ( my $r = $results->next ) {
        diag( $r->uri );
    }
}

END {
    unless ( $ENV{DEZI_DEBUG} ) {
        $invindex->path->rmtree;
    }
}
