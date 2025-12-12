# This code is part of Perl distribution HTML-FromMail version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package HTML::FromMail::Object;{
our $VERSION = '4.00';
}

use base 'Mail::Reporter';

use strict;
use warnings;

use Log::Report 'html-frommail';

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->{HFO_topic}    = $args->{topic} // panic "No topic";
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
