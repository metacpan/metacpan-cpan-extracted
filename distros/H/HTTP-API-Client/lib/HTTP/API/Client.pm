package HTTP::API::Client;
$HTTP::API::Client::VERSION = '1.23';
use Moo;

=head1 NAME

HTTP::API::Client - lightweight HTTP/REST client with per-request signing
hooks, retry-with-backoff, and JSON/form encoding

=head1 DESCRIPTION

Talking to an authenticated JSON or form-urlencoded REST API with plain
L<LWP::UserAgent> usually means the same boilerplate on every call: compute
a signature or auth header from the request's own data, remember not to
leak the signing secret into the body, retry on a flaky response, and
serialize Perl values (which have no native boolean and no native
comma-list) unambiguously. C<HTTP::API::Client> is that boilerplate,
written once - a thin L<LWP::UserAgent> wrapper with:

=over 4

=item * An event/callback system (see L</"new_request(%options)">) that computes
header or data values from the rest of the request at build time - the
mechanism for a signed-request header, not a special case bolted on top
of it.

=item * Retry-with-backoff on failed responses, configurable per status
code (see L</"ENVIRONMENT VARIABLES">).

=item * JSON and form-urlencoded body encoding from the same C<%data>
hash, including L<HTTP::API::DataTypeMarker>'s C<xTRUE>/C<xCSV>-family
markers for the values Perl scalars can't represent unambiguously on
their own.

=back

If none of that boilerplate applies to what you're calling - no signing,
no retry policy, plain data - reaching for L<LWP::UserAgent> or
L<HTTP::Tiny> directly is simpler. This module earns its weight
specifically for authenticated API clients that would otherwise
reimplement the same header-signing/retry logic by hand.

=head1 USAGE

 use HTTP::API::Client;

The constructor takes no required arguments:

 my $ua = HTTP::API::Client->new(
     base_url => "https://api.example.com",
 );

=head2 A signed request

This is the case the module exists for: compute an auth header from the
request's own data, once, at construction - every call this client makes
carries it automatically, and the secret used to compute it never appears
in the request itself.

 my $ua = HTTP::API::Client->new(
     base_url => "https://api.example.com",
     pre_defined_data => {
         api_key    => "AKIA123",
         api_secret => sub { "s3cr3t" },    # or read from config/env
     },
     pre_defined_headers => {
         APIKEY    => sub { my (undef, %o) = @_; $o{data}{api_key} },
         Signature => sub {
             my (undef, %o) = @_;
             "$o{data}{api_key}:$o{data}{api_secret}";    # a real HMAC in practice
         },
     },
     pre_defined_events => {
         not_include => { api_secret => 1 },    # keep the secret out of the body/query
     },
 );

 $ua->get("/search", { q => "widgets" });
 # -> GET https://api.example.com/search?api_key=AKIA123&q=widgets
 #    APIKEY: AKIA123
 #    Signature: AKIA123:s3cr3t

See L</"new_request(%options)"> for the full list of build-time hooks this uses.

=head2 Shorthand methods

C<get>/C<post>/C<put>/C<head>/C<delete> are shorthand over C<send()>:

 $ua->get($url);                       # same as $ua->send( GET, $url )
 $ua->post($url, \%data, \%headers);   # same as $ua->send( POST, $url, \%data, \%headers )

=head2 JSON in, JSON out

 my $ua = HTTP::API::Client->new(base_url => "http://example.com");
 $ua->get("/search", { q => "something" });
 my $decoded = $ua->json_response;   # the response body, JSON-decoded

=head2 Form-urlencoded

 my $ua = HTTP::API::Client->new(content_type => "application/x-www-form-urlencoded");
 $ua->post("http://example.com", { q => "something" });
 my $response = $ua->last_response;   # an HTTP::Response object

Body encoding only knows how to serialize into JSON or a query string
(see C<convert_data()> below) - any other content type must be built and
passed in already-encoded.

=head1 ATTRIBUTES

All constructor arguments below are also read-write accessors
(C<< $ua->base_url("http://new-host") >>), except C<engine> which is
read-only after construction. Several fall back to an environment
variable (see L</"ENVIRONMENT VARIABLES">) when not passed explicitly.

=over 4

=item base_url

Prefixed onto every C<$path> passed to C<send()> (and the shorthand
methods). Not set by default - a bare path is used as-is.

=item username / password

HTTP Basic auth credentials. If either is set, Basic auth is used and
C<auth_token> is ignored. Default from C<HTTP_USERNAME>/C<HTTP_PASSWORD>.

=item auth_token

Sent verbatim as the C<Authorization> header when C<username>/C<password>
are both unset. Default from C<HTTP_AUTH_TOKEN>.

=item content_type

Forces the request content type. Left unset, GET defaults to
C<application/x-www-form-urlencoded> and every other method defaults to
C<application/json; charset=$charset>.

=item charset

Used to build the default JSON content-type header and to decide whether
UTF-8 byte-encoding is applied to the request body. Default C<utf8>, from
C<HTTP_CHARSET>. Must be a real L<JSON::XS> charset method name (C<utf8>,
C<latin1>, C<ascii>, ...) - an invalid value dies immediately and clearly,
naming the bad value, the next time C<kvp2json()> is called, whether or
not C<json> has already been built.

=item timeout

Request timeout in seconds, passed to the underlying L<LWP::UserAgent>.
Default C<60>, from C<HTTP_TIMEOUT>. Re-applied to C<ua> at the start of
every C<send()> call, so changing it between calls takes effect on the
next one, not just at construction.

=item ssl_verify

Passed through as C<verify_hostname> to L<LWP::UserAgent>'s C<ssl_opts>.
Default off (C<0>), from C<SSL_VERIFY>. Re-applied to C<ua> at the start
of every C<send()> call, so changing it between calls takes effect on
the next one, not just at construction.

=item pre_defined_data / pre_defined_headers / pre_defined_events

Hashrefs merged underneath the C<%data>/C<%headers>/C<%events> passed to
each individual call - set once at construction time for values every
request should carry (an API key, a fixed header, a standing callback),
then override per-call as needed.

=item engine

Read-only. Defaults to C<"LWP::UserAgent">, the only engine C<send()>
actually dispatches requests through - C<_build_ua> will call a
same-named method on a subclass to build an alternate UA object, but
C<send()> itself does not yet know how to use anything other than
L<LWP::UserAgent> with it (see C<t/12_unsupported_engine.t>: setting a
different engine fails with a clear error rather than silently doing
nothing).

=item last_response

Read-write. The most recent L<HTTP::Response>, set by C<send()> and read by
L</json_response>/L</kvp_response>. C<undef> until the first request.

=item ua

Read-write. The underlying user-agent object C<send()> dispatches through
- an L<LWP::UserAgent> by default, built lazily by C<_build_ua> on first
use, then reused for every subsequent call. Set this directly to inject
a stand-in (a fake, a mock, a pre-configured instance) instead of the
real one; this is how the test suite avoids making real network calls.
C<browser_id>/C<timeout>/C<ssl_verify> are re-applied to it (via
C<< $ua->agent >>/C<< $ua->timeout >>/C<< $ua->ssl_opts >>, each only if
C<ua> supports that method) at the start of every C<send()> call, not
just when it's first built.

=item browser_id

Read-write. The C<User-Agent> header value passed to the underlying
C<ua>. Defaults to C<"HTTP API Client v$VERSION"> - C<$VERSION> is only
set when running the installed CPAN release (Dist::Zilla's
C<[PkgVersion]> plugin injects it at build time), so a development
checkout reports C<"HTTP API Client vdev"> instead. Re-applied to C<ua>
at the start of every C<send()> call, so changing it between calls takes
effect on the next one, not just at construction.

=item retry_config

Read-write hashref C<< { fail_response => $n, fail_status => $csv, delay
=> $seconds } >>. The programmatic equivalent of
C<RETRY_FAIL_RESPONSE>/C<RETRY_FAIL_STATUS>/C<RETRY_DELAY> - set this
directly to configure retry behavior at construction without touching
process environment variables. A partial hashref is fine - any key you
omit falls back to that same env var's default (C<0>/C<''>/C<5>), not to
the environment variable itself. Re-applied at the start of every
C<send()> call, so changing it between calls takes effect on the next
one, not just at construction. See L</"ENVIRONMENT VARIABLES"> for what
each key does.

=item json

Read-write. The L<JSON::XS> instance C<kvp2json()> encodes through and
C<json_response()> decodes through, built lazily with
C<->canonical->allow_nonref>. Set this directly to inject a
differently-configured instance (e.g. one with C<->allow_blessed>
enabled) instead of the default. C<charset> is re-applied to it (via its
C<utf8>/C<latin1>/etc method) at the start of every C<kvp2json()>/
C<json_response()> call, not just when C<json> is first built, so a
C<charset> change takes effect on the next encode or decode even if
C<json> was already in use - this also applies to an injected custom
instance.

=back

=head1 ENVIRONMENT VARIABLES

These environment variables expose the controls without changing the existing code.

HTTP VARIABLES

 HTTP_USERNAME   - basic auth username
 HTTP_PASSWORD   - basic auth password
 HTTP_AUTH_TOKEN - basic auth token string
 HTTP_CHARSET    - content type charset. default utf8
 HTTP_TIMEOUT    - timeout the request in seconds. default 60 seconds.
 SSL_VERIFY      - verify ssl url. default is off

DEBUG VARIABLES

 DEBUG_IN_OUT               - print out request and response in string to STDERR
 DEBUG_SEND_OUT             - print out request in string to STDERR
 DEBUG_RESPONSE             - print out response in string to STDERR
 DEBUG_RESPONSE_HEADER_ONLY - print out response header only without the body
 DEBUG_RESPONSE_IF_FAIL     - narrows DEBUG_IN_OUT/DEBUG_RESPONSE to only print
                              on a failed response. Does nothing by itself -
                              DEBUG_IN_OUT or DEBUG_RESPONSE must also be set.

RETRY VARIABLES

 RETRY_FAIL_RESPONSE  - number of time to retry if response comes back is failed. default 0 retry.
                        A negative value is clamped to 0 (no retry) rather than silently
                        making zero attempts.
 RETRY_FAIL_STATUS    - only retry if specified status code. e.g. 500,404
                        An empty entry (a doubled comma, stray whitespace) is
                        skipped rather than becoming a bogus always-false entry.
 RETRY_DELAY          - retry with wait time of 5 seconds in between, by default. A negative
                        value is clamped to 0 rather than reaching sleep() as-is.

=head1 METHODS

=head2 get / post / put / head / delete ($path, \%data, \%headers, \%events)

Shorthand for C<send($METHOD, $path, \%data, \%headers, \%events)>. C<$path>
is appended to the C<base_url> attribute if one was given. Returns whatever
C<send()> returns - normally an L<HTTP::Response>.

=head2 send($method, $path, \%data, \%headers, \%events)

Builds and sends one HTTP request, retrying per L</"ENVIRONMENT VARIABLES">
if configured. C<%data> and C<%headers> are merged over C<pre_defined_data>
and C<pre_defined_headers>. C<%events> are the per-call callbacks documented
under C<new_request()> below. Sets and returns the C<last_response>
attribute.

None of C<\%data>/C<\%headers>/C<\%events> are mutated - C<send()> copies
each before doing anything with it, so a hashref you pass in (and may
reuse across other calls) comes back exactly as you passed it, with no
merged-in C<pre_defined_*> keys or event-hook keys added by C<send()>'s
own machinery.

Passing C<< $events->{test_request_object} = 1 >> makes it return the built
L<HTTP::Request> instead of sending it - the way this module's own test
suite inspects what would have gone out.

=head2 json_response

Decode the C<last_response> body as JSON and return the resulting hashref.
Never dies - a missing response or invalid JSON comes back as
C<< { status => "error", error => $message } >> instead. C<charset> is
re-applied to C<json> at the start of every call, the same as
C<kvp2json()> does on the encode side, so a C<charset> change takes
effect on the next decode too.

=head2 kvp_response

Parse the C<last_response> body as a C<key=value&key=value> query string
and return it as a hashref. Returns C<{}> if no request has been made yet,
or the response body is empty. A key that repeats (the shape
C<kvp2str_each> produces when encoding an array-valued field) decodes to
an arrayref of every value seen, in order; a key seen once still decodes
to a plain scalar. Decodes both percent-encoding and the
C<application/x-www-form-urlencoded> convention of a literal C<+> meaning
a space (a genuinely percent-encoded literal C<+>, i.e. C<%2B>, still
decodes to C<+>) - this matters for a response body from any API, not
just one built by this module's own C<kvp2str_each>, which never emits a
raw C<+> itself. An empty C<&>-separated segment (a leading, trailing,
or doubled C<&>) is skipped rather than decoded into a bogus
C<< '' => undef >> entry.

=head2 new_request(%options)

Builds the L<HTTP::Request> for one call. This is where the C<%events>
callbacks passed to C<send()> are read: C<before_headers>, C<headers_keys> /
C<add_headers_keys> (which header keys to consider, in what order),
C<before_header>/C<after_header> keyed by header name, and
C<after_header_keys> - the hooks used to compute things like a signature
header from other data at build time. See F<t/04_callbacks.t> for a worked
example (API key + signature).

C<%options> also accepts C<skip_headers>, a hashref of header names to
exclude from the request no matter what C<%headers> or the events above
say. Only reachable by calling C<new_request()> directly with it - C<send()>
never sets it, and setting it inside an C<%events> callback has no effect
(a callback receives a snapshot copy of C<%options>, not the one
C<new_request()> itself is iterating). See F<t/23_skip_headers.t>.

=head2 get_content_type(%options)

Resolves the effective content type for one call: the C<content_type>
attribute if set explicitly; otherwise C<application/x-www-form-urlencoded>
for a GET, or C<application/json; charset=$charset> for anything else.
Called internally by C<convert_data()>, C<prepare_request()>, and
C<new_request()> - there is normally no need to call this directly.

=head2 convert_data(%options)

Turn C<%options>'s C<data> hashref into the request body, according to
content type: JSON via C<kvp2json()> if the content type contains C<json>,
a query string via C<kvp2str()> if it is exactly
C<application/x-www-form-urlencoded>. Any other content type returns an
empty string for empty data, or dies naming the content type - there is no
generic way to serialize arbitrary data into an arbitrary content type.

=head2 prepare_request(%options)

Builds the bare L<HTTP::Request> (method, URL, content-type header) and
applies authentication: C<username>/C<password> take priority and are sent
as HTTP Basic auth via C<basic_authenticator()>; C<auth_token> is used only
if neither is set, and is sent as a raw C<Authorization> header value
verbatim (no C<Bearer> prefix is added for you - include it in the token
itself if the API expects one). C<auth_token> only supplies a I<default>
C<Authorization> header - an explicit one already present in C<%headers>
for this call (any casing: C<Authorization>, C<authorization>, ...) is
left alone rather than overwritten. Called by C<new_request()> - there is
normally no need to call this directly.

=head2 basic_authenticator($request, $username, $password)

Sets HTTP Basic auth on C<$request> via
C<< $request->headers->authorization_basic >>. Override this in a subclass
to change how basic auth is applied without touching the rest of request
building.

=head2 kvp2json(%options) / kvp2str(%options)

The two body encoders C<convert_data> dispatches to. C<kvp2json> walks
C<%options>'s C<data> hashref and JSON::XS-encodes it, resolving any
C<CODE> values by calling them and unwrapping L<HTTP::API::DataTypeMarker>'s
C<xBOOLEAN>-family markers into their JSON form; an C<xCSV>-marked value
has no special JSON handling and just JSON-encodes as an ordinary array
(there's no C<key=value&key=value> repetition problem in JSON for it to
solve). C<kvp2str> produces a C<key=value&key=value> query string instead,
with C<xCSV>-marked values joined by commas instead of repeated per key.
An empty arrayref value is omitted from C<kvp2str>'s output entirely (an
empty array has no C<key=value> representation), the same as a key
mapped to C<undef>/missing already is - including an empty array nested
inside an C<xCSV(...)> list, which contributes nothing to the joined
string rather than leaving a blank comma segment behind. An C<xCSV()>
with no elements at all is different: it still emits C<key=> (present,
empty value) rather than being omitted - there is no join-corruption
risk to avoid the way there is for a nested empty array, and C<key=> is
valid, parseable form data distinct from the key being absent.
Both respect an C<< $events->{keys} >> callback to control which keys are
included and in what order, and both accept a C<skip_key> hashref in
C<%options> (same reachability caveat as C<new_request()>'s
C<skip_headers> above - only useful from a direct call, e.g. a C<data>
callback recursively re-invoking C<kvp2str()>/C<kvp2json()> on itself to
build its own value without infinite-looping on its own key; see
F<t/04_callbacks.t>) to exclude a key from the encoded body.

C<kvp2str> alone also fires C<< $events->{before_sorting_keys} >> and
C<< $events->{after_sorting_keys} >>, each called with C<< keys => \@keys
>> - an arrayref of the field names about to be (respectively, just
were) sorted. Both are genuinely live: a callback that mutates
C<@$keys> in place (push/splice/grep out an element) changes what
C<kvp2str> actually encodes, as long as C<< $events->{keys} >> isn't
also set (which replaces C<@keys> outright, discarding
C<before_sorting_keys>' mutation). See F<t/21_before_events.t> and
F<t/33_before_sorting_keys_mutation.t>. C<kvp2json> has no equivalent
hook - its C<@keys> is either C<< $events->{keys} >>'s return value or
an unsorted C<keys %$data>, with no separate sorting step to hook into.

C<kvp2json> encodes a numeric-looking string value as a genuine JSON
number rather than a quoted string - but only when doing so loses
nothing (stringifying the number back reproduces the original value
exactly). A value like C<"5"> becomes C<5>, but C<"00501"> (a US zip
code) or C<"5.0"> stays a string, since numifying either would silently
discard meaningful formatting. A value like C<"NaN">, C<"Inf">, or
C<"-Inf"> also stays a string even though it round-trips losslessly as
a Perl number - JSON has no valid representation for a non-finite
number, and numifying it would make C<kvp2json> emit the bareword
C<nan>/C<inf>/C<-inf>, which is not valid JSON and no parser (including
this module's own JSON::XS) can decode. C<kvp2str> never numifies at
all - a query string has no separate number/string type, so there was
never a reason to risk altering the original representation.

=head2 kvp2json_each(%options) / kvp2str_each(%options)

The per-value helpers C<kvp2json()>/C<kvp2str()> recurse into for each key
via C<%options>'s C<value> (and C<key> - the field's own key, available
to a C<CODE> value's callback via C<%options>; C<kvp2json_each> passes it
through at every level, including a nested hash value's own key, not
just the top-level field's). Resolves a C<CODE> value by calling it,
unwraps L<HTTP::API::DataTypeMarker> markers (C<xCSV>/C<xBOOLEAN> and
friends), and recurses into plain array values. There is normally no
need to call these directly - they exist as public methods so a
C<data>/C<value> callback can recursively re-invoke them on itself (see
C<kvp2json()>/C<kvp2str()> above).

These two are not symmetric on invalid input, in two ways. First,
C<kvp2json_each> dies if a raw-bytes (non-UTF8-flagged) value is not
valid UTF-8, rather than silently corrupting it into C<U+FFFD>
replacement characters - JSON has no way to represent arbitrary bytes.
C<kvp2str_each> has no such restriction; a query string can carry any
byte sequence unescaped-safe via percent-encoding, so the same input
that dies in the JSON path passes through the form-urlencoded path
unchanged. Second, a plain hash value recurses in C<kvp2json_each> (JSON
has a native object type for it) but dies in C<kvp2str_each> - a query
string has no standard convention for representing a nested hash.

Both die - with the same message, naming the offending ref type and
pointing at C<xBOOLEAN()> - on any other reference type neither of them
otherwise recognizes, most commonly a bare (not C<xBOOLEAN>-wrapped)
scalar ref: a value like C<< \$flag >> passed directly, typically from
forgetting to call C<xBOOLEAN(\$flag)> around it. Before this die was
added, C<kvp2str_each> silently stringified such a value as
C<SCALAR(0x...)>, and C<kvp2json_each> reached the same outcome only by
accident of JSON::XS itself refusing to encode an arbitrary scalar ref
- with a message that never mentioned this module's own vocabulary.

C<kvp2str_each>'s C<%options> also accepts C<no_key>, set internally when
recursing into an ARRAY or C<xCSV> element: when true, the returned
fragment omits the leading C<key=> prefix (a plain scalar, C<xCSV>, and
C<xBOOLEAN>-marked value all honor this identically) so a CSV/array
element joins as a bare value rather than a spurious embedded
C<key=value> pair.

Both encoders unwrap an C<xBOOLEAN(\$flag)> live scalar ref to whatever
C<$flag> currently holds, not just the C<0>/C<1> case C<xTRUE>/C<xFALSE>
use - a live ref that currently holds exactly (C<eq>, not merely
numerically C<==>) the string C<0> or C<1> still becomes a native JSON
boolean in C<kvp2json_each> (matching C<xTRUE>/C<xFALSE>; JSON::XS's own
convention only accepts that exact canonical form, not e.g. C<"01"> or
C<"1.0">), but any other live value - including one that is numerically
equal to C<0>/C<1> without being formatted exactly that way - encodes as
its own actual contents in both encoders alike, the same way a plain
(non-live) C<xBOOLEAN> value already did - including
C<kvp2json_each>'s invalid-UTF-8 die documented above, which a live
non-canonical value goes through exactly like the plain-scalar case
does. A live value that currently holds C<undef> is treated as an
empty string in both encoders, not C<undef> itself - it never reaches
the invalid-UTF-8 check (an empty string is trivially valid UTF-8) and
encodes as C<""> in JSON, matching how C<kvp2str_each> already handled
this case.

A plain (non-live) C<xBOOLEAN> value - anything other than the
C<\1>/C<\0> shape C<xTRUE>/C<xFALSE> use, including a value passed to
C<xBOOLEAN()> directly with no leading backslash - goes through the
exact same invalid-UTF-8 die and lossless-numify treatment in
C<kvp2json_each> as the plain scalar branch: C<xBOOLEAN("5")> encodes as
the JSON number C<5>, and invalid UTF-8 bytes die with the same message
rather than silently corrupting into JSON, just like a plain scalar
value with the identical content would.

C<xBOOLEAN()> only accepts a plain scalar or a scalar ref - wrapping
anything else (an arrayref, a hashref) dies with a clear message naming
the offending ref type in both encoders, rather than silently
stringifying it (e.g. into C<"HASH(0x...)">) the way an unmarked
reference of the wrong shape does elsewhere in this module (see
C<kvp2str_each>'s nested-hash die, above).

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Michael Vu.

This is free software, licensed under:

  The MIT (X11) License

The MIT License

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to
whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall
be included in all copies or substantial portions of the
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT
SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

use Encode;
use HTTP::Headers;
use HTTP::Request;
use JSON::XS;
use LWP::UserAgent;
use Try::Tiny;
use URI;
use URI::Escape qw( uri_escape uri_unescape );
use Scalar::Util qw( looks_like_number );
use POSIX qw( isnan isinf );
use HTTP::API::DataTypeMarker;

extends 'Exporter';

our @EXPORT = qw( xCSV xBOOLEAN
    xTRUE xFALSE
    xTrue xFalse
    xtrue xfalse
    xt__e xf___e
);

has username => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_username { _defor($ENV{HTTP_USERNAME}, '') }

has password => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_password { _defor($ENV{HTTP_PASSWORD}, '') }

has auth_token => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_auth_token { _defor($ENV{HTTP_AUTH_TOKEN}, '') }

has base_url => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_base_url {}

has last_response => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_last_response {}

has charset => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_charset { _defor($ENV{HTTP_CHARSET}, "utf8") }

has browser_id => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_browser_id {
    my $ver = _defor($HTTP::API::Client::VERSION, 'dev');
    return "HTTP API Client v$ver";
}

has content_type => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_content_type {}

sub get_content_type {
    my ($self, %o) = @_;
    my $content_type = $self->content_type;

    if ($content_type) {
        return $content_type;
    }

    my $method = ${$o{method}};

    if ($method eq 'GET') {
        return 'application/x-www-form-urlencoded';
    }

    my $charset = $self->charset;
    return "application/json; charset=$charset";
}

has engine => (
    is      => "ro",
    lazy    => 1,
    builder => 1,
);

sub _build_engine {"LWP::UserAgent"}

has ua => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_ua {
    my ($self)     = @_;
    my $ssl_verify = $self->ssl_verify;
    my $engine     = $self->engine;

    my $ua;

    if ( $engine eq "LWP::UserAgent" ) {
        $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => $ssl_verify } );
        $ua->agent( $self->browser_id );
        $ua->timeout( $self->timeout );
    }
    else {
        $ua = $self->$engine($ssl_verify);
    }

    return $ua;
}

has ssl_verify => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_ssl_verify {
    return _defor( $ENV{SSL_VERIFY}, 0 );
}

# send() does NOT read this attribute - since HAC-068 it calls
# $self->_build_retry directly on every call, so retry_config changes
# take effect live. This accessor is kept only for external callers who
# already read $api->retry directly; it's a one-time snapshot at
# whatever moment it's first accessed, not a live view of send()'s
# actual behavior.
has retry => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_retry {
    my ($self) = @_;
    my %retry  = %{ _defor($self->retry_config, {}) };
    my $count  = _defor( $retry{fail_response}, 0 );
    $count = 0 if looks_like_number($count) && $count < 0;
    my %status = map { $_ => 1 }
        grep { length }
        map { s/^\s+|\s+$//g; $_ }
        split /,/, _defor($retry{fail_status}, '');

    my $delay = _defor( $retry{delay}, 5 );

    return {
        count  => $count,
        status => \%status,
        delay  => $delay,
    };
}

has retry_config => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_retry_config {
    return {
        fail_response => _defor( $ENV{RETRY_FAIL_RESPONSE}, 0 ),
        fail_status => _defor($ENV{RETRY_FAIL_STATUS}, ''),
        delay => _defor( $ENV{RETRY_DELAY}, 5 ),
    };
}

has timeout => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_timeout { _defor($ENV{HTTP_TIMEOUT}, 60) }

has json => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_json {
    my ($self) = @_;
    return _apply_charset( JSON::XS->new->canonical->allow_nonref, $self->charset );
}

sub _apply_charset {
    my ($json, $charset) = @_;
    eval { $json->$charset; 1 } or die "Unsupported charset '$charset': $@";
    return $json;
}

has debug_flags => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_debug_flags {
    return {
        in_out               => $ENV{DEBUG_IN_OUT},
        send_out             => $ENV{DEBUG_SEND_OUT},
        response             => $ENV{DEBUG_RESPONSE},
        response_header_only => $ENV{DEBUG_RESPONSE_HEADER_ONLY},
        response_if_fail     => $ENV{DEBUG_RESPONSE_IF_FAIL},
    };
}

has pre_defined_data => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_pre_defined_data {{}}

has pre_defined_headers => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_pre_defined_headers {{}}

has pre_defined_events => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_pre_defined_events {{}}

sub get {
    my ($self, @args) = @_;
    return $self->send( GET => @args );
}

sub post {
    my ($self, @args) = @_;
    return $self->send( POST => @args );
}

sub put {
    my ($self, @args) = @_;
    return $self->send( PUT => @args );
}

sub head {
    my ($self, @args) = @_;
    return $self->send( HEAD => @args );
}

sub delete {
    my ($self, @args) = @_;
    return $self->send( DELETE => @args );
}

sub _execute_callbacks {
    my ($self, $type, %options) = @_;

    my $sth = $options{$type};

    for my $key (keys %$sth) {
        my $callback = $sth->{$key};
        next if !defined $callback;
        next if !UNIVERSAL::isa($callback, 'CODE');
        $sth->{$key} = $self->$callback(key => $key, %options);
    }
}

sub send {
    my ($self, $method, $path,
        $data, $headers, $events) = @_;

    $method  = uc $method;
    $path    = _defor( $path,    '' );
    $data    = { %{ _defor( $data,    {} ) } };
    $headers = { %{ _defor( $headers, {} ) } };
    $events  = { %{ _defor( $events,  {} ) } };

    my $base_url     = $self->base_url;
    my $url          = $base_url ? $base_url . $path : $path;
    my $ua           = $self->ua;
    $ua->agent( $self->browser_id ) if $ua->can('agent');
    $ua->timeout( $self->timeout ) if $ua->can('timeout');
    $ua->ssl_opts( verify_hostname => $self->ssl_verify ) if $ua->can('ssl_opts');
    my $retry_settings = $self->_build_retry;
    my $retry_count  = _defor( $retry_settings->{count}, 1 );
    my $retry_delay  = _defor( $retry_settings->{delay}, 5 );
    $retry_delay = 0 if looks_like_number($retry_delay) && $retry_delay < 0;
    my %retry_status = %{ _defor($retry_settings->{status}, {}) };
    my %debug        = %{ _defor($self->debug_flags, {}) };
    my $eng          = $self->engine;

    if ( my $pd = $self->pre_defined_data ) {
        %$data = ( %$pd, %$data );
    }

    if ( my $ph = $self->pre_defined_headers ) {
        %$headers = ( %$ph, %$headers );
    }

    if ( my $pe = $self->pre_defined_events ) {
        %$events = ( %$pe, %$events );
    }

    my %options = (
        method  => \$method,
        url     => \$url,
        path    => \$path,
        data    => $data,
        headers => $headers,
        events  => $events,
    );

    $self->_execute_callbacks(data    => %options);
    $self->_execute_callbacks(headers => %options);

    my $response;

  RETRY:
    foreach my $retry ( 0 .. $retry_count ) {
        my $started_time = time;

        if ( $eng eq 'LWP::UserAgent' ) {
            my $req = $self->new_request( %options );

            if ($events->{test_request_object}) {
                return $req;
            }

            $response = $ua->request($req);
        }
        else {
            die "Unsupported engine: $eng - only LWP::UserAgent is currently wired up in send()";
        }

        my $suppress_on_success = $debug{response_if_fail} && $response->is_success;

        if ( $debug{send_out} || ( $debug{in_out} && !$suppress_on_success ) ) {
            print STDERR "-- REQUEST --\n";
            if ( $retry_count && $retry ) {
                print STDERR "-- RETRY $retry of $retry_count\n";
            }
            print STDERR $response->request->as_string;
            print STDERR "\n";
        }

        my $debug_response = _defor($debug{in_out}, $debug{response});

        $debug_response = 0
          if $suppress_on_success;

        if ($debug_response) {
            my $used_time = time - $started_time;

            print STDERR "-- RESPONSE $used_time sec(s) --\n";

            print STDERR $debug{response_header_only}
              ? $response->headers->as_string
              : $response->as_string;

            print STDERR ( "-" x 80 ) . "\n";
        }

        last RETRY    ## request is success, not further for retry
          if $response->is_success;

        last RETRY    ## no attempts left, don't sleep for a retry that won't happen
          if $retry >= $retry_count;

        if ( !%retry_status ) {
            sleep $retry_delay;
            ## no retry pattern at all then just retry
            next RETRY;
        }

        $retry_status{ $response->code }
          or
          last RETRY;  ## status code not in RETRY_FAIL_STATUS, just stop retry

        sleep $retry_delay;
        next RETRY;
    }

    return $self->last_response($response);
}

sub json_response {
    my ($self) = @_;

    my $response = try {
        my $content = _defor($self->last_response->decoded_content, '{}');
        my $json = _apply_charset( $self->json, $self->charset );
        $json->decode($content);
    }
    catch {
        my $error = $_;
        { status => "error", error => $error };
    };

    return $response;
}

sub kvp_response {
    my ($self) = @_;

    my $response = $self->last_response
        or return {};

    my $content = $response->decoded_content
        or return {};

    my %data;
    for my $pair ( split /&/, $content ) {
        next if $pair eq '';
        my ( $k, $v ) = map { ( my $s = $_ ) =~ tr/+/ /; uri_unescape($s) } split /=/, $pair, 2;
        if ( exists $data{$k} ) {
            $data{$k} = [ $data{$k} ] unless ref $data{$k} eq 'ARRAY';
            push @{ $data{$k} }, $v;
        }
        else {
            $data{$k} = $v;
        }
    }

    return \%data;
}

sub new_request {
    my ($self, %o) = @_;

    my ($method, $url) = map { $$_ } @o{qw(method url)};

    my ($data, $headers, $events) = @o{qw(data headers events)};

    my $content_type = $self->get_content_type(%o);

    my $content = $self->convert_data(%o);

    if ($content) {
        if ($self->charset eq 'utf8') {
            $content = _tune_utf8($content);
        }
    }

    my $request;

    if ($method eq 'GET') {
        if ($content_type ne 'application/x-www-form-urlencoded') {
            die "Unable to create a get request with content_type: $content_type";
        }
        elsif ($content) {
            if ($url =~ m/\?/) {
                $request = $self->prepare_request(%o, url => \"$url&$content");
            }
            else {
                $request = $self->prepare_request(%o, url => \"$url?$content");
            }
        }
        else {
            $request = $self->prepare_request(%o);
        }
    }
    elsif ($content) {
        $request = $self->prepare_request(%o);
        $request->content($content);
    }
    else {
        $request = $self->prepare_request(%o);
    }

    %o = (%o,
        request => $request,
        content => \$content,
    );

    if (my $do = $events->{before_headers}) {
        $self->$do(%o);
    }

    my @keys;

    if (my $keys = $events->{headers_keys}) {
        @keys = $self->$keys(%o);
    }
    elsif (my $add = $events->{add_headers_keys}) {
        my %seen;
        @keys = sort grep { !$seen{$_}++ } $self->$add(%o), keys %$headers;
    }
    else {
        @keys = sort keys %$headers;
    }

    foreach my $key ( @keys ) {
        if (my $do = $events->{before_header}{$key}) {
            $headers->{$key} = $self->$do(%o);
        }

        next if $o{skip_headers}{$key} || !exists $headers->{$key} || !defined $headers->{$key};

        $request->header( $key => _encode_if_utf8_flagged( $headers->{$key} ) );

        if (my $do = $events->{after_header}{$key}) {
            $self->$do(%o);
        }
    }

    if (my $do = $events->{after_header_keys}) {
        $self->$do(%o);
    }

    return $request;
}

sub prepare_request {
    my ($self, %o) = @_;

    my ($method, $url) = map { $$_ } @o{qw(method url)};

    my ($headers) = @o{qw(headers)};

    my $request = HTTP::Request->new( $method => $url );

    $request->content_type($self->get_content_type(%o));

    my ($u, $p, $at) = map { _defor($self->$_, '') }
        qw(username password auth_token);

    if ($u || $p) {
        $self->basic_authenticator( $request,
            _encode_if_utf8_flagged($u), _encode_if_utf8_flagged($p) );
    }
    elsif ($at) {
        $headers->{authorization} = $at
            unless grep { lc($_) eq 'authorization' } keys %$headers;
    }

    return $request;
}

sub _tune_utf8 {
    my ($content) = @_;

    my $req = HTTP::Request->new( POST => "http://find-encoding.com" );

    try {
        $req->content($content);
    }
    catch {
        my $error = $_;
        if ( $error =~ /content must be bytes/ ) {
            eval { $content = Encode::encode( utf8 => $content ); };
        }
    };
    return $content;
}

sub _should_skip_key {
    my (%o) = @_;
    my ($key, $data) = @o{qw(key data)};
    return $o{skip_key}{$key} || !exists $data->{$key} || !defined $data->{$key};
}

sub _encode_if_utf8_flagged {
    my ($v) = @_;
    return utf8::is_utf8($v) ? Encode::encode( utf8 => $v ) : $v;
}

sub _uri_escape_bytes_or_chars {
    my ($v) = @_;
    return uri_escape( _encode_if_utf8_flagged($v) );
}

sub _json_validate_utf8 {
    my ($v) = @_;
    return $v if utf8::is_utf8($v);
    my $decoded = eval { Encode::decode( utf8 => $v, Encode::FB_CROAK ) };
    die sprintf(
        "kvp2json_each: value is not valid UTF-8, refusing to silently corrupt it into JSON (raw bytes: %v02x)\n",
        $v
    ) if !defined $decoded;
    return $decoded;
}

sub _numify_if_lossless {
    my ($v) = @_;
    return $v if !looks_like_number($v);
    # NaN/Infinity have no valid JSON representation - JSON::XS's utf8-mode
    # encoder emits them as the bareword nan/inf/-inf, which is not valid
    # JSON. Leave the original string untouched rather than numifying into
    # a token no JSON parser (including JSON::XS itself) can decode.
    return $v if isnan($v + 0) || isinf($v + 0);
    # Compare against a throwaway stringified copy, not $v+0 itself - comparing
    # a number with eq caches a string form on that same scalar (SvPOK), and
    # JSON::XS then encodes it as a JSON string instead of a JSON number.
    my $stringified = ($v + 0) . '';
    return $v eq $stringified ? $v + 0 : $v;
}

sub convert_data {
    my ($self, %o) = @_;

    my ($data, $events) = @o{qw(data events)};

    my $content_type = $self->get_content_type(%o);

    if ($content_type =~ m/json/) {
        return $self->kvp2json(%o);
    }
    elsif ($content_type eq 'application/x-www-form-urlencoded') {
        return $self->kvp2str(%o);
    }
    else {
        return '' if !%$data;
        die "Unable to convert data for content_type: $content_type";
    }
}

sub kvp2json {
    my ($self, %o) = @_;

    my ($data, $events) = @o{qw(data events)};

    my $json = _apply_charset( $self->json, $self->charset );

    my @keys;

    if (my $do = $events->{keys}) {
        @keys = $self->$do(%o);
    }
    else {
        @keys = keys %$data;
    }

    my %data = ();

    foreach my $key(@keys) {
        if ($events->{not_include}{$key}) {
            next
        }
        next if _should_skip_key(%o, key => $key);
        $data{$key} = $self->kvp2json_each(%o, key => $key, value => $data->{$key});
    }

    return $json->encode(\%data);
}

sub kvp2json_each {
    my ($self, %o) = @_;

    my ($v) = map { _defor($_, '') } @o{qw( value )};

    if (UNIVERSAL::isa($v, 'CODE')) {
        $v = $self->$v(%o);
    }

    if (!ref $v) {
        return _numify_if_lossless( _json_validate_utf8($v) );
    }
    elsif (ref $v eq 'BOOL') {
        my $inner = $v->[0];
        if ( ref $inner eq 'SCALAR' ) {
            my $live_value = _defor( $$inner, '' );
            if ( !( $live_value eq '0' || $live_value eq '1' ) ) {
                return _numify_if_lossless( _json_validate_utf8($live_value) );
            }
            return $inner;
        }
        die "xBOOLEAN() only accepts a plain scalar or a scalar ref, not a "
            . ref($inner) . " ref\n" if ref $inner;
        return _numify_if_lossless( _json_validate_utf8( _defor( $inner, '' ) ) );
    }
    elsif (UNIVERSAL::isa($v, 'ARRAY')) {
        my @parts;

        foreach my $val(@$v) {
            push @parts, $self->kvp2json_each(%o, value => $val);
        }

        return \@parts;
    }
    elsif (UNIVERSAL::isa($v, 'HASH')) {
        my %parts;

        foreach my $key(keys %$v) {
            $parts{$key} = $self->kvp2json_each(%o, key => $key, value => $v->{$key});
        }

        return \%parts;
    }

    die "Unable to convert a " . ref($v) . " reference into JSON for key '"
        . _defor( $o{key}, '' ) . "' - wrap it in xBOOLEAN() if you meant a "
        . "live boolean/tracked value\n";
}

sub kvp2str {
    my ($self, %o) = @_;

    my ($data, $events) = @o{qw(data events)};

    my @keys = keys %$data;

    if (my $do = $events->{before_sorting_keys}) {
        $self->$do(%o, keys => \@keys);
    }

    if (my $do = $events->{keys}) {
        @keys = $self->$do(%o);
    }
    else {
        @keys = sort @keys;
    }

    if (my $do = $events->{after_sorting_keys}) {
        $self->$do(%o, keys => \@keys);
    }

    my @parts;

    foreach my $key(@keys) {
        next if $events->{not_include}{$key};
        next if _should_skip_key(%o, key => $key);
        my $part = $self->kvp2str_each(%o, key => $key, value => $data->{$key});
        push @parts, $part if length $part;
    }

    return join '&', @parts;
}

sub kvp2str_each {
    my ($self, %o) = @_;

    my ($raw_key, $v) = map { _defor($_, '') } @o{qw( key value )};

    my $k = _uri_escape_bytes_or_chars($raw_key);

    if (UNIVERSAL::isa($v, 'CODE')) {
        $v = $self->$v(%o, key => $k);
    }

    if (!ref $v) {
        $v = _uri_escape_bytes_or_chars($v);

        if ($o{no_key}) {
            return $v;
        }
        else {
            return "$k=$v";
        }
    }
    elsif (ref $v eq 'BOOL') {
        my $inner = $v->[0];
        die "xBOOLEAN() only accepts a plain scalar or a scalar ref, not a "
            . ref($inner) . " ref\n" if ref $inner && ref $inner ne 'SCALAR';
        my $bool_value = ref $inner eq 'SCALAR' ? $$inner : $inner;
        my $escaped = _uri_escape_bytes_or_chars( _defor($bool_value, '') );
        return $o{no_key} ? $escaped : "$k=$escaped";
    }
    elsif (ref $v eq 'ARRAY') {
        my @parts;

        foreach my $val(@$v) {
            my $part = $self->kvp2str_each(%o, key => $raw_key, value => $val, no_key => 0);
            push @parts, $part if length $part;
        }

        return '' if !@parts;

        return ($o{no_key} ? '&' : '') . join '&', @parts;
    }
    elsif (ref $v eq 'CSV') {
        my @csv;
        my @parts;

        foreach my $val(@$v) {
            next if ref $val eq 'ARRAY' && !@$val;

            my $part = $self->kvp2str_each(%o, key => $raw_key, value => $val, no_key => 1);

            if ($part =~ m/&/) {
                push @parts, $part;
            }
            else {
                push @csv, $part;
            }
        }

        my $csv = ($o{no_key} ? '' : "$k=") . join( ',', @csv);

        if (@parts) {
            return join '&', $csv, map { s/^&//r } @parts;
        }

        return $csv;
    }
    elsif (UNIVERSAL::isa($v, 'HASH')) {
        die "Unable to convert nested hash value for key '$k' into a form-urlencoded query string";
    }

    die "Unable to convert a " . ref($v) . " reference into a form-urlencoded "
        . "query string value for key '$k' - wrap it in xBOOLEAN() if you meant "
        . "a live boolean/tracked value\n";
}

sub basic_authenticator {
    my ($self, $req, $u, $p) = @_;
    return $req->headers->authorization_basic($u, $p);
}

sub _defor {
    my ($default, $or) = @_;
    return (defined($default) && length($default)) ? $default : $or;
}

no Moo;

1;
