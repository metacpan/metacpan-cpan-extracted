package Ethereum::RPC::Contract;
# ABSTRACT: Support for interacting with Ethereum contracts using the geth RPC interface

use strict;
use warnings;

our $VERSION = '0.03';

=head1 NAME

    Ethereum::Contract - Support for interacting with Ethereum contracts using the geth RPC interface

=cut

use Moo;
use JSON::MaybeXS;
use Math::BigInt;

use Ethereum::RPC::Client;
use Ethereum::RPC::Contract::ContractResponse;
use Ethereum::RPC::Contract::ContractTransaction;
use Ethereum::RPC::Contract::Helper::UnitConversion;

has contract_address => (is => 'rw');
has contract_abi => (
    is       => 'ro',
    required => 1
);
has rpc_client => (
    is   => 'ro',
    lazy => 1
);

sub _build_rpc_client {
    return Ethereum::RPC::Client->new;
}

has from => (
    is   => 'rw',
    lazy => 1
);

sub _build_from {
    return shift->rpc_client->eth_coinbase();
}

has gas_price => (
    is   => 'rw',
    lazy => 1
);

sub _build_gas_price {
    return shift->rpc_client->eth_gasPrice();
}

has gas => (is => 'rw');

has contract_decoded => (
    is      => 'ro',
    default => sub { {} });

=head2 BUILD

Constructor: Here we get all functions from the passed ABI and bring it to contract class subs.

Parameters:
    contract_address    ( Optional - only if the contract already exists ),
    contract_abi        ( Required - https://solidity.readthedocs.io/en/develop/abi-spec.html ),
    rpc_client          ( Optional - Ethereum::RPC::Client(https://github.com/binary-com/perl-Ethereum-RPC-Client) - if not given, new instance will be created );
    from                ( Optional - Address )
    gas                 ( Optional - Integer gas )
    gas_price           ( Optional - Integer gasPrice )

Return:
    New contract instance

=cut

sub BUILD {
    my ($self) = @_;

    my @decoded_json = @{decode_json($self->contract_abi)};

    for my $json_input (@decoded_json) {
        if ($json_input->{type} =~ /^function|event$/) {
            $self->contract_decoded->{$json_input->{name}} ||= [];
            push(@{$self->contract_decoded->{$json_input->{name}}}, $json_input->{inputs}) if scalar @{$json_input->{inputs}} > 0;
        }
    }

    $self->from($self->rpc_client->eth_coinbase())      unless $self->from;
    $self->gas_price($self->rpc_client->eth_gasPrice()) unless $self->gas_price;

    return;

}

=head2 invoke

Invokes all calls from ABI to the contract.

Parameters:
    name (Required - the string function name )
    params (Optional - the parameters)

Return:
    Ethereum::Contract::ContractTransaction

=cut

sub invoke {
    my ($self, $name, @params) = @_;

    my $function_id = substr($self->get_function_id($name, scalar @params), 0, 10);

    my $res = $self->_prepare_transaction($function_id, \@params);

    return $res;
}

=head2 get_function_id

Get the function and parameters and merge to create the hashed ethereum function ID

Ex: function approve with the inputs address _spender and uint value must be represented as:
    SHA3("approve(address,uint)")

Parameters:
    function_string (Required - the string function name )
    inputs (Required - the input list given on the contract ABI)

Return:
    New function ID hash

=cut

sub get_function_id {
    my ($self, $function_string, $params_size) = @_;

    my @inputs        = @{$self->contract_decoded->{$function_string}};
    my @selected_data = ();
    if (scalar @inputs > 0) {
        for my $v (@inputs) {
            @selected_data = @{$v} if ($params_size and @{$v} == $params_size) or not $params_size;
            last if scalar @selected_data > 0;
        }
    }

    $function_string .= "(";
    $function_string .= $_->{type} ? "$_->{type}," : "" for @selected_data;
    chop($function_string) if scalar @selected_data > 0;
    $function_string .= ")";

    my $hex_function = $self->append_prefix(unpack("H*", $function_string));

    my $sha3_hex_function = $self->rpc_client->web3_sha3($hex_function);

    return $sha3_hex_function;

}

=head2 _prepare_transaction

Join the data and parameters and return a prepared transaction to be called as send, call or deploy.

Parameters:
    $compiled_data  ( Required - the hashed function string name with parameters or the compiled contract bytecode )
    params          ( Required - the parameters args given by the method call )

Return:
    Future object
        on_done: Ethereum::Contract::ContractTransaction
        on_fail: string message

=cut

sub _prepare_transaction {
    my ($self, $compiled_data, $params) = @_;

    my $data = join("", $compiled_data, map { $self->get_hex_param($_) } @{$params});

    return Ethereum::RPC::Contract::ContractTransaction->new(
        contract_address => $self->contract_address,
        rpc_client       => $self->rpc_client,
        data             => $self->append_prefix($data),
        from             => $self->from,
        gas              => $self->gas,
        gas_price        => $self->gas_price,
    );

}

=head2 get_hex_param

Convert the given value to hexadecimal format

Parameters:
    function_id (Required - arg to be converted to hexadecimal)

Return:
    Hexadecimal string

=cut

sub get_hex_param {
    my ($self, $param) = @_;

    my $new_param;
    # Is hexadecimal string
    if ($param =~ /^0x[0-9A-F]+$/i) {
        $new_param = sprintf("%064s", substr($param, 2));
        # Is integer
    } elsif ($param =~ /^[+-]?[0-9?e+]+$/) {
        $new_param = sprintf("%064s", substr(Math::BigInt->new($param)->as_hex, 2));
        # Is string
    } else {
        $new_param = sprintf("%064s", unpack("H*", $param));
    }

    return $new_param;

}

=head2 read_all_events_from_block

Create a filter based on the given block to listen all events sent by the contract.

The filter is killed before the list return, so for each request a new filter will be created.

Parameters:
    from_block ( Optional - start search block )
    function     ( Required - function name )

Return:
    https://github.com/ethereum/wiki/wiki/JSON-RPC#returns-42

=cut

sub read_all_events_from_block {
    my ($self, $from_block, $function) = @_;

    my $function_id = $self->get_function_id($function);

    $from_block = $self->append_prefix(unpack("H*", $from_block // "latest"));

    my $res = $self->rpc_client->eth_getLogs([{
                address   => $self->contract_address,
                fromBlock => $from_block,
                topics    => [$function_id]}]);

    return $res;

}

=head2 invoke_deploy

Prepare a deploy transaction,

Parameters:
    compiled ( Required - contract bytecode)
    params   ( Required - contract constructor params

Return:
    Ethereum::Contract::ContractTransaction

=cut

sub invoke_deploy {
    my ($self, $compiled_data, @params) = @_;
    return $self->_prepare_transaction($compiled_data, \@params);
}

=head2 append_prefix

Ensure that the given hexadecimal string starts with 0x.

=cut

sub append_prefix {
    my ($self, $str) = @_;
    return "0x$str" unless $str =~ /^0x/;
    return $str;
}

1;
