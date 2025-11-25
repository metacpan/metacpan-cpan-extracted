# This code is part of Perl distribution Mail-Message version 3.019.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Field::Address;{
our $VERSION = '3.019';
}

use base 'Mail::Identity';

use strict;
use warnings;

use Mail::Message::Field::Addresses ();
use Mail::Message::Field::Full      ();

use Scalar::Util  qw/blessed/;

my $format = 'Mail::Message::Field::Full';

#--------------------

use overload
	'""' => 'string',
	bool => sub {1},
	cmp  => sub { lc($_[0]->address) cmp lc($_[1]) };

#--------------------

sub coerce($@)
{	my ($class, $addr, %args) = @_;
	return () unless defined $addr;

	blessed $addr or return $class->parse($addr);
	$addr->isa($class) and return $addr;

	my $from = $class->from($addr, %args);

	Mail::Reporter->log(ERROR => "Cannot coerce a ".ref($addr)." into a $class"),
	return () unless defined $from;

	bless $from, $class;
}

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);
	$self->{MMFA_encoding} = delete $args->{encoding};
	$self;
}


sub parse($)
{	my $self   = shift;
	my $parsed = Mail::Message::Field::Addresses->new(To => shift);
	defined $parsed ? ($parsed->addresses)[0] : ();
}

#--------------------

sub encoding() { $_[0]->{MMFA_encoding} }

#--------------------

sub string()
{	my $self  = shift;
	my @opts  = (charset => $self->charset, encoding => $self->encoding);
		# language => $self->language

	my @parts;
	my $phrase  = $self->phrase;
	push @parts, $format->createPhrase($phrase, @opts) if defined $phrase;

	my $address = $self->address;
	push @parts, @parts ? '<'.$address.'>' : $address;

	my $comment = $self->comment;
	push @parts, $format->createComment($comment, @opts) if defined $comment;

	join ' ', @parts;
}

1;
