package IPC::Shm::Make;
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

IPC::Shm::Make

=head1 SYNOPSIS

This module is part of the IPC::Shm::Tied::* implementations. You should
definitely not be using it directly.

=head1 FUNCTIONS

=head2 makeshm( $scalar_variable_reference );

If the referenced variable contains a plain scalar, nothing is done.

If the referenced variable itself contains a reference, the target of that
inner reference is tied into shared memory with its contents preserved.

The inner reference is then replaced with a stand-in containing an
identifier, which can be used to recover the original (now tied) target.

=head2 getback( $standin );

Given the standin left by makeshm, returns a reference to the original
(now tied into shared memory) data. It's up to the calling program to
know whether it expects a scalar, array, or hash reference.

=head2 getback_discard( $standin );

The same as C<getback> but also decrements the reference counter.

=cut

###############################################################################
# library dependencies

use base 'Exporter';
our @EXPORT = qw( makeshm getback );

use Data::Dumper;

###############################################################################
# lower level migration handlers

sub _makeshm_scalar {
	my ( $ref ) = @_;

	my $tmp = $$ref;
	my $obj = tie $$ref, 'IPC::Shm::Tied';

	$obj->writelock;
	$$ref = $tmp;
	$obj->incref;
	$obj->unlock;

#	$obj->reftype( 'SCALAR' );
	$obj->tiedref( $ref );

	return $obj->standin;
}

sub _makeshm_array {
	my ( $ref ) = @_;

	my @tmp = @$ref;
	my $obj = tie @$ref, 'IPC::Shm::Tied';

	$obj->writelock;
	@$ref = @tmp;
	$obj->incref;
	$obj->unlock;

#	$obj->reftype( 'ARRAY' );
	$obj->tiedref( $ref );

	return $obj->standin;
}

sub _makeshm_hash {
	my ( $ref ) = @_;

	my %tmp = %$ref;
	my $obj = tie %$ref, 'IPC::Shm::Tied';

	$obj->writelock;
	%$ref = %tmp;
	$obj->incref;
	$obj->unlock;

#	$obj->reftype( 'HASH' );
	$obj->tiedref( $ref );

	return $obj->standin;
}


###############################################################################
# migrate a variable into anonymous shared memory

sub makeshm {
	my ( $valueref ) = @_;

	my $reftype = ref( $$valueref );

	# pass plain scalars as-is
	return unless $reftype;

	# save a few dereferences
	my $refdata = $$valueref;

	if    ( $reftype eq 'SCALAR' ) {
		if ( my $obj = tied $$refdata ) {
			confess "Cannot store tied scalars in shared memory"
 				unless $obj->isa( 'IPC::Shm::Tied' );
			$obj->incref;
			$$valueref = $obj->standin;
		} else {
			$$valueref = _makeshm_scalar( $refdata );
		}
	}

	elsif ( $reftype eq 'ARRAY' ) {
		if ( my $obj = tied @$refdata ) {
			confess "Cannot store tied arrays in shared memory"
 				unless $obj->isa( 'IPC::Shm::Tied' );
			$obj->incref;
			$$valueref = $obj->standin;
		} else {
			$$valueref = _makeshm_array( $refdata );
		}
	}

	elsif ( $reftype eq 'HASH' ) {
		if ( my $obj = tied %$refdata ) {
			confess "Cannot store tied hashes in shared memory"
 				unless $obj->isa( 'IPC::Shm::Tied' );
			$obj->incref;
			$$valueref = $obj->standin;
		} else {
			$$valueref = _makeshm_hash( $refdata );
		}
	}

	else {
		confess "Incompatible reference type $reftype";
	}

}


###############################################################################
# get back the (now shared) referenced datum

sub getback {
	my ( $standin ) = @_;

	return IPC::Shm::Tied->standin_tiedref( $standin );
}

sub getback_discard {
	my ( $standin ) = @_;

	my $this = IPC::Shm::Tied->standin_discard( $standin );

	return $this->tiedref;
}


###############################################################################
###############################################################################

=head1 AUTHOR

Kevin Cody-Little <kcody@cpan.org>

=cut

1;
