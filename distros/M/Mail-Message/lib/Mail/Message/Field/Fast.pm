# This code is part of Perl distribution Mail-Message version 4.02.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Field::Fast;{
our $VERSION = '4.02';
}

use parent 'Mail::Message::Field';

use strict;
use warnings;

use Log::Report     'mail-message', import => [ qw// ];

use Scalar::Util  qw/blessed/;

#--------------------

# The DATA is stored as:   [ NAME, FOLDED-BODY ]
# The body is kept in a folded fashion, where each line starts with
# a single blank.


sub new($;$@)
{	my $class = shift;

	my ($name, $body) = $class->consume(@_==1 ? (shift) : (shift, shift));
	defined $body or return ();

	my $self = bless +[$name, $body], $class;

	# Attributes
	$self->comment(shift)             if @_==1;   # one attribute line
	$self->attribute(shift, shift) while @_ > 1;  # attribute pairs
	$self;
}

sub clone()
{	my $self = shift;
	bless +[ @$self ], ref $self;
}

sub length()
{	my $self = shift;
	length($self->[0]) + 1 + length($self->[1]);
}

sub name() { lc shift->[0] }
sub Name() { $_[0]->[0] }

sub folded()
{	my $self = shift;
	wantarray or return $self->[0] .':'. $self->[1];

	my @lines = $self->foldedBody;
	my $first = $self->[0]. ':'. shift @lines;
	($first, @lines);
}

sub unfoldedBody($;@)
{	my $self = shift;

	$self->[1] = $self->fold($self->[0], @_)
		if @_;

	$self->unfold($self->[1]);
}

sub foldedBody($)
{	my ($self, $body) = @_;
	if(@_==2) { $self->[1] = $body }
	else      { $body = $self->[1] }

	wantarray ? (split m/^/, $body) : $body;
}

# For performance reasons only
sub print(;$)
{	my $self = shift;
	my $fh   = shift || select;
	$fh->print($self->[0].':'.$self->[1]);
	$self;
}

1;
