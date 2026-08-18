=head1 NAME

38_invalid_charset.t - HAC-046: _build_json's 'eval { $json->$charset };'
silently swallowed a failure when $charset wasn't a real JSON::XS method
(e.g. a typo in HTTP_CHARSET). $json was left in JSON::XS's raw default
state instead of erroring, so a JSON request with any non-ASCII data
crashed much later with "HTTP::Message content must be bytes" - a
confusing, unrelated error giving no hint the real problem was the
charset config.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new( charset => "bogus123" );

my $error = eval { $api->json; 1 } ? undef : $@;

ok defined $error, "an invalid charset dies instead of silently succeeding";
like $error, qr/bogus123/, "the error message names the actual invalid charset";
unlike $error, qr/content must be bytes/,
    "the error is about the charset, not a confusing unrelated HTTP::Message crash";

done_testing;
