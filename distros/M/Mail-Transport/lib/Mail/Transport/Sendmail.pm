# This code is part of Perl distribution Mail-Transport version 3.008.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Transport::Sendmail;{
our $VERSION = '3.008';
}

use base 'Mail::Transport::Send';

use strict;
use warnings;

use Carp;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{via} = 'sendmail';

	$self->SUPER::init($args) or return;

	$self->{MTS_program} = $args->{proxy} || $self->findBinary('sendmail') or return;
	$self->{MTS_opts} = $args->{sendmail_options} || [];
	$self;
}

#--------------------

sub trySend($@)
{	my ($self, $message, %args) = @_;

	my $program = $self->{MTS_program};
	my $mailer;
	if(open($mailer, '|-')==0)
	{	# Child process is sendmail binary
		my $options = $args{sendmail_options} || [];
		my @to = map $_->address, $self->destinations($message, $args{to});

		# {} to avoid warning about code after exec
		{	exec $program, '-i', @{$self->{MTS_opts}}, @$options, @to; }

		$self->log(NOTICE => "Errors when opening pipe to $program: $!");
		exit 1;
	}

	# Parent process is the main program, still
	$self->putContent($message, $mailer, undisclosed => 1);

	unless($mailer->close)
	{	$self->log(NOTICE => "Errors when closing sendmail mailer $program: $!");
		$? ||= $!;
		return 0;
	}

	1;
}

1;
