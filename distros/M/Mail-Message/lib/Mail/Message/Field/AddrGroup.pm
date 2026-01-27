# This code is part of Perl distribution Mail-Message version 4.03.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Field::AddrGroup;{
our $VERSION = '4.03';
}

use parent 'User::Identity::Collection::Emails';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x error/ ];

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

	error __x"cannot coerce a {type} into a {class}.", type => ref $addr // 'string', class => $class;
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
