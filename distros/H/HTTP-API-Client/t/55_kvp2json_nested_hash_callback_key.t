=head1 NAME

55_kvp2json_nested_hash_callback_key.t - HAC-072: kvp2json_each's HASH
branch never passed the nested hash's own key into %o, so a CODE-valued
callback nested inside a hash saw its *outer* field's key instead of its
own inner key. Extends HAC-064's exact bug class one level deeper - the
top-level key-passing HAC-064 fixed didn't propagate into this recursive
branch, which HAC-064's own test never exercised.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

my $callback = sub {
    my ( $self, %o ) = @_;
    return $o{key};
};

my $json = $api->kvp2json(
    data   => { outer => { inner => $callback } },
    events => {},
);

is $json, '{"outer":{"inner":"inner"}}',
    "a callback nested inside a hash value sees its own key, not the outer field's key";

done_testing;
