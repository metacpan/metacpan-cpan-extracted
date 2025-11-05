# This code is part of Perl distribution Log-Report version 1.42.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2007-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package MojoX::Log::Report;{
our $VERSION = '1.42';
}

use Mojo::Base 'Mojo::Log';  # implies use strict etc

use Log::Report 'log-report', import => 'report';

#--------------------

sub new(@) {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# issue with Mojo, where the base-class registers a function --not
	# a method-- to handle the message.
	$self->unsubscribe('message');    # clean all listeners
	$self->on(message => '_message'); # call it OO
	$self;
}

my %level2reason = qw/
	debug  TRACE
	info   INFO
	warn   WARNING
	error  ERROR
	fatal  ALERT
/;

sub _message($$@)
{	my ($self, $level) = (shift, shift);

	report +{is_fatal => 0},    # do not die on errors
		$level2reason{$level}, join('', @_);
}

1;
