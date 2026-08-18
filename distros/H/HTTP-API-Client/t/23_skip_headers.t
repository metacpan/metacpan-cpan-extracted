=head1 NAME

23_skip_headers.t - HAC-026: skip_headers (new_request) and skip_key
(kvp2json/kvp2str) are real, working options - reachable only via a direct
call to these public methods, not through send()/get()/post() or the
%events callback mechanism (a callback's %o is a snapshot copy, so setting
$o{skip_headers} inside one has no effect on the caller). t/04_callbacks.t
already exercises skip_key this way, recursively, from within its own data
callback; this covers skip_headers, which had no coverage at all.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;
my ($method, $url, $path) = ("GET", "http://example.com", "");

my $req = $api->new_request(
    method  => \$method,
    url     => \$url,
    path    => \$path,
    data    => {},
    headers => { A => "1", B => "2" },
    events  => {},
    skip_headers => { B => 1 },
);

is $req->header("A"), "1", "skip_headers: an unlisted key is still set";
ok !defined $req->header("B"), "skip_headers: the listed key is excluded";

done_testing;
