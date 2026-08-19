=head1 NAME

68_empty_xcsv.t - HAC-087: xCSV() with zero elements produces "key="
(an empty value, key still present) in kvp2str's output, unlike a
top-level empty plain array ([]) which is omitted entirely per HAC-065.
This is intentional, not a bug - HAC-065's omission exists specifically
to avoid the stray "&&" a truly-nothing-contributed empty array would
otherwise leave in the joined string; xCSV() has no such join-corruption
risk, and "key=" is valid, parseable form data (many APIs use it to mean
"explicitly present but empty", distinct from the key being absent
altogether). Previously untested and undocumented; both behaviors are
now both.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

is $api->kvp2str( data => { e => xCSV() }, events => {} ), "e=",
    "an empty xCSV() still emits its key with an empty value";

is $api->kvp2str( data => { e => [] }, events => {} ), "",
    "a top-level empty plain array is omitted entirely (HAC-065), unlike an empty xCSV()";

done_testing;
