# Error model

`HTTP::API::Core` uses `HTTP::API::Core::Error` objects for failures that cross the public client API boundary.

## Stable categories

The `category` method is the machine-readable classification:

| Category | Meaning |
| --- | --- |
| `encode` | JSON request encoding failed |
| `decode` | Explicit JSON response decoding failed |
| `transport` | The HTTP transport failed or returned an invalid transport response |
| `http` | The server returned a non-success HTTP status |
| `hook` | A lifecycle hook failed |

Code should branch on `category`, status, and other structured fields rather than parsing `message`.

Exact human-readable message wording is not a compatibility guarantee.

The default `HTTP::Tiny` transport reports network-level failures as a
pseudo-response with status `599` and reason `Internal Exception`, rather
than throwing. The core recognizes this specific sentinel as a `transport`
error, not an HTTP error from a remote server. It remains retryable according
to the method's configured retry policy. The raw exception text is included in
the error message for diagnosis, so avoid logging errors or URLs to untrusted
destinations when requests contain credentials. An actual HTTP `599` with a
different reason, or a response from a custom transport, continues through the
normal HTTP error path.

## Credential-conscious logging

Errors retain useful diagnostic information, but the raw `message`, `url`,
`request_id`, headers, and body may contain sensitive data. The stringified
exception (e.g. `warn "$error"`) is intended for protected debugging, not
necessarily for routine application logs.

Use `log_summary` when a concise summary is enough:

```perl
eval { $api->get('/private') };
if (my $error = $@) {
    if (ref($error) && eval { $error->isa('HTTP::API::Core::Error') }) {
        warn $error->log_summary, "\n";
    }
    else {
        warn "API operation failed\n";
    }
}
```

`log_summary` emits a single line containing an allowlisted error category,
HTTP method, optional validated HTTP status, and retryability. It does not
include raw request URLs, exception messages, request IDs, response headers,
or bodies. Unknown category or method values are replaced with fixed labels.
For example:

```text
HTTP API error category=transport method=GET retryable=1
HTTP API error category=http method=POST status=422 retryable=0
```

Do not append `$error->url`, `$error->message`, or request/response context
to unprotected log messages; those accessors intentionally preserve full
details for applications that need them.

## HTTP errors

HTTP errors retain the associated response:

```perl
eval {
    $api->get('/users/404');
};

if (my $error = $@) {
    if ($error->category eq 'http') {
        say $error->status;
        say $error->body;
        say $error->header('content-type');

        my $payload = $error->json;
    }
}
```

`body` and `text` expose the response body. `headers` returns a defensive copy. `json` delegates to the response object's explicit JSON decoding semantics.

## Errors without responses

Transport, encode, and hook failures may not have an HTTP response. In that case:

- `response`, `body`, `text`, `header`, and `json` return `undef`
- `headers` returns an empty hash reference

## Compatibility

The documented error categories and accessors are part of the stable 1.x
contract described in `DESIGN.md`. Runtime failures have regression tests
that do not require network access.
