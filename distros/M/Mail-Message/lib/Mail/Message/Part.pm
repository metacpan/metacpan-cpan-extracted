# This code is part of Perl distribution Mail-Message version 3.020.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Part;{
our $VERSION = '3.020';
}

use base 'Mail::Message';

use strict;
use warnings;

use Scalar::Util    qw/weaken/;
use Carp;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{head} ||= Mail::Message::Head::Complete->new;

	$self->SUPER::init($args);

	exists $args->{container}
		or confess "No container specified for part.\n";

	weaken($self->{MMP_container})
		if $self->{MMP_container} = $args->{container};

	$self;
}


sub coerce($@)
{	my ($class, $thing, $container) = (shift, shift, shift);
	if($thing->isa($class))
	{	$thing->container($container);
		return $thing;
	}

	return $class->buildFromBody($thing, $container, @_)
		if $thing->isa('Mail::Message::Body');

	# Although cloning is a Bad Thing(tm), we must avoid modifying
	# header fields of messages which reside in a folder.
	my $message = $thing->isa('Mail::Box::Message') ? $thing->clone : $thing;

	my $part    = $class->SUPER::coerce($message);
	$part->container($container);
	$part;
}


sub buildFromBody($$;@)
{	my ($class, $body, $container) = (shift, shift, shift);
	my @log  = $body->logSettings;

	my $head = Mail::Message::Head::Complete->new(@log);
	while(@_)
	{	if(ref $_[0]) {$head->add(shift)}
		else          {$head->add(shift, shift)}
	}

	my $part = $class->new(head => $head, container => $container, @log);

	$part->body($body);
	$part;
}

sub container(;$)
{	my $self = shift;
	return $self->{MMP_container} unless @_;

	$self->{MMP_container} = shift;
	weaken($self->{MMP_container});
}

sub toplevel()
{	my $body = shift->container or return;
	my $msg  = $body->message   or return;
	$msg->toplevel;
}

sub isPart() { 1 }

sub partNumber()
{	my $self = shift;
	my $body = $self->container or confess 'no container';
	$body->partNumberOf($self);
}

sub readFromParser($;$)
{	my ($self, $parser, $bodytype) = @_;

	my $head = $self->readHead($parser) //
		Mail::Message::Head::Complete->new(message => $self, field_type => $self->{MM_field_type}, $self->logSettings);

	my $body = $self->readBody($parser, $head, $bodytype) //
		Mail::Message::Body::Lines->new(data => []);

	$self->head($head);
	$self->storeBody($body->contentInfoFrom($head));
	$self;
}

#--------------------

sub printEscapedFrom($)
{	my ($self, $out) = @_;
	$self->head->print($out);
	$self->body->printEscapedFrom($out);
}

#--------------------

sub destruct()
{	my $self = shift;
	$self->log(ERROR =>'You cannot destruct message parts, only whole messages');
	undef;
}

1;
