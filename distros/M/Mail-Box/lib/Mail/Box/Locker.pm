# This code is part of Perl distribution Mail-Box version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Locker;{
our $VERSION = '4.01';
}

use parent 'Mail::Reporter';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x error panic/ ];

use Scalar::Util     qw/weaken/;
use Devel::GlobalDestruction qw/in_global_destruction/;

#--------------------

my %lockers = (
	DOTLOCK   => __PACKAGE__ .'::DotLock',
	FCNTLLOCK => __PACKAGE__ .'::FcntlLock',
	FLOCK     => __PACKAGE__ .'::Flock',
	MULTI     => __PACKAGE__ .'::Multi',
	MUTT      => __PACKAGE__ .'::Mutt',
	NFS       => __PACKAGE__ .'::NFS',
	NONE      => __PACKAGE__,
	POSIX     => __PACKAGE__ .'::POSIX',
);

sub new(@)
{	my ($class, %args) = @_;
	$class eq __PACKAGE__ or return $class->SUPER::new(%args);

	# Try to figure out which locking method we really want (bootstrap)

	my $method
	  = ! defined $args{method}      ? 'DOTLOCK'
	  : ref $args{method} eq 'ARRAY' ? 'MULTI'
	  :    uc $args{method};

	my $create = $lockers{$method} || $args{$method}
		or error __x"no locking method {name} defined: use {avail}.", name => $method, avail => [ keys %lockers ];

	# compile the locking module (if needed)
	eval "require $create";
	error __x"failed to use locking module {class}:\n{error}", class => $create, error => $@ if $@;

	$args{use} = $args{method} if ref $args{method} eq 'ARRAY';
	$create->SUPER::new(%args);
}

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->{MBL_expires}  = $args->{expires} || 3600;  # one hour
	$self->{MBL_timeout}  = $args->{timeout} || 10;    # ten secs
	$self->{MBL_filename} = $args->{file}    || $args->{folder}->name;
	$self->{MBL_has_lock} = 0;

	$self->folder($args->{folder});
	$self;
}

#--------------------

sub timeout(;$) { my $self = shift; @_ ? $self->{MBL_timeout} = shift : $self->{MBL_timeout} }
sub expires(;$) { my $self = shift; @_ ? $self->{MBL_expires} = shift : $self->{MBL_expires} }


sub name { $_[0]->notImplemented }

sub lockMethod($$$$) { panic "Method removed: use inheritance to implement own method." }


sub folder(;$)
{	my $self = shift;
	@_ && $_[0] or return $self->{MBL_folder};

	$self->{MBL_folder} = shift;
	weaken $self->{MBL_folder};
}


sub filename(;$) { my $self = shift; @_ ? $self->{MBL_filename} = shift : $self->{MBL_filename} }

#--------------------

sub lock($) { $_[0]->{MBL_has_lock} = 1 }


sub isLocked($) {0}


sub hasLock() { $_[0]->{MBL_has_lock} }


# implementation hazard: the unlock must be self-reliant, without
# help by the folder, because it may be called at global destruction
# after the folder has been removed.

sub unlock() { $_[0]->{MBL_has_lock} = 0 }

#--------------------

sub DESTROY()
{	my $self = shift;
	return $self if in_global_destruction;

	$self->unlock if $self->hasLock;
	$self->SUPER::DESTROY;
	$self;
}

1;
