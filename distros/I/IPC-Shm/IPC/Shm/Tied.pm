package IPC::Shm::Tied;
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

IPC::Shm::Tied

=head1 SYNOPSIS

This class is part of the IPC::Shm implementation.

 use IPC::Shm;
 my $obj = tie my %foo, 'IPC::Shm::Tied';
 $obj->tiedref( \%foo );

You may use this module to tie lexicals as above, but if used on
a package variable, it will behave as a lexical and be destroyed
when all connections are closed.

If the call to $obj->tiedref is omitted, another tied reference
will be created when another shared variable's reference to this
one is dereferenced. This is not desirable behavior.

Optionally takes an IPC::Shm::Segment object as an argument. If
none is supplied, C<IPC::Shm::Segment->anonymous> is called.

It is simpler to use the C<: shm> interface. See C<perldoc IPC::Shm>.

=head1 SUPERCLASS

This class is a derivative of IPC::Shm::Segment, which in turn
is a derivative of IPC::Shm::Simple.

=head1 CONSTRUCTORS

=head2 TIEHASH, TIEARRAY, TIESCALAR

This package supports the tie() call.

=head2 $this->retie

When an anonymous variable is dereferenced, and in some other
circumstances, it has to be tied to a variable so it can be
accessed normally.

=head1 DESTRUCTOR

=head2 $this->DETACH

Called from IPC::Shm::Simple when the last in-process instance
of this same segment is being DESTROYed.

=head1 TIED REFERENCE RETRIEVAL

=head2 $this->tiedref

Retrieves a reference to the object's associated
tied variable. Calls retie() when necessary.

=head2 $this->tiedref( $reference )

Stores a reference to the object's associated tied variable.
This allows retie() to be avoided most of the time.

=head2 $this->tiedref_clean

Removes the object's tied reference from the cache.

=head2 $this->standin_tiedref( $standin )

Returns a reference to the tied variable, given a standin hash.
See IPC::Shm::Segment for more about standins.

=head2 $this->reftype( $reftype )

Stores the type of object the associated reference
points to. This makes the retie() method possible
for anonymous segments.

Valid values are 'HASH', 'ARRAY', and 'SCALAR'.

=head2 $this->reftype

Retrieves the reference type stored above.

=head1 VALUE CACHE METHODS

=head2 $this->vcache

Retrieves the cached copy of the deserializer's last run.

=head2 $this->vcache( $newvalue )

Stores a new cached value, discarding the old. The Storable
module expects this to be a reference (no raw strings).

=head2 $this->vcache_clean

Removes the object's value cache from in-process memory.

=head2 $class->EMPTY

Returns a reference to an empty object, compatible with
the vcache method above. This is an abstract method and
must be implemented by inheriting classes.

=head1 SERIALIZE/DESERIALIZE

=head2 $this->FRESH

Called by IPC::Shm::Simple->fetch when a new value is
actually read in from shared memory. The deserializing
step happens here.

=head2 $this->flush

Serializes and writes the contents of the value cache to shared memory.


=cut

###############################################################################
# dependencies

use base 'IPC::Shm::Segment';

use IPC::Shm::Tied::HASH;
use IPC::Shm::Tied::ARRAY;
use IPC::Shm::Tied::SCALAR;

use Scalar::Util qw( weaken );
use Storable	 qw( freeze thaw );


###############################################################################
# tie constructors

sub TIEHASH {
	shift; # discard class we were called as
	$_[0] ||= IPC::Shm::Segment->anonymous;
	return IPC::Shm::Tied::HASH->TIEHASH( @_ );
}

sub TIEARRAY {
	shift; # discard class we were called as
	$_[0] ||= IPC::Shm::Segment->anonymous;
	return IPC::Shm::Tied::ARRAY->TIEARRAY( @_ );
}

sub TIESCALAR {
	shift; # discard class we were called as
	$_[0] ||= IPC::Shm::Segment->anonymous;
	return IPC::Shm::Tied::SCALAR->TIESCALAR( @_ );
}


###############################################################################
# reconstructor - dynamically create a tied reference

sub retie {
	my ( $this ) = @_;
	my ( $rv );

	my $type = $this->vartype;

	if    ( $type eq 'HASH' ) {
		tie my %tmp, 'IPC::Shm::Tied', $this;
		$this->tiedref( $rv = \%tmp );
	}

	elsif ( $type eq 'ARRAY' ) {
		tie my @tmp, 'IPC::Shm::Tied', $this;
		$this->tiedref( $rv = \@tmp );
	}

	elsif ( $type eq 'SCALAR' ) {
		tie my $tmp, 'IPC::Shm::Tied', $this;
		$this->tiedref( $rv = \$tmp );
	}

	else {
		confess "unknown reference type";
	}

	return $rv;
}


###############################################################################
# destructor - called when the last in-process instance is DESTROYed

sub DETACH {
	my ( $this ) = @_;

	$this->SUPER::DETACH;
	$this->vcache_clean;
	$this->tiedref_clean;

	return;
}


###############################################################################
# store the tied reference so we can get it back from the object later

{ # BEGIN private lexicals
my %TiedRef = ();

sub tiedref {
	my $this = shift;

	my $shmid = $this->{shmid};

	if ( my $newval = shift ) {

		unless ( defined $newval ) {
			delete $TiedRef{$shmid};
			return;
		}

		confess __PACKAGE__ . "->tiedref() expects a reference"
			unless my $reftype = ref( $newval );

		$this->reftype( $reftype );

		$TiedRef{$shmid} = $newval;
		weaken $TiedRef{$shmid};

		return $newval;
	}

	my $tv; # silence perlcritic by declaring before conditional

	# keep a temporary reference to the end of this sub
	$tv = $this->retie unless defined $TiedRef{$shmid};

	return $TiedRef{$shmid};
}

sub tiedref_clean {
	delete $TiedRef{shift->{shmid}};
	return;
}

sub standin_tiedref {
	my ( $callclass, $standin ) = @_;

	my $shmid = $callclass->standin_shmid( $standin );

	return $TiedRef{$shmid} if defined $TiedRef{$shmid};

	my $this = $callclass->standin_restand( $standin );

	return $this->tiedref;
}

} # END private lexicals

sub reftype {
	my $this = shift;

	return $this->{reftype} unless my $newval = shift;

	# avoid unnecessary shared memory access
	if ( $this->{reftype} ) {
		return $newval if $newval eq $this->{reftype};
	}

	# we only care about anonymous segments
	return $this->{reftype} unless my $vanon = $this->varanon;

	my $value = $IPC::Shm::ANONTYPE{$vanon};

	# and we want to avoid unnecessary shared memory writes
	unless ( $value and $value eq $newval ) {
		$IPC::Shm::ANONTYPE{$vanon} =  $newval;
	}

	return $this->{reftype} = $newval;
}


###############################################################################
# value cache, for the unserialized in-memory state

{ # BEGIN private lexicals
my %ValCache = ();

sub vcache {
	my $this = shift;

	my $shmid = $this->{shmid};

	if ( my $newval = shift ) {
		return $ValCache{$shmid} = $newval;
	}

	unless ( defined $ValCache{$shmid} ) {
		$ValCache{$shmid} = $this->EMPTY;
	}

	return $ValCache{$shmid};
}

sub vcache_clean {
	delete $ValCache{shift->{shmid}};
	return;
}

} # END private lexicals


###############################################################################
# abstract empty value representation

sub EMPTY {
	croak "Abstract EMPTY() invocation";
}


###############################################################################
# serialize and deserialize routines

# reads from scache, writes to vcache
# called by IPC::Shm::Simple::fetch
sub FRESH {
	my ( $this ) = @_;

	my $thawed = eval { thaw( ${$this->scache} ) };
	$this->vcache( $thawed ? $thawed : $this->EMPTY );

}

# reads from vcache, calls store
sub flush {
	my ( $this ) = @_;

	$this->store( freeze( $this->vcache ) );
	
}


###############################################################################
###############################################################################

=head1 AUTHOR

Kevin Cody-Little <kcody@cpan.org>

=cut

1;
