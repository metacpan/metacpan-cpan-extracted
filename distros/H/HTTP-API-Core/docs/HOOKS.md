# Lifecycle Hooks

`HTTP::API::Core` supports three lifecycle hook names:

- `before_request`
- `after_response`
- `on_error`

Hooks may be configured on the client constructor and per request. A hook value may be a code reference or an array reference of code references.

## Ordering

Client-level hooks run before request-level hooks of the same name. Within each level, callbacks run in declaration order.

Hooks are evaluated for each request attempt. If a retry occurs, `before_request` runs again before the new attempt. `on_error` runs after a failed attempt and before retry handling continues. `after_response` runs only for a successful response.

## `before_request`

A `before_request` callback receives one mutable request context hash reference.

The context includes:

- `method`
- `url`
- `headers`
- `content`
- `attempt`

Before the transport call, the core also records `started_at` in the same context. The callback may modify `method`, `url`, `headers`, or `content`; those changes are used for that attempt.

Example:

```perl
hooks => {
    before_request => sub {
        my ($ctx) = @_;
        $ctx->{headers}{'X-Trace-Id'} = make_trace_id();
    },
}
```

## `after_response`

An `after_response` callback receives:

```perl
($response, $context)
```

It runs after a successful transport response has been normalized into an `HTTP::API::Core::Response` object.

The context includes request fields plus observability fields such as `started_at`, `elapsed`, and `request_id` when available.

## `on_error`

An `on_error` callback receives:

```perl
($error, $context)
```

It runs for failed request attempts after the error has been normalized into an `HTTP::API::Core::Error`. If the retry policy allows another attempt, `on_error` runs before that retry.

## Hook failures

If a hook dies with an ordinary Perl exception, the core throws an `HTTP::API::Core::Error` with category `hook`. Hook errors are non-retryable.

If a hook throws an existing `HTTP::API::Core::Error`, that error is preserved rather than wrapped again.

## Validation

Unknown hook names are rejected. Each hook must be a code reference or an array reference containing only code references.

The public lifecycle hook contract includes hook names, callback ordering, callback argument shapes, per-attempt execution, request-context mutability for `before_request`, and structured hook error behavior.
