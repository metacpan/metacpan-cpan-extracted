# This code is part of Perl distribution Mail-Message version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::TransferEnc::Base64;{
our $VERSION = '4.01';
}

use parent 'Mail::Message::TransferEnc';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/warning/ ];

use MIME::Base64  qw/decode_base64 encode_base64/;

#--------------------

sub name() { 'base64' }

sub check($@)
{	my ($self, $body, %args) = @_;
	$body;
}


sub decode($@)
{	my ($self, $body, %args) = @_;

	my $lines = decode_base64($body->string);
	unless($lines)
	{	$body->transferEncoding('none');
		return $body;
	}

	my $bodytype = $args{result_type} || ($body->isBinary ? 'Mail::Message::Body::File' : ref $body);
	$bodytype->new(based_on => $body, transfer_encoding => 'none', data => $lines);
}

sub encode($@)
{	my ($self, $body, %args) = @_;
	my $bodytype = $args{result_type} || ref $body;

	$bodytype->new(
		based_on          => $body,
		checked           => 1,
		transfer_encoding => 'base64',
		data              => encode_base64($body->string),
	);
}

1;
