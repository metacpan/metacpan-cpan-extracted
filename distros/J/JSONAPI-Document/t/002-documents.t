#! perl -w

use lib 't/lib';

use Test::Most;
use Test::JSONAPI;

my $t = Test::JSONAPI->new({ api_url => 'http://example.com/api' });

ok($t->can('resource_document'),          'provides resource_document method');
ok($t->can('resource_documents'),         'provides resource_documents method');
ok($t->can('compound_resource_document'), 'provides compound_resource_document method');

my $post = $t->schema->resultset('Post')->find(1);

is_deeply(
    $t->resource_document($post),
    {
        id         => 1,
        type       => 'posts',
        attributes => {
            author_id   => 1,
            description => 'This is a Perl transformer for the JSON API specification',
            title       => 'Intro to JSON API',
        },
    },
    'created document'
);

is_deeply(
    $t->resource_document($post, { includes => [qw/author comments/] }),
    {
        id         => 1,
        type       => 'posts',
        attributes => {
            author_id   => 1,
            description => 'This is a Perl transformer for the JSON API specification',
            title       => 'Intro to JSON API',
        },
        relationships => {
            author => {
                links => {
                    self    => 'http://example.com/api/posts/1/relationships/author',
                    related => 'http://example.com/api/posts/1/author'
                },
                data => { type => 'authors', id => 1, }
            },
            comments => {
                links => {
                    self    => 'http://example.com/api/posts/1/relationships/comments',
                    related => 'http://example.com/api/posts/1/comments'
                },
                data => [{ type => 'comments', id => 1, }, { type => 'comments', id => 2, },] } }
    },
    'created document with relationship links'
);

is_deeply(
    $t->compound_resource_document($post),
    {
        data => {
            id         => 1,
            type       => 'posts',
            attributes => {
                author_id   => 1,
                description => 'This is a Perl transformer for the JSON API specification',
                title       => 'Intro to JSON API',
            },
            relationships => {
                author => {
                    links => {
                        self    => 'http://example.com/api/posts/1/relationships/author',
                        related => 'http://example.com/api/posts/1/author'
                    },
                    data => { type => 'authors', id => 1, }
                },
                comments => {
                    links => {
                        self    => 'http://example.com/api/posts/1/relationships/comments',
                        related => 'http://example.com/api/posts/1/comments'
                    },
                    data => [{ type => 'comments', id => 1, }, { type => 'comments', id => 2, },] } }
        },
        included => [{
                type       => 'authors',
                id         => 1,
                attributes => {
                    name => 'John Doe',
                    age  => 28,
                },
            },
            {
                type       => 'comments',
                id         => 1,
                attributes => {
                    author_id   => 1,
                    post_id     => 1,
                    description => 'This is a really good post',
                    likes       => 2,
                },
            },
            {
                type       => 'comments',
                id         => 2,
                attributes => {
                    author_id   => 1,
                    post_id     => 1,
                    description => 'Another really good post',
                    likes       => 4,
                },
            },
        ]
    },
    'compound document structure'
);

is_deeply(
    $t->resource_documents($t->schema->resultset('Comment')),
    {
        data => [{
                type       => 'comments',
                id         => 1,
                attributes => {
                    author_id   => 1,
                    post_id     => 1,
                    description => 'This is a really good post',
                    likes       => 2,
                },
            },
            {
                type       => 'comments',
                id         => 2,
                attributes => {
                    author_id   => 1,
                    post_id     => 1,
                    description => 'Another really good post',
                    likes       => 4,
                },
            },
        ]
    },
    'resource documents'
);

is_deeply(
    $t->compound_resource_document($post, { includes => [qw/author/] }),
    {
        data => {
            id         => 1,
            type       => 'posts',
            attributes => {
                author_id   => 1,
                description => 'This is a Perl transformer for the JSON API specification',
                title       => 'Intro to JSON API',
            },
            relationships => {
                author => {
                    links => {
                        self    => 'http://example.com/api/posts/1/relationships/author',
                        related => 'http://example.com/api/posts/1/author'
                    },
                    data => { type => 'authors', id => 1, }
                },
            }
        },
        included => [{
                type       => 'authors',
                id         => 1,
                attributes => {
                    name => 'John Doe',
                    age  => 28,
                },
            },
        ]
    },
    'compound document structure with includes'
);

is_deeply(
    $t->resource_document($t->schema->resultset('EmailTemplate')->find(1)),
    {
        id         => 1,
        type       => 'email-templates',
        attributes => {
            author_id => 1,
            name      => 'Test Template',
            body      => 'Test template body',
        }
    },
    'resource with dashes'
);

is_deeply(
    $t->resource_document($t->schema->resultset('EmailTemplate')->find(1), { includes => 'all_related' }),
    {
        id         => 1,
        type       => 'email-templates',
        attributes => {
            author_id => 1,
            name      => 'Test Template',
            body      => 'Test template body',
        },
        relationships => {
            author => {
                links => {
                    self    => 'http://example.com/api/email-templates/1/relationships/author',
                    related => 'http://example.com/api/email-templates/1/author'
                },
                data => { type => 'authors', id => 1, }

            } }
    },
    'resource with all related relationships'
);

is_deeply(
    $t->compound_resource_document($post, { includes => [{ author => [qw/email_templates/] }] }),
    {
        data => {
            id         => 1,
            type       => 'posts',
            attributes => {
                author_id   => 1,
                description => 'This is a Perl transformer for the JSON API specification',
                title       => 'Intro to JSON API',
            },
            relationships => {
                author => {
                    links => {
                        self    => 'http://example.com/api/posts/1/relationships/author',
                        related => 'http://example.com/api/posts/1/author'
                    },
                    data => { type => 'authors', id => 1, }
                },
            },
        },
        included => [{
                id         => 1,
                type       => 'email-templates',
                attributes => {
                    author_id => 1,
                    name      => 'Test Template',
                    body      => 'Test template body',
                },
            },
            {
                id         => 1,
                type       => 'authors',
                attributes => {
                    name => 'John Doe',
                    age  => 28,
                },
                relationships => {
                    'email-templates' => {
                        data => [{
                                id   => 1,
                                type => 'email-templates',
                            }
                        ],
                    },
                },
            },
        ],
    },
    'compound resource document with singular primary relationship and its plural nested relationship'
);

is_deeply(
    $t->compound_resource_document($post, { includes => [{ comments => [qw/author/] }] }),
    {
        data => {
            id         => 1,
            type       => 'posts',
            attributes => {
                author_id   => 1,
                description => 'This is a Perl transformer for the JSON API specification',
                title       => 'Intro to JSON API',
            },
            relationships => {
                comments => {
                    links => {
                        self    => 'http://example.com/api/posts/1/relationships/comments',
                        related => 'http://example.com/api/posts/1/comments'
                    },
                    data => [{ type => 'comments', id => 1, }, { type => 'comments', id => 2, },],
                },
            },
        },
        included => [{
                id         => 1,
                type       => 'authors',
                attributes => {
                    name => 'John Doe',
                    age  => 28,
                },
            },
            {
                id         => 1,
                type       => 'comments',
                attributes => {
                    author_id   => 1,
                    description => 'This is a really good post',
                    likes       => 2,
                    post_id     => 1,
                },
                relationships => {
                    author => {
                        data => {
                            id   => 1,
                            type => 'authors',
                        },
                    },
                },
            },
            {
                id         => 2,
                type       => 'comments',
                attributes => {
                    author_id   => 1,
                    description => 'Another really good post',
                    likes       => 4,
                    post_id     => 1,
                },
                relationships => {
                    author => {
                        data => {
                            id   => 1,
                            type => 'authors',
                        },
                    },
                },
            },
        ],
    },
    'compound resource document with plural primary relation and its singular nested relationship'
);

is_deeply(
    $t->compound_resource_document($t->schema->resultset('Author')->find(1), { includes => [qw/email_templates/] }),
    {
        data => {
            id         => 1,
            type       => 'authors',
            attributes => {
                name => 'John Doe',
                age  => 28,
            },
            relationships => {
                'email-templates' => {
                    links => {
                        self    => 'http://example.com/api/authors/1/relationships/email-templates',
                        related => 'http://example.com/api/authors/1/email-templates'
                    },
                    data => [{ type => 'email-templates', id => 1, }],
                },
            },
        },
        included => [{
                id         => 1,
                type       => 'email-templates',
                attributes => {
                    author_id => 1,
                    name      => 'Test Template',
                    body      => 'Test template body',
                },
            },
        ],
    },
    'compound resource document with underscore case primary relationship'
);

done_testing;
