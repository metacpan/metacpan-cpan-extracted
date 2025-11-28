# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Dummy;{
our $VERSION = '3.012';
}

use parent 'Mail::Message';

use strict;
use warnings;

#--------------------

sub init($)
{	my ($self, $args) = @_;

	@$args{ qw/modified trusted/ } = (0, 1);
	$self->SUPER::init($args);

	exists $args->{messageId}
		or $self->log(ERROR => "Message-Id is required for a dummy."), return undef;

	$self;
}

sub isDummy()    { 1 }


sub head()
{	shift->log(ERROR => "You cannot take the head of a dummy message");
	();
}

sub body()
{	shift->log(ERROR => "You cannot take the body of a dummy message");
	();
}

1;
