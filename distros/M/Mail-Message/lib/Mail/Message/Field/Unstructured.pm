# This code is part of Perl distribution Mail-Message version 4.02.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Field::Unstructured;{
our $VERSION = '4.02';
}

use parent 'Mail::Message::Field::Full';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x warning/ ];

#--------------------

sub init($)
{	my ($self, $args) = @_;

	if($args->{body} && ($args->{encoding} || $args->{charset}))
	{	$args->{body} = $self->encode($args->{body}, %$args);
	}

	$self->SUPER::init($args);

	! defined $args->{attributes} or warning __x"attributes are not supported for unstructured fields.";
	! defined $args->{extra}      or warning __x"no extras for unstructured fields.";
	$self;
}

#--------------------

1;
