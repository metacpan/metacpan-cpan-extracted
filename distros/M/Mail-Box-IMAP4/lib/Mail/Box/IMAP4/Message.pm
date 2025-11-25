# This code is part of Perl distribution Mail-Box-IMAP4 version 3.010.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::IMAP4::Message;{
our $VERSION = '3.010';
}

use base 'Mail::Box::Net::Message';

use strict;
use warnings;

use Date::Parse 'str2time';

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->{MBIM_write_labels} = exists $args->{write_labels} ? $args->{write_labels} : 1;
	$self->{MBIM_cache_labels} = $args->{cache_labels};
	$self->{MBIM_cache_head}   = $args->{cache_head};
	$self->{MBIM_cache_body}   = $args->{cache_body};
	$self;
}


sub size($)
{	my $self = shift;
	$self->isDelayed ? $self->fetch('RFC822.SIZE') : $self->SUPER::size;
}

sub recvstamp()
{	my $date = shift->fetch('INTERNALDATE');
	defined $date ? str2time($date) : undef;
}


sub label(@)
{	my $self = shift;
	my $imap = $self->folder->transporter or return;
	my $id   = $self->unique or return;

	if(@_ == 1)
	{	# get one value only
		my $label  = shift;
		my $labels = $self->{MM_labels};
		return $labels->{$label}
			if exists $labels->{$label} || exists $labels->{seen};

		my $flags = $imap->getFlags($id);
		if($self->{MBIM_cache_labels})
		{	# the program may have added own labels
			@{$labels}{keys %$flags} = values %$flags;
			delete $self->{MBIM_labels_changed};
		}
		return $flags->{$label};
	}

	my @private;
	if($self->{MBIM_write_labels})
	{	@private = $imap->setFlags($id, @_);
		delete $self->{MBIM_labels_changed};
	}
	else
	{	@private = @_;
	}

	my $labels  = $self->{MM_labels};
	my @keep    = $self->{MBIM_cache_labels} ? @_ : @private;

	while(@keep)
	{	my ($k, $v) = (shift @keep, shift @keep);
		next if defined $labels->{$k} && $labels->{$k} eq $v;

		$self->{MBIM_labels_changed}++;
		$labels->{$k} = $v;
	}

	$self->modified(1) if @private && $self->{MBIM_labels_changed};
	$self;
}


sub labels()
{	my $self   = shift;
	my $id     = $self->unique;
	my $labels = $self->SUPER::labels;
	$labels    = { %$labels } unless $self->{MBIM_cache_labels};

	if($id && !exists $labels->{seen})
	{	my $imap = $self->folder->transporter or return;
		my $flags = $imap->getFlags($id);
		@{$labels}{keys %$flags} = values %$flags;
	}

	$labels;
}

#--------------------

sub loadHead()
{	my $self     = shift;
	my $head     = $self->head;
	$head->isDelayed or return $head;

	$head         = $self->folder->getHead($self);
	$self->head($head) if $self->{MBIM_cache_head};
	$head;
}

sub loadBody()
{	my $self     = shift;

	my $body     = $self->body;
	$body->isDelayed or return $body;

	(my $head, $body) = $self->folder->getHeadAndBody($self);
	defined $head or return undef;

	$self->head($head)      if $self->{MBIM_cache_head} && $head->isDelayed;
	$self->storeBody($body) if $self->{MBIM_cache_body};
	$body;
}


sub fetch(@)
{	my ($self, @info) = @_;
	my $folder = $self->folder;
	my $answer = ($folder->fetch( [$self], @info))[0];

	@info==1 ? $answer->{$info[0]} : @{$answer}{@info};
}


sub writeDelayed($$)
{	my ($self, $foldername, $imap) = @_;

	my $id     = $self->unique;
	my $labels = $self->labels;

	if($self->head->modified || $self->body->modified || !$id)
	{	$imap->appendMessage($self, $foldername);
		if($id)
		{	$self->delete;
			$self->unique(undef);
		}
	}
	elsif($self->{MBIM_labels_changed})
	{	$imap->setFlags($id, %$labels);  # non-IMAP4 labels disappear
		delete $self->{MBIM_labels_changed};
	}

	$self;
}

#--------------------

1;
