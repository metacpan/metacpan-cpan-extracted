# This code is part of Perl distribution Mail-Message version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::TransferEnc::SevenBit;{
our $VERSION = '4.01';
}

use parent 'Mail::Message::TransferEnc';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw// ];

#--------------------

sub name() { '7bit' }

sub check($@)
{	my ($self, $body, %args) = @_;
	$body;
}

sub decode($@)
{	my ($self, $body, %args) = @_;
	$body->transferEncoding('none');
	$body;
}

sub encode($@)
{	my ($self, $body, %args) = @_;

	my @lines;
	my $changes = 0;

	foreach ($body->lines)
	{	$changes++ if s/([^\000-\127])/chr(ord($1) & 0x7f)/ge;
		$changes++ if s/[\000\013]//g;

		$changes++ if length > 997;
		push @lines, substr($_, 0, 996, '')."\n"
			while length > 997;

		push @lines, $_;
	}

	unless($changes)
	{	$body->transferEncoding('7bit');
		return $body;
	}

	my $bodytype = $args{result_type} || ref $body;
	$bodytype->new(based_on => $body, transfer_encoding => '7bit', data => \@lines);
}

1;
