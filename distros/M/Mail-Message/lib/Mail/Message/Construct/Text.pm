# This code is part of Perl distribution Mail-Message version 4.02.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message;{
our $VERSION = '4.02';
}


use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw// ];

use IO::Lines  ();

#--------------------

sub string()
{	my $self = shift;
	$self->head->string . $self->body->string;
}


sub lines()
{	my $self = shift;
	my @lines;
	my $file = IO::Lines->new(\@lines);
	$self->print($file);
	wantarray ? @lines : \@lines;
}


sub file()
{	my $self = shift;
	my $file = IO::Lines->new;
	$self->print($file);
	$file->seek(0,0);
	$file;
}


sub printStructure(;$$)
{	my $self    = shift;

	my $indent
	  = @_==2                       ? pop
	  : defined $_[0] && !ref $_[0] ? shift
	  :   '';

	my $fh      = @_ ? shift : select;

	my $buffer;   # only filled if filehandle==undef
	open $fh, '>:raw', \$buffer unless defined $fh;

	my $subject = $self->get('Subject') || '';
	$subject    = ": $subject" if length $subject;

	my $type    = $self->get('Content-Type', 0) || '';
	my $size    = $self->size;
	my $deleted = $self->label('deleted') ? ', deleted' : '';

	my $text    = "$indent$type$subject ($size bytes$deleted)\n";
	$fh->print($text);

	my $body    = $self->body;
	my @parts
	  = $body->isNested    ? ($body->nested)
	  : $body->isMultipart ? $body->parts
	  :    ();

	$_->printStructure($fh, $indent.'   ')
		for @parts;

	$buffer;
}

#--------------------

1;
