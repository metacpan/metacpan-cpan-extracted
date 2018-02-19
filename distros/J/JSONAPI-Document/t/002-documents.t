#! perl -w

use lib 't/lib';

use Test::Most;
use Test::JSONAPI;

my $t = Test::JSONAPI->new();

ok($t->can('resource_document'), 'provides resource_document method');
ok($t->can('resource_documents'), 'provides resource_documents method');
ok($t->can('compound_resource_document'), 'provides compound_resource_document method');

my $post = $t->schema->resultset('Post')->find(1);

is_deeply($t->resource_document($post, { with_relationships => 1 }), {
    id => 1,
    type => 'posts',
    attributes => {
        author_id => 1,
        description => 'This is a Perl transformer for the JSON API specification',
        title => 'Intro to JSON API Role',
    },
    relationships => {
        author => {
            data => { type => 'authors', id => 1, }
        },
        comments => {
            data => [
                { type => 'comments', id => 1, },
                { type => 'comments', id => 2, },
            ]
        }
    }
}, 'created document with relationships');

is_deeply(
    $t->compound_resource_document($post),
    {
        data => [{
            id => 1,
            type => 'posts',
            attributes => {
                author_id => 1,
                description => 'This is a Perl transformer for the JSON API specification',
                title => 'Intro to JSON API Role',
            },
            relationships => {
                author => {
                    data => { type => 'authors', id => 1, }
                },
                comments => {
                    data => [
                        { type => 'comments', id => 1, },
                        { type => 'comments', id => 2, },
                    ]
                }
            }
        }],
        included => [
            {
                type => 'authors',
                id => 1,
                attributes => {
                    name => 'John Doe',
                    age => 28,
                },
            },
            {
                type => 'comments',
                id => 1,
                attributes => {
                    author_id => 1,
                    post_id => 1,
                    description => 'This is a really good post',
                    likes => 2,
                },
            },
            {
                type => 'comments',
                id => 2,
                attributes => {
                    author_id => 1,
                    post_id => 1,
                    description => 'Another really good post',
                    likes => 4,
                },
            },
        ]
    },
    'compound document structure');

is_deeply(
    $t->resource_documents($t->schema->resultset('Comment')),
    {
        data => [
            {
                type => 'comments',
                id => 1,
                attributes => {
                    author_id => 1,
                    post_id => 1,
                    description => 'This is a really good post',
                    likes => 2,
                },
            },
            {
                type => 'comments',
                id => 2,
                attributes => {
                    author_id => 1,
                    post_id => 1,
                    description => 'Another really good post',
                    likes => 4,
                },
            },
        ]
    },
    'resource documents');

done_testing;
