# Response API

`HTTP::API::Core::Response` keeps response handling explicit and predictable.

## Body access

```perl
my $response = $api->get('/users');

$response->content;
$response->text;
$response->has_content;
$response->json;
```

`text` does not perform charset transcoding. `json` is explicit and does not
depend on the `Content-Type` header. Empty or whitespace-only bodies return
`undef`; invalid non-empty JSON throws a structured `decode` error.

## Content type

`content_type` returns the lower-cased media type with parameters removed.
`is_json` recognizes `application/json` and `application/*+json`.

## Metadata

The response object also exposes `status`, `reason`, `headers`, `header($name)`,
`method`, `url`, `elapsed`, `request_id`, and `rate_limit`.

`headers` returns a copy rather than the internal hash.

## Design principle

The response API should remain small and transport-independent. It does not
automatically deserialize based on Content-Type or perform charset conversion.
