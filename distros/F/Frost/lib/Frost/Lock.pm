package Frost::Lock;

#	LIBS
#
use Moose;

use Frost::Types;
use Frost::Util;

use IO::File;

#	CLASS VARS
#
our $VERSION	= 0.62;
our $AUTHORITY	= 'cpan:ERNESTO';

#	CLASS METHODS
#

#	PUBLIC ATTRIBUTES
#

#	PRIVATE ATTRIBUTES
#
has _lock_rw			=> ( isa => 'Bool',				is	=> 'ro',	init_arg => 'lock_rw',			default => true		);
has _lock_wait			=> ( isa => 'Frost::Natural',			is	=> 'ro',	init_arg => 'lock_wait',		default => 30			);	#	sec > 0
has _lock_sleep		=> ( isa => 'Frost::RealPositive',	is	=> 'ro',	init_arg => 'lock_sleep',		default => 0.2			);	#	sec > 0.0
has _lock_filename	=> ( isa	=> 'Frost::FilePath',			is	=> 'ro', init_arg => 'lock_filename',	default => '.lock'	);

has _lock_fh			=> ( isa => 'IO::File',	is	=> 'rw',	clearer => '_clear_lock_fh', predicate => 'is_locked'	);

#	CONSTRUCTORS
#

#	DESTRUCTORS
#

#	PUBLIC METHODS
#
sub lock
{
	my ( $self )	= @_;

	return true		if $self->is_locked;

	my $how			= $self->_lock_rw ? O_RDWR : O_RDONLY;

	IS_DEBUG and DEBUG "Locking=$how ", ( ( $how == O_RDWR ) ? 'read-write' : 'read-only' );

	my $lock_file	= $self->_lock_filename;
	my $lock_fh		= new IO::File $lock_file, O_CREAT | $how, 0600;

	return false	unless defined $lock_fh;

	$self->_lock_fh ( $lock_fh )		if lock_fh $lock_fh, $how, $self->_lock_wait, $self->_lock_sleep;

	return $self->is_locked;
}

sub unlock
{
	my ( $self )	= @_;

	return true		unless $self->is_locked;

	my $lock_fh		= $self->_lock_fh;

	unlock_fh $lock_fh;

	$lock_fh->close();

	$self->_clear_lock_fh;

	return not $self->is_locked;
}

#	PRIVATE METHODS
#

#	CALLBACKS
#

#	IMMUTABLE
#
no Moose;

__PACKAGE__->meta->make_immutable ( debug => 0 );

1;

__END__


=head1 NAME

Frost::Lock - There can be only one

=head1 ABSTRACT

No documentation yet...

=head1 DESCRIPTION

No user maintainable parts inside ;-)

=for comment CLASS VARS

=for comment CLASS METHODS

=for comment PUBLIC ATTRIBUTES

=head1 PRIVATE ATTRIBUTES

=head2 _lock_rw

=head2 _lock_wait

=head2 _lock_sleep

=head2 _lock_filename

=head2 _lock_fh

=head1 CONSTRUCTORS

=head2 Frost::Lock->new ( %params )

=for comment DESTRUCTORS

=head1 PUBLIC METHODS

=head2 lock

=head2 unlock

=for comment PRIVATE METHODS

=for comment CALLBACKS

=for comment IMMUTABLE

=head1 GETTING HELP

I'm reading the Moose mailing list frequently, so please ask your
questions there.

The mailing list is L<moose@perl.org>. You must be subscribed to send
a message. To subscribe, send an empty message to
L<moose-subscribe@perl.org>

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception.

Please report any bugs to me or the mailing list.

=head1 AUTHOR

Ernesto L<ernesto@dienstleistung-kultur.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Dienstleistung Kultur Ltd. & Co. KG

L<http://dienstleistung-kultur.de/frost/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
