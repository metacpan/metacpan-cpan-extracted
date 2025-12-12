# This code is part of Perl distribution Mail-Box version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Thread::Manager;{
our $VERSION = '4.00';
}

use parent 'Mail::Reporter';

use strict;
use warnings;

use Log::Report             'mail-box', import => [ qw/__x error/ ];

use Mail::Box::Thread::Node ();
use Mail::Message::Dummy    ();
use Scalar::Util            qw/blessed/;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->{MBTM_manager} = $args->{manager}
		or error __x"thread manager needs a folder manager to work with.";

	$self->{MBTM_thread_body}= $args->{thread_body} // 0;
	$self->{MBTM_thread_type}= $args->{thread_type} // 'Mail::Box::Thread::Node';
	$self->{MBTM_dummy_type} = $args->{dummy_type}  // 'Mail::Message::Dummy';
	$self->{MBTM_window}     = $args->{window}      // 10;
	$self->{MBTM_ids}        = +{ };
	$_[0]->{MBTM_folders}    = +{ };

	my $ts = $args->{timespan} || '3 days';
	$self->{MBTM_timespan} = $ts eq 'EVER' ? 'EVER' : Mail::Box->timespan2seconds($ts);
	$self;
}

#--------------------

sub folderIndex() { $_[0]->{MBTM_folders} }
sub folders()     { values %{$_[0]->folderIndex} }
sub folder($)     { $_[0]->folderIndex->{$_[1]} }


sub byId { $_[0]->{MBTM_ids} }


sub msgById($) { my $ids = $_[0]->byId; @_ > 2 ? $ids->{$_[1]} = $_[2] : $ids->{$_[1]} }

#--------------------

sub includeFolder(@)
{	my $self  = shift;
	my $index = $self->folderIndex;

	foreach my $folder (@_)
	{	blessed $folder && $folder->isa('Mail::Box')
			or error __x"attempt to include a none folder: {what UNKNOWN}.", what => $folder;

		my $name = $folder->name;
		next if exists $index->{$name};

		$index->{$name} = $folder;
		$self->inThread($_) for grep ! $_->head->isDelayed, $folder->messages;
	}

	$self;
}


sub removeFolder(@)
{	my $self  = shift;
	my $index = $self->folderIndex;

	foreach my $folder (@_)
	{	blessed $folder && $folder->isa('Mail::Box')
			or error __x"attempt to remove a none folder: {what UNKNOWN}.", what => $folder;

		my $name = $folder->name;
		delete $index->{$name} or next;

		$_->headIsRead && $self->outThread($_)
			for $folder->messages;

		$self->{MBTM_cleanup_needed} = 1;
	}

	$self;
}

#--------------------

sub thread($)
{	my ($self, $message) = @_;
	my $msgid     = $message->messageId;
	my $timestamp = $message->timestamp;

	$self->_processDelayedNodes;
	my $thread    = $self->msgById($msgid) or return;

	my @missing;
	$thread->recurse( sub {
		my $node = shift;
		push @missing, $node->messageId if $node->isDummy;
		1;
	});

	@missing or return $thread;

	foreach my $folder ($self->folders)
	{
		# Pull-in all messages received after this-one, from any folder.
		# Clocks may drift a bit, so use margin.
		my @now_missing = $folder->scanForMessages($msgid, \@missing, $timestamp - 3600, 0);

		if(@now_missing != @missing)
		{	$self->_processDelayedNodes;
			@now_missing or last;
			@missing = @now_missing;
		}
	}

	$thread;
}


sub threadStart($)
{	my ($self, $message) = @_;
	my $thread = $self->thread($message) or return;

	while(my $parent = $thread->repliedTo)
	{	unless($parent->isDummy)
		{	# Message already found, no special action to be taken.
			$thread = $parent;
			next;
		}

		foreach my $folder ($self->folders)
		{	my $message  = $thread->message;
			my $timespan = $message->isDummy ? 'ALL' : $message->timestamp - $self->{MBTM_timespan};

			$folder->scanForMessages($thread->messageId, $parent->messageId, $timespan, $self->{MBTM_window})
				or last;
		}

		$self->_processDelayedNodes;
		$thread = $parent;
	}

	$thread;
}


sub all()
{	my $self = shift;
	$_->find('not-existing') for $self->folders;
	$self->known;
}


sub sortedAll(@)
{	my $self = shift;
	$_->find('not-existing') for $self->folders;
	$self->sortedKnown(@_);
}


sub known()
{	my $self      = shift->_processDelayedNodes->_cleanup;
	grep !defined $_->repliedTo, values %{$self->byId};
}


sub sortedKnown(;$$)
{	my $self    = shift;
	my $prepare = shift || sub { $_[0]->startTimeEstimate || 0 };
	my $compare = shift || sub { $_[0] <=> $_[1] };

	# Special care for double keys.
	my %value;
	push @{$value{$prepare->($_)}}, $_ for $self->known;
	map @{$value{$_}}, sort {$compare->($a, $b)} keys %value;
}

# When a whole folder is removed, many threads can become existing
# only of dummies.  They must be removed.

sub _cleanup()
{	my $self = shift;
	$self->{MBTM_cleanup_needed} or return $self;

	foreach my $thread ($self->known)
	{	my $real = 0;
		$thread->recurse( sub {
			my $node = shift;
			foreach my $msg ($node->messages)
			{	next if $msg->isDummy;
				$real = 1;
				return 0;
			}
			1;
		});

		next if $real;

		$thread->recurse( sub {
			my $node  = shift;
			delete $self->byId->{$node->messageId};
			1;
		});
	}

	delete $self->{MBTM_cleanup_needed};
	$self;
}

#--------------------

sub toBeThreaded($@)
{	my ($self, $folder) = (shift, shift);
	$self->folder($folder->name) or return $self;
	$self->inThread($_) for @_;
	$self;
}


sub toBeUnthreaded($@)
{	my ($self, $folder) = (shift, shift);
	$self->folder($folder->name) or return $self;
	$self->outThread($_) for @_;
	$self;
}


sub inThread($)
{	my ($self, $message) = @_;
	my $msgid = $message->messageId;
	my $node  = $self->msgById($msgid);

	# Already known, but might reside in many folders.
	if($node) { $node->addMessage($message) }
	else
	{	$node = Mail::Box::Thread::Node->new(message => $message, msgid => $msgid, dummy_type => $self->{MBTM_dummy_type});
		$self->msgById($msgid, $node);
	}

	$self->{MBTM_delayed}{$msgid} = $node; # removes doubles.
}

# The relation between nodes is delayed, to avoid that first
# dummy nodes have to be made, and then immediately upgrades
# to real nodes.  So: at first we inventory what we have, and
# then build thread-lists.

sub _processDelayedNodes()
{	my $self    = shift;
	$self->{MBTM_delayed} or return $self;

	foreach my $node (values %{$self->{MBTM_delayed}})
	{	$self->_processDelayedMessage($node, $_) for $node->message;
	}

	delete $self->{MBTM_delayed};
	$self;
}

sub _processDelayedMessage($$)
{	my ($self, $node, $message) = @_;
	my $msgid = $message->messageId;

	# will force parsing of head when not done yet.
	my $head  = $message->head or return $self;

	my $replies;
	if(my $irt  = $head->get('in-reply-to'))
	{	for($irt =~ m/\<(\S+\@\S+)\>/)
		{	my $msgid = $1;
			$replies  = $self->msgById($msgid) || $self->createDummy($msgid);
		}
	}

	my @refs;
	if(my $refs = $head->get('references'))
	{	while($refs =~ s/\<(\S+\@\S+)\>//s)
		{	my $msgid = $1;
			push @refs, $self->msgById($msgid) || $self->createDummy($msgid);
		}
	}

	# Handle the `In-Reply-To' message header.
	# This is the most secure relationship.

	if($replies)
	{	$node->follows($replies, 'REPLY')
			and $replies->followedBy($node);
	}

	# Handle the `References' message header.
	# The (ordered) list of message-IDs give an impression where this
	# message resides in the thread.  There is a little less certainty
	# that the list is correctly ordered and correctly maintained.

	if(@refs)
	{	push @refs, $node unless $refs[-1] eq $node;
		my $from = shift @refs;

		while(my $to = shift @refs)
		{	$to->follows($from, 'REFERENCE')
				and $from->followedBy($to);
			$from = $to;
		}
	}

	$self;
}


sub outThread($)
{	my ($self, $message) = @_;
	my $msgid = $message->messageId;
	my $node  = $self->msgById($msgid) or return $message;

	$node->{MBTM_messages} = [ grep $_ ne $message, @{$node->{MBTM_messages}} ];
	$self;
}


sub createDummy($)
{	my ($self, $msgid) = @_;
	$self->byId->{$msgid} = $self->{MBTM_thread_type}->new(msgid => $msgid, dummy_type => $self->{MBTM_dummy_type});
}

#--------------------

1;
