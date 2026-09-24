use strict;
use warnings;
use Test::More;

use HTTP::API::Core::Auth qw(api_key_auth);

sub apply_query_key {
    my ($url) = @_;
    my $hook = api_key_auth(
        in    => 'query',
        name  => 'api_key',
        value => 'secret key',
    );
    my $ctx = { url => $url, headers => {} };
    $hook->($ctx);
    return $ctx->{url};
}

is apply_query_key('/items#section'),
    '/items?api_key=secret%20key#section',
    'query API key is inserted before fragment';

is apply_query_key('/items?page=2#section'),
    '/items?page=2&api_key=secret%20key#section',
    'existing query and fragment are preserved';

is apply_query_key('/items?api_key=explicit#section'),
    '/items?api_key=explicit#section',
    'existing query API key remains authoritative with fragment';

done_testing;
