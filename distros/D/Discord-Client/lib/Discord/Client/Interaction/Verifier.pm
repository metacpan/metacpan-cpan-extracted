package Discord::Client::Interaction::Verifier;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use Crypt::PK::Ed25519;
use Time::HiRes qw(time);

our $VERSION = '0.002';

sub new {
    my ( $class, %args ) = @_;

    # Import only an exact Ed25519 public key, then configure the local freshness policy.
    croak 'public_key must be a 32-byte hexadecimal Ed25519 public key'
        unless defined( $args{public_key} ) && !ref( $args{public_key} ) && $args{public_key} =~ /\A[0-9a-fA-F]{64}\z/;
    my $key = eval { Crypt::PK::Ed25519->new->import_key_raw( pack( 'H*', $args{public_key} ), 'public' ) };
    croak 'Invalid Ed25519 public key' unless $key;
    my $age = $args{max_age} // 300;
    croak 'max_age must be a nonnegative integer' unless !ref($age) && $age =~ /\A\d+\z/;
    croak 'wall_clock must be a code reference' if exists( $args{wall_clock} ) && ref( $args{wall_clock} ) ne 'CODE';
    return bless { key => $key, max_age => $age, wall_clock => $args{wall_clock} // sub { time() } }, $class;
}

sub verify {
    my ( $self, $signature, $timestamp, $body ) = @_;

    # Reject malformed signatures, timestamps and decoded text before cryptographic work.
    return 0
        unless defined($signature)
        && !ref($signature)
        && $signature =~ /\A[0-9a-fA-F]{128}\z/
        && defined($timestamp)
        && !ref($timestamp)
        && $timestamp =~ /\A\d{1,20}\z/
        && defined($body)
        && !ref($body)
        && !utf8::is_utf8($body);

    # Timestamp tolerance is a local replay policy, independent of signature validity.
    return 0 if $self->{max_age} && abs( $self->{wall_clock}->() - $timestamp ) > $self->{max_age};

    # Verify the exact timestamp and body octets before JSON parsing.
    return eval { $self->{key}->verify_message( pack( 'H*', $signature ), $timestamp . $body ) } ? 1 : 0;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::Interaction::Verifier - Discord Ed25519 request verification

=head1 SYNOPSIS

    use Discord::Client::Interaction::Verifier;

    # Verify the timestamp and exact raw body before parsing JSON.
    my $verifier = Discord::Client::Interaction::Verifier->new(public_key => $key);
    my $valid = $verifier->verify($signature_hex, $timestamp, $raw_body);

=head1 DESCRIPTION

Checks L<Discord request signatures|https://docs.discord.com/developers/interactions/overview#validating-security-request-headers>
using Ed25519. L<Discord::Client::HTTPInteractions> applies it before dispatch.

=head1 METHODS

=head2 new

C<new(public_key =E<gt> $key, max_age =E<gt> 300)> returns a verifier.
The public key must be 64 hexadecimal characters. Invalid configuration throws.
C<max_age> is the allowed difference from the local wall clock in seconds;
zero disables this SDK freshness policy. C<wall_clock> can supply a callback
returning Unix seconds for testing.

=head2 verify

C<verify(signature_hex, timestamp, raw_body)> returns a boolean synchronously.
The signature must be 128 hexadecimal characters and the timestamp a decimal
string. C<raw_body> must contain exact octets, before decoding or reserializing.
Verification covers the timestamp followed by those bytes. Invalid arguments,
failed signatures and stale timestamps return false.

=head1 LICENSE

Apache License 2.0.

=cut
