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

## Supported modes

Three modes are supported:

- `next_url`
- `page`
- `cursor`

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

After the first page, continuation URLs are requested as returned by the API. Relative continuation URLs continue to pass through the client request layer and therefore use the configured base URL.

An undefined or empty continuation marks the pagination sequence complete.

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

`items`, `next`, and `has_more` may use dotted paths into decoded JSON structures.

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

The items extractor must return an array reference. Any other value is an error.

The default items extractor is `items`.

## Query parameters

The `query` option provides query parameters applied to pagination requests.

```perl
query => {
    active => 1,
    limit  => 50,
}
```

Pagination-generated page or cursor parameters are merged with these values. Values are URI-escaped, and keys are emitted deterministically.

## Request options

The `request` option is a hash reference whose values are passed to the client's `get()` method for every page request.

This is the supported way to carry request-level options such as headers, retry overrides, or hooks into pagination.

## Continuation-loop protection

Repeated next URLs or cursor values are rejected instead of looping forever.

A repeated continuation throws an error containing `pagination continuation repeated`.

## Validation

The constructor rejects:

- missing `client`
- missing `path`
- unsupported modes
- non-hash `query`
- non-hash `request`
- non-positive `page_size`
- non-positive `start_page`
- unknown options

These validation rules are part of the compatibility contract.

## Compatibility expectations

Across the 1.x series, the project intends to preserve:

- the three supported modes and their default names
- `next()` and `all()` consumption behavior
- dotted-path and code-reference extractors
- query and request option handling
- continuation-loop protection
- documented validation behavior

New optional pagination capabilities may be added in minor releases, but existing documented behavior should not require downstream client changes.
