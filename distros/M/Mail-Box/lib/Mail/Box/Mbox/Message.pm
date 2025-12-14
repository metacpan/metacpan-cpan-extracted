# This code is part of Perl distribution Mail-Box version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Mbox::Message;{
our $VERSION = '4.01';
}

use parent 'Mail::Box::File::Message';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw// ];

#--------------------

sub head(;$$)
{	my $self  = shift;
	return $self->SUPER::head unless @_;

	my ($head, $labels) = @_;
	$self->SUPER::head($head, $labels);

	$self->statusToLabels if $head && !$head->isDelayed;
	$head;
}

sub label(@)
{	my $self   = shift;
	$self->loadHead;    # be sure the status fields have been read
	$self->SUPER::label(@_);
}

sub labels(@)
{	my $self   = shift;
	$self->loadHead;    # be sure the status fields have been read
	$self->SUPER::labels(@_);
}

1;
