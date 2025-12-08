# This code is part of Perl distribution Mail-Message version 3.020.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Convert::HtmlFormatText;{
our $VERSION = '3.020';
}

use base 'Mail::Message::Convert';

use strict;
use warnings;

use HTML::TreeBuilder ();
use HTML::FormatText  ();

use Mail::Message::Body::String ();

#--------------------

sub init($)
{	my ($self, $args)  = @_;
	$self->SUPER::init($args);

	$self->{MMCH_formatter} = HTML::FormatText->new(
		leftmargin  => $args->{leftmargin}  //  3,,
		rightmargin => $args->{rightmargin} // 72,
	);

	$self;
}

#--------------------

sub format($)
{	my ($self, $body) = @_;

	my $dec  = $body->encode(transfer_encoding => 'none');
	my $tree = HTML::TreeBuilder->new_from_file($dec->file);

	(ref $body)->new(
		based_on  => $body,
		mime_type => 'text/plain',
		charset   => 'iso-8859-1',
		data     => [ $self->{MMCH_formatter}->format($tree) ],
	);
}

1;
