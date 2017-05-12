# -*- mode: Perl; -*-
package EventTest;

use parent qw(Eve::EventTestBase);

use strict;
use warnings;

use Test::MockObject;
use Test::More;

use Eve::Event;

sub setup : Test(setup) {
    my $self = shift;

    $self->SUPER::setup();

    $self->{'event'} = Eve::Event->new(event_map => $self->{'event_map'});
}

1;
