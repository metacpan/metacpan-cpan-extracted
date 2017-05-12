package MyService;

use strict;
use warnings;

use base qw(JSON::RPC::Simple);

sub echo : JSONRpcMethod(text) {
    my ($self, $request, $args) = @_;
    return reverse $args->{text};
}

1;