# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Thread::Node;{
our $VERSION = '3.012';
}

use parent 'Mail::Reporter';

use strict;
use warnings;

use Carp;
use List::Util  qw/first/;

#--------------------

sub new(@)
{	my ($class, %args) = @_;
	(bless {}, $class)->init(\%args);
}

sub init($)
{	my ($self, $args) = @_;

	if(my $message = $args->{message})
	{	push @{$self->{MBTN_messages}}, $message;
		$self->{MBTN_msgid} = $args->{msgid} || $message->messageId;
	}
	elsif(my $msgid = $args->{msgid})
	{	$self->{MBTN_msgid} = $msgid;
	}
	else
	{	croak "Need to specify message or message-id";
	}

	$self->{MBTN_dummy_type} = $args->{dummy_type};
	$self;
}

#--------------------

sub isDummy()
{	my $self = shift;
	my $msgs = $self->{MBTN_messages};
	! defined $msgs || ! @$msgs || $msgs->[0]->isDummy;
}


sub messageId() { $_[0]->{MBTN_msgid} }

#--------------------

sub message()
{	my $self = shift;
	my $messages = $self->{MBTN_messages} ||= [];

	unless(@$messages)
	{	return () if wantarray;

		my $dummy = $self->{MBTN_dummy_type}->new(messageId => $self->{MBTN_msgid});
		push @$messages, $dummy;
		return $dummy;
	}

	return @$messages if wantarray;
	(first { ! $_->isDeleted } @$messages) // $messages->[0];
}


sub addMessage($)
{	my ($self, $message) = @_;

	return $self->{MBTN_messages} = [ $message ]
		if $self->isDummy;

	push @{$self->{MBTN_messages}}, $message;
	$message;
}


sub expand(;$)
{	my $self = shift;
	@_ or return $self->message->label('folded') || 0;

	my $fold = not shift;
	$_->label(folded => $fold) for $self->message;
	$fold;
}

# compatibility <2.0
sub folded(;$) { my $s = shift; @_ ? $s->expand(not $_[0]) : $s->expand }

#--------------------

sub repliedTo()
{	my $self = shift;
	wantarray ? ($self->{MBTN_parent}, $self->{MBTN_quality}) : $self->{MBTN_parent};
}


sub follows($$)
{	my ($self, $thread, $how) = @_;
	my $quality = $self->{MBTN_quality};

	# Do not create cyclic constructs caused by erroneous refs.

	my $msgid = $self->messageId;       # Look up for myself, upwards in thread
	for(my $walker = $thread; defined $walker; $walker = $walker->repliedTo)
	{	return undef if $walker->messageId eq $msgid;
	}

	my $threadid = $thread->messageId;  # a->b and b->a  (ref order reversed)
	foreach ($self->followUps)
	{	return undef if $_->messageId eq $threadid;
	}

	# Register

	if($how eq 'REPLY' || !defined $quality)
	{	$self->{MBTN_parent}  = $thread;
		$self->{MBTN_quality} = $how;
		return $self;
	}

	return $self if $quality eq 'REPLY';

	if($how eq 'REFERENCE' || ($how eq 'GUESS' && $quality ne 'REFERENCE'))
	{	$self->{MBTN_parent}  = $thread;
		$self->{MBTN_quality} = $how;
	}

	$self;
}


sub followedBy(@)
{	my $self = shift;
	$self->{MBTN_followUps}{$_->messageId} = $_ foreach @_;
	$self;
}


sub followUps()
{	my $self    = shift;
	$self->{MBTN_followUps} ? values %{$self->{MBTN_followUps}} : ();
}


sub sortedFollowUps()
{	my $self    = shift;
	my $prepare = shift || sub { $_[0]->startTimeEstimate || 0 };
	my $compare = shift || sub { $_[0] <=> $_[1]};

	my %value   = map +($prepare->($_) => $_), $self->followUps;
	map $value{$_}, sort { $compare->($a, $b) } keys %value;
}

#--------------------

sub threadToString(;$$$)   # two undocumented parameters for layout args
{	my $self    = shift;
	my $code    = shift || sub {shift->head->study('subject')};
	my ($first, $other) = (shift || '', shift || '');
	my $message = $self->message;
	my @follows = $self->sortedFollowUps;

	my @out;
	if($self->folded)
	{	my $text = $code->($message) || '';
		chomp $text;
		return "    $first [" . $self->nrMessages . "] $text\n";
	}
	elsif($message->isDummy)
	{	$first .= $first ? '-*-' : ' *-';
		return (shift @follows)->threadToString($code, $first, "$other   " )
			if @follows==1;

		push @out, (shift @follows)->threadToString($code, $first, "$other | " )
			while @follows > 1;
	}
	else
	{	my $text  = $code->($message) || '';
		chomp $text;
		my $size  = $message->shortSize;
		@out = "$size$first $text\n";
		push @out, (shift @follows)->threadToString($code, "$other |-", "$other | " )
			while @follows > 1;
	}

	push @out, (shift @follows)->threadToString($code, "$other `-","$other   " )
		if @follows;

	join '', @out;
}


sub startTimeEstimate()
{	my $self = shift;
	$self->isDummy or return $self->message->timestamp;

	my $earliest;
	foreach ($self->followUps)
	{	my $stamp = $_->startTimeEstimate;
		$earliest = $stamp if !defined $earliest || (defined $stamp && $stamp < $earliest);
	}

	$earliest;
}


sub endTimeEstimate()
{	my $self = shift;

	my $latest;
	$self->recurse( sub {
		my $node = shift;
		return 1 if $node->isDummy;
		my $stamp = $node->message->timestamp;
		$latest   = $stamp if !$latest || $stamp > $latest;
		1;
	});

	$latest;
}


sub recurse($)
{	my ($self, $code) = @_;

	$code->($self) or return $self;

	$_->recurse($code) or last
		for $self->followUps;

	$self;
}


sub totalSize()
{	my $self  = shift;
	my $total = 0;

	$self->recurse(sub {
		my @msgs = shift->messages;
		$total += $msgs[0]->size if @msgs;
		1;
	});

	$total;
}


sub numberOfMessages()
{	my $self  = shift;
	my $total = 0;
	$self->recurse( sub { $_[0]->isDummy or ++$total; 1 } );
	$total;
}

sub nrMessages() { $_[0]->numberOfMessages }  # compatibility


sub threadMessages()
{	my $self = shift;
	my @messages;
	$self->recurse( sub {
		my $node = shift;
		push @messages, $node->message unless $node->isDummy;
		1;
	});

	@messages;
}


sub ids()
{	my $self = shift;
	my @ids;
	$self->recurse( sub { push @ids, $_[0]->messageId } );
	@ids;
}

1;
