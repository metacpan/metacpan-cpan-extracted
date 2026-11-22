# Pagination

`HTTP::API::Core` provides a small pagination helper through `$api->paginate(...)` and `HTTP::API::Core::Pagination`.

This document describes the pagination behavior treated as part of the public compatibility contract on the path to 1.0.

## Entry point

```perl
my $pager = $api->paginate(
    '/users',
    mode => 'page',
    page_size => 100,
);

my $all = $pager->all;
```

`paginate()` returns an `HTTP::API::Core::Pagination` object. Items can be consumed one at a time with `next()` or collected with `all()`.

In list context, `all()` returns the items as a list. In scalar context, it returns an array reference.

`all()` preserves JSON `null` elements (decoded as Perl `undef`) within item arrays, including at page boundaries. `next()` retains its existing contract of returning `undef` at exhaustion; it therefore cannot distinguish an actual `undef` item from the end of iteration. Use `all()` when preserving nullable elements matters, or normalize them to explicit values in a custom `items` extractor before using `next()`.

## Optional page limit

Use `max_pages` to bound the number of successfully validated pages fetched by
any pagination mode. The default is unlimited, preserving existing behavior.

```perl
my $pager = $api->paginate(
    '/users',
    mode      => 'page',
    has_more  => 'has_more',
    max_pages => 50,
);
```

If more pages remain after the limit is reached, the next attempt to fetch a
page throws `pagination maximum page count exceeded` **before** issuing
another HTTP request. Items already buffered by the last permitted page can
still be consumed with `next()`. A pagination sequence that finishes on the
last permitted page completes normally.

Failed pages do not count against this limit: the iterator can retry a page
whose response or continuation metadata was rejected without exhausting its
page allowance. In page-number mode, an empty page with `has_more` true
can legitimately precede a populated page; without `max_pages` the iterator
still honors that flag. Set a limit when the API could repeatedly claim more
pages without returning useful data.


## Supported modes

Four modes are supported:

- `next_url`
- `page`
- `cursor`
- `offset`

The default mode is `next_url`.

### `next_url`

The first request uses `path`. The continuation URL is extracted from the response using the `next` extractor, which defaults to `next`.

```perl
my $pager = $api->paginate(
    '/users',
    mode  => 'next_url',
    items => 'data.items',
    next  => 'links.next',
);
```

After the first page, continuation URLs are requested as returned by the API. Absolute HTTP(S) continuation URLs are recognized even when the scheme uses uppercase or mixed-case letters (for example, `HTTPS://api.example.com/users?page=2`). Relative continuation URLs continue to pass through the client request layer and therefore use the configured base URL.

An undefined or empty continuation marks the pagination sequence complete.

Absolute continuation URLs are restricted to the client's configured origin by default. This prevents client-level credentials and other default headers from being forwarded to an unrelated origin when a continuation URL comes from a response. Set `allow_cross_origin => 1` only when the API intentionally paginates across origins and forwarding the client's request configuration is expected.

Origin comparisons use the scheme and host, treating an omitted port as equivalent to the scheme's default port (`80` for HTTP, `443` for HTTPS), including zero-padded spellings such as `:080` and `:0443`. Query strings and fragments do not affect the origin, including absolute continuations without a path such as `https://api.example.com?page=2`. Different schemes, hosts, and non-default ports remain restricted.

For safety, cross-origin rejection errors do not echo the rejected continuation URL: its query string may contain credentials or other private data. Treat continuation URLs received from APIs as untrusted input.

### `page`

Page-number mode adds a page parameter to each request.

```perl
my $pager = $api->paginate(
    '/users',
    mode      => 'page',
    page_size => 100,
);
```

Defaults:

- first page: `1`
- page parameter: `page`
- page-size parameter: `per_page`

These can be changed with `start_page`, `page_param`, and `page_size_param`.

When `has_more` is supplied, its extracted value controls whether another page is requested. Otherwise, if `page_size` is set, a page containing fewer than `page_size` items ends pagination. Without either setting, an empty item list ends pagination.

### `offset`

Offset mode adds a zero-based offset parameter to each request and advances it by the **actual number of returned items** (not the requested page size). It works for APIs that limit the page size below the requested size, provided that the API reports the total number of items.

For example, with Jira REST API v2:

```perl
my $pager = $api->paginate(
    '/jira/rest/api/2/search',
    mode            => 'offset',
    items           => 'issues',
    total           => 'total',
    offset_param    => 'startAt',
    page_size_param => 'maxResults',
    page_size       => 1000,
    query => {
        jql    => 'filter=12345',
        fields => 'summary,description,components',
    },
);

while (my $issue = $pager->next) {
    # Process one issue
}
```

Defaults:

- initial offset: `0`
- offset parameter: `offset`
- page-size parameter: `per_page`

Override these with `start_offset`, `offset_param`, and `page_size_param`. When `total` is provided, it is an extractor (a dotted path or code reference) returning a non-negative integer. Pagination ends when the number of items consumed (including the starting offset) reaches the total. An empty page always ends pagination to prevent a non-advancing loop.

Without `total`, a provided `has_more` extractor controls completion. Otherwise, an item count shorter than `page_size` ends pagination; with neither configured, an empty page ends pagination. For APIs that silently cap the page size, supply `total` or `has_more` to avoid stopping early. If both `total` and `has_more` are supplied, `total` takes precedence.

### `cursor`

Cursor mode sends a cursor value as a query parameter after the first response supplies one.

```perl
my $pager = $api->paginate(
    '/users',
    mode   => 'cursor',
    next   => 'next_cursor',
    query  => { limit => 100 },
);
```

Defaults:

- cursor extractor: `next_cursor`
- cursor parameter: `cursor`

The cursor parameter can be renamed with `cursor_param`, and an initial cursor can be provided with `cursor`.

Undefined or empty cursors end pagination.

## Item and continuation extractors

`items`, `next`, `has_more`, and `total` may use dotted paths into decoded JSON structures.

```perl
items => 'data.items'
next  => 'links.next'
```

An extractor may also be a code reference:

```perl
items => sub {
    my ($data) = @_;
    return $data->{records};
}
```

The items extractor must return an array reference. Any other value is an error. Numeric array indices in dotted paths use ASCII digits only; Unicode digit characters are not silently coerced to array offsets.

The default items extractor is `items`.

## Query parameters

The `query` option provides query parameters applied to pagination requests.

```perl
query => {
    active => 1,
    limit  => 50,
}
```

Pagination-generated page or cursor parameters are merged with these values. Scalar values are URI-escaped, array references generate repeated keys, and undefined values (including undefined array entries) are omitted. Other reference values are rejected. Keys are emitted deterministically. Existing query strings are preserved, and generated parameters are inserted before URL fragments.

## Request options

The `request` option is a hash reference whose values are passed to the client's `get()` method for every page request.

This is the supported way to carry request-level options such as headers, retry overrides, or hooks into pagination.

## Error handling and page state

A page is accepted only after its items and continuation metadata are both validated. If an extractor throws or a continuation URL/cursor is rejected, the paginator does not expose that failed page's items or advance its cursor, page number, or loop-detection state. A later call on the same paginator can refetch the failed page; callers should only retry when the underlying failure can be corrected. Earlier successfully accepted pages remain consumed.

## Continuation-loop protection

Repeated next URLs or cursor values are rejected instead of looping forever. This includes a continuation that returns to the initial requested URL (including pagination query options) or to an explicitly supplied initial cursor; the duplicate request is avoided. Detection compares the URL and cursor values directly, without URL canonicalization.

A repeated continuation throws an error containing `pagination continuation repeated` and identifies whether the repeated value was a URL or cursor. The exception deliberately does **not** include the original URL or cursor value, because server-supplied continuation metadata can contain secrets.

## Validation

The constructor rejects:

- missing `client`
- missing `path`
- unsupported modes
- non-hash `query`
- non-hash `request`
- non-positive `page_size`
- non-positive, non-integer, or non-ASCII `max_pages`
- non-positive `start_page`
- non-ASCII digits in `page_size` or `start_page`
- invalid or negative `start_offset`
- invalid `total` extractor type
- unknown options

These validation rules are part of the compatibility contract.

## Compatibility expectations

Across the 1.x series, the project intends to preserve:

- the four supported modes and their default names
- `next()` and `all()` consumption behavior
- dotted-path and code-reference extractors
- query and request option handling
- continuation-loop protection
- documented validation behavior

New optional pagination capabilities may be added in minor releases, but existing documented behavior should not require downstream client changes.

## Response-aware extractors

By default, code-reference extractors keep the 1.x calling convention and receive only the decoded response body. Set `response_aware_extractors => 1` on the paginator to opt in to a second argument containing the `HTTP::API::Core::Response` object. This explicit opt-in preserves compatibility with fixed-arity one-argument callbacks.

This allows service layers to follow continuation metadata carried in response headers, such as an HTTP `Link` header, without adding service-specific header parsing to the core.
