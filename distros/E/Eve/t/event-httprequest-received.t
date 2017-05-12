# -*- mode: Perl; -*-
package EventHttpRequestReceivedTest;

use parent qw(Eve::EventTestBase);

use strict;
use warnings;

use Test::More;

use Eve::Event::HttpRequestReceived;

sub setup : Test(setup) {
    my $self = shift;

    $self->SUPER::setup();

    $self->{'event'} = Eve::Event::HttpRequestReceived->new(
        event_map => $self->{'event_map'});
}

1;
