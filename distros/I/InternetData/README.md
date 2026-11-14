# [<img src="https://s3.internetdata.io/internetdata-public/brand/mark.svg" alt="InternetData" height="28"/>](https://internetdata.io/) InternetData Perl Client Library

[![CPAN](https://img.shields.io/cpan/v/InternetData.svg)](https://metacpan.org/dist/InternetData)
[![CI](https://github.com/internetdata/sdk-perl/actions/workflows/ci.yml/badge.svg)](https://github.com/internetdata/sdk-perl/actions/workflows/ci.yml)
[![license](https://img.shields.io/cpan/l/InternetData.svg)](LICENSE)

The official Perl client library for the [InternetData](https://internetdata.io) API.

It tells you what every InternetData database says about an IP address, an AS or a domain, and downloads the databases themselves: geolocation, anonymity, ownership and network data, published as CSV.GZ and MMDB.

## Getting Started

```bash
cpanm InternetData
```

Requires Perl 5.22 or newer. [Mojolicious](https://metacpan.org/dist/Mojolicious) is the only runtime dependency, plus `IO::Socket::SSL` for TLS.

## Usage

**No API key needed to start.** Unlimited, the free plan, answers `ip`, `is_bogon`, the Tor, relay, anycast, carrier, satellite and service flags, `location` to the country, `asn`, `company`, `hostname` and the abuse email, with no daily or monthly cap, with a key or without one.

```perl
use InternetData;

my $client = InternetData->new;

my $result = $client->lookup('146.70.116.130');
print $result->company->{name};      # M247 LTD Vienna Infrastructure
print $result->asn->{name};          # who runs the announcing network
print $result->location->{country};  # the ISO 3166 country code
print $result->is_anycast;           # 0
```

### With an API key

Every paid plan answers every field: the VPN, proxy, hosting and CDN flags as well, the detail behind each flag, the city and coordinates, WHOIS and RWHOIS, and the domains hosted on the address. The plans differ only in how many lookups they include, and a free account tries every field, 100 lookups a day. Create a key in the [console](https://app.internetdata.io), then pass it in:

```perl
my $client = InternetData->new(api_key => $ENV{INTERNETDATA_API_KEY});

my $result = $client->lookup('146.70.116.130');
print $result->is_vpn;                # 1, on a paid plan
print $result->vpn->{provider_name};  # Mullvad, on a paid plan
print $result->location->{city};      # Vienna, on a paid plan
```

### An AS or a domain

```perl
my $as = $client->lookup_asn(9009);
print $as->name;        # M247 Europe SRL
print $as->registry;    # ripe
print $as->type;        # hosting, on a paid plan

my $domain = $client->lookup_domain('example.com');
print $domain->is_registered;   # 1
print $domain->has_mx;          # 1 or 0
```

The AS number is sent as given, so `9009` and `'AS9009'` both work. Neither call is cached or batched, and `lookup_asn_p` and `lookup_domain_p` are the non-blocking forms. They return an `InternetData::AsnResult` and an `InternetData::DomainResult`, which read like a lookup's result. `lookup` takes an address alone, and refuses anything else as a `bad_request` before sending it.

### Your own address

```perl
my $result = $client->my_ip;
print $result->ip;   # the address we saw this call come from
```

Same answer `lookup` would give for that address, and the same cost against your allowance. It is deliberately not cached: which address you are is the whole question, and a machine that moves between networks would otherwise be told where it used to be.

### Your plan and usage

```perl
my $acct = $client->my_entitlement;
print $acct->{plan}{key};          # free
print $acct->{usage}{requests};    # 4
print $acct->{usage}{window_end};  # when the allowance resets
```

Usage counts against the anniversary of your subscription on a paid plan, not the calendar month and not the billing period, and against the UTC day on the free plan; it is the same number a lookup is gated on. `hard_limit` is `undef` on an uncapped plan, which is not the same as zero.

`my_ip` returns an `InternetData::Result` like `lookup` does; `my_entitlement` returns the decoded hashref. `my_ip_p` and `my_entitlement_p` are the non-blocking forms.

### Batch lookup

Look up many addresses at once. Bogons and cached answers are handled locally, and everything else goes to the batch endpoint in chunks of up to 1000 addresses, in parallel. The batch endpoint needs a paid plan:

```perl
my $answers = $client->lookup_batch(['146.70.116.130', '8.8.8.8', '1.1.1.1']);

for my $ip (keys %$answers) {
    my $answer = $answers->{$ip};
    if ($answer->isa('InternetData::Error')) {
        warn "$ip: $answer";
        next;
    }
    print "$ip: ", $answer->company->{name}, "\n";
}
```

Results are keyed by address, so duplicates in your list collapse into a single entry and one address failing never loses the rest: it carries its error as its value, with the status the API would have given that address on its own. Perl hashes carry no insertion order, so iterate your own list when order matters.

There's no limit on how many addresses you pass. How many chunks are in flight at once, how many times a failed chunk is retried, and how long each attempt may take are configurable per call:

```perl
my $answers = $client->lookup_batch(\@many_ips, concurrency => 4, retries => 4, timeout => 10);
```

### Caching

Address answers are cached by default, so repeat lookups of the same address are free:

```perl
my $client = InternetData->new;

my $result = $client->lookup('146.70.116.130');   # API request
my $again = $client->lookup('146.70.116.130');    # no API request, result was cached
```

You can change the default cache variables (max size, TTL in seconds) on initialization, or even disable it:

```perl
my $client = InternetData->new(cache_size => 50_000, cache_ttl => 6 * 60 * 60);
my $uncached = InternetData->new(cache_size => 0);
```

The cache belongs to the client, never to the process. Two clients holding different keys are on different plans and entitled to different fields, so a shared cache would serve one of them the other's shape. Nothing else is cached: an AS or a domain answer, `my_ip`, `my_entitlement` and every database call go to the API each time.

### Private and reserved addresses

Private, loopback, link-local, documentation and multicast addresses (and their IPv6 equivalents, including the 6to4 and Teredo ranges) are in no database. The library answers them locally, so they cost no request and no quota:

```perl
my $result = $client->lookup('192.168.1.1');
$result->is_bogon;    # 1
$result->is_vpn;      # 0
```

That answer carries every field, empty, whatever your plan, so don't read your plan from it. The check is available on the client, which is handy when your inputs are addresses anyway:

```perl
$client->is_bogon('10.0.0.1');    # 1
$client->is_bogon('8.8.8.8');     # 0
```

It is also importable on its own, if you want it without a client:

```perl
use InternetData 'is_bogon';

is_bogon('10.0.0.1');    # 1
```

### Errors

Failures die with an `InternetData::Error` carrying a `kind` and a `retryable` flag. It stringifies to its message, so it reads like an ordinary string exception where you do not care which it is:

```perl
my $result = eval { $client->lookup('146.70.116.130') };
if (my $err = $@) {
    die $err unless ref $err && $err->isa('InternetData::Error');
    warn $err->kind, ' ', $err->status, ' ', $err->retryable, ' ', $err->message;
}
```

`kind` is one of `bad_request`, `unauthorized`, `forbidden`, `rate_limited`, `quota_exceeded`, `server_error` or `network`. `message` is a lookup refusal's explanation, or a database call's own result code, so a 403 from a download tells you whether it was `NOT_LICENSED`, `LICENSE_EXPIRED` or `IP_NOT_ALLOWED`, a call from an address the key or its organization does not allow.

Note that `rate_limited` and `quota_exceeded` both arrive as HTTP 429 and are not the same thing. A rate limit is when the API faces extreme traffic bursts and so retrying later works; but a spent quota needs your allowance raised or the window to roll over. The library retries rate limits for you, but not if your quota is exceeded. The database API has no quota, so you won't see `quota_exceeded` from it. Nothing else in the 4xx range is retried at all: a misspelled database ID is a 404, and asking for it three times gets the same answer three times.

### Timeouts and retries

Each attempt gives up after 30 seconds, and a transient failure is retried twice. Both can be changed for the client, and for a single call:

```perl
my $client = InternetData->new(timeout => 10, retries => 4);

my $result = $client->lookup('146.70.116.130', timeout => 2.5, retries => 0);
```

The timeout is in seconds and applies to each attempt, so a retried call can take longer in total. An attempt that runs out of time fails as a retryable `network` error. A database download isn't bound by it, since a large file takes as long as it takes, so `download` and `download_bytes` refuse a per-call `timeout` rather than quietly ignoring it.

### Non-blocking use

Every call has a `_p` twin returning a [Mojo::Promise](https://metacpan.org/pod/Mojo::Promise), so the library drops into a Mojolicious application without a worker or a thread:

```perl
$client->lookup_p('146.70.116.130')
    ->then(sub { print shift->company->{name} })
    ->catch(sub { warn shift })
    ->wait;
```

The blocking calls are those same promises plus a `wait`, so both paths retry, cache and short-circuit identically. Inside an already running event loop the blocking calls cannot block, and say so rather than returning nothing.

In a Mojolicious app, look the visitor up in an `under`:

```perl
use Mojolicious::Lite -signatures;
use InternetData;

my $internetdata = InternetData->new(api_key => $ENV{INTERNETDATA_API_KEY}, timeout => 2, retries => 0);

under sub ($c) {
    $internetdata->lookup_p($c->tx->remote_address)->then(sub ($result) {
        $c->stash(country => $result->location->{country});
        $c->continue;
    })->catch(sub ($err) {
        $c->app->log->warn("internetdata: $err");
        $c->continue;
    });
    return undef;
};
```

- **Bound the lookup.** The defaults (30 seconds an attempt, two retries) outlast Mojolicious's own 30-second inactivity timeout, so with the API unreachable the visitor gets an empty reply, or a 502 through a proxy, before the `catch` runs.
- **Return `undef` and call `$c->continue`.** A promise returned from an `under` does not hold the route: it carries on at once, and anything you render then dies with "A response has already been rendered".

### Database downloads

The databases your organization is licensed for are under `$client->database`, which needs a key with the `db.download` scope. `list` returns the database *families* your organization may see. A license is held against a family, and the ID you download is the one hanging off its `versions`:

```perl
my ($bogon) = grep { $_->{base} eq 'bogon_ip' } @{ $client->database->list };

print $bogon->{standing};             # licensed, expired or unlicensed
print $bogon->{license_type};         # evaluation, standard or redistribute
my $id = $bogon->{versions}[-1]{id};  # bogon_ip_v1, and this is what you download
```

`standing` tells you where you stand against a database, so one you have not bought is still listed and you can see that it exists. `InternetData::Database::STANDINGS` and `InternetData::Database::LICENSE_TYPES` list every value the two fields take. A family you hold no license for has an undefined `license_type`.

`metadata` describes one database without transferring it - row count, build date, per-format schema, sample rows and exact sizes - so you can decide whether today's build is worth fetching and budget a transfer before starting it:

```perl
my $meta = $client->database->metadata($id);

print $meta->{updated};          # 2026-09-04
print $meta->{entries};          # rows in this build
print $meta->{size}{csvgz};      # bytes
```

There are three ways to fetch one file: straight to disk, as bytes, or as a link you transfer yourself.

```perl
my $written = $client->database->download($id, 'csvgz', "./$id.csv.gz");
my $bytes = $client->database->download_bytes($id, 'csvgz');
my $url = $client->database->download_url($id, 'csvgz');
```

`download` holds nothing but a single chunk in memory whatever the database weighs. It writes to a neighboring `.part` file and renames it on completion, and a transfer that stops short of the length the origin declared is an error rather than a short file, so a path that exists is a whole database and a failed refresh cannot destroy the copy already there.

`download_bytes` holds the **entire file** in memory. The catalog spans seven orders of magnitude, from `bogon_asn_v1` at 264 bytes to `resproxy_ip_14d_v1` at 5.34 GiB, and a 5.34 GiB database is 5.34 GiB of resident memory here, so reach for it at the small end. `metadata` publishes the size per format without transferring anything, which is how you find out which end you are at.

`download_url` hands back the link rather than the bytes, so you choose how to move the file, hand it to a downloader, or pass it on without passing on your API key. The link is presigned and authorizes itself; it authorizes the START of a transfer, so one already running is not interrupted when it lapses. The client never follows that redirect for you. `download` and `download_bytes` do follow it, and that second request carries no API key: object storage has no business holding your credential.

Each of the three downloads the build that is live unless you name one. A `database.updated` webhook names the build it announces and carries its `sha256`, so a receiver that downloads after the next publish asks for that build to get the file the hash is of:

```perl
$client->database->download('vpn_ip_v1', 'mmdb', './vpn_ip_v1.mmdb', build => $event->{data}{build});
```

A build is kept 7 days. Past that the call dies with a `bad_request` whose message is `BUILD_GONE`, and downloading without `build` fetches the live one.

`retries` covers a transfer only until its first byte reaches you: object storage failing before then is retried like any server error, but a transfer that dies part way is not repeated, since a second copy would append to the bytes already written.

A format is `csvgz` or `mmdb`, and `InternetData::Database::FORMATS` lists them. Anything else is refused before a request is made.

`checksums` publishes all four digests for one published file, so you can check the bytes you received, and `downloads` is your organization's recent attempts, newest first, refusals included. Without a limit the API applies its own default of 50, and it is clamped to 200.

```perl
my $sums = $client->database->checksums($id, 'csvgz');
print $sums->{sha256};

for my $attempt (@{ $client->database->downloads(limit => 20) }) {
    print "$attempt->{created} $attempt->{dataset_id} $attempt->{outcome}\n";
}
```

### Sign in with OAuth (device flow)

A program running on the person's own machine can let them sign in with a browser and pick one of their API keys, instead of asking them to paste it:

```perl
my $client = InternetData->new;

my $device = $client->oauth->device_authorization('your-client-id',
    scope => 'account.read apikeys.read apikeys.reveal');
print "Open $device->{verification_uri} and enter $device->{user_code}\n";

my $token = $client->oauth->poll_device_token('your-client-id', $device);
die "no API key came back: none was picked, or it can't be shown again\n"
    unless defined $token->{apikey};
my $keyed = InternetData->new(api_key => $token->{apikey});
```

A denied sign-in dies with `InternetData::OauthAccessDeniedError` and a code that ran out with `InternetData::OauthExpiredTokenError`. Client IDs are issued on request from support@internetdata.io, and `$client->oauth->revoke('your-client-id', $token->{refresh_token})` signs the machine out again.

### Sign in with OAuth (authorization code)

An app that can take a browser redirect signs the person in there instead, with a PKCE pair made for that one sign-in:

```perl
my $client = InternetData->new;
my $redirect_uri = 'http://127.0.0.1:8765/callback';
my $pkce = $client->oauth->create_pkce;

my $url = $client->oauth->authorization_url('your-client-id', $redirect_uri, $pkce->{challenge},
    scope => 'apikeys.use', state => 'your-state');
# Open $url in the browser. Its redirect to $redirect_uri carries code and state.
my $token = $client->oauth->exchange_authorization_code('your-client-id', $code,
    $pkce->{verifier}, $redirect_uri);
```

Check that `state` came back as you sent it before you exchange `code`, which works once. The client ID can also be the https URL of a client metadata document your app serves, and such an app is never handed a key, so `$token->{apikey}` stays absent.

### Register a client

An app with no client ID, and no client metadata document to use as one, registers itself, then signs in with the `client_id` it gets back as the client ID for `authorization_url` and `exchange_authorization_code`:

```perl
my $client = InternetData->new;
my $registration = $client->oauth->register(
    ['http://127.0.0.1:8765/callback'], client_name => 'Your App');
```

Each redirect URI must be https on a public host name, or http on a loopback address, which then matches any port. Nothing is kept until a person approves the client, so an app with no client ID saved can simply register again.

### Absent is not false

Unlimited leaves out `is_vpn`, `is_hosting`, `is_cdn` and the four proxy flags, the detail behind them, and the paid members inside `location`, `asn`, `company` and `abuse`, such as `location->{city}`; a free-plan key's answer carries `trial_expired`, true once its daily trial is spent. A field your plan does not include is absent, which never means "we checked and found nothing". Perl makes that easy to miss, since `undef` and `0` are both false.

```perl
if ($result->is_hosting // 0) { ... }          # absent counts as false
if ($result->has('is_hosting')) { ... }        # is this field in my plan? Not without a key
if (exists $result->location->{city}) { ... }  # and a member inside an object
if ($result->trial_expired) { ... }            # a free-plan key's daily trial is spent
```

## Other Libraries

There are official InternetData client libraries available for many languages including PHP, Python, Go, Java, and Ruby. See our GitHub at https://github.com/internetdata for more.

## About InternetData

Geolocation, anonymity, ownership and network data for IP addresses, AS numbers and domains, as an API and as databases you download and query yourself.

[<img src="https://s3.internetdata.io/internetdata-public/brand/mark.svg" alt="InternetData" height="64"/>](https://internetdata.io/)

## License

This project is licensed under the [MIT License](LICENSE).
