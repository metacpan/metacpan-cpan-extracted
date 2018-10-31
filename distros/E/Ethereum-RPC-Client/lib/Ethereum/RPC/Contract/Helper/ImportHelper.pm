package Ethereum::RPC::Contract::Helper::ImportHelper;

use strict;
use warnings;

use Path::Tiny;

our $VERSION = '0.03';

=head1 NAME

    Ethereum::RPC::Contract::Helper::ImportHelper - ImportHelper

=cut

use JSON::MaybeXS;

=head2 to_hex

Auxiliar to get bytecode and the ABI from the compiled truffle json.

Parameters:
    file path

Return:
    {abi, bytecode}

=cut

sub from_truffle_build {
    my $file = shift;

    my $document = path($file)->slurp_utf8;

    my $decoded_json = decode_json($document);

    return {
        abi      => encode_json($decoded_json->{abi}),
        bytecode => $decoded_json->{bytecode}};
}

1;
