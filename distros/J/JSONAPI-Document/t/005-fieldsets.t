#! perl -w

use lib 't/lib';

use Test::Most;
use Test::JSONAPI;

my $t = Test::JSONAPI->new({ api_url => 'http://example.com/api' });

my $post = $t->schema->resultset('Post')->find(1);

is_deeply(
    $t->resource_document($post, { fields => [qw/title/] }),
    {
        id         => 1,
        type       => 'posts',
        attributes => {
            title => 'Intro to JSON API',
        }
    },
    'resource with sparse fieldset'
);

is_deeply(
    $t->resource_document(
        $post,
        {
            fields          => [qw/title/],
            with_attributes => 1,
            includes        => [qw/comments/],
            related_fields  => {
                comments => [qw/likes/] } }
    ),
    {
        id         => 1,
        type       => 'posts',
        attributes => {
            title => 'Intro to JSON API',
        },
        relationships => {
            comments => {
                data => [{
                        id         => 1,
                        type       => 'comments',
                        attributes => {
                            likes => 2,
                        },
                    },
                    {
                        id         => 2,
                        type       => 'comments',
                        attributes => {
                            likes => 4,
                        },
                    },
                ],
            },
        },
    },
    'resource with relationships that have sparse fieldsets'
);

is_deeply(
    $t->resource_documents(
        $t->schema->resultset('Comment'),
        {
            fields => [qw/likes/]
        },
    ),
    {
        data => [{
                id         => 1,
                type       => 'comments',
                attributes => {
                    likes => 2,
                },
            },
            {
                id         => 2,
                type       => 'comments',
                attributes => {
                    likes => 4,
                },
            },
        ]
    },
    'resource documents can read the sparse fieldset option'
);

done_testing;
