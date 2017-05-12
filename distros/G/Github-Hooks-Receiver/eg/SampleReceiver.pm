package SampleReceiver;
use strict;
use warnings;
use utf8;

use Github::Hooks::Receiver::Declare;

use Class::Accessor::Lite (
    new => 1,
);

sub server {
    my $self = shift;
    $self->{server} ||= receiver {
        on push => sub {

        };
    };
}

sub run {
    shift->server->run(@_);
}

1;
