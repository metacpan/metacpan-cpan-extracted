# [<img src="https://s3.internetdata.io/internetdata-public/brand/mark.svg" alt="InternetData" height="28"/>](https://internetdata.io/) InternetData Perl Client Library

[![CPAN](https://img.shields.io/cpan/v/InternetData.svg)](https://metacpan.org/dist/InternetData)
[![CI](https://github.com/internetdata/sdk-perl/actions/workflows/ci.yml/badge.svg)](https://github.com/internetdata/sdk-perl/actions/workflows/ci.yml)
[![license](https://img.shields.io/cpan/l/InternetData.svg)](LICENSE)

The official Perl client library for the [InternetData](https://internetdata.io) API.

The library helps you browse and download InternetData's licensed IP and network databases: VPN, residential, datacenter and mobile proxy ranges, hosting and CDN address space, Tor nodes, relays and more, published as CSV.GZ and MMDB.

## Getting Started

```bash
cpanm InternetData
```

Requires Perl 5.22 or newer. [Mojolicious](https://metacpan.org/dist/Mojolicious) is the only runtime dependency, plus `IO::Socket::SSL` for TLS.

## Usage

Every database endpoint published today is licensed, so you need a key with the `db.download` scope; create one in the console. `api_key` is nevertheless an OPTION rather than a requirement: a client built without one sends no `Authorization` header at all, ready for a database served without a license.

```perl
use InternetData;

my $client = InternetData->new(api_key => $ENV{INTERNETDATA_API_KEY});

for my $db (@{ $client->database->list }) {
    print "$db->{base} $db->{standing}\n";
}
```

Every call lives under `$client->database`. The downloads are the whole of this API today, but the sibling VPNDetection client spells the same seven calls the same way, so a program holding both does not have to remember which one is flat.

### The catalog

`list` returns the database *families* your organization may see. A license is held against a family, and the id you download is the one hanging off its `versions`:

```perl
my ($bogon) = grep { $_->{base} eq 'bogon_ip' } @{ $client->database->list };

print $bogon->{standing};             # licensed, expired or unlicensed
print $bogon->{license_type};       # evaluation, standard or redistribute
my $id = $bogon->{versions}[-1]{id};  # bogon_ip_v1, and this is what you download
```

`standing` tells you where you stand against a database, so one you have not bought is still listed and you can see that it exists.

`InternetData::Database::STANDINGS` and `InternetData::Database::LICENSE_TYPES` list every value the two fields take. A family you hold no license for has an undefined `license_type`.

### Metadata

`metadata` describes one database without transferring it - row count, build date, per-format schema, sample rows and exact sizes - so you can decide whether today's build is worth fetching and budget a transfer before starting it:

```perl
my $meta = $client->database->metadata($id);

print $meta->{updated};          # 2026-09-04
print $meta->{entries};          # rows in this build
print $meta->{size}{csvgz};      # bytes
```

### Downloading

There are three ways to fetch one file: straight to disk, as bytes, or as a link you transfer yourself.

```perl
my $written = $client->database->download($id, 'csvgz', "./$id.csv.gz");
my $bytes = $client->database->download_bytes($id, 'csvgz');
my $url = $client->database->download_url($id, 'csvgz');
```

`download` holds nothing but a single chunk in memory whatever the database weighs. It writes to a neighboring `.part` file and renames it on completion, and a transfer that stops short of the length the origin declared is an error rather than a short file, so a path that exists is a whole database and a failed refresh cannot destroy the copy already there.

`download_bytes` holds the **entire file** in memory. The catalog spans seven orders of magnitude, from `bogon_asn_v1` at 264 bytes to `resproxy_ip_14d_v1` at 5.34 GiB, and a 5.34 GiB database is 5.34 GiB of resident memory here, so reach for it at the small end. `metadata` publishes the size per format without transferring anything, which is how you find out which end you are at.

`download_url` hands back the link rather than the bytes, so you choose how to move the file, hand it to a downloader, or pass it on without passing on your API key. The link is presigned and authorizes itself; it authorizes the START of a transfer, so one already running is not interrupted when it lapses. The client never follows that redirect for you. `download` and `download_bytes` do follow it, and that second request carries no API key: object storage has no business holding your credential.

The per-request timeout that bounds an API call is lifted for a transfer. `retries` covers the transfer only until its first byte reaches you: object storage failing before then is retried like any server error, but a transfer that dies part way is not repeated, since a second copy would append to the bytes already written.

A format is `csvgz` or `mmdb`, and `InternetData::Database::FORMATS` lists them. Anything else is refused before a request is made.

### Verifying a download

`checksums` publishes all four digests for one published file, so you can check the bytes you received:

```perl
use Digest::SHA ();

my $sums = $client->database->checksums($id, 'csvgz');
print $sums->{sha256};
```

### Download history

`downloads` is your organization's recent attempts, newest first, refusals included: a denial is what answers "it stopped working", and its absence answers nothing. Without a limit the API applies its own default of 50, and it is clamped to 200.

```perl
for my $attempt (@{ $client->database->downloads(limit => 20) }) {
    print "$attempt->{created} $attempt->{dataset_id} $attempt->{outcome}\n";
}
```

### Errors

Failures die with an `InternetData::Error` carrying a `kind` and a `retryable` flag. It stringifies to its message, so it reads like an ordinary string exception where you do not care which it is:

```perl
my $databases = eval { $client->database->list };
if (my $err = $@) {
    die $err unless ref $err && $err->isa('InternetData::Error');
    warn $err->kind, ' ', $err->status, ' ', $err->retryable, ' ', $err->message;
}
```

`kind` is one of `bad_request`, `unauthorized`, `forbidden`, `rate_limited`, `quota_exceeded`, `server_error` or `network`. `message` is the API's own result code, so a 403 tells you whether it was `NOT_LICENSED` or `LICENSE_EXPIRED`.

Note that `rate_limited` and `quota_exceeded` both arrive as HTTP 429 and are not the same thing. A rate limit is when the API faces extreme traffic bursts and so retrying later works; but a spent quota needs your allowance raised or the window to roll over. The library retries rate limits for you, but not if your quota is exceeded. Nothing else in the 4xx range is retried at all: a misspelled database id is a 404, and asking for it three times gets the same answer three times.

Each attempt gives up after 30 seconds, and a transient failure is retried twice. Both can be changed for the client, and for a single call:

```perl
my $client = InternetData->new(api_key => $key, retries => 4, timeout => 60);
my $databases = $client->database->list(retries => 0, timeout => 5);
```

The timeout is in seconds and applies to each attempt, so a retried call can take longer in total. A transfer isn't bound by it, so `download` and `download_bytes` refuse a per-call `timeout` rather than quietly ignoring it.

### Non-blocking use

Every call has a `_p` twin returning a [Mojo::Promise](https://metacpan.org/pod/Mojo::Promise), so the library drops into a Mojolicious application without a worker or a thread:

```perl
$client->database->download_p($id, 'csvgz', "./$id.csv.gz")
    ->then(sub { print 'wrote ', shift, " bytes\n" })
    ->catch(sub { warn shift })
    ->wait;
```

The blocking calls are those same promises plus a `wait`, so both paths retry identically. Inside an already running event loop the blocking calls cannot block, and say so rather than returning nothing.

### Nothing is cached

The client caches nothing. What your organization may see depends on the key, so a listing held from one client is not an answer for another, and the catalog is small enough that re-reading it costs less than being wrong about whose it was.

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

## Other Libraries

There are official InternetData client libraries available for many languages including PHP, Python, Go, Java, Ruby, and many popular frameworks such as Django, Rails, and Laravel. See our GitHub at https://github.com/internetdata for more.

## About InternetData

InternetData: licensed IP and network intelligence databases covering VPN, proxy, hosting, CDN, relay and Tor address space, published daily as CSV.GZ and MMDB.

[<img src="https://s3.internetdata.io/internetdata-public/brand/mark.svg" alt="InternetData" width="96"/>](https://internetdata.io/)

## License

This project is licensed under the [MIT License](LICENSE).
