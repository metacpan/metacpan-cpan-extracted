[![Build Status](https://travis-ci.org/binary-com/perl-Ethereum-Contract.svg?branch=master)](https://travis-ci.org/binary-com/perl-Ethereum-Contract)
[![codecov](https://codecov.io/gh/binary-com/perl-Ethereum-Contract/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Ethereum-Contract)

# NAME

perl-Ethereum-RPC

# SYNOPSIS

```perl
use strict;
use warnings;
use Ethereum::RPC::Client;

my $abi = ...;
my $bytecode = ...;
my $rpc_client = Ethereum::RPC::Client->new;

my $coinbase = $rpc_client->eth_coinbase;

my $contract = $rpc_client->contract({
    contract_abi    => $abi,
    from            => $from,
    gas             => $gas,
});

my $message = $contract->deploy($bytecode)->get_contract_address(35);
die $message->failure if $message->is_failed;

$message = $contract->invoke("functionname", qw{param1 param2 param3})->call_transaction();
print $message->get->to_big_int() unless $error;

$message = $contract->invoke("functionname", $param1, $param2, $param3)->send_transaction();

```

# DESCRIPTION

perl-Ethereum-Contract is a library to enable perl to call the contract functions using RPC calls.

# USAGE

- Calling RPC commands

    ```perl
        my $rpc_client = Ethereum::RPC::Client->new; 
        my $balance = $rpc_client->eth_getBalance("0x0...", "latest");
    ```

- Loading Contract

    ```perl
        my $rpc_client = Ethereum::RPC::Client->new; 

        my $contract = $rpc_client->contract({
            contract_abi    => $abi,
            from            => $coinbase,
            gas             => 3000000,
        });
    ```
    
- Deploying a Contract

    ```perl
        $contract->deploy($bytecode);
    ```
    
- Calling a Contract function

    ```perl
        my $message = $contract->invoke($function_name, param1, param2, ...)->call_transaction();
        $big_int = $message->get->to_big_int unless $message->is_failed;
    ```

# CAVEATS

This software is in an early state.

### REQUIREMENTS
* perl 5

# AUTHOR

Binary.com

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

