# This code is part of Perl distribution Mail-Message version 3.019.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::TransferEnc;{
our $VERSION = '3.019';
}

use base 'Mail::Reporter';

use strict;
use warnings;

#--------------------

my %encoder = (
	'base64' => 'Mail::Message::TransferEnc::Base64',
	'7bit'   => 'Mail::Message::TransferEnc::SevenBit',
	'8bit'   => 'Mail::Message::TransferEnc::EightBit',
	'quoted-printable' => 'Mail::Message::TransferEnc::QuotedPrint',
);

#--------------------

sub create($@)
{	my ($class, $type) = (shift, shift);

	my $encoder = $encoder{lc $type};
	unless($encoder)
	{	$class->new(@_)->log(WARNING => "No decoder for transfer encoding $type.");
		return;
	}

	eval "require $encoder";
	if($@)
	{	$class->new(@_)->log(ERROR => "Decoder for transfer encoding $type does not work:\n$@");
		return;
	}

	$encoder->new(@_);
}


sub addTransferEncoder($$)
{	my ($class, $type, $encoderclass) = @_;
	$encoder{lc $type} = $encoderclass;
	$class;
}


sub name { $_[0]->notImplemented }

#--------------------

sub check($@) { $_[0]->notImplemented }


sub decode($@) { $_[0]->notImplemented }


sub encode($) { $_[0]->notImplemented }

#--------------------

1;
