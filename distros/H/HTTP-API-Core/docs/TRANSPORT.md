# Transport adapter contract

`HTTP::API::Core` is an API-client layer, not an HTTP stack. The transport boundary is a supported extension point so alternate HTTP implementations can be used without changing API-specific client code.

This document describes the transport behavior intended to remain compatible through the 1.x series.

## Accepted transports

The `transport` constructor option accepts either:

1. a code reference; or
2. an object with a `request` method.

Both forms use the same call contract:

```perl
my $raw = $transport->request($method, $url, {
    headers => \%headers,
    content => $content, # present only when a request body exists
});
```

For a code reference, the same arguments are passed directly:

```perl
my $raw = $transport->($method, $url, \%options);
```

The method is the normalized uppercase method used by `HTTP::API::Core`. The URL is the final request URL after base-URL joining, query construction, and `before_request` hook changes. Headers likewise include client defaults, per-request headers, and any `before_request` mutations.

The `content` option is omitted entirely when the request has no body. It is present when a body was explicitly supplied, including an explicit empty string.

## Return value

A transport must return a hash reference with:

- `status` — required HTTP status
- `reason` — optional reason phrase
- `headers` — optional hash reference of response headers
- `content` — optional raw response body

Example:

```perl
return {
    status  => 200,
    reason  => 'OK',
    headers => { 'content-type' => 'application/json' },
    content => '{"ok":true}',
};
```

`HTTP::API::Core` converts this transport response into `HTTP::API::Core::Response`. Missing `headers` are treated as an empty header set, missing `content` becomes an empty string, and a missing `reason` remains undefined.

## Failures

A transport may throw an exception for connection, TLS, timeout, DNS, or other transport failures. Ordinary exceptions are normalized into `HTTP::API::Core::Error` with `category => 'transport'` and participate in the configured retry policy.

If a transport throws an existing `HTTP::API::Core::Error`, that structured error is preserved rather than wrapped again.

Returning a non-hash value or a hash without `status` is normalized into a retryable structured `transport` error.

Transport adapters should not implement API-level retry, pagination, rate-limit policy, JSON decoding, or authentication unless required by the underlying HTTP library. Those responsibilities belong above the transport boundary.

## Example object adapter

```perl
package My::Transport;

sub new {
    my ($class, %args) = @_;
    return bless { ua => $args{ua} }, $class;
}

sub request {
    my ($self, $method, $url, $opts) = @_;

    my $response = $self->{ua}->request(...);

    return {
        status  => $response->code,
        reason  => $response->message,
        headers => { ... },
        content => $response->decoded_content,
    };
}
```

This contract intentionally stays small so adapters for LWP, Mojo::UserAgent, Furl, or other HTTP libraries can live in separate distributions.
