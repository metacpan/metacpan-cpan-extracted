# This code is part of Perl distribution Mail-Box version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Message::Destructed;{
our $VERSION = '4.01';
}

use parent 'Mail::Box::Message';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x error/ ];

#--------------------

sub new(@) { error __x"you cannot instantiate a destructed message." }

sub isDummy()    { 1 }


sub head(;$)
{	my ($self, $head) = @_;
	@_==1 and error __x"you cannot take the head of a destructed message.";
	defined $head and error __x"you cannot set the head on a destructed message.";
	undef;
}


sub body(;$)
{	my ($self, $body) = @_;
	@_==1 and error __x"you cannot take the body of a destructed message.";
	defined $body and error __x"you cannot set the body on a destructed message.";
	undef;
}


sub coerce($)
{	my ($class, $message) = @_;

	$message->isa('Mail::Box::Message')
		or error __x"you cannot coerce a {class} into destruction.", class => ref $message;

	$message->body(undef);
	$message->head(undef);
	$message->modified(0);

	bless $message, $class;
}


sub modified(;$)
{	my $self = shift;

	! @_ || ! $_[0]
		or error __x"you cannot set the modified flag on a destructed message.";

	0;
}

sub isModified() { 0 }


sub label($;@)
{	my $self = shift;

	if(@_==1)
	{	my $label = shift;
		return $self->SUPER::label('deleted') if $label eq 'deleted';

		error __x"destructed message has no labels except 'deleted', requested is {label}.", label => $label;
	}

	my %flags = @_;
	keys %flags==1 && exists $flags{deleted}
		or error __x"destructed message has no labels except 'deleted', trying to set {labels}.", labels => [keys %flags];

	$flags{deleted}
		or error __x"destructed message can not be undeleted.";

	1;
}

sub labels() { wantarray ? ('deleted') : +{deleted => 1} }

1;
