package JSON::RPC::Spec;
use Moo;
use Carp ();
use version; our $VERSION = version->declare("v1.0.7");
use Try::Tiny;
use Router::Simple;
use JSON::RPC::Spec::Procedure;
use JSON::RPC::Spec::Client;
with qw(
  JSON::RPC::Spec::Common
);

use constant DEBUG => $ENV{PERL_JSON_RPC_SPEC_DEBUG} || 0;

has router => (
    is  => 'lazy',
    isa => sub {
        my $self = shift;
        $self->can('match') or Carp::croak('method match required.');
    },
);

has _procedure => (is => 'lazy');

has _client => (
    is      => 'lazy',
    handles => [qw(compose)],
);

has [qw(_is_batch _content)] => (is => 'rw');

use namespace::clean;


sub _build_router {
    Router::Simple->new;
}

sub _build__procedure {
    JSON::RPC::Spec::Procedure->new(router => shift->router);
}

sub _build__client {
    JSON::RPC::Spec::Client->new;
}

sub _parse_json {
    my ($self, $extra_args) = @_;
    warn qq{-- start parsing @{[$self->_content]}\n} if DEBUG;

    unless (length $self->_content) {
        return $self->_rpc_invalid_request;
    }

    # JSON decode
    # rpc call with invalid JSON:
    # rpc call Batch, invalid JSON:
    my ($req, $err);
    try {
        $req = $self->coder->decode($self->_content);
    }
    catch {
        $err = $_;
        warn qq{-- error : @{[$err]} } if DEBUG;
    };
    if ($err) {
        return $self->_rpc_parse_error;
    }

    # Batch mode flag
    if (ref $req eq 'ARRAY') {
        $self->_is_batch(1);
    }
    else {
        $self->_is_batch(0);
        $req = [$req];
    }

    # rpc call with an empty Array:
    unless (scalar @{$req}) {
        return $self->_rpc_invalid_request;
    }

    # procedure call and create response
    my @response;
    for my $obj (@{$req}) {
        my $res = $self->_procedure->parse($obj, $extra_args);

        # notification is ignore
        push @response, $res if $res;
    }
    return unless @response;
    return [@response] if $self->_is_batch;
    return $response[0];
}

# parse JSON string to hash
sub parse_without_encode {
    my $self        = shift;
    my $json_string = shift;
    my $extra_args  = +[@_];
    $self->_content($json_string);
    return $self->_parse_json($extra_args);
}

# parse JSON string to JSON string
sub parse {
    my $self        = shift;
    my $json_string = shift;
    my $extra_args  = +[@_];
    $self->_content($json_string);
    my $result = $self->_parse_json($extra_args);
    return unless $result;
    return $self->coder->encode($result);
}

# register method
sub register {
    my ($self, $pattern, $cb) = @_;
    if (!defined $pattern) {
        Carp::croak('pattern required');
    }
    if (ref $cb ne 'CODE') {
        Carp::croak('code required');
    }
    $self->router->connect($pattern, +{$self->_callback_key => $cb}, +{});
    return $self;
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::RPC::Spec - Yet another JSON-RPC 2.0 Implementation

=head1 SYNOPSIS

    use strict;
    use JSON::RPC::Spec;

    my $rpc = JSON::RPC::Spec->new;

    # server
    $rpc->register(echo => sub { $_[0] });
    print $rpc->parse(
        '{"jsonrpc": "2.0", "method": "echo", "params": "Hello, World!", "id": 1}'
    );    # -> {"jsonrpc":"2.0","result":"Hello, World!","id":1}

    # client
    print $rpc->compose(echo => 'Hello, World!', 1);
      # -> {"jsonrpc":"2.0","method":"echo","params":"Hello, World!","id":1}

=head1 DESCRIPTION

JSON::RPC::Spec is Yet another JSON-RPC 2.0 Implementation.

JSON format string execute registered method.

JSON::RPC - PSGI

The tightly also supports BATCH.

As a feature.
1. JSON string to JSON string.
2. Simple register callback.

=head1 FUNCTIONS

=head2 new

constructor.

options L<< JSON::RPC::Spec::Common/coder >> and L<< /router >> are available.

=head2 register

    # method => code refs
    use List::Util qw(max);
    $rpc->register(max => sub { max(@{$_[0]}) });

    # method matching via Router::Simple
    $rpc->register('myapp.{action}' => sub {
        my ($params, $match) = @_;
        my $action = $match->{action};
        return MyApp->new->$action($params);
    });

register method.

=head2 parse

    my $result = $rpc->parse(
        '{"jsonrpc": "2.0", "method": "max", "params": [9,4,11,0], "id": 1}'
    );    # returns JSON encoded string -> {"id":1,"result":11,"jsonrpc":"2.0"}

parse JSON and triggered method. returns JSON encoded string.

=head2 parse_without_encode

    my $result = $rpc->parse_without_encode(
        '{"jsonrpc": "2.0", "method": "max", "params": [9,4,11,0], "id": 1}'
    );    # returns hash -> {id => 1, result => 11, jsonrpc => '2.0'}

parse JSON and triggered method. returns HASH.

=head2 compose

See L<< JSON::RPC::Spec::Client/compose >> for full documentation.

=head2 router

similar L<< Router::Simple >>.

=head1 DEBUGGING

You can set the C<PERL_JSON_RPC_SPEC_DEBUG> environment variable to get some advanced diagnostics information printed to C<STDERR>.

    PERL_JSON_RPC_SPEC_DEBUG = 1

=head1 SEE ALSO

L<JSON::RPC>

L<JSON::RPC::Dispatcher>

L<JSON::RPC::Common>

=head1 LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

nqounet E<lt>mail@nqou.netE<gt>

=cut
