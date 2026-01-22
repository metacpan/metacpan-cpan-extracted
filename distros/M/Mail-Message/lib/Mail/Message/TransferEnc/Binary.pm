# This code is part of Perl distribution Mail-Message version 4.02.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::TransferEnc::Binary;{
our $VERSION = '4.02';
}

use parent 'Mail::Message::TransferEnc';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw// ];

#--------------------

sub name() { 'binary' }

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
	{	$changes++ if s/[\000\013]//g;
		push @lines, $_;
	}

	unless($changes)
	{	$body->transferEncoding('none');
		return $body;
	}

	my $bodytype = $args{result_type} || ref($self->load);
	$bodytype->new(based_on => $body, transfer_encoding => 'none', data => \@lines);
}

1;
