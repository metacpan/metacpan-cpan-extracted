=head1 NAME

56_kvp2str_nested_hash_dies.t - HAC-073: kvp2str_each's HASH branch dies
with a clear message instead of recursing - a query string has no
standard convention for a nested hash value, unlike kvp2json_each's HASH
branch, which does recurse (JSON has a native object type for it).
Previously undocumented (the METHODS POD said the two "recurse into
plain array/hash values" jointly, which was true only for kvp2json_each)
and untested.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

eval { $api->kvp2str( data => { outer => { inner => "x" } }, events => {} ) };
my $error = $@;

ok $error, "a nested hash value dies instead of silently producing garbage";
like $error, qr/nested hash/, "the error names the actual problem";
like $error, qr/outer/, "the error names the offending key";

done_testing;
