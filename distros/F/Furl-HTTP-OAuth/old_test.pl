#!/usr/bin/perl

use lib './lib';
use Furl::HTTP::OAuth;
use URI;
use Encode;
use JSON::XS;

my $client = Furl::HTTP::OAuth->new(
    consumer_key => "vgyYVbu7yljXXd2MZTfDmw",
    consumer_secret => "QnS5arFmnmeQQ-iB_Zbi9MuocY0",
    signature_method => "HMAC-SHA1",
    token => "9AkV-RywDkMD5JTZUUYeCltl2rbhCR2p",
    token_secret => "PRMLwzaY17Zb8fsPR9aMx7LQzbI"
);

my ($version, $code, $msg, $headers, $body) = $client->get('https://api.yelp.com/v2/search?term=Food&location=San+Francisco');

use Data::Dumper;
warn Dumper({
    version => $version,
    code => $code,
    message => $msg,
    headers => $headers,
    body => decode_json($body)
});


    # consumer_key => "9djdj82h48djs9d2",
    # consumer_secret => "consumersecret",
    # signature_method => "HMAC-SHA1",
    # token => "kkk9d7dh3k39sjv7",
    # token_secret => "tokensecret"
# $url, $method, $content, $headers, $write_file, $write_code

exit;


my $url = 'http://google.com/blah';
my $uri = URI->new($url);
$uri->query_form(
    b5 => '=%3D',
    a3 => 'a',
    'c@' => '',
    a2 => 'r b',
    c2 => '',
    a3 => '2 q'
);

warn "url: " . $uri->as_string;

warn "string: " . $client->request(
    method => 'GET',
    url => $uri->as_string
);

exit;

    # "137131201" - timestamp
    # "7d8f3e4a"- nonce

#sub decode_param {
#    my $param = shift;
#    URI::Escape::uri_unescape($param);
#}

# oauth_consumer_key
# oauth_consumer_secret
# oauth_nonce
# oauth_signature_method
# oauth_timestamp
# oauth_token
# oauth_token_secret

# FURL HANDLES THESE INPUT TYPES TO ->REQUEST
# potential input types
# - HTTP::Request (see HTTP::Message)
# - filehandle for binary?
# - hashref of parameters and/or parameters in the URL
# - arrayref of parameters and/or parameters in the URL

# OAUTH REQUIRES HANDLING OF THESE PARAMETERS (SIG GENERATION)
# - query component of URI
# - The OAuth HTTP "Authorization" header field (Section 3.5.1) if
#      present.  The header's content is parsed into a list of name/value
#      pairs excluding the "realm" parameter if present.  The parameter
#      values are decoded as defined by Section 3.5.1.
# - the request body IF 
#     1. body is single part 
#     2. body is application/x-www-form-urlencoded
#     3. body Content-Type is application/x-www-form-urlencoded
# - EXCLUDE "oauth_signature" parameter from sig generation IF PRESENT

# SIGNATURE GENERATION
# Parts:
# - HTTP METHOD
# - authority as declared by http "Host" header field
# - The path and query components of the request resource URI.
# - The protocol parameters excluding the "oauth_signature".
# - Parameters included in the request entity-body SEE ABOVE

# Process, Join:
# 1. HTTP req method in uppercase
# 2. An "&" character
# 3. URI string - scheme, authority, path, all in lowercase. include port if not 80. see URI STRING EXAMPLE below. - PERCENT ENCODED
# 4. An "&" character
# 5. normalized request parameters - PERCENT ENCODED THEN SORTED

# URI STRING EXAMPLE
  #    GET /r%20v/X?id=123 HTTP/1.1
  # Host: EXAMPLE.COM:80

  #  is represented by the base string URI: "http://example.com/r%20v/X".

  #  In another example, the HTTPS request:

  #    GET /?q=1 HTTP/1.1
  # Host: www.example.net:8080

  #  is represented by the base string URI:
  #  "https://www.example.net:8080/".

# Make OAuth 1.0a signed requests with Furl

# docs:
# - https://www.yelp.com/developers/documentation/v2/authentication
# - https://www.yelp.com/developers/manage_api_keys
# - http://nouncer.com/oauth/authentication.html
# - http://tools.ietf.org/html/rfc5849#section-3.1

# examples
# - http://cpansearch.perl.org/src/IKEBE/Furl-S3-0.02/lib/Furl/S3.pm
# - http://search.cpan.org/~tokuhirom/Furl-3.08/lib/Furl/HTTP.pm
# - http://search.cpan.org/~mathias/OAuth-Consumer-0.03/lib/OAuth/Consumer.pm
# - http://blog.kazuhooku.com/2011/02/5x-performance-switching-from-lwp-to.html

# http://cpansearch.perl.org/src/LYOKATO/OAuth-Lite-1.34/lib/OAuth/Lite/Util.pm
# http://search.cpan.org/~gaas/Digest-HMAC-1.03/lib/Digest/HMAC_SHA1.pm
# https://www.yelp.com/developers/manage_api_keys
# http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4

# http://tools.ietf.org/html/rfc5849#section-3.4.1.3.2
# http://tools.ietf.org/html/rfc5849#section-3.4.1.3.1
# http://tools.ietf.org/html/rfc5849#section-3.6 - percent encoding
# http://tools.ietf.org/html/rfc5849#section-3.5.2
# http://stackoverflow.com/questions/4113934/how-is-oauth-2-different-from-oauth-1

# -------------------------------------------------------------------
# END OF NOTES


# my @foo = ('foo', '1', 'bar', '2', 'baz', '3', 'blah', undef);

# for (my $i = 0; $i <= (@foo - 1); $i += 2) {
#     my $key = $foo[$i];
#     my $val = $foo[$i + 1];

#     warn "key: $key | val: $val";
# }

#exit;
my ($scheme, $host, $path, $query, undef) = $url =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;

my $port;

($host, $port) = split /:/, $host
    if ($host =~ m!:!);

warn "host: $host | port: $port |";

if ($port) {
    warn "port: $port";
}
use Data::Dumper;
warn Dumper(\@parts);

use URI;
my $uri = URI->new($url);
my @q = $uri->query_form;

warn Dumper(\@q);

warn $uri->scheme;
warn $uri->host;
warn $uri->path;
warn $uri->port;
