# -*- mode: Perl; -*-
package HttpResponseTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Eve::HttpResponse;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'http_response'} = Eve::HttpResponse->new();
}

sub test_interface : Test(5) {
    my $self = shift;

    throws_ok(
        sub {
            $self->{'http_response'}->set_status(),
        },
        qr/Eve::Error::NotImplemented/);
    throws_ok(
        sub {
            $self->{'http_response'}->set_header(),
        },
        qr/Eve::Error::NotImplemented/);
    throws_ok(
        sub {
            $self->{'http_response'}->set_cookie(),
        },
        qr/Eve::Error::NotImplemented/);
    throws_ok(
        sub {
            $self->{'http_response'}->set_body(),
        },
        qr/Eve::Error::NotImplemented/);
    throws_ok(
        sub {
            $self->{'http_response'}->get_text(),
        },
        qr/Eve::Error::NotImplemented/);
}

1;
