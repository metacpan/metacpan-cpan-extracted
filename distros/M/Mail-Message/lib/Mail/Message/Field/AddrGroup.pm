# This code is part of Perl distribution Mail-Message version 3.019.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Field::AddrGroup;{
our $VERSION = '3.019';
}

use base 'User::Identity::Collection::Emails';

use strict;
use warnings;

use Scalar::Util  qw/blessed/;

#--------------------

use overload '""' => 'string';

#--------------------

sub string()
{	my $self = shift;
	my $name = $self->name;
	my @addr = sort map $_->string, $self->addresses;

	local $" = ', ';
	length $name ? "$name: @addr;" : @addr ? "@addr" : '';
}

#--------------------

sub coerce($@)
{	my ($class, $addr, %args) = @_;
	defined $addr or return ();

	if(blessed $addr)
	{	return $addr if $addr->isa($class);

		return bless $addr, $class
			if $addr->isa('User::Identity::Collection::Emails');
	}

	$class->log(ERROR => "Cannot coerce a ".(ref($addr)|'string').  " into a $class");
	();
}


#--------------------

sub addAddress(@)
{	my $self = shift;

	my $addr
	  = @_ > 1 ? Mail::Message::Field::Address->new(@_)
	  : !$_[0] ? return ()
	  :   Mail::Message::Field::Address->coerce(shift);

	$self->addRole($addr);
	$addr;
}


# roles are stored in a hash, so produce
sub addresses() { $_[0]->roles }

#--------------------

1;
