package JSON::RPC::Spec::Procedure;
use Moo;
use Carp ();
use Try::Tiny;
with qw(
  JSON::RPC::Spec::Common
);

use constant DEBUG => $ENV{PERL_JSON_RPC_SPEC_DEBUG} || 0;

has router => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        my $self = shift;
        $self->can('match') or Carp::croak('method match required.');
    },
);

use namespace::clean;

sub parse {
    my ($self, $obj, $extra_args) = @_;
    if (ref $obj ne 'HASH') {
        return $self->_rpc_invalid_request;
    }
    $self->_is_notification(!exists $obj->{id});
    $self->_id($obj->{id});
    my $method = $obj->{method} || '';

    # rpc call with invalid Request object:
    # rpc call with an invalid Batch (but not empty):
    # rpc call with invalid Batch:
    if ($method eq '' or $method =~ m!\A\.|\A[0-9]+\z!) {
        return $self->_rpc_invalid_request;
    }
    my $jsonrpc_version = $self->_jsonrpc;
    $obj->{jsonrpc} ne $jsonrpc_version
      and return $self->_rpc_invalid_request(
        qq{Invalid Request: jsonrpc must be '$jsonrpc_version'});

    my ($result, $err);
    try {
        $result = $self->_trigger($method, $obj->{params}, $extra_args);
    }
    catch {
        $err = $_;
        warn qq{-- error : @{[ $err ]} } if DEBUG;
    };
    if ($self->_is_notification) {
        return;
    }
    if ($err) {
        my $error;
        if ($err =~ m!rpc_method_not_found!) {
            $err =~ s!\sat\s.*?\n\z!!;
            $err =~ s!rpc_method_not_found!Method not found!;
            $error = $self->_rpc_method_not_found($err);
        }
        elsif ($err =~ m!rpc_invalid_params!) {
            $err =~ s!\sat\s.*?\n\z!!;
            $err =~ s!rpc_invalid_params!Invalid params!;
            $error = $self->_rpc_invalid_params($err);
        }
        else {
            $error = $self->_rpc_internal_error(data => $err);
        }
        return $error;
    }
    return +{
        jsonrpc => $self->_jsonrpc,
        result  => $result,
        id      => $self->_id
    };
}

# trigger registered method
sub _trigger {
    my ($self, $name, $params, $extra_args) = @_;
    my $router  = $self->router;
    my $matched = $router->match($name);

    # rpc call of non-existent method:
    unless ($matched) {
        Carp::croak 'rpc_method_not_found';
    }
    my $cb = delete $matched->{$self->_callback_key};
    return $cb->($params, $matched, @{$extra_args});
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::RPC::Spec::Procedure - Subclass of JSON::RPC::Spec

=head1 DESCRIPTION

JSON::RPC::Spec::Procedure is Subclass of JSON::RPC::Spec.

=head1 FUNCTIONS

=head2 new

constructor. `router` required.

=head2 parse

parse procedure.

=head2 router

similar L<< Router::Simple >>.

=head1 LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

nqounet E<lt>mail@nqou.netE<gt>

=cut
