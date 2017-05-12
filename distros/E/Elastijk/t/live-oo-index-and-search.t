#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

unless ($ENV{TEST_LIVE}) {
    plan skip_all => "Set env TEST_LIVE=1 to run this test."
}


use Elastijk;

my $res;
my $test_index_name = "test_index_$$".rand();

my $es = Elastijk->new(
    host => 'localhost',
    port => '9200',
    index => $test_index_name,
);


## create the index, and index some documents.
$res = $es->put(
    index => $test_index_name,
    body => {
        settings => {
            index => {
                number_of_replicas => 0,
                number_of_shards => 1
            }
        },
        mappings => {
            cafe => {
                properties => {
                    name => { type => "string" },
                    address => { type => "string" }
                }
            }
        }
    }
);
ok $es->exists( index => $test_index_name ), "The newly created index doe exist.";

subtest "index 2 documents" => sub {
    my $sources = [{
        name => "autumn",
        address => "No. 42, leaf road.",
    },{
        name => "ink",
        address => "No. 42, black street.",
    }];

    $res = $es->bulk(
        type => "cafe",
        body => [ map {({index=>{}}, $_)} @$sources ]
    );

    is ref($res), 'HASH';
    is ref($res->{items}), 'ARRAY';

    for(my $i = 0; $i < @$sources; $i++) {
        my $source = $sources->[$i];
        my ($action, $res2) = (%{$res->{items}[$i]});
        is $action, 'create';
        my $res3 = $es->get( type => "cafe", id => $res2->{_id} );
        is_deeply($res3->{_source}, $source);
    }
};

subtest "index then count" => sub {
    my $sources = [{
        name => "autumn",
        address => "No. 42, leaf road.",
    },{
        name => "ink",
        address => "No. 42, black street.",
    }];

    my $res = $es->bulk(
        index => $test_index_name,
        type => "cafe",
        body => [ map {({index=>{}}, $_)} @$sources ]
    );

    $res = $es->count(index => $test_index_name);
    is ref($res), '', "count = $res";
    ok($res >= 0);
};


subtest "index a single document, then get it." => sub {
    my $source = {
        name => "daily",
        address => "No. 42, routine road. " . rand(),
    };

    my $res = $es->index(
        type  => "cafe",
        body  => $source
    );

    is ref($res), 'HASH';
    my $id = $res->{_id};
    ok defined($id), "the new document id is found.";

    $res = $es->get( type => "cafe", id => $id );
    is_deeply($res->{_source}, $source, "The _source match our original document.");
};

subtest "index 2 documents with the value of 'type' attribute in the object." => sub {
    my $es = Elastijk->new(
        host => 'localhost',
        port => '9200',

        index => $test_index_name,
        type => "cafe",
    );

    pass ref($es);

    my $sources = [{
        name => "where",
        address => "No. 42, that road.",
    },{
        name => "leave",
        address => "No. 42, the street.",
    }];

    $res = $es->bulk(body => [map {( {index => {}}, $_ )} @$sources]);

    is ref($res), 'HASH';
    is ref($res->{items}), 'ARRAY';

    for(my $i = 0; $i < @$sources; $i++) {
        my $source = $sources->[$i];
        my ($action, $res2) = (%{$res->{items}[$i]});
        is $action, 'create';
        my $res3 = $es->get( type => "cafe", id => $res2->{_id} );
        is_deeply($res3->{_source}, $source);
    }
};

# done testing. delete the index.
$es->delete( index => $test_index_name );

done_testing;
