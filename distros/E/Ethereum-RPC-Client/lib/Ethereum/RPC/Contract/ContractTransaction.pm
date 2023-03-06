package Ethereum::RPC::Contract::ContractTransaction;

use strict;
use warnings;

our $VERSION = '0.05';

=head1 NAME

   Ethereum::RPC::Contract::ContractTransaction - Centralize contract transactions

=cut

use Moo;
use Future;

use Ethereum::RPC::Contract::ContractResponse;
use Ethereum::RPC::Contract::Helper::UnitConversion;

has contract_address => (is => 'ro');
has rpc_client => (
    is   => 'ro',
    lazy => 1
);

sub _build_rpc_client {
    return Ethereum::RPC::Client->new;
}

has data => (
    is       => 'ro',
    required => 1
);

has from                     => (is => 'ro');
has gas                      => (is => 'ro');
has gas_price                => (is => 'ro');
has max_fee_per_gas          => (is => 'ro');
has max_priority_fee_per_gas => (is => 'ro');

=head2 call_transaction

Call a public functions and variables from a ethereum contract

Return:
    Ethereum::RPC::Contract::ContractResponse, error message

=cut

sub call_transaction {
    my ($self, $block) = @_;

    my $res = $self->rpc_client->eth_call([{
                to   => $self->contract_address,
                data => $self->data,
            },
            $block // "latest"
        ]);

    my $future = Future->new;
    return $future->done(Ethereum::RPC::Contract::ContractResponse->new({response => $res})) if $res and $res =~ /^0x/;
    return $future->fail($res || "Can't call transaction");

}

=head2 send_transaction

Send a transaction to a payable functions from a ethereum contract

The parameter GAS is required to send a payable request.

Return:
    Ethereum::RPC::Contract::ContractResponse, error message

=cut

sub send_transaction {
    my $self = shift;

    my $future = Future->new;

    my $params = {
        to   => $self->contract_address,
        from => $self->from,
        data => $self->data,
    };

    $params->{gas}                  = Ethereum::RPC::Contract::Helper::UnitConversion::to_wei($self->gas) if $self->gas;
    $params->{gasPrice}             = $self->gas_price                                                    if $self->gas_price;
    $params->{maxFeePerGas}         = $self->max_fee_per_gas                                              if $self->max_fee_per_gas;
    $params->{maxPriorityFeePerGas} = $self->max_priority_fee_per_gas                                     if $self->max_priority_fee_per_gas;

    my $res = $self->rpc_client->eth_sendTransaction([$params]);

    return $future->done(Ethereum::RPC::Contract::ContractResponse->new({response => $res})) if $res and $res =~ /^0x/;
    return $future->fail($res || "Can't send transaction");

}

=head2 get_contract_address

Try to get a contract address based on a transaction hash

Parameters:
    $wait_seconds    ( Optional - max time to wait for the contract address response ),
    $send_response     ( Optional - response of the send method, if not informed send a new transaction and then try to get the address ),

Return:
    Ethereum::Contract::ContractResponse

=cut

sub get_contract_address {

    my ($self, $wait_seconds, $send_response) = @_;

    my $transaction = $send_response // $self->send_transaction();
    return $transaction if $transaction->is_failed;

    my $deployed = $self->rpc_client->eth_getTransactionReceipt($transaction->get->response);

    while ($wait_seconds and not $deployed and $wait_seconds > 0) {
        sleep(1);
        $wait_seconds--;
        $deployed = $self->rpc_client->eth_getTransactionReceipt($transaction->get->response);
    }

    my $future = Future->new;
    return $future->done(Ethereum::RPC::Contract::ContractResponse->new({response => $deployed->{contractAddress}}))
        if $deployed and ref($deployed) eq 'HASH';

    return $future->fail("Can't get the contract address for transaction: " . $transaction->get->response);

}

1;
