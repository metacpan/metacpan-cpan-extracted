# This code is part of Perl distribution Mail-Message version 3.020.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Field::Unstructured;{
our $VERSION = '3.020';
}

use base 'Mail::Message::Field::Full';

use strict;
use warnings;

#--------------------

sub init($)
{	my ($self, $args) = @_;

	if($args->{body} && ($args->{encoding} || $args->{charset}))
	{	$args->{body} = $self->encode($args->{body}, %$args);
	}

	$self->SUPER::init($args) or return;

	! defined $args->{attributes}
		or $self->log(WARNING => "Attributes are not supported for unstructured fields");

	! defined $args->{extra}
		or $self->log(WARNING => "No extras for unstructured fields");

	$self;
}

#--------------------

1;
