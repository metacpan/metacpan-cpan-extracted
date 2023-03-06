package Ethereum::RPC::Contract;
# ABSTRACT: Support for interacting with Ethereum contracts using the geth RPC interface

use strict;
use warnings;

our $VERSION = '0.05';

=head1 NAME

    Ethereum::Contract - Support for interacting with Ethereum contracts using the geth RPC interface

=cut

use Moo;
use JSON::MaybeXS;
use Math::BigInt;
use Scalar::Util   qw(looks_like_number);
use List::Util     qw(first);
use Digest::Keccak qw(keccak_256_hex);

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
    is => 'lazy',
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

has max_fee_per_gas => (is => 'rw');

has max_priority_fee_per_gas => (is => 'rw');

has gas => (is => 'rw');

has contract_decoded => (
    is      => 'rw',
    default => sub { {} },
);

=head2 BUILD

Constructor: Here we get all functions and events from the given ABI and set
it to the contract class.

=over 4

=item contract_address => string (optional)

=item contract_abi => string (required, https://solidity.readthedocs.io/en/develop/abi-spec.html)

=item rpc_client => L<Ethereum::RPC::Client> (optional, default: L<Ethereum::RPC::Client>)

=item from => string (optional)

=item gas => numeric (optional)

=item gas_price => numeric (optional)

=item max_fee_per_gas => numeric (optional)

=item max_priority_fee_per_gas => numeric (optional)

=back

=cut

sub BUILD {
    my ($self) = @_;
    my @decoded_json = @{decode_json($self->contract_abi // "[]")};

    for my $json_input (@decoded_json) {
        if ($json_input->{type} =~ /^function|event|constructor$/) {
            push(@{$self->contract_decoded->{$json_input->{name} // $json_input->{type}}}, $json_input->{inputs});
        }
    }

    unless ($self->contract_decoded->{constructor}) {
        push(@{$self->contract_decoded->{constructor}}, []);
    }

    return;

}

=head2 invoke

Prepare a function to be called/sent to a contract.

=over 4

=item name => string (required)

=item params => array (optional, the function params)

=back

Returns a L<Ethereum::Contract::ContractTransaction> object.

=cut

sub invoke {
    my ($self, $name, @params) = @_;

    my $function_id = substr($self->get_function_id($name, scalar @params), 0, 10);

    my $res = $self->_prepare_transaction($function_id, $name, \@params);

    return $res;
}

=head2 get_function_id

The function ID is derived from the function signature using: SHA3(approve(address,uint256)).

=over 4

=item fuction_name => string (required)

=item params_size => numeric (required, size of inputs called by the function)

=back

Returns a string hash

=cut

sub get_function_id {
    my ($self, $function_name, $params_size) = @_;

    my @inputs = @{$self->contract_decoded->{$function_name}};

    my $selected_data = first { (not $_ and not $params_size) or ($params_size and scalar @{$_} == $params_size) } @inputs;

    $function_name .= sprintf("(%s)", join(",", map { $_->{type} } grep { $_->{type} } @$selected_data));

    my $sha3_hex_function = '0x' . keccak_256_hex($function_name);

    return $sha3_hex_function;
}

=head2 _prepare_transaction

Join the data and parameters and return a prepared transaction to be called as send, call or deploy.

=over 4

=item compiled_data => string (required, function signature or the contract bytecode)

=item function_name => string (contract function as specified in the ABI)

=item params => array (required)

=back

L<Future> object
on_done: L<Ethereum::Contract::ContractTransaction>
on_fail: error string

=cut

sub _prepare_transaction {
    my ($self, $compiled_data, $function_name, $params) = @_;
    $compiled_data =~ s/\s+//g;

    my $encoded = $self->encode($function_name, $params);

    my $data = $compiled_data . $encoded;

    my $transaction = Ethereum::RPC::Contract::ContractTransaction->new(
        contract_address => $self->contract_address,
        rpc_client       => $self->rpc_client,
        data             => $self->append_prefix($data),
        from             => $self->from,
        gas              => $self->gas
    );

    if ($self->gas_price) {
        $transaction->{gas_price} = $self->gas_price;
        # if the gas price is set the transaction type is legacy
        return $transaction;
    }

    # transaction type 2 EIP1559
    $transaction->{max_fee_per_gas}          = $self->max_fee_per_gas          if $self->max_fee_per_gas;
    $transaction->{max_priority_fee_per_gas} = $self->max_priority_fee_per_gas if $self->max_priority_fee_per_gas;
    return $transaction;
}

=head2 encode

Encode function arguments to the ABI format

=over 4

=item C<function_name> ABI function name

=item C<params> all the values for the function in the same order than the ABI

=back

Returns an encoded data string

=cut

sub encode {
    my ($self, $function_name, $params) = @_;

    my $inputs = $self->contract_decoded->{$function_name}->[0];

    # no inputs
    return "" unless $inputs;

    my $offset = $self->get_function_offset($inputs);

    my (@static, @dynamic);
    my @inputs = $inputs->@*;
    for (my $input_index = 0; $input_index < scalar @inputs; $input_index++) {
        my ($static, $dynamic) = $self->get_hex_param($offset, $inputs[$input_index]->{type}, $params->[$input_index]);
        push(@static,  $static->@*);
        push(@dynamic, $dynamic->@*);
        $offset += scalar $dynamic->@*;
    }

    my @data = (@static, @dynamic);
    my $data = join("", @data);

    return $data;
}

=head2 get_function_offset

Get the abi function total offset

For the cases we have arrays as parameters we can have a dynamic size
for the static values, for sample if the basic type has a fixed value
and also the array is fixed, we will have all the items on the array
being added with the static items before the dynamic items in the encoded
data

=over 4

=item C<input_list> the json input from the abi data

=back

return the integer offset

=cut

sub get_function_offset {
    my ($self, $input_list) = @_;
    my $offset = 0;
    for my $input ($input_list->@*) {
        $input->{type} =~ /^([a-z]+)([0-9]+)?\[(\d+)?\]/;
        my $basic_type = $1;
        my $input_size = $2;
        my $array_size = $3;
        if ($input_size && $array_size || ($array_size && $basic_type =~ /^uint|int|fixed/)) {
            $offset += $array_size;
            next;
        }
        $offset += 1;
    }
    return $offset;
}

=head2 get_hex_param

Convert parameter list to the ABI format:
https://solidity.readthedocs.io/en/develop/abi-spec.html#function-selector-and-argument-encoding

=over 4

=item C<current_offset_count> The offset where we should base the calculation for the next dynamic value

=item C<input_type> The input type specified in the abi sample: string, bytes, uint

=item C<param> The input value

=back

Returns 2 arrays

Static => contains the static values from the conversion
Dynamic => contains the dynamic values from the conversion

=cut

sub get_hex_param {
    my ($self, $current_offset_count, $input_type, $param) = @_;

    my @static;
    my @dynamic;

    # is an array
    if ($input_type =~ /(\d+)?\[(\d+)?\]/) {
        my $size              = $param->@*;
        my $static_item_size  = $1;
        my $static_array_size = $2;

        # if it is dynamic array we just write the offset
        unless ($static_array_size && $static_item_size) {
            push(@static, sprintf("%064s", Math::BigInt->new($current_offset_count * 32)->to_hex));
        }

        # if the array is static we add the array size to the dynamic list
        unless ($static_array_size) {
            push(@dynamic, sprintf("%064s", Math::BigInt->new($size)->to_hex));
        }

        my @internal_static;
        my @internal_dynamic;

        # for each item on the array we call get_hex_param recursively
        # passing the basic type with the size if it is present
        $input_type =~ /^([a-z]+([0-9]+)?)\[(?:\d+)?\]/;
        for my $item ($param->@*) {
            my ($internal_static, $internal_dynamic) = $self->get_hex_param($size, $1, $item);
            push(@internal_static,  $internal_static->@*);
            push(@internal_dynamic, $internal_dynamic->@*);
            # the size of the array is used to calculate the current offset
            # the static offset has already been calculated counting the params
            # size, so we need to add now just the dynamic values
            $size += $internal_dynamic->@*;
        }

        # if the byte and the basic type have a fixed size
        # they are considered static, so we can just add them to
        # the static list
        if ($static_item_size && $static_array_size) {
            push(@static, @internal_static);
        } else {
            push(@dynamic, @internal_static);
        }
        push(@dynamic, @internal_dynamic);

    } elsif ($input_type eq 'address' && $param =~ /^0x[0-9A-F]+$/i) {
        push(@static, sprintf("%064s", substr($param, 2)));
    } elsif ($input_type =~ /^(u)?(int|bool)(\d+)?/ && looks_like_number($param)) {
        push(@static, sprintf("%064s", Math::BigInt->new($param)->to_hex));
    } elsif ($input_type =~ /^(?:string|bytes)(\d+)?$/) {
        my $basic_type_size = $1;
        my $hex_value;
        my $size;
        # is already an hexadecimal value
        if ($param =~ /^(?:0x|0X)([a-fA-F0-9]+)$/) {
            # hex without 0x
            $hex_value = $1;
            $size      = length(pack("H*", $hex_value));
        } else {
            $hex_value = unpack("H*", $param);
            $size      = length($param);
        }
        # if it has a fixed size we can add the value directly
        # this is mostly for the bytes
        if ($basic_type_size) {
            push(@static, $hex_value . "0" x (64 - length($hex_value)));
        } else {
            push(@static,  sprintf("%064s", Math::BigInt->new($current_offset_count * 32)->to_hex));
            push(@dynamic, sprintf("%064s", sprintf("%x", $size)));
            push(@dynamic, $hex_value . "0" x (64 - length($hex_value)));
        }
    }

    return \@static, \@dynamic;

}

=head2 read_event

Read the specified log from the specified block to the latest block

=over 4

=item from_block => numeric (optional)

=item event => string (required)

=item event_params_size => numeric (required)

=back

Returns a json encoded object: https://github.com/ethereum/wiki/wiki/JSON-RPC#returns-42

=cut

sub read_event {
    my ($self, $from_block, $event, $event_params_size) = @_;

    my $function_id = $self->get_function_id($event, $event_params_size);

    $from_block = $self->append_prefix(unpack("H*", $from_block // "latest"));

    my $res = $self->rpc_client->eth_getLogs([{
                address   => $self->contract_address,
                fromBlock => $from_block,
                topics    => [$function_id]}]);

    return $res;
}

=head2 invoke_deploy

Prepare a deploy transaction.

=over 4

=item compiled (required, contract bytecode)

=item params (required, constructor params)

=back

Returns a L<Ethereum::Contract::ContractTransaction> object.

=cut

sub invoke_deploy {
    my ($self, $compiled_data, @params) = @_;
    return $self->_prepare_transaction($compiled_data, "constructor", \@params);
}

=head2 append_prefix

Ensure that the given hexadecimal string starts with 0x.

=over 4

=item str => string (hexadecimal)

=back

Returns a string hexadecimal

=cut

sub append_prefix {
    my ($self, $str) = @_;
    return $str =~ /^0x/ ? $str : "0x$str";
}

1;
