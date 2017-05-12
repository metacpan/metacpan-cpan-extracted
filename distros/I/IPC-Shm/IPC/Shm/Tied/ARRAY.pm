package IPC::Shm::Tied::ARRAY;
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

IPC::Shm::Tied::ARRAY

=head1 SYNOPSIS

This class is part of the IPC::Shm implementation. You should not be using it directly.

=cut

# Loaded from IPC::Shm::Tied, so don't reload it
use vars qw( @ISA );
@ISA = qw( IPC::Shm::Tied );

use IPC::Shm::Make;


sub EMPTY {
	return [];
}

sub TIEARRAY {
	my ( $class, $this ) = @_;

	return bless $this, $class;
}

sub FETCH {
	my ( $this, $index ) = @_;

	my $locked = $this->readlock;
	$this->fetch;
	$this->unlock if $locked;

	my $rv = $this->vcache->[$index];

	return ref( $rv ) ? getback( $rv ) : $rv;
}

sub STORE {
	my ( $this, $index, $value ) = @_;

	makeshm( \$value );

	my $locked = $this->writelock;

	$this->fetch;
	my $vcache = $this->vcache;
	my $oldval = $vcache->[$index];

	$vcache->[$index] = $value;
	$this->flush;

	$this->unlock if $locked;

	$this->standin_discard( $oldval ) if ( $oldval and ref( $oldval ) );

	return $value;
}

sub FETCHSIZE {
	my ( $this ) = @_;

	my $locked = $this->readlock;
	$this->fetch;
	$this->unlock if $locked;

	return scalar @{$this->vcache};
}

sub STORESIZE {
	my ( $this, $newcount ) = @_;

	my $oldcount = $this->FETCHSIZE;

	$this->writelock;

	if ( $newcount > $oldcount ) {
		for ( my $i = $oldcount; $i < $newcount; $i++ ) {
			$this->PUSH( undef );
		}
	}

	elsif ( $newcount < $oldcount ) {
		for ( my $i = $oldcount; $i > $newcount; $i-- ) {
			$this->POP;
		}
	}

	$this->unlock;

	return 1;
}

sub EXTEND {
	my ( $this, $count ) = @_;

	$this->STORESIZE( $count );

	return 1;
}

sub EXISTS {
	my ( $this, $index ) = @_;

	my $locked = $this->readlock;
	$this->fetch;
	$this->unlock if $locked;

	return exists $this->vcache->[$index];
}

sub DELETE {
	my ( $this, $index ) = @_;

	$this->STORE( $index, undef );

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

	foreach my $oldval ( @{$vcache} ) {
		$this->standin_discard( $oldval ) if ( $oldval and ref( $oldval ) );
	}

	return 1;
}

sub PUSH {
	my ( $this, @list ) = @_;

	my $locked = $this->writelock;

	$this->fetch;
	my $vcache = $this->vcache;

	foreach my $newval ( @list ) {
		makeshm( \$newval );
		push @{$vcache}, $newval;
	}

	$this->flush;

	$this->unlock if $locked;

	return 1;
}

sub POP {
	my ( $this ) = @_;

	my $locked = $this->writelock;

	$this->fetch;
	my $vcache = $this->vcache;

	unless ( scalar @{$vcache} ) {
		$this->unlock if $locked;
		return;
	}

	my $rv = pop @{$vcache};
	$this->flush;

	$this->unlock if $locked;

	return ref( $rv ) ? getback_discard( $rv ) : $rv;
}

sub SHIFT {
	my ( $this ) = @_;

	my $locked = $this->writelock;

	$this->fetch;
	my $vcache = $this->vcache;

	unless ( scalar @{$vcache} ) {
		$this->unlock if $locked;
		return;
	}

	my $rv = shift @{$vcache};
	$this->flush;

	$this->unlock if $locked;

	return ref( $rv ) ? getback_discard( $rv ) : $rv;
}

sub UNSHIFT {
	my ( $this, @list ) = @_;

	my $locked = $this->writelock;

	$this->fetch;
	my $vcache = $this->vcache;

	foreach my $newval ( @list ) {
		makeshm( \$newval );
		unshift @{$vcache}, $newval;
	}

	$this->flush;

	$this->unlock if $locked;

	return 1;
}

sub SPLICE {
	my ( $this, $offset, $length, @list ) = @_;

	my $locked = $this->writelock;

	$this->fetch;
	my $vcache = $this->vcache;

	my @newval = ();
	foreach my $newval ( @list ) {
		makeshm( \$newval );
		push @newval, $newval;
	}

	my @oldval = splice( @{$vcache}, $offset, $length, @newval );

	$this->flush;
	$this->unlock if $locked;

	my @retval = ();
	foreach my $oldval ( @oldval ) {
		push @retval, ref( $oldval )
			    ? getback_discard( $oldval )
			    : $oldval;
	}

	return wantarray ? @retval : pop( @retval );
}



=head1 AUTHOR

Kevin Cody-Little <kcody@cpan.org>

=cut

1;
