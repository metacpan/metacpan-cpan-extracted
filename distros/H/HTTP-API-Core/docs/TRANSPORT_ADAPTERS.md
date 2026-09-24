# Common transport adapters

The transport contract is intentionally small enough to map onto common Perl
HTTP clients without moving retry, pagination, authentication, or API-specific
logic into the HTTP layer.

Reference helpers live in
`examples/HTTP/API/Core/Example/TransportAdapters.pm`. They are examples, not a
new supported adapter API: copy or adapt them into your application or a
separate transport distribution.

## HTTP::Tiny

`HTTP::Tiny` is the closest fit because its `request` method accepts method,
URL, headers, and optional content and returns a hash containing `status`,
`reason`, `headers`, and `content`.

```perl
use HTTP::Tiny;
use HTTP::API::Core;
use HTTP::API::Core::Example::TransportAdapters;

my $http = HTTP::Tiny->new(timeout => 10);
my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.com',
    transport => HTTP::API::Core::Example::TransportAdapters::http_tiny($http),
);
```

Caveat: HTTP::Tiny response header keys are commonly lowercase. Core response
lookup is case-insensitive, so adapters do not need to rewrite them.

## LWP::UserAgent

LWP expects an `HTTP::Request` object rather than separate request arguments.
The adapter copies headers, preserves the difference between no body and an
explicit empty body, then maps the `HTTP::Response` back to the core hash
shape.

```perl
use LWP::UserAgent;
use HTTP::API::Core;
use HTTP::API::Core::Example::TransportAdapters;

my $ua = LWP::UserAgent->new(timeout => 10);
my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.com',
    transport => HTTP::API::Core::Example::TransportAdapters::lwp_user_agent($ua),
);
```

Caveat: use raw `content`, not `decoded_content`, at the transport boundary.
Content decoding belongs to the layer above the transport and using
`decoded_content` could change the bytes returned by the server.

## Mojo::UserAgent

Mojo uses transactions. The adapter builds a transaction from method, URL, and
headers, sets the raw request body when present, starts the transaction, and
maps the result object back to the core response hash.

```perl
use Mojo::UserAgent;
use HTTP::API::Core;
use HTTP::API::Core::Example::TransportAdapters;

my $ua = Mojo::UserAgent->new;
my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.com',
    transport => HTTP::API::Core::Example::TransportAdapters::mojo_user_agent($ua),
);
```

Caveat: this is the synchronous mapping. Async/promise behavior stays outside
HTTP::API::Core's synchronous transport contract.

## Furl

Furl accepts named request arguments and a flat header list. The adapter
converts the core header hash to that list and maps the response object back to
the core response hash.

```perl
use Furl;
use HTTP::API::Core;
use HTTP::API::Core::Example::TransportAdapters;

my $furl = Furl->new(timeout => 10);
my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.com',
    transport => HTTP::API::Core::Example::TransportAdapters::furl($furl),
);
```

## What stays above the adapter

Adapters should only translate the transport contract. Keep these concerns in
HTTP::API::Core or service-specific code:

- retry and Retry-After policy
- pagination
- rate-limit policy
- authentication hooks
- JSON encoding/decoding
- structured API errors
- observability hooks
- idempotency policy
