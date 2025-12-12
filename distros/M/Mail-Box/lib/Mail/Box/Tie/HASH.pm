# This code is part of Perl distribution Mail-Box version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Tie::HASH;{
our $VERSION = '4.00';
}

use parent 'Mail::Box::Tie';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x warning/ ];

#--------------------

sub TIEHASH(@)
{	my ($class, $folder) = @_;
	$class->new($folder, 'HASH');
}

#--------------------

#--------------------

sub FETCH($) { $_[0]->folder->messageId($_[1]) }


sub STORE($$)
{	my ($self, $key, $basicmsg) = @_;

	! defined $key || $key eq 'undef'
		or warning __x"use undef as key, because the message-id of the message is used.";

	$self->folder->addMessages($basicmsg);
}


sub FIRSTKEY()
{	my $self   = shift;
	$self->{MBT_each_index} = 0;
	$self->NEXTKEY();
}


sub NEXTKEY($)
{	my $self   = shift;
	my $folder = $self->{MBT_folder};
	my $nrmsgs = $folder->messages;

	my $msg;
	while(1)
	{	my $index = $self->{MBT_each_index}++;
		$index < $nrmsgs or return undef;
		$msg      = $folder->message($index);
		$msg->isDeleted or last;
	}

	$msg->messageId;
}


sub EXISTS($)
{	my ($self, $msgid) = @_;
	my $msg = $self->folder->messageId($msgid);
	defined $msg && ! $msg->isDeleted;
}


sub DELETE($)
{	my ($self, $msgid) = @_;
	$self->folder->messageId($msgid)->delete;
}


sub CLEAR()
{	my $self = shift;
	$_->delete for $self->folder->messages;
}

1;
