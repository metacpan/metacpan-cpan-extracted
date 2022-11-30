package Ethereum::RPC::Client;

use strict;
use warnings;

use Moo;
use JSON::MaybeXS;
use Mojo::UserAgent;
use Ethereum::RPC::Contract;

our $VERSION = '0.04';

has host => (
    is      => 'ro',
    default => sub { '127.0.0.1' });
has port => (
    is      => "ro",
    default => 8545
);
has http_client => (
    is      => 'ro',
    default => sub { Mojo::UserAgent->new });

## no critic (RequireArgUnpacking)
sub AUTOLOAD {
    my $self = shift;

    my $method = $Ethereum::RPC::Client::AUTOLOAD;
    $method =~ s/.*:://;

    return if ($method eq 'DESTROY');

    my $url = "http://" . $self->host . ":" . $self->port;

    $self->{id} = 1;
    my $obj = {
        id     => $self->{id}++,
        method => $method,
        params => (ref $_[0] ? $_[0] : [@_]),
    };

    my $res = $self->http_client->post($url => json => $obj)->result;

    # https://eth.wiki/json-rpc/json-rpc-error-codes-improvement-proposal
    die sprintf("error code: %d, error message: %s (%s)\n", $res->json->{error}->{code}, $res->json->{error}->{message}, $method)
        if ($res->json->{error}->{message});
    return $res->json->{result};
}

=head2 contract

Creates a new contract instance

Parameters:
    contract_address    ( Optional - only if the contract already exists ),
    contract_abi        ( Required - https://solidity.readthedocs.io/en/develop/abi-spec.html ),
    from                ( Optional - Address )
    gas                 ( Optional - Integer gas )
    gas_price           ( Optional - Integer gasPrice )

Return:
    New contract instance

=cut

sub contract {
    my $self   = shift;
    my $params = shift;
    return Ethereum::RPC::Contract->new((%{$params}, rpc_client => $self));
}

1;

=pod

=head1 NAME

Ethereum::RPC::Client - Ethereum JSON-RPC Client

=head1 SYNOPSIS

   use Ethereum::RPC::Client;

   # Create Ethereum::RPC::Client object
   my $eth = Ethereum::RPC::Client->new(
      host     => "127.0.0.1",
   );

   my $web3_clientVersion = $eth->web3_clientVersion;

   # https://github.com/ethereum/wiki/wiki/JSON-RPC

=head1 DESCRIPTION

This module implements in PERL the JSON-RPC of Ethereum L<https://github.com/ethereum/wiki/wiki/JSON-RPC>

=head1 SEE ALSO

L<Bitcoin::RPC::Client>

=head1 AUTHOR

Binary.com E<lt>fayland@binary.comE<gt>

=head1 COPYRIGHT

Copyright 2017- Binary.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
