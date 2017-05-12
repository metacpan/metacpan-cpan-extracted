package JSON::RPC::Spec::Client;
use Moo;
use Carp ();
with qw(
  JSON::RPC::Spec::Common
);

use namespace::clean;


sub compose {
    my ($self, $method, $params, $id) = @_;
    my @args;
    if (defined $id) {
        @args = (id => $id);
    }
    return $self->coder->encode(
        +{
            jsonrpc => $self->_jsonrpc,
            method  => $method,
            params  => $params,
            @args
        }
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::RPC::Spec::Client - Yet another JSON-RPC 2.0 Client Implementation

=head1 FUNCTIONS

=head2 compose

    use JSON::RPC::Spec::Client;
    my $rpc_client = JSON::RPC::Spec::Client->new;
    my $json_string = $rpc_client->compose('echo' => 'Hello', 1);

    # for notification
    my $json_string = $rpc_client->compose('echo' => 'Hello');

build a JSON encoded string of specifications of the JSON-RPC 2.0.

=head1 LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

nqounet E<lt>mail@nqou.netE<gt>

=cut
