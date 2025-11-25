# This code is part of Perl distribution Mail-Transport version 3.008.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Transport::Send;{
our $VERSION = '3.008';
}

use base 'Mail::Transport';

use strict;
use warnings;

use Carp;
use File::Spec;
use Errno 'EAGAIN';

#--------------------

sub new(@)
{	my $class = shift;
	$class eq __PACKAGE__ or return $class->SUPER::new(@_);

	require Mail::Transport::Sendmail;
	Mail::Transport::Sendmail->new(@_);
}

#--------------------

sub send($@)
{	my ($self, $message, %args) = @_;

	unless($message->isa('Mail::Message'))  # avoid rebless.
	{	$message = Mail::Message->coerce($message);
		defined $message
			or confess "Unable to coerce object into Mail::Message.";
	}

	$self->trySend($message, %args)
		and return 1;

	$?==EAGAIN
		or return 0;

	my ($interval, $retry) = $self->retry;
	$interval = $args{interval} if exists $args{interval};
	$retry    = $args{retry}    if exists $args{retry};

	while($retry!=0)
	{	sleep $interval;
		return 1 if $self->trySend($message, %args);
		$?==EAGAIN or return 0;
		$retry--;
	}

	0;
}


sub trySend($@)
{	my $self = shift;
	$self->log(ERROR => "Transporters of type ".ref($self). " cannot send.");
}


sub putContent($$@)
{	my ($self, $message, $fh, %args) = @_;

	   if($args{body_only})   { $message->body->print($fh) }
	elsif($args{undisclosed}) { $message->Mail::Message::print($fh) }
	else
	{	$message->head->printUndisclosed($fh);
		$message->body->print($fh);
	}

	$self;
}



sub destinations($;$)
{	my ($self, $message, $overrule) = @_;
	my @to;

	if(defined $overrule)      # Destinations overruled by user.
	{	@to = map { ref $_ && $_->isa('Mail::Address') ? ($_) : Mail::Address->parse($_) }
			ref $overrule eq 'ARRAY' ? @$overrule : ($overrule);
	}
	elsif(my @rgs = $message->head->resentGroups)
	{	# Create with bounce
		@to = $rgs[0]->destinations;
		@to or $self->log(WARNING => "Resent group does not specify a destination"), return ();
	}
	else
	{	@to = $message->destinations;
		@to or $self->log(WARNING => "Message has no destination"), return ();
	}

	@to;
}

#--------------------

1;
