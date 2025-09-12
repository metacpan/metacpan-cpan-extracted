# This code is part of Perl distribution Log-Report version 1.41.
# The POD got stripped from this file by OODoc version 3.04.
# For contributors see file ChangeLog.

# This software is copyright (c) 2007-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Dancer2::Plugin::LogReport::Message;{
our $VERSION = '1.41';
}

use parent 'Log::Report::Message';

use strict;
use warnings;

#--------------------

sub reason
{	my $self = shift;
	$self->{reason} = $_[0] if exists $_[0];
	$self->{reason};
}

my %reason2color = (
	TRACE   => 'info',
	ASSERT  => 'info',
	INFO    => 'info',
	NOTICE  => 'info',
	WARNING => 'warning',
	MISTAKE => 'warning',
);


sub bootstrap_color
{	my $self = shift;
	return 'success' if $self->inClass('success');
	$reason2color{$self->reason} || 'danger';
}

1;
