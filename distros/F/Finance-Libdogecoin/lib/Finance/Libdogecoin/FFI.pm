package Finance::Libdogecoin::FFI;
# ABSTRACT: Use features from libdogecoin via FFI

use strict;
use warnings;

use FFI::Platypus;
use FFI::CheckLib 0.28 'find_lib_or_die';
use FFI::Platypus::Buffer qw( buffer_to_scalar grow set_used_length );

use Alien::Libdogecoin;

{
    my $ffi = FFI::Platypus->new(
        api => 1,
        lib => [
            find_lib_or_die lib => 'dogecoin',
            alien => [ 'Alien::Libdogecoin' ],
        ],
    );

    while (my $sig = <DATA>) {
        chomp $sig;
        my ($return, $name, @args) = split /,/, $sig;
        $ffi->attach( $name => \@args => $return );
    }

    *context_start = \&dogecoin_ecc_start;
    *context_stop  = \&dogecoin_ecc_stop;
}

sub _call_with_buffer_pair {
    my ($is_testnet, $priv_buffer_len, $pub_buffer_len, $function) = @_;

    grow( (my $privkeybuf), $priv_buffer_len );
    grow( (my $pubkeybuf), $pub_buffer_len + 1);

    $function->($privkeybuf, $pubkeybuf, $is_testnet);

    return( substr($privkeybuf, 0, $priv_buffer_len), substr($pubkeybuf, 0, $pub_buffer_len) );
}

sub generate_key_pair {
    my $is_testnet = shift( @_ ) ? 1 : 0;
    return _call_with_buffer_pair( $is_testnet, 53, 34, \&generatePrivPubKeypair );
}

sub verify_key_pair {
    my ($priv_key, $pub_key, $is_testnet) = @_;

    return verifyPrivPubKeypair( $priv_key, $pub_key, !!$is_testnet );
}

sub verify_p2pkh_address {
    my $address = shift;
    return !! verifyP2pkhAddress( $address, length($address) );
}

sub generate_hd_master_pub_key_pair {
    my $chaincode = shift( @_ ) ? 1 : 0;
    return _call_with_buffer_pair( $chaincode, 128, 35, \&generateHDMasterPubKeypair );
}

sub generate_derived_hd_pub_key {
    my $master_priv_key = shift;
    grow my $pubkeybuf, 128;
    generateDerivedHDPubkey($master_priv_key, $pubkeybuf);

    return substr($pubkeybuf, 0, 128);
}

sub verify_master_priv_pub_keypair {
    my ($priv_key, $pub_key, $chaincode) = @_;
    $chaincode = $chaincode ? 1 : 0;

    return verifyHDMasterPubKeypair( $priv_key, $pub_key, $chaincode );
}

'much wow';

=pod

=encoding UTF-8

=head1 NAME

Finance::Libdogecoin::FFI - Use features from libdogecoin via FFI

=head1 VERSION

version 1.20220815.1712

=head2 SYNOPSIS

To generate and verify a private/public keypair:

    # call this before all key-manipulation functions
    Finance::Libdogecoin::FFI::context_start();

    my ($priv_key, $pub_key) = Finance::Libdogecoin::FFI::generate_key_pair();

    if (Finance::Libdogecoin::FFI::verify_key_pair( $priv_key, $pub_key )) {
        # ... key pair is valid
    }

    # call this after all key-manipulation functions
    Finance::Libdogecoin::FFI::context_stop();

From this example be aware of three things:

=over 4

=item * First, call C<context_start()> before and C<context_stop()> after any
use of the key-manipulation functions. These start and finish the cryptographic
context used in the underlying C library.

=item * Second, these function are available from the
C<Finance::Libdogecoin::FFI> namespace and are not exported by default.

=item * Third, these functions are minimally Perlish. A nicer interface should/will exist.

=back

=head2 DESCRIPTION

This module provides a minimal FFI interface to C<libdogecoin> functions. It
uses L<Alien::Libdogecoin> to use a local installation of this library or the
system version.

See
L<https://github.com/dogecoinfoundation/libdogecoin/blob/main/doc/address.md>
for full documentation of the C<libdogecoin> library, including the principles
behind the design. The API of this module follows the example of the Python
bindings, though the C function calls are also available in this namespace.

=head2 FUNCTIONS

=head3 C<context_start()>

Initializes the C<libdogecoin> cryptography mechanism. Call this before using
any other key-management functions.

=head3 C<context_start()>

Finishes the C<libdogecoin> cryptography mechanism. Call this when you no
longer need to use any other key-management functions.

=head3 C<generate_key_pair( $is_testnet )>

The boolean C<$is_testnet> argument is optional; the default value is false.

Generates and returns a private/public key pair for the network. The return value
is two strings in base-58 encoding. Do not share the private key. Do not lose
the private key.

The public key is a valid P2PKH address.

=head3 C<verify_key_pair( $private_key, $public_key, $is_testnet )>

The boolean C<$is_testnet> argument is optional; the default value is false.

Given two strings in base-58 encoding, returns a boolean value to indicate
whether the pair is valid for the given network.

=head3 C<verify_p2pkh_address( $address )>

Given a public key, returns a boolean to indicate whether the address passes
validation checks. This doesn't guarantee that an address I<is> legitimate, but
it can help decide whether it's worth sending to it at all.

=head3 C<generate_hd_master_pub_key_pair( $is_testnet )>

The boolean C<$is_testnet> argument is optional; the default value is false.

Generates and returns a private/public key hierarchical deterministic pair for
the network. The return value is two strings in base-58 encoding. Do not share
the private key. Do not lose the private key.

=head3 C<generate_derived_hd_pub_key( $master_private_key )>

Given a master key hierarchical deterministic key, derive and return a public
key associated with the master.

=head3 C<verify_master_priv_pub_keypair( $master_private_key, $master_public_key, $is_testnet )>

The boolean C<$is_testnet> argument is optional; the default value is false.

Given two strings representing hierarchical deterministic keys (a master
public key and a master private key) in base-58 encoding, returns a boolean
value to indicate whether the pair both match and are valid for the given
network. In other words, for the given network, can the public key be derived
from the private key?

=head2 AUTHOR, COPYRIGHT, and LICENSE

Copyright (c) 2022, chromatic. Interface based on and derived from the C<libdogecoin> Python bindings.

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by chromatic.

This is free software, licensed under:

  The MIT (X11) License

=cut

__DATA__
void,dogecoin_ecc_start
void,dogecoin_ecc_stop
int,generatePrivPubKeypair,string,string,bool
void,generateHDMasterPubKeypair,string,string,bool
int,generateDerivedHDPubkey,string,string
int,verifyPrivPubKeypair,string,string,bool
int,verifyHDMasterPubKeypair,string,string,bool
int,verifyP2pkhAddress,string,uchar
