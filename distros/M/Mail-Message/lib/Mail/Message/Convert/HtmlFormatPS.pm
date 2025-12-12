# This code is part of Perl distribution Mail-Message version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Convert::HtmlFormatPS;{
our $VERSION = '4.00';
}

use parent 'Mail::Message::Convert';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw// ];

use Mail::Message::Body::String ();

use HTML::TreeBuilder ();
use HTML::FormatPS    ();

#--------------------

sub init($)
{	my ($self, $args)  = @_;
	my @formopts = map +($_ => delete $args->{$_}), grep m/^[A-Z]/, keys %$args;
	$self->SUPER::init($args);

	$self->{MMCH_formatter} = HTML::FormatPS->new(@formopts);
	$self;
}

#--------------------

sub format($)
{	my ($self, $body) = @_;

	my $dec  = $body->encode(transfer_encoding => 'none');
	my $tree = HTML::TreeBuilder->new_from_file($dec->file);

	(ref $body)->new(
		based_on  => $body,
		mime_type => 'application/postscript',
		data      => [ $self->{MMCH_formatter}->format($tree) ],
	);
}

1;
