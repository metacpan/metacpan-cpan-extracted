package IPC::Shm;
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

IPC::Shm - Easily store variables in SysV shared memory.

=head1 SYNOPSIS

 use IPC::Shm;
 our %variable : shm;

Then, just use it like any other variable.

=head1 EXPLANATION

The "shm" variable attribute confers two properties to a package variable:

=over

=item 1. The variable will persist beyond the program's end.

=item 2. All simultaneous processes will see the same value.

=back

Scalars, hashes, and arrays are supported. Filehandles and code are not.

Storing references is legal; however, the target of the reference will itself
be moved into its own anonymous shared memory segment with contents preserved.
That is to say, the original variable the reference points at gets tied, and
its contents restored. Thus, any other Perlish reference copying will behave
as expected.

Blessed references might work but are entirely untested.

=head1 LEXICALS

 use IPC::Shm;
 my $lexical1 : shm;
 my $lexical2 : shm = 'foo';

Lexical variables are supported, and have slightly different semantics. The
properties conferred by the "shm" attribute are:

=over

=item 1. The variable will only persist beyond the program's end if another
shared variable contains a reference to it.

=item 2. The parent and all children will see the same value. Unrelated programs
only have access if a reference is stored via some shared package variable.

=item 3. They will automatically disappear from the system when all copies have
gone out of scope and no reference exists in another shared variable.

=back

=head1 LOCKING

If you need the state of the variable to remain unchanged between two
or more operations, the calling program should assert a lock thus:

 my $obj = tied %variable;
 my $locked = $obj->writelock; # or readlock, if no changes will be made

 $variable{foo} = "bar";
 $variable{bar} = $variable{foo};

 $obj->unlock if $locked;      # don't forget

If a lock is already held by another process, newer locks will block and
wait. However, if the same process is asking for the same lock, it will
return zero. This allows pseudo nested locking.

To summarize the locking behavior, reads are prohibited while a
writelock is in effect (and only one writelock may be held), and
writes are prohibited while one or more readlocks are in effect.

If the process exits, any held locks are released, assuming the
exit was sufficiently clean to allow destructors to run. Something
more severe, such as a segmentation fault, would leave stale locks.

=head1 CACHING

To avoid excessive serialization and deserialization, the underlying
IPC::Shm::Simple class provides a serial number that automatically
increments during writes. Perl uses this to indicate when a change
has been made by another process, and otherwise the in-process
cached copy is trusted.

=head1 ATOMICITY

Perl will read and write the entire variable at once, whether it be a scalar,
array, or hash. At the lowest level, a C implementation just sees the
serialized string. Updates can be considered atomic as reads are locked
out during writes, and vice versa, using a SysV semaphore array.

=head1 PERMISSIONS

SysV shared memory segments have only a user ownership. The group bits
of its UNIX permissions refer to the owner's primary group.

Currently, all users see the same shared memory namespace. This may
change in future versions.

See below for how to influence the permission bits.

=head1 CLEANING UP

If you wish to remove all IPC::Shm segments from the system, do this:

 use IPC::Shm;
 IPC::Shm->cleanup;

Accessing shared variables is not valid after calling this, so you
should probably only call it from an END block.

=head1 IMPLEMENTATION DETAILS

One SysV shared memory segment and one SysV semaphore array for locking
are created for each Perl variable, named or anonymous.

Only one segment, containing %IPC::Shm::NAMEVARS, uses an IPCKEY. It
is currently defaulted to 0xdeadbeef, and will likely change in the
future. One possible path would be to relate the IPCKEY to the
effective userid.

By default, segments are created with 4096 bytes and 0660 permissions.
To change that, you'd need to change the default before the variables
are created:

 sub BEGIN {
        IPC::Shm::Tied->Size( 8192 );
        IPC::Shm::Tied->Mode( 0600 );
 }

Storable freeze() and thaw() are used for serialization and deserialization,
respectively.

Variables are mapped using a hash table. When the next process starts,
it attaches to that first hash table using a four byte IPCKEY. All
other variables are mentioned directly or indirectly in that table,
allowing transparent reconnection.

=head1 CURRENT STATUS

This is alpha code. There are no doubt many bugs.

In particular, the multiple simultaneous process use case has not been tested.

Also, the garbage collection is a bit tenative, and removing named segments
causes them to be cleared immediately rather than during global destruction.

=cut

###############################################################################
# library dependencies

use Attribute::Handlers;

our $VERSION = '0.35';


###############################################################################
# argument normalizers

sub _attrtie_normalize_data {
	my ( $data ) = @_;

	if ( not defined $data ) {
		$data = [];
	}

	elsif ( ref( $data ) ne 'ARRAY' ) {
		$data = [ $data ];
	}

	return $data;
}

sub _attrtie_normalize_symbol {
	my ( $sym, $type ) = @_;

	return $sym if $sym eq 'LEXICAL';

	$sym = *$sym;

	my $tmp = $type eq 'HASH' ? '%'
		: $type eq 'ARRAY' ? '@'
		: $type eq 'SCALAR' ? '$'
		: '*';

	$sym =~ s/^\*/$tmp/;

	return $sym;
}


###############################################################################
# sanity checks

sub _attrtie_check_ref_sanity {
	my ( $ref ) = @_;

	my $rv = ref( $ref )
		or confess "BUG:\$_[2] is not a reference";

	if ( $rv eq 'CODE' ) {
		confess "Subroutines cannot be placed in shared memory";
	}

	if ( $rv eq 'HANDLE' ) {
		confess "Handles cannot be placed in shared memory";
	}

	return $rv if $rv eq 'HASH';
	return $rv if $rv eq 'ARRAY';
	return $rv if $rv eq 'SCALAR';

	confess "Unknown reference type '$rv'";
}


###############################################################################
# shared memory attribute handler

sub UNIVERSAL::shm : ATTR(ANY) {
	my ( $pkg, $sym, $ref, $attr, $data, $phase ) = @_;
	my ( $type, $obj );

	$data = _attrtie_normalize_data( $data );
	$type = _attrtie_check_ref_sanity( $ref );
	$sym  = _attrtie_normalize_symbol( $sym, $type );

	my $segment = $sym eq 'LEXICAL'
		? IPC::Shm::Segment->anonymous
		: IPC::Shm::Segment->named( $sym )
		or confess "Unable to find shm store";

	if    ( $type eq 'HASH' ) {
		$obj = tie %$ref, 'IPC::Shm::Tied', $segment, @$data;
	}

	elsif ( $type eq 'ARRAY' ) {
		$obj = tie @$ref, 'IPC::Shm::Tied', $segment, @$data;
	}

	elsif ( $type eq 'SCALAR' ) {
		$obj = tie $$ref, 'IPC::Shm::Tied', $segment, @$data;
	}

	$obj->tiedref( $ref );

	if ( $sym eq '%IPC::Shm::NAMEVARS' ) {
		unless ( $IPC::Shm::NAMEVARS{$sym} ) {
			$IPC::Shm::NAMEVARS{$sym} = $segment->shmid;
		}
	}

}

###############################################################################
# alias to avoid warnings during make test

sub UNIVERSAL::Shm : ATTR(ANY) {
	UNIVERSAL::shm(@_);
}


###############################################################################
# late library dependencies - after the above compiles

use IPC::Shm::Segment;
use IPC::Shm::Tied;


###############################################################################
# shared memory variables used by this package

our %NAMEVARS : Shm;
our %ANONVARS : Shm;
our %ANONTYPE : Shm;


###############################################################################
# global cleanup routine

sub cleanup {

	foreach my $vanon ( keys %ANONVARS ) {
		my $shmid = $ANONVARS{$vanon};
		my $share = IPC::Shm::Segment->shmat( $shmid );
		   $share->remove;
	}

	foreach my $vname ( keys %NAMEVARS ) {
		next if $vname eq '%IPC::Shm::NAMEVARS';
		my $shmid = $NAMEVARS{$vname};
		my $share = IPC::Shm::Segment->shmat( $shmid );
		   $share->remove;
	}

	my $obj = tied %NAMEVARS;
	$obj->remove;

}


###############################################################################
###############################################################################

=head1 AUTHOR

Kevin Cody-Little <kcody@cpan.org>

=cut

1;
