# This code is part of Perl distribution Mail-Box version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Collection;{
our $VERSION = '4.00';
}

use parent qw/User::Identity::Collection Mail::Reporter/;

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw// ];

use Mail::Box::Identity;

use Scalar::Util    qw/weaken/;

#--------------------

sub new(@)
{	my $class = shift;
	unshift  @_,'name' if @_ % 2;
	$class->Mail::Reporter::new(@_);
}

sub init($)
{	my ($self, $args) = @_;
	$args->{item_type} //= 'Mail::Box::Identity';

	$self->Mail::Reporter::init($args);
	$self->User::Identity::Collection::init($args);

	weaken($self->{MBC_manager})
		if $self->{MBC_manager} = delete $args->{manager};

	$self->{MBC_ftype} = delete $args->{folder_type};
	$self;
}

#--------------------

sub type() { 'folders' }


sub manager()
{	my $self = shift;
	return $self->{MBC_manager}
		if defined $self->{MBC_manager};

	my $parent = $self->parent;
	defined $parent ? $self->parent->manager : undef;
}


sub folderType()
{	my $self = shift;
	return ($self->{MBC_ftype} = shift) if @_;
	return $self->{MBC_ftype} if exists $self->{MBC_ftype};

	if(my $parent = $self->parent)
	{	return $self->{MBC_ftype} = $parent->folderType;
	}

	undef;
}

1;
