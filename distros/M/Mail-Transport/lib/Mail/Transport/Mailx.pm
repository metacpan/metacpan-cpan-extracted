# This code is part of Perl distribution Mail-Transport version 3.008.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Transport::Mailx;{
our $VERSION = '3.008';
}

use base 'Mail::Transport::Send';

use strict;
use warnings;

use Carp;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{via} = 'mailx';

	$self->SUPER::init($args) or return;

	$self->{MTM_program} = $args->{proxy} || $self->findBinary('mailx') || $self->findBinary('Mail')
		|| $self->findBinary('mail') or return;

	$self->{MTM_style} = $args->{style} // ( $^O =~ m/linux|freebsd|bsdos|netbsd|openbsd/ ? 'BSD' : 'RFC822' );
	$self;
}


sub _try_send_bsdish($$)
{	my ($self, $message, $args) = @_;

	my @options = ('-s' => $message->subject);

	{	local $" = ',';
		my @cc  = map $_->format, $message->cc;
		push @options, ('-c' => "@cc")  if @cc;

		my @bcc = map $_->format, $message->bcc;
		push @options, ('-b' => "@bcc") if @bcc;
	}

	my @to      = map $_->format, $message->to;
	my $program = $self->{MTM_program};

	my $mailer;
	if((open $mailer, '|-')==0)
	{	close STDOUT;
		{	exec $program, @options, @to }
		$self->log(NOTICE => "Cannot start contact to $program: $!");
		exit 1;
	}

	$self->putContent($message, $mailer, body_only => 1);

	$mailer->close
		or $self->log(ERROR => "Sending via mailx mailer $program failed: $! ($?)"), return 0;

	my $msgid = $message->messageId;
	$self->log(PROGRESS => "Message $msgid send.");
	1;
}

sub trySend($@)
{	my ($self, $message, %args) = @_;

	return $self->_try_send_bsdish($message, \%args)
		if $self->{MTM_style} eq 'BSD';

	my $program = $self->{MTM_program};
	open my $mailer, '|-', $program, '-t'
		or $self->log(NOTICE => "Cannot start contact to $program: $!"), return 0;

	$self->putContent($message, $mailer);

	$mailer->close
		or $self->log(ERROR => "Sending via mailx mailer $program failed: $! ($?)"), return 0;

	1;
}

1;
