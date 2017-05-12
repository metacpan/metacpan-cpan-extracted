package Mackerel::Webhook::Receiver::Event;
use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/payload event/],
);

1;
