# This code is part of Perl distribution Mail-Message version 4.02.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::TransferEnc::QuotedPrint;{
our $VERSION = '4.02';
}

use parent 'Mail::Message::TransferEnc';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw// ];

use MIME::QuotedPrint qw/encode_qp decode_qp/;

#--------------------

sub name() { 'quoted-printable' }

sub check($@)
{	my ($self, $body, %args) = @_;
	$body;
}


sub decode($@)
{	my ($self, $body, %args) = @_;

	my $bodytype = $args{result_type} || ref $body;
	$bodytype->new(based_on => $body, transfer_encoding => 'none', data => decode_qp($body->string));
}


sub encode($@)
{	my ($self, $body, %args) = @_;

	my $bodytype = $args{result_type} || ref $body;
	$bodytype->new(based_on => $body, transfer_encoding => 'quoted-printable', data => encode_qp($body->string));
}

1;
