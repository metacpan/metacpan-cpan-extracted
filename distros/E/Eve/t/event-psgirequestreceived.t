# -*- mode: Perl; -*-
package EventPsgiRequestReceivedTest;

use parent qw(Eve::EventTestBase);

use strict;
use warnings;

use Test::More;

use Eve::Event::PsgiRequestReceived;

sub setup : Test(setup) {
    my $self = shift;

    $self->SUPER::setup();

    $self->{'event'} = Eve::Event::PsgiRequestReceived->new(
        event_map => $self->{'event_map'},
        env_hash => {});
}

1;
