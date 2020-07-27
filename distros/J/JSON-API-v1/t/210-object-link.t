use Test::Lib;
use Test::JSON::API::v1;

use URI;

my $plain = new_link(
    uri => 'https://example.com/linkage',
);

cmp_object_json(
    $plain,
    {
        self => 'https://example.com/linkage',
    },
    "Link object shows itself",
);

my $meta = new_link(
    uri => 'https://example.com/meta',
    meta => 'example',
);

cmp_object_json(
    $meta,
    {
        href => "https://example.com/meta",
        meta => "example",
    },
    ".. and shows itself with metadata"
);

my $related = new_link(related => $plain);

cmp_object_json(
    $related,
    {
        related => {
            self => 'https://example.com/linkage',
        }
    },
    ".. and related links also work",
);

$related = new_link(
    related => $meta,
);

cmp_object_json(
    $related,
    {
        related => {
            href => 'https://example.com/meta',
            meta => 'example',
        }
    },
    ".. and related meta links also work",
);

$meta = new_link(
    uri => 'https://example.com/meta/nest',
    meta => { some => { nested => 'data' }},
);

cmp_object_json(
    $meta,
    {
        href => 'https://example.com/meta/nest',
        meta => { some => { nested => 'data' }},
    },
    ".. and nested structures in meta work also",
);

my $uri= new_link(
    uri => URI->new('https://example.com/coerced'),
);

cmp_object_json(
    $uri,
    {
        self => 'https://example.com/coerced',
    },
    ".. and coercing works",
);

done_testing;
