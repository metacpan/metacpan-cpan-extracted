use strict;
use warnings;

use Test::More;
use HTML::Restrict ();

my $hr = HTML::Restrict->new(
    rules => {
        a          => [qw( href )],
        img        => [qw( src /)],
        blockquote => [qw( cite )],
    },
);

$hr->set_uri_schemes( [ 'http', 'https', undef, 'ftp' ] );

cmp_ok(
    $hr->process(q{<a href="http://example.com">link</a>}),
    'eq', q{<a href="http://example.com">link</a>},
    'http scheme preserved',
);

cmp_ok(
    $hr->process(q{<a href="https://example.com">link</a>}),
    'eq', q{<a href="https://example.com">link</a>},
    'https scheme preserved',
);

cmp_ok(
    $hr->process(q{<a href="/some/file">link</a>}),
    'eq', q{<a href="/some/file">link</a>},
    'relative scheme preserved',
);

cmp_ok(
    $hr->process(q{<a href="ftp://example.com">link</a>}),
    'eq', q{<a href="ftp://example.com">link</a>},
    'ftp scheme preserved',
);

cmp_ok(
    $hr->process(q{<a href="file://example.com">link</a>}),
    'eq', '<a>link</a>',
    'file scheme removed',
);

cmp_ok(
    $hr->process(q{<img src="javascript:evil_fc()" />}),
    'eq', '<img>',
    'img src with javascript removed',
);

cmp_ok(
    $hr->process(
        q{<blockquote cite="javascript:evil_fc()">blockquote</blockquote>}),
    'eq',
    '<blockquote>blockquote</blockquote>',
    'blockquote cite with javascript removed',
);

# disable relative schemes
$hr->set_uri_schemes( [ 'http', 'https', 'ftp' ] );

cmp_ok(
    $hr->process(q{<a href="/some/file">link</a>}),
    'eq', '<a>link</a>',
    'relative scheme removed',
);

done_testing();
