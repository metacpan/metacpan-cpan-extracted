# This code is part of Perl distribution Mail-Transport version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Transport::Exim;{
our $VERSION = '4.00';
}

use parent 'Mail::Transport::Send';

use strict;
use warnings;

use Log::Report   'mail-transport', import => [ qw/__x error fault warning/ ];

use Scalar::Util  qw/blessed/;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{via} = 'exim';
	$self->SUPER::init($args);

	$self->{MTS_program} = $args->{proxy} ||
		( -x '/usr/sbin/exim4' ? '/usr/sbin/exim4' : undef) || $self->findBinary('exim', '/usr/exim/bin')
		or error __x"cannot find binary for exim.";

	$self;
}


sub trySend($@)
{	my ($self, $message, %args) = @_;

	my $from = $args{from} || $message->sender;
	$from    = $from->address if blessed $from && $from->isa('Mail::Address');
	my @to   = map $_->address, $self->destinations($message, $args{to});

	my $program = $self->{MTS_program};
	my $mailer;
	if(open($mailer, '|-')==0)
	{	{ exec $program, '-i', '-f', $from, @to; }  # {} to avoid warning
		fault __x"cannot open pipe to {program}", program => $program;
	}

	$self->putContent($message, $mailer, undisclosed => 1);

	$mailer->close
		or fault __x"errors when closing Exim mailer {program}", program => $program;

	1;
}

1;
