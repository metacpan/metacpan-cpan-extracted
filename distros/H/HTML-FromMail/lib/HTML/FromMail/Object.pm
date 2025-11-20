# This code is part of Perl distribution HTML-FromMail version 3.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package HTML::FromMail::Object;{
our $VERSION = '3.00';
}

use base 'Mail::Reporter';

use strict;
use warnings;

#--------------------

sub init($)
{	my ($self, $args) = @_;

	$self->SUPER::init($args) or return;

	defined($self->{HFO_topic} = $args->{topic})
		or $self->log(INTERNAL => 'No topic defined for '.ref($self)), exit 1;

	$self->{HFO_settings} = $args->{settings} || {};
	$self;
}

#--------------------

sub topic() { $_[0]->{HFO_topic} }


sub settings(;$)
{	my $self  = shift;
	my $topic = @_ ? shift : $self->topic;
	defined $topic or return {};
	$self->{HFO_settings}{$topic} || {};
}

#--------------------

sub plain2html($)
{	my $self   = shift;
	my $string = join '', @_;
	for($string)
	{	s/\&/\&amp;/g;
		s/\</\&lt;/g;
		s/\>/\&gt;/g;
		s/"/\&quot;/g;
	}
	$string;
}

1;
