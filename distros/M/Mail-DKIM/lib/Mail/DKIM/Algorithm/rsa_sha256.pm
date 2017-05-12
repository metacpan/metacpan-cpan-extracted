#!/usr/bin/perl

# Copyright 2005-2006 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;

package Mail::DKIM::Algorithm::rsa_sha256;
use base "Mail::DKIM::Algorithm::Base";
use Carp;
use MIME::Base64;
use Digest::SHA;

sub init_digests
{
	my $self = shift;

	# initialize a SHA-256 Digest
	$self->{header_digest} = new Digest::SHA(256);
	$self->{body_digest} = new Digest::SHA(256);
}

sub sign
{
	my $self = shift;
	croak "wrong number of arguments" unless (@_ == 1);
	my ($private_key) = @_;

	my $digest = $self->{header_digest}->digest;
	my $signature = $private_key->sign_digest("SHA-256", $digest);

	return encode_base64($signature, "");
}

sub verify
{
	my $self = shift;
	croak "wrong number of arguments" unless (@_ == 0);

	my $base64 = $self->signature->data;
	my $public_key = $self->signature->get_public_key;

	my $digest = $self->{header_digest}->digest;
	my $sig = decode_base64($base64);
	return unless $public_key->verify_digest("SHA-256", $digest, $sig);
	return $self->check_body_hash;
}

sub wants_pre_signature_headers
{
	return 1;
}

1;
