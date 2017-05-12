package IPC::Shm::Tied::SCALAR;
use warnings;
use strict;
use Carp;

#
# Copyright (c) 2014 by Kevin Cody-Little <kcody@cpan.org>
#
# This code may be modified or redistributed under the terms
# of either the Artistic or GNU General Public licenses, at
# the modifier or redistributor's discretion.
#

=head1 NAME

IPC::Shm::Tied::HASH

=head1 SYNOPSIS

This class is part of the IPC::Shm implementation. You should not be using it directly.

=cut

# Loaded from IPC::Shm::Tied, so don't reload it
use vars qw( @ISA );
@ISA = qw( IPC::Shm::Tied );

use IPC::Shm::Make;


sub EMPTY {
	return \undef;
}

sub TIESCALAR {
	my ( $class, $this ) = @_;

	return bless $this, $class;
}

sub FETCH {
	my ( $this ) = @_;

	my $locked = $this->readlock;

	$this->fetch;

	$this->unlock if $locked;

	my $rv = ${$this->vcache};

	return ref( $rv ) ? getback( $rv ) : $rv;
}

sub STORE {
	my ( $this, $value ) = @_;

	makeshm( \$value );

	my $locked = $this->writelock;

	$this->fetch;
	my $oldval = ${$this->vcache};

	$this->vcache( \$value );
	$this->flush;

	$this->unlock if $locked;

	$this->standin_discard( $oldval ) if ( $oldval and ref( $oldval ) );

	return $value;
}

sub CLEAR {
	my ( $this ) = @_;

	my $locked = $this->writelock;

	$this->fetch;
	my $oldval = ${$this->vcache};

	$this->vcache( $this->EMPTY );
	$this->flush;

	$this->unlock if $locked;

	$this->standin_discard( $oldval ) if ( $oldval and ref( $oldval ) );

	return 1;
}



=head1 AUTHOR

Kevin Cody-Little <kcody@cpan.org>

=cut

1;
