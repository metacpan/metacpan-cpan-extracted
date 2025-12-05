# This code is part of Perl distribution Log-Report version 1.43.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2007-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Log::Report::Dispatcher::Callback;{
our $VERSION = '1.43';
}

use base 'Log::Report::Dispatcher';

use warnings;
use strict;

use Log::Report 'log-report';

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->{callback} = $args->{callback}
		or error __x"dispatcher {name} needs a 'callback'", name => $self->name;

	$self;
}

#--------------------

sub callback() { $_[0]->{callback} }

#--------------------

sub log($$$$)
{	my $self = shift;
	$self->{callback}->($self, @_);
}

1;
