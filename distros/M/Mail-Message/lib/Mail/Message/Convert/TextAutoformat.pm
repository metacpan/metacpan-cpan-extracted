# This code is part of Perl distribution Mail-Message version 4.03.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Convert::TextAutoformat;{
our $VERSION = '4.03';
}

use parent 'Mail::Message::Convert';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw// ];

use Text::Autoformat qw/autoformat/;

use Mail::Message::Body::String ();

#--------------------

sub init($)
{	my ($self, $args)  = @_;
	$self->SUPER::init($args);

	$self->{MMCA_options} = $args->{autoformat} || +{ all => 1 };
	$self;
}

#--------------------

sub autoformatBody($)
{	my ($self, $body) = @_;
	(ref $body)->new(based_on => $body, data => autoformat($body->string, $self->{MMCA_options}));
}

1;
