# -*- mode: Perl; -*-
package HttpRequestTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Eve::HttpRequest;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'http_request'} = Eve::HttpRequest->new();
}

sub test_methods : Test(4) {
    my $self = shift;

    my $method_list = ['get_uri', 'get_method', 'get_parameter', 'get_cookie'];

    for my $method_name (@{$method_list}) {
        throws_ok(
            sub {
                $self->{'http_request'}->$method_name();
            },
            qr/Eve::Error::NotImplemented/);
    }
}

1;
