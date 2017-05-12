package IPC::Shm::Simple;
use warnings;
use strict;
use Carp;

#
# Copyright (C) 2005,2014 by Kevin Cody-Little <kcody@cpan.org>
#
# Although this package as a whole is derived from
# IPC::ShareLite, this particular file is a new work.
# 
# This code may be modified or redistributed under the terms
# of either the Artistic or GNU General Public licenses, at
# the modifier or redistributor's discretion.
#

=head1 NAME

IPC::Shm::Simple - Simple data in SysV shared memory segments.

=head1 SYNOPSIS

Provides the ability to create a shared segment with or without first
knowing what ipckey it will use. Caches shared memory reads in process
memory, and defeatably verifies writes by reading the value back
and comparing it stringwise.

Can only store string or numeric data.

=head1 OBJECT CACHING

This module caches the underlying C object, such that the process only
has one attachment to the shared segment. However, the Perl objects are
not cached, to facilitate timely destruction. There can be many distinct
blessed references to the same shared segment. This is made transparent
by storing all state information in package lexicals, not upon the object.

=cut


use Fcntl qw( :flock );
use IPC::SysV qw( IPC_PRIVATE );

use Class::Attrib;
use DynaLoader;
use UNIVERSAL;

use vars qw( $VERSION @ISA %Attrib );

$VERSION = '1.10';
@ISA     = qw( Class::Attrib DynaLoader );
%Attrib  = (
	Mode		=> oct( 660 ),
	Size		=> 4096,
	dwell		=> 0,
	verify		=> 1
);


###
### Constructors
###

=head1 CONSTRUCTORS

=head2 $this->bind( ipckey, [size], [mode] );

Attach to the shared memory segment identified by ipckey, whether it
exists already or not.

If a segment must be created, size and permissions may be specified as
for the C<< $this->create() >> call. Otherwise, the class defaults will apply.

Returns blessed reference on success, undef on failure.

Throws an exception on invalid parameters.

The segment will be unlocked even if it was just created.

=cut

sub bind {
	my ( $this, $ipckey, $size, $mode ) = @_;
	my ( $self );

	unless ( $self = $this->attach( $ipckey ) ) {

		$self = $this->create( $ipckey, $size, $mode )
			or return;

		$self->unlock;

	}

	return $self;
}

{ # BEGIN lexical scope
my %ShmIndex = ();		# cache key=ipckey value=shmid
my %ShmShare = ();		# cache key=shmid  value=sharelite
my %ShmCount = ();		# cache key=shmid  value=integer

=head2 $this->attach( ipckey );

Attach to the shared memory segment identified by ipckey if it exists.

Returns blessed reference on success, undef on failure.

Throws an exception on invalid parameters.

=cut

sub attach {
	my ( $this, $ipckey ) = @_;

	confess( __PACKAGE__ . "->attach: Called without ipckey." )
		unless defined $ipckey;

	confess( __PACKAGE__ . "->attach: Called with empty ipckey." )
		unless $ipckey;

	confess( __PACKAGE__ . "->attach: Called with string ipckey." )
		unless $ipckey > 0;

	confess( __PACKAGE__ . "->attach: Called with IPC_PRIVATE." )
		if $ipckey == IPC_PRIVATE;

	my $class = ref( $this ) || $this;

	if ( my $shmid = $ShmIndex{$ipckey} ) {
		my $share = $ShmShare{$shmid};
		unless ( $share ) {
			carp __PACKAGE__ . "->attach: dangling ShmIndex";
			delete $ShmIndex{$ipckey};
			return;
		}

		bless my $self = {}, $class;
		$self->{share} = $share;
		$self->{shmid} = $shmid;

		if ( $self->is_valid ) {
			$ShmCount{$shmid}++;
			return $self;
		}

		carp __PACKAGE__ . "->attach: got invalid cached object";

		delete $ShmCount{$shmid};
		delete $ShmShare{$shmid};
		delete $ShmIndex{$ipckey};

		return;
	}

	my $share = sharelite_attach( $ipckey );

	return unless $share; # no carp, $! is set

	my $shmid = sharelite_shmid( $share );

	unless ( defined $shmid ) {
		carp "sharelite_shmid returned undef";
		sharelite_shmdt( $share );
		return;
	}

	bless my $self = {}, $class;
	$self->{share} = $share;
	$self->{shmid} = $shmid;

	# inform subclasses that an uncached attachment has occurred
	$self->ATTACH()
		or return;

	# save the attached object in the cache
	$ShmIndex{$ipckey} = $shmid;
	$ShmShare{$shmid}  = $share;
	$ShmCount{$shmid}  = 1;

	return $self;
}

=head2 $self->ATTACH();

Called by C< $this->attach() > and C< $this->shmat() > when an uncached
attachment occurs.

Must return true, otherwise the attachment is aborted.

Does nothing on its own; this is meant for subclasses to override.

=cut

sub ATTACH {
	my ( $self ) = @_;

	return 1;
}

=head2 $this->create( [ipckey], [segsize], [permissions] )

Create a new shared memory segment, with the given ipckey, unless it exists.
Can be given C<IPC_PRIVATE> as an ipckey to create an unkeyed segment, which
is assumed if no argument is provided.

The optional parameters segsize and permissions default to C<< $this->Size() >>
and C<< $this->Mode() >>, respectively.

Returns blessed reference on success, undef on failure.

The segment will automatically have a writelock in effect.

=cut

sub create {
	my ( $this, $ipckey, $size, $mode ) = @_;

	$ipckey ||= IPC_PRIVATE;
	$size   ||= $this->Size();
	$mode   ||= $this->Mode();

	my $class = ref( $this ) || $this;

	my $share = sharelite_create( $ipckey, $size, $mode );

	return unless $share; # no carp, $! is set

	my $shmid = sharelite_shmid( $share );

	unless ( defined $shmid ) {
		carp "sharelite_shmid returned undef";
		sharelite_remove( $share );
		sharelite_shmdt( $share );
		return;
	}

	bless my $self = {}, $class;
	$self->{share} = $share;
	$self->{shmid} = $shmid;

	$ShmIndex{$ipckey} = $shmid unless $ipckey == IPC_PRIVATE;
	$ShmShare{$shmid}  = $share;
	$ShmCount{$shmid}  = 1;

	return $self;
}

=head2 $this->shmat( shmid );

Attach to an existing shared memory segment by its shmid.

=cut

sub shmat {
	my ( $this, $shmid ) = @_;

	confess( __PACKAGE__ . "->shmat: Called without shmid." )
		unless defined $shmid;

	confess( __PACKAGE__ . "->shmat: Called with invalid shmid." )
		if $shmid == -1;

	my $class = ref( $this ) || $this;

	if ( my $share = $ShmShare{$shmid} ) {

		bless my $self = {}, $class;
		$self->{share} = $share;
		$self->{shmid} = $shmid;

		if ( $self->is_valid ) {
			$ShmCount{$shmid}++;
			return $self;
		}

		carp __PACKAGE__ . "->shmat: got invalid cached object";

		delete $ShmCount{$shmid};
		delete $ShmShare{$shmid};

		return;
	}

	my $share = sharelite_shmat( $shmid );

	return unless $share; # no carp, $! is set

	bless my $self = {}, $class;
	$self->{share} = $share;
	$self->{shmid} = $shmid;

	# inform subclasses that an uncached attachment has occurred
	$self->ATTACH()
		or return;

	# save the attached object in the cache
	$ShmShare{$shmid} = $share;
	$ShmCount{$shmid} = 1;

	return $self;
}

=head1 CLEANUP METHOD

=head2 $self->remove();

Uncaches the referenced instance, and causes the underlying shared
memory segments to be removed from the operating system when DESTROYed.

Returns 1 on success, undef on failure.

=cut

sub remove {
	my ( $self ) = @_;
	my ( $share, $shmid, $ipckey );

	$share  = $self->{share};

	unless ( $share ) {
		carp "undefined share during remove";
		return;
	}

	return ( sharelite_remove( $share ) == -1 ) ? undef : 1;
}

# when the object is destroyed, the sharelite object must be too
# otherwise segment removal (and even removal marking) would never occur
sub DESTROY {
	my ( $self ) = @_;

	my $shmid = $self->{shmid};

	unless ( defined $shmid ) {
		carp "undefined shmid during DESTROY";
		return;
	}

	$ShmCount{$shmid}--;

	return if $ShmCount{$shmid};

	$self->DETACH;

	return;
}

=head1 DESTRUCTOR

=head2 $self->DETACH();

Called by C< $self->DESTROY() > on the last copy of the object.

Uncaches the referenced instance, and causes the underlying shared
memory segments to be detached by the operating system.

If subclasees override this, they must call C< $self->SUPER::DESTROY() >.

=cut
sub DETACH {
	my ( $self ) = @_;

	$self->scache_clean;

	my $shmid = $self->{shmid};

	unless ( defined $shmid ) {
		carp "undefined shmid during DETACH";
		return;
	}

	my $share = $self->{share};

	unless ( $share ) {
		carp "undefined share during DETACH";
		return;
	}

	my $ipckey = sharelite_key( $share );

	delete $ShmCount{$shmid};
	delete $ShmShare{$shmid};
	delete $ShmIndex{$ipckey} unless $ipckey == IPC_PRIVATE;

	sharelite_shmdt( $share );

	return;
}

} # END lexical scope


=head1 ACCESSOR METHODS

=head2 $self->key();

Returns the ipckey assigned by the program at instantiation.

=head2 $self->shmid();

Returns the shmid assigned by the operating system at instantiation.

=head2 $self->flags();

Returns the permissions flags assigned at instantiation.

=head2 $self->length();

Returns the number of bytes currently stored in the share.

=head2 $self->serial();

Returns the serial number of the current shared memory value.

=head2 $self->top_seg_size();

Returns the total size of the top share segment, in bytes.

=head2 $self->chunk_seg_size();

Returns the size of data chunk segments, in bytes.

=head2 $self->chunk_seg_size( chunk_segment_size );

Changes the size of chunk data segments. The share must have only one
allocated segment (the top segment) for this call to succeed.

=head2 $self->nconns();

Reports the number of processes connected to the share.

=head2 $self->nrefs();

Returns the current shared reference count.

=head2 $self->incref();

Increments the shared reference counter.

=head2 $self->decref();

Decrements the shared reference counter.

=cut

sub key {
	return sharelite_key( shift->{share} );
}

sub shmid {
	return sharelite_shmid( shift->{share} );
}

sub flags {
	return sharelite_flags( shift->{share} );
}

sub length {
	return sharelite_length( shift->{share} );
}

sub serial {
	return sharelite_serial( shift->{share} );
}

sub is_valid {
	return sharelite_is_valid( shift->{share} );
}

sub nsegments {
	return sharelite_nsegments( shift->{share} );
}

sub top_seg_size {
	return sharelite_top_seg_size( shift->{share} );
}

sub chunk_seg_size {
	return sharelite_chunk_seg_size( shift->{share}, @_ );
}

sub nconns {
	return sharelite_nconns( shift->{share} );
}

sub nrefs {
	return sharelite_nrefs( shift->{share} );
}

sub incref {
	return sharelite_incref( shift->{share}, @_ );
}

sub decref {
	return sharelite_decref( shift->{share}, @_ );
}


=head1 DATA METHODS

=head2 $self->scache();

Returns a scalar reference to the segment cache. Does not guarantee
freshness, and the reference can become invalid after the next I/O
operation.

=head2 $self->scache_clean();

Entirely removes the cache entry for the object.

=head2 $self->fetch();

Fetch a previously stored value.

If nothing has been stored yet, C<''> (the empty string) is returned.

=head2 $self->FRESH();

Invoked by C< fetch() > when the data has been changed by another process.

=cut


{ # BEGIN private lexical scope
my %ShmCache = ();		# cache key=shmid  value={}
				#			scache = string
				#			serial = integer
				#			sstamp = timestamp

sub scache {
	my $self = shift;

	my $shmid = $self->{shmid};

	unless ( defined $shmid ) {
		carp "undefined shmid during scache retrieval";
		return;
	}

	my $cache = $ShmCache{$shmid} ||= {};

	$cache->{scache} ||= '';

	return \($cache->{scache});
}

sub scache_clean {
	my $self = shift;

	delete $ShmCache{$self->{shmid}};

}

sub fetch {
	my $self = shift;

	carp(  __PACKAGE__ . "->fetch: Called without at least shared lock!" )
		if $self->_locked( LOCK_UN );

	my $share = $self->{share};

	unless ( $share ) {
		carp "undefined share during fetch";
		return;
	}

	my $shmid = $self->{shmid};

	unless ( defined $shmid ) {
		carp "undefined shmid during fetch";
		return;
	}

	my $cache = $ShmCache{$shmid} ||= {};

	# determine current shared memory value serial number
	my $serial = sharelite_serial( $share );

	# short circuit remaining tests if cache is found invalid
	my $dofetch = 0;

	# definitely fetch if we don't have a matching serial number
	$dofetch = 1
		unless $cache->{serial} && ( $cache->{serial} == $serial );

	# same serial; believe the cached value if it isn't too old
	# a zero ttl means trust the cached value until the serial changes
	unless ( $dofetch ) {
		if ( my $ttl = $self->dwell() ) {
			$dofetch = 1 if $cache->{sstamp} + $ttl < time();
		}
	}

	if ( $dofetch ) {

		$cache->{scache} = sharelite_fetch( $share );

		croak( __PACKAGE__ . "->fetch: failed: $!" )
			unless defined $cache->{scache};

		$cache->{sstamp} = time();
		$cache->{serial} = $serial;

		if ( my $cref = UNIVERSAL::can( $self, 'FRESH' ) ) {
			&$cref( $self );
		}

	}

	return $cache->{scache};
}

=head2 $self->store( value );

Stores a string or numeric value in the shared memory segment.

=cut

sub store {
	my $self = shift;

	carp(  __PACKAGE__ . "->store: Called without exclusive lock!" )
		unless $self->_locked( LOCK_EX );

	my $share = $self->{share};

	unless ( $share ) {
		carp "undefined share during store";
		return;
	}

	my $shmid = $self->{shmid};

	unless ( $shmid ) {
		carp "undefined shmid during store";
		return;
	}

	my $cache = $ShmCache{$shmid} ||= {};

	my $rc = sharelite_store( $share, $_[0], CORE::length( $_[0] ) );

	croak( __PACKAGE__ . "->store: failed: $!" )
		if $rc == -1;

	if ( $self->verify() ) {
		my $data = sharelite_fetch( $share );

		croak( __PACKAGE__ . "->store: fetch failed: $!" )
			unless defined $data;

		croak( __PACKAGE__ . "->store: Write verify failed!" )
			unless $_[0] eq $data;

	}

	# simulate a fetch because storing also serves to confirm the value
	$cache->{scache} = $_[0];
	$cache->{sstamp} = time();
	$cache->{serial} = sharelite_serial( $share );

	# return true so test harnesses pass
	return 1;
}

} # END scope


###
### Object Lock Methods - Class::Lockable friendly
###

sub lock {
	return shift->_lock( @_ );
}

sub _lock {
	my ( $self, $flag ) = @_;

	my $share = $self->{share};

	unless ( $share ) {
		carp "undefined share during _lock";
		return;
	}

	# short circuit if already locked as requested
	return 0 if sharelite_locked( $share, $flag );

	my $rc = sharelite_lock( $share, $flag );

	if ( $rc == -1 ) {
		carp( __PACKAGE__ . "->_lock: $!" );
		return;
	}

	return $rc == 0;
}

sub locked {
	return shift->_locked( @_ );
}

sub _locked {
	my ( $self, $flag ) = @_;

	my $share = $self->{share};

	unless ( $share ) {
		carp "undefined share during _locked";
		return;
	}

	my $rc = sharelite_locked( $share, $flag );

	if ( $rc == -1 ) {
		carp( __PACKAGE__ . "->_locked: $!" );
		return;
	}

	return $rc != 0;
}


###
### Higher Level Lock Methods
###

sub unlock {
	return shift->_lock( LOCK_UN );
}

sub readlock {
	return shift->_lock( LOCK_SH );
}

sub writelock {
	return shift->_lock( LOCK_EX );
}


bootstrap IPC::Shm::Simple $VERSION;

1;


=head1 INSTANCE ATTRIBUTES - I/O BEHAVIOR

=head2 $this->dwell( [seconds] );

Specifies the time-to-live of cached shared memory reads, in seconds.
This only affects the case where the serial number has -not- changed.

Default: 0.

=head2 $this->verify( [boolean] );

Specifies whether to read-back and compare shared memory writes.

Expensive.

Default: 1.

=head1 PACKAGE ATTRIBUTES - SEGMENT PARAMETERS

These methods carry the default values used during instantiation.

=head2 $this->Mode( [value] );

Specifies or fetches the permissions for new segments. Default: 0660.

=head2 $this->Size( [value] );

Specifies or fetches the initial size of new shared memory segments.
Default: 4096

=head1 CAVEATS

To do.

=cut

