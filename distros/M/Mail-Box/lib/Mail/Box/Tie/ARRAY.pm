# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Tie::ARRAY;{
our $VERSION = '3.012';
}

use parent 'Mail::Box::Tie';

use strict;
use warnings;

use Carp;
use Scalar::Util   qw/blessed/;

#--------------------

sub TIEARRAY(@)
{	my ($class, $folder) = @_;
	$class->new($folder, 'ARRAY');
}

#--------------------

#--------------------

sub FETCH($)
{	my ($self, $index) = @_;
	my $msg = $self->folder->message($index);
	$msg->isDeleted ? undef : $msg;
}


sub STORE($$)
{	my ($self, $index, $msg) = @_;
	my $folder = $self->folder;

	$index == $folder->messages
		or croak "Cannot simply replace messages in a folder: use delete old, then push new.";

	$folder->addMessages($msg);
	$msg;
}


sub FETCHSIZE()  { scalar $_[0]->folder->messages }


sub PUSH(@)
{	my $folder = shift->folder;
	$folder->addMessages(@_);
	scalar $folder->messages;
}


sub DELETE($) { $_[0]->folder->message($_[1])->delete }


sub STORESIZE($)
{	my $folder = $_[0]->folder;
	my $length = $_[1];
	$folder->message($_) for $length..$folder->messages;
	$length;
}

# DESTROY is implemented in Mail::Box

#--------------------

1;
