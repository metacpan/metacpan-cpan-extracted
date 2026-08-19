=head1 NAME

47_kvp2json_callback_key.t - HAC-064: kvp2json()/kvp2json_each() never
passed the field's own key into %o for a CODE-valued field's callback,
unlike kvp2str()/kvp2str_each() which explicitly pass key => $k. A
callback could see its own key in the form-urlencoded path but not the
JSON path - the same class of two-encoders-drift as HAC-059/060/061,
here in the callback mechanism rather than array/CSV encoding.

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

{
    my $json = $api->kvp2json( data => { foo => $callback }, events => {} );
    is $json, '{"foo":"foo"}',
        "a CODE-valued field's callback can see its own key via \%o, matching kvp2str_each";
}

{
    my $str = $api->kvp2str( data => { foo => $callback }, events => {} );
    is $str, 'foo=foo', "kvp2str_each's existing key-in-\%o behavior is unchanged";
}

done_testing;
