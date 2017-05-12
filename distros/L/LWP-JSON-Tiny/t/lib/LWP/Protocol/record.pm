package LWP::Protocol::record;

use strict;
use warnings;
no warnings 'uninitialized';

use parent 'LWP::Protocol';

sub request {
    my ($self, $request) = @_;

    $self->_add_request($request);
    return HTTP::Response->new;
}

{
    my @requests;
    sub clear_requests { @requests = () }
    sub requests { @requests }
    sub _add_request { push @requests, pop }
}

1;