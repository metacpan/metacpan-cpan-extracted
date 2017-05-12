#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dump qw( dump );
use File::Temp qw( tempdir );
my $invindex = tempdir( CLEANUP => 1 );

use Lucy;

use_ok('LucyX::Search::AnyTermQuery');
use_ok('LucyX::Search::NullTermQuery');

my $case_folder = Lucy::Analysis::CaseFolder->new;
my $tokenizer   = Lucy::Analysis::RegexTokenizer->new;
my $analyzer    = Lucy::Analysis::PolyAnalyzer->new(
    analyzers => [ $case_folder, $tokenizer, ], );

my $schema   = Lucy::Plan::Schema->new;
my $fulltext = Lucy::Plan::FullTextType->new(
    analyzer => $analyzer,
    sortable => 1,
);
my $fulltext_nosort = Lucy::Plan::FullTextType->new(
    analyzer => $analyzer,
    sortable => 0,
);
$schema->spec_field( name => 'uri',       type => $fulltext );
$schema->spec_field( name => 'nullfield', type => $fulltext );
$schema->spec_field( name => 'title',     type => $fulltext );
$schema->spec_field( name => 'color',     type => $fulltext_nosort );
$schema->spec_field( name => 'date',      type => $fulltext );
$schema->spec_field( name => 'option',    type => $fulltext_nosort );

my $indexer = Lucy::Index::Indexer->new(
    index    => $invindex,
    schema   => $schema,
    create   => 1,
    truncate => 1,
);

my %docs = (
    'doc1' => {
        title  => 'Acute-Phase Reaction',
        color  => 'red blue orange',
        date   => '20100329',
        option => 'a',
    },
    'doc2' => {
        title  => 'Leukemia, Biphenotypic, Acute',
        color  => 'green yellow purple',
        date   => '20100301',
        option => 'b',
    },
    'doc3' => {
        title  => 'Leukemia, Megakaryoblastic, Acute',
        color  => 'brown black white',
        date   => '19720329',
        option => '',
    },
    'doc4' => {
        title  => 'Porphyria, Acute Intermittent',
        color  => '',
        date   => '20100510',
        option => 'c',
    },
    'doc5' => {
        title  => '',
        color  => 'white',
        date   => '20100510',
        option => 'e',
    },
    'doc6' => {
        title  => 'Acute Kidney Injury',
        color  => 'teal',
        date   => '19000101',
        option => 'd',
    },
);

# set up the index
for my $doc ( keys %docs ) {
    my $doc_ref = { %{ $docs{$doc} }, uri => $doc };

    #diag( dump $doc_ref );
    $indexer->add_doc($doc_ref);
}

$indexer->commit;

my $searcher = Lucy::Search::IndexSearcher->new( index => $invindex, );

# search
my %queries = (
    'color:NULL'     => 1,
    'color!:NULL'    => 5,
    'option:NULL'    => 1,
    'title!:NULL'    => 5,    # this and next should parse identically
    'NOT title:NULL' => 5,
    'nullfield:NULL' => 6,
);

for my $str ( sort keys %queries ) {
    my $query = make_query($str);

    my $hits_expected = $queries{$str};
    if ( ref $hits_expected ) {
        $query->debug(1);
        $hits_expected = $hits_expected->[0];
    }

    #diag($query);
    my $hits = $searcher->hits(
        query      => $query,
        offset     => 0,
        num_wanted => 10,       # more than we have
    );

    is( $hits->total_hits, $hits_expected, "$str == $hits_expected" );

    if ( $hits->total_hits != $hits_expected ) {
        diag( dump( $query->dump ) );

        my $count = 0;
        while ( my $hit = $hits->next ) {
            $count++;
            diag( " [$count] hit: " . $hit->{uri} );
        }
    }

}

# allow for adding new queries without adjusting test count
done_testing( scalar( keys %queries ) + 2 );

sub make_query {
    my $str = shift;

    my ( $field, $op ) = ( $str =~ m/(\w+)(!?:)NULL/ );

    #diag("field == \'$field\'  op=$op");
    my $query;
    if ( $op eq '!:' or $str =~ m/^NOT/ ) {
        $query = LucyX::Search::AnyTermQuery->new( field => $field, );
    }
    else {
        $query = LucyX::Search::NullTermQuery->new( field => $field, );
    }
    return $query;
}
