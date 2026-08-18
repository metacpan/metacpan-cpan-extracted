=head1 NAME

39_browser_id_dev_fallback.t - HAC-049: browser_id's version fallback
was -1, producing the nonsensical User-Agent "HTTP API Client v-1" for
every non-CPAN-installed usage (a git checkout, or anyone running
directly from src/lib/ without installing the released tarball) -
$HTTP::API::Client::VERSION is only ever set by Dist::Zilla's
[PkgVersion] plugin at build time, so it's unset in exactly this
project's own dev/test environment.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

unlike $api->browser_id, qr/v-1\b/,
    "browser_id's fallback is not the nonsensical v-1 when VERSION is unset";
like $api->browser_id, qr/^HTTP API Client v/,
    "browser_id still has the expected prefix";

done_testing;
