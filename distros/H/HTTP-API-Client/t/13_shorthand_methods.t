=head1 NAME

13_shorthand_methods.t - coverage for put()/head()/delete(), which had
never actually been exercised by any test (only get()/post() were)

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

for my $case (
    [ put    => 'PUT' ],
    [ head   => 'HEAD' ],
    [ delete => 'DELETE' ],
) {
    my ($method_name, $http_method) = @$case;

    my $req = $api->$method_name(
        "http://example.com", {}, {}, { test_request_object => 1 },
    );

    is $req->method, $http_method, "$method_name() dispatches a $http_method request";
}

done_testing;
