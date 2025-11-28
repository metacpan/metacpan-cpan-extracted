# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Message::Destructed;{
our $VERSION = '3.012';
}

use parent 'Mail::Box::Message';

use strict;
use warnings;

use Carp;

#--------------------

sub new(@)
{	my $class = shift;
	$class->log(ERROR => 'You cannot instantiate a destructed message');
	undef;
}

sub isDummy()    { 1 }


sub head(;$)
{	my ($self, $head) = @_;
	return undef if @_ && !defined(shift);

	$self->log(ERROR => "You cannot take the head of a destructed message");
	undef;
}


sub body(;$)
{	my $self = shift;
	return undef if @_ && !defined(shift);

	$self->log(ERROR => "You cannot take the body of a destructed message");
	undef;
}


sub coerce($)
{	my ($class, $message) = @_;

	$message->isa('Mail::Box::Message')
		or $class->log(ERROR=>"Cannot coerce a ",ref($message), " into destruction"), return ();

	$message->body(undef);
	$message->head(undef);
	$message->modified(0);

	bless $message, $class;
}

sub modified(;$)
{	my $self = shift;

	! @_ || ! $_[0]
		or $self->log(ERROR => 'Do not set the modified flag on a destructed message');

	0;
}

sub isModified() { 0 }


sub label($;@)
{	my $self = shift;

	if(@_==1)
	{	my $label = shift;
		return $self->SUPER::label('deleted') if $label eq 'deleted';

		$self->log(ERROR => "Destructed message has no labels except 'deleted', requested is $label");
		return 0;
	}

	my %flags = @_;
	keys %flags==1 && exists $flags{deleted}
		or $self->log(ERROR => "Destructed message has no labels except 'deleted', trying to set @{[ keys %flags ]}"), return 0;

	$flags{deleted}
		or $self->log(ERROR => "Destructed messages can not be undeleted"), return 0;

	1;
}

sub labels() { wantarray ? ('deleted') : +{deleted => 1} }

1;
