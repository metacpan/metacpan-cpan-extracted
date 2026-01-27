# This code is part of Perl distribution Mail-Message version 4.03.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::TransferEnc;{
our $VERSION = '4.03';
}

use parent 'Mail::Reporter';

use strict;
use warnings;

use Log::Report     'mail-message', import => [ qw/__x error/ ];

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

	my $encoder = $encoder{lc $type}
		or error __x"no decoder for transfer encoding {type}.", type => $type;

	eval "require $encoder";
	$@ and error __x"decoder for transfer encoding {type} does not work:\n{error}", type => $type, error => $@;

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
