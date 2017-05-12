package IPC::Shm::Tied::HASH;
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
	return {};
}

sub TIEHASH {
	my ( $class, $this ) = @_;

	return bless $this, $class;
}

sub FETCH {
	my ( $this, $key ) = @_;

	my $locked = $this->readlock;
	$this->fetch;
	$this->unlock if $locked;

	my $rv = $this->vcache->{$key};

	return ref( $rv ) ? getback( $rv ) : $rv;	
}

sub STORE {
	my ( $this, $key, $value ) = @_;

	makeshm( \$value );

	my $locked = $this->writelock;

	$this->fetch;
	my $vcache = $this->vcache;
	my $oldval = $vcache->{$key};

	$vcache->{$key} = $value;
	$this->flush;

	$this->unlock if $locked;

	$this->standin_discard( $oldval ) if ( $oldval and ref( $oldval ) );

	return $value;
}

sub DELETE {
	my ( $this, $key ) = @_;

	my $locked = $this->writelock;

	$this->fetch;
	my $vcache = $this->vcache;
	my $oldval = $vcache->{$key};

	delete $vcache->{$key};
	$this->flush;

	$this->unlock if $locked;

	$this->standin_discard( $oldval ) if ( $oldval and ref( $oldval ) );

	return 1;
}

sub CLEAR {
	my ( $this ) = @_;

	my $locked = $this->writelock;

	$this->fetch;
	my $vcache = $this->vcache;

	$this->vcache( $this->EMPTY );
	$this->flush;

	$this->unlock if $locked;

	foreach my $oldval ( values %{$vcache} ) {
		$this->standin_discard( $oldval ) if ( $oldval and ref( $oldval ) );
	}

	return 1;
}

sub EXISTS {
	my ( $this, $key ) = @_;

	my $locked = $this->readlock;
	$this->fetch;
	$this->unlock if $locked;

	return exists $this->vcache->{$key};
}

sub FIRSTKEY {
	my ( $this ) = @_;

	my $locked = $this->readlock;
	$this->fetch;
	$this->unlock if $locked;

	my ( %index, $first, $last );
	foreach my $key ( keys %{$this->vcache} ) {

		unless ( defined $first ) {
			$first = $last = $key;
			next;
		}

		$index{$last} = $key;
		$last = $key;

	}

	return unless defined $first;

	$index{$last} = undef if $last;

	$this->{icache} = \%index;

	return $first;
}

sub NEXTKEY {
	my ( $this, $lastkey ) = @_;

	my $icache = $this->{icache};

	return unless defined $icache->{$lastkey};

	return $icache->{$lastkey};
}

sub SCALAR {
	my ( $this ) = @_;

	my $locked = $this->readlock;
	$this->fetch;
	$this->unlock if $locked;

	return scalar %{$this->vcache};
}



=head1 AUTHOR

Kevin Cody-Little <kcody@cpan.org>

=cut

1;
