package IPC::Shm::Segment;
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

IPC::Shm::Segment

=head1 SYNOPSIS

This class is part of the IPC::Shm implementation. You should probably
not be using it directly. 

=head1 CONSTRUCTORS

=head2 $class->named( $varname )

Attach to a named variable's segment, creating if necessary. The contents
of the varname string are just how the variable is typed in perl code.

=head2 $class->anonymous

Create a new anonymous segment.

=head2 $class->anonymous( $cookie )

Attach to an existing anonymous segment using a cookie value.
Those cookies might be retrieved with the varanon method,
or might be stored in a standin. See below.

=head1 ATTRIBUTES

=head2 $this->varname

Returns the variable's name, if any.

=head2 $this->varname( $varname );

Sets the variable's name.

=head2 $this->varanon

Returns the anonymous variable identifier cookie, if any.

=head2 $this->varanon( $cookie )

Sets the anonymous variable identifier cookie.

=head2 $this->vartype

Returns 'HASH', 'ARRAY', or 'SCALAR'.

=head2 $this->vartype( $vartype )

Stores the variable type. Only meaningful for anonymous segments.

=head2 $this->varid

Retrieves a human-redable string identifying the variable.

=head1 OVERRIDDES

=head2 $this->remove

Overridden from IPC::Shm::Simple to remove table entries for named variables.

=head2 $this->DETACH

Called by IPC::Shm::Simple when the last in-process instance
is being DESTROYed.

=head1 STAND-IN REFERENCES

=head2 $this->standin

This is a shared memory analogue of a reference. It is stored in the
shared memory variable that holds the reference.

Returns a reference to an anonymous hash containing suitable identifiers.

=head2 $class->standin_type( $standin )

Returns the variable type that the standin points to.

=head2 $class->standin_shmid( $standin )

Returns the shmid where the standin points to.

=head2 $class->standin_restand( $standin )

Returns the original object that generated the standin, or
an exactly equal copy of that object.

=head2 $class->standin_discard( $standin )

Indicates that the standin reference is going away.

Returns the original object as C<standin_restand>.

=cut

###############################################################################
# library dependencies

use base 'IPC::Shm::Simple';

use Digest::SHA1 qw( sha1_hex );


###############################################################################
# package variables

my $IPCKEY = 0xdeadbeef;

our %Attrib = (
	varname => undef,
	varanon => undef
);


###############################################################################
###############################################################################

###############################################################################
# get the segment for a variable (by symbol), creating if needed

sub named {
	my ( $class, $sym ) = @_;
	my ( $rv );

	unless ( $sym ) {
		carp __PACKAGE__ . ' cannot cope with a null symbol name';
		return;
	}

	if ( $sym eq '%IPC::Shm::NAMEVARS' ) {
		unless ( $rv = $class->bind( $IPCKEY ) ) {
			carp "shmbind failed: $!";
			return;
		}
	}

	elsif ( my $shmid = $IPC::Shm::NAMEVARS{$sym} ) {
		unless ( $rv = $class->shmat( $shmid ) ) {
			carp "shmattach failed: $!";
			return;
		}
	}

	else {
		unless ( $rv = $class->create ) {
			carp "shmcreate failed: $!";
			return;
		}
		$rv->incref;
		$rv->unlock;
		$IPC::Shm::NAMEVARS{$sym} = $rv->shmid;
	}

	$rv->varname( $sym );

	return $rv;
}


###############################################################################
# attach to an anonymous segment by cookie, or create a new one

sub anonymous {
	my ( $class, $aname ) = @_;
	my ( $rv, $shmid );

	if ( defined $aname ) {

		unless ( $shmid = $IPC::Shm::ANONVARS{$aname} ) {
			carp "no such anonymous segment $aname";
			return;
		}

		unless ( $rv = $class->shmat( $shmid ) ) {
			carp "failed to attach to shmid $shmid: $!";
			return;
		}

	}

	else {
		unless ( $rv = $class->create ) {
			carp "shmcreate failed: $!";
			return;
		}

		$rv->unlock;
		$aname = sha1_hex( rand( 10000 ) . ' ' . $$ );
		$IPC::Shm::ANONVARS{$aname} = $rv->shmid;

	}

	$rv->varanon( $aname );

	return $rv;
}


###############################################################################
###############################################################################

###############################################################################
# produce a human-readable identifier for the variable

sub varid {
	my ( $this ) = @_;

	if ( my $vname = $this->varname ) {
		return 'NAME=' . $vname;
	}

	if ( my $vanon = $this->varanon ) {
		return 'ANON=' . $vanon;
	}

	return "UNKNOWN!";
}

###############################################################################
# determine the variable type based on its name or cookie

sub vartype {
	my ( $this ) = @_;

	if ( my $vanon = $this->varanon ) {
		return $IPC::Shm::ANONTYPE{$vanon} || 'INVALID';
	}

	my $vname = $this->varname;

	return 'HASH' if $vname =~ /^%/;
	return 'ARRAY' if $vname =~ /^@/;
	return 'SCALAR' if $vname =~ /^\$/;

	return 'INVALID';
}


###############################################################################
# deliberate removal override

sub remove {
	my ( $this ) = @_;

	if ( my $vname = $this->varname ) {
		delete $IPC::Shm::NAMEVARS{$vname};
		$this->decref;
		$this->CLEAR;
	}

	return $this->SUPER::remove();
}


###############################################################################
# disconnect-time cleanups

sub DETACH {
	my ( $this ) = @_;

	unless ( $this->nrefs or $this->varname ) {

		my $vanon = $this->varanon;

		$this->writelock;

		if ( $this->nconns == 1 ) {

			$this->CLEAR;
			$this->SUPER::remove;

			delete $IPC::Shm::ANONVARS{$vanon};
			delete $IPC::Shm::ANONTYPE{$vanon};

		}

	}

	$this->SUPER::DETACH();

}


###############################################################################
###############################################################################

###############################################################################
# generate a stand-in hashref containing one identifier or another

sub standin {
	my ( $this ) = @_;

	if    ( my $vname = $this->varname ) {
		return { varname => $vname };
	}

	elsif ( my $vanon = $this->varanon ) {
		return { varanon => $vanon };
	}

	else {
		carp __PACKAGE__ . ' object has no identifier';
		return;
	}

}


###############################################################################
# determine the standin variable type based on its name or cookie

sub standin_type {
	my ( $callclass, $standin ) = @_;

	if ( my $vanon = $standin->{varanon} ) {
		return $IPC::Shm::ANONTYPE{$vanon} || 'INVALID';
	}

	my $vname = $standin->{varname};

	return 'HASH' if $vname =~ /^%/;
	return 'ARRAY' if $vname =~ /^@/;
	return 'SCALAR' if $vname =~ /^\$/;

	return 'INVALID';
}


###############################################################################
# get back the shared memory id given a standin from above

sub standin_shmid {
	my ( $callclass, $standin ) = @_;

	if ( my $vname = $standin->{varname} ) {
		return $IPC::Shm::NAMEVARS{$vname};
	}

	if ( my $vanon = $standin->{varanon} ) {
		return $IPC::Shm::ANONVARS{$vanon};
	}

	return 0;
}


###############################################################################
# get back the object given a standin from above

sub standin_restand {
	my ( $callclass, $standin ) = @_;

	my $shmid = $callclass->standin_shmid( $standin );

	unless ( $shmid ) {
		carp "could not get shmid for standin";
		return;
	}

	my $class = 'IPC::Shm::Tied::' . $callclass->standin_type( $standin );

	my $rv = $class->shmat( $shmid );

	unless ( $rv ) {
		carp "restand_obj shmat failed: $!\n";
		return;
	}

	$rv->varname( $standin->{varname} ) if $standin->{varname};
	$rv->varanon( $standin->{varanon} ) if $standin->{varanon};

	return $rv;
}


###############################################################################
# indicate a standin is being thrown away, and return the object

sub standin_discard {
	my ( $callclass, $standin ) = @_;

	my $rv = $callclass->standin_restand( $standin )
		or return;

	$rv->decref;

	return $rv;
}


###############################################################################
###############################################################################

=head1 AUTHOR

Kevin Cody-Little <kcody@cpan.org>

=cut

1;
