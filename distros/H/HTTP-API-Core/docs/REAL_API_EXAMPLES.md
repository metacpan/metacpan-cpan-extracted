# Real API examples

The modules under `examples/` are intentionally small integration recipes. They
show how an API-specific client can keep endpoint names and pagination shapes in
its own layer while inheriting retry, errors, authentication headers,
observability, and rate-limit normalization from `HTTP::API::Core`.

They are tested with deterministic transports and do not make network requests
during the distribution test suite. They are not official SDKs for GitHub,
Slack, or Cloudflare.

Add the example directory when running one from a source checkout:

```perl
use lib 'examples';
```

## GitHub

GitHub's authenticated-repositories endpoint returns a top-level JSON array and
advertises continuation through the HTTP `Link` header. The example opts in to
response-aware extractors, maps the top-level array into the common pager
interface, and follows the exact `rel="next"` URL while keeping Link parsing in
the GitHub service layer.

```perl
use HTTP::API::Core::Example::GitHub;

my $github = HTTP::API::Core::Example::GitHub->new(
    token => $ENV{GITHUB_TOKEN},
);

my $pager = $github->repositories_pager(
    affiliation => 'owner,collaborator',
    sort        => 'updated',
);

while (my $repo = $pager->next) {
    print "$repo->{full_name}\n";
}

my $response = $github->get('/rate_limit');
my $rate = $response->rate_limit;
print $rate->remaining, " requests remain\n"
    if defined $rate->remaining;
```

API reference: <https://docs.github.com/en/rest/repos/repos#list-repositories-for-the-authenticated-user>

## Slack

`conversations.history` returns messages and its continuation cursor in
`response_metadata.next_cursor`, which maps directly to cursor mode.

```perl
use HTTP::API::Core::Example::Slack;

my $slack = HTTP::API::Core::Example::Slack->new(
    token => $ENV{SLACK_TOKEN},
);

my $pager = $slack->messages_pager(
    channel => $ENV{SLACK_CHANNEL_ID},
    limit   => 15,
);

while (my $message = $pager->next) {
    print "$message->{ts} $message->{text}\n";
}
```

Slack commonly returns API-level failures as JSON with `ok` set to false even
when the HTTP request succeeds. A production Slack client should add that
service-specific validation above the core. The conservative default of 15
items also works with the stricter limit applied to some commercially
distributed non-Marketplace apps; internal and Marketplace apps can request a
larger page size.

API reference: <https://docs.slack.dev/reference/methods/conversations.history/>

## Cloudflare

Cloudflare's zones endpoint returns records under `result` and page metadata
under `result_info`. The `has_more` extractor compares the current page with the
reported total.

```perl
use HTTP::API::Core::Example::Cloudflare;

my $cloudflare = HTTP::API::Core::Example::Cloudflare->new(
    token => $ENV{CLOUDFLARE_API_TOKEN},
);

my $pager = $cloudflare->zones_pager(
    status   => 'active',
    per_page => 50,
);

while (my $zone = $pager->next) {
    print "$zone->{id} $zone->{name}\n";
}
```

API reference: <https://developers.cloudflare.com/api/resources/zones/methods/list/>


## Stripe

Stripe combines bearer authentication, form-encoded request bodies,
`Idempotency-Key`, request IDs, and cursor pagination. The example maps list
pagination by extracting the last object's `id` when `has_more` is true and
feeding it back as `starting_after`.

```perl
use HTTP::API::Core::Example::Stripe;

my $stripe = HTTP::API::Core::Example::Stripe->new(
    token => $ENV{STRIPE_SECRET_KEY},
);

my $pager = $stripe->customers_pager(limit => 100);
while (my $customer = $pager->next) {
    print "$customer->{id}\n";
}
```

The validation found no need for a Stripe-specific core primitive. Form encoding
is intentionally service-layer behavior; generic idempotency and cursor
pagination already compose with it.

API reference: <https://docs.stripe.com/api>

## GitLab

GitLab's REST API is a useful contrast: private-token authentication, top-level
JSON arrays, ordinary page/per-page query pagination, request IDs, and
rate-limit headers all fit existing core primitives.

```perl
use HTTP::API::Core::Example::GitLab;

my $gitlab = HTTP::API::Core::Example::GitLab->new(
    token => $ENV{GITLAB_TOKEN},
);

my $pager = $gitlab->projects_pager(
    membership => 'true',
    per_page => 50,
);
```

This validation likewise did not expose a new generic core requirement.

API reference: <https://docs.gitlab.com/api/rest/>

## Validation notes

Across GitHub, Slack, Cloudflare, Stripe, and GitLab, the recurring shapes are
covered by the transport-independent primitives: header authentication, query
encoding, page/cursor/next-URL pagination, response-aware pagination extractors,
generic idempotency headers, normalized rate-limit metadata, request IDs, and
structured HTTP/transport errors.

The 1.08 review also hardened two generic boundaries exposed by those recipes:
cross-origin absolute pagination continuations are rejected by default to avoid
forwarding client credentials unexpectedly, and mutable `before_request` context
fields are revalidated before transport.

Two patterns remain deliberately service-specific:

- application-level success/failure envelopes such as Slack's `ok: false`
- request body encodings and nested parameter conventions such as Stripe form data

Neither pattern currently justifies adding behavior to the core because their
semantics vary by service.
