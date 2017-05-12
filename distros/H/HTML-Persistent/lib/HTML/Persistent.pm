package HTML::Persistent;

use 5.010001;
use strict;
use warnings;

use Carp;
use HTML::Persistent::base;
use HTML::Persistent::hash;
use HTML::Persistent::array;
use Data::Dumper;
use Digest::SHA qw(sha1_hex);
use Fcntl ':flock';
use IO::File;
use POSIX;
use Storable qw(nfreeze fd_retrieve nstore_fd);


BEGIN
{
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
	$VERSION = '0.04';
	require Exporter;
	@ISA = qw(Exporter HTML::Persistent::base);
}

sub file_debug
{
	return;

	my $open_close = shift;
	my $sha = shift;
	my $mode = shift;
	my $ls = `/bin/ls -l /proc/$$/fd | /bin/fgrep -v /dev/`;
	print STDERR "FILE: ${open_close}, ${mode}, $sha\n";
	print STDERR "FILE: ${ls}\n";
	if( $open_close eq 'open' and $ls =~ m{$sha} )
	{
		die( "double-open on $sha" );
	}
}

sub new
{
	my $class = shift;
	my $x = { cache => {}};
	my $self  = \$x;

	my $param = shift;

	my $directory = $param->{'dir'};
	croak( "Must specify 'dir' parameter" ) unless( defined( $directory ));

	$x->{dir} = $directory;
	croak( "Directory $directory does not exist" ) unless -d $directory;

	my $max_size = ( $param->{max} or 65536 );
	$x->{max} = $max_size;

	# Statistic counters
	$x->{sync} = 0;             # Count calls to sync()
	$x->{write_open} = 0;       # Count every time we open a file for writing
	$x->{read_open} = 0;        # Count every time we open a file for reading
	$x->{write_split} = 0;      # Count every time we create a new file because of a split
	$x->{write_close} = 0;      # Count every time we write out and close a file (slow)
	$x->{write_clean} = 0;      # Count every time we close a non-dirty write file (fast)
	$x->{read_close} = 0;       # Count every time we close a read-only file     (fast)

	bless( $self, $class );
	return $self;
}

#
# Cache structure:
#
#    $x->{cache}{$sha}{n}      -- data node for this cache entry
#    $x->{cache}{$sha}{n}{s}   -- set to 1 if this node should split
#    $x->{cache}{$sha}{fh}     -- file handle of currently open data store
#    $x->{cache}{$sha}{lockw}  -- set to 1 if this node is locked for writing
#    $x->{cache}{$sha}{lockr}  -- set to 1 if this node is locked for reading
#    $x->{cache}{$sha}{sha1}   -- copy of the SHA1 key (base for filename, etc)
#
# Return value is the cache entry {n, fh, lockw, lockr, sha1, ...}
#
sub load_cache
{
	my $self = shift;
	my $sha = shift;
	my $x = $$self;

	# Could potentially already be in the cache
	my $cache = $x->{cache};
	my $cent = $cache->{$sha};
	if( defined( $cent ))
	{
		return( $cent ) if( $cent->{lockw});
	}

	if( $x->{lockr})
	{
		#
		# Need to upgrade the read-lock to a write lock.
		# Easiest way (not fastest) is to unlock everything we have,
		# and then start from scratch. They are lockr so no need to
		# worry about saving anything valuable here.
		#
		foreach my $k ( keys( %$cache ))
		{
			$cent = $cache->{$k};
			flock $cent->{fh}, LOCK_UN;
			file_debug( 'close', $k, 'load_cache()' );
			$x->{read_close} += 1;
			close $cent->{fh};
			delete $cent->{fh};
		}
		$x->{cache} = $cache = {}; # Start fresh
		delete $x->{lockr};
		$cent = undef;
	}
	#
	# Always touch the data file and always open up for R/W on the basis that
	# sooner or later we will get the lock.
	#
	my $directory = $x->{dir};
	my $dfile = "$directory/${sha}.data";
	my $fh;
	my $n; # Actual node data

	file_debug( 'open', $sha, 'load_cache( +>> )' );
	unless( open( $fh, '+>>', $dfile )) { croak( "Cannot create file $dfile" ); }
	$x->{write_open} += 1;
	binmode $fh;
	unless( flock( $fh, LOCK_EX )) { croak "Unable to write-lock $dfile"; }
	$x->{lockw} = 1; # We are in write mode
	$cent = undef;

	eval
	{
		# This might fail, if we just created an empty file
		seek $fh, 0, SEEK_SET;
		$n = fd_retrieve( $fh );
		$cent = { n => $n, sha1 => $sha, fh => $fh, lockw => 1 };
		$x->{cache}{$sha} = $cent;
	};

	if( defined( $cent )) { return( $cent ); }

	# If we get to here, it means no suitable node exists on disk,
	# so we create a likely looking empty node and send that.
	# Always presume no split, don't force keys or anything.
	$cent = { n => {  }, sha1 => $sha, fh => $fh, lockw => 1 };
	$x->{cache}{$sha} = $cent;
	return $cent;
}

#
# Read-only version but same as above.
#
sub load_cache_ro
{
	my $self = shift;
	my $sha = shift;
	my $x = $$self;

	# Keep write locks if we are in write mode,
	# eventually a sync() will clear this out, but until then stay in write mode.
	if( $x->{lockw}) { return( $self->load_cache( $sha )); }

	# Could potentially already be in the cache
	my $cache = $x->{cache};
	my $cent = $cache->{$sha};
	if( defined( $cent )) { return( $cent ); }

	my $directory = $x->{dir};
	my $dfile = "$directory/${sha}.data";
	my $fh;
	my $n; # Actual node data

	file_debug( 'open', $sha, 'load_cache_ro( < )' );
	unless( open( $fh, '<', $dfile ))
	{
		# Could be a permissions problem or something
		if( -f $dfile ) { croak( "File exists but cannot open for reading ($dfile)" ); }
		# File not existing is OK, someone is asking for data that does not exist.
		return undef;
	}
	binmode $fh;
	unless( flock( $fh, LOCK_SH ))
	{
		file_debug( 'close', $sha, 'load_cache_ro()' );
		close( $fh );
		croak "Unable to read-lock $dfile";
	}
	$x->{lockr} = 1; # We are in read mode
	$x->{read_open} += 1;
	$cent = undef;

	eval
	{
		# This might fail, but only if files have been deleted or corrupted
		$n = fd_retrieve( $fh );
		$cent = { n => $n, sha1 => $sha, fh => $fh, lockr => 1 };
	};

	# use Data::Dumper; print STDERR Dumper( $x );

	if( defined( $cent ))
	{
		$cache->{$sha} = $cent;
		return $cent;
	}

	carp( "File $dfile is not reading correctly, likely missing data" );
	file_debug( 'close', $sha, 'load_cache_ro()' );
	close( $fh );
	$x->{read_close} += 1;
	return undef;
}

#
# Write a single cache entry back to the filesystem.
# Split it up if necessary (recursively calls itself)
#
# Don't worry about locks here, that's already handled so we lock nothing
# and unlock nothing. Also, don't close any already-existing files here.
#
sub write_cache_entry;
sub write_cache_entry
{
	my $self = shift;
	my $x = $$self;
	my $cent = shift;

	my $n = $cent->{n};
	my $sha = $cent->{sha1};

	my $fh = $cent->{fh}; # Filehandle to open file
	unless( defined( $fh )) { die( "Buggy cache $sha" ); }
	unless( $cent->{lockw})
	{
		$x->{read_close} += 1;
		return undef;
	} # Flag to indicate locked for writing

	# Bail out early for non-dirty cache entries (saves unnecessary writes)
	$x->{write_close} += 1;
	unless( $cent->{dirty})
	{
		$x->{write_clean} += 1;
		return undef;
	}

	# We have a write lock, so rewrite the output file.
	truncate $fh, 0;
	seek $fh, 0, SEEK_SET;
	nstore_fd( $n, $fh );

	if( $n->{s})
	{
		# If node is already split then nothing more can be done.
		return undef;
	}

	autoflush $fh 1;

	# Now check unsplit node to see if we violated the maximum size limit
	my @stat_list = stat( $fh );
	# print STDERR "size of $sha is $stat_list[7] \n";

	if( $stat_list[ 7 ] <= $x->{max})
	{
		# Size is fine so nothing to worry about here.
		return undef;
	}

	# print STDERR "Need to split $sha because too big.\n";

	# We need to split-up this node.
	$n->{s} = 1;

	# We must shuffle out all the sub-items into their own files,
	# but since we have a write-lock here and since we expect the sha to be unique
	# we don't bother locking the sub-item output files (much easier).

	my $directory = $x->{dir};
	my $hash = $n->{h};
	if( defined( $hash ))
	{
		foreach my $item ( sort keys %$hash )
		{
			# Build a fake cache entry (not really in cache) and recursively call ourself.
			# We pretend the entry is locked, but don't really lock it.
			my $nfh;
			my $lk = HTML::Persistent::hash::long_key_static( $item );
			my $nsha1 = sha1_hex( $sha . $lk );
			file_debug( 'open', $nsha1, 'write_cache_entry( > )' );
			unless( open( $nfh, '>', "$directory/${nsha1}.data" ))
			{
				# This should never happen, but check it out anhyow
				croak "Write failed $directory/${nsha1}.data";
			}
			binmode $nfh;
			$x->{write_split} += 1;
			$self->write_cache_entry({ n => $hash->{$item}, lockw => 1, sha1 => $nsha1, fh => $nfh, dirty => 1 });
			file_debug( 'close', $nsha1, 'write_cache_entry()' );
			close $nfh;
			$hash->{$item} = 1; # Residual flag so item can be found later
		}
	}
	my $array = $n->{a};
	if( defined( $array ))
	{
		for( my $ix = 0; $ix < scalar( @$array ); ++$ix )
		{
			my $nn = $array->[ $ix ];
			next unless defined( $nn );
			my $lk = HTML::Persistent::array::long_key_static( $ix );
			my $nsha1 = sha1_hex( $sha . $lk );
			my $nfh;
			file_debug( 'open', $nsha1, 'write_cache_entry( > )' );
			unless( open( $nfh, '>', "$directory/${nsha1}.data" ))
			{
				croak "Write failed $directory/${nsha1}.data";
			}
			binmode $nfh;
			# Fake cache entry and recursive call same as above
			$x->{write_split} += 1;
			$self->write_cache_entry({ n => $nn, lockw => 1, sha1 => $nsha1, fh => $nfh, dirty => 1 });
			file_debug( 'close', $nsha1, 'write_cache_entry()' );
			close $nfh;
			$array->[ $ix ] = 1; # Residual flag so item can be found later
		}
	}

	# print STDERR "Store node $sha for a second time (after splitting).\n";
	# Now store the node again (with flags instead of real data, should be smaller)
	truncate $fh, 0;
	seek $fh, 0, SEEK_SET;
	nstore_fd( $n, $fh );
	return( 1 ); # Split happened
}

#
# Flushe the cache and update filesystem.
# Get rid of all locks and cache entries.
#
sub sync
{
	my $self = shift;
	my $x = $$self;
	$x->{sync} += 1;
	my $directory = $x->{dir};
	my $cache = $x->{cache};
	foreach my $sha ( sort keys %$cache )
	{
		my $cent = $cache->{$sha};
		my $fh = $cent->{fh}; # Filehandle to open file
		unless( defined( $fh )) { die( "Buggy cache $sha" ); }
		$self->write_cache_entry( $cent );
		flock( $fh, LOCK_UN );
		file_debug( 'close', $sha, 'sync()' );
		close $fh;
		delete $cent->{n};			
		delete $cent->{fh};
	}
	$x->{cache} = {};
	delete $x->{lockr};
	delete $x->{lockw};
}

sub stats
{
	my $self = shift;
	my $x = $$self;

	return({
		read_open => $x->{read_open},
		read_close => $x->{read_close},
		write_open => $x->{write_open},
		write_close => $x->{write_close},
		write_clean => $x->{write_clean},
		write_split => $x->{write_split},
		});
}

sub DESTROY
{
	my $self = shift;
	my $x = $$self;
	my $cache = $x->{cache};
	if( scalar( keys( %$cache )))
	{
		carp( "Better to explicitly call sync() rather than allow object to DESTROY" );
		$self->sync();
	}
}

sub create_this_node
{
	my $self = shift;
	my $x = $$self;

	my $directory = $x->{dir};
	my $sha1 = $self->sha1();
	# This is the tree root, can never be part of another node.
	my $cent = $self->load_cache( $sha1 );
	# Auto-dirty root node if not already split (only happens with single-node database)
	my $n = $cent->{n};
	unless( $n->{s}) { $cent->{dirty} = 1; }
	return( $n );
}

sub path
{
	return '->';
}

#
# Get the SHA1 hash for this object and also save a way to reconstruct the node
# so we can externally keep the hash and find our way back again (e.g. as a web cookie).
#
sub path_hash
{
	return '->';
}

1;
__END__

=head1 NAME

HTML::Persistent - Perl database aimed at storing HTML tree structures.

=head1 SYNOPSIS

  use HTML::Persistent;
  $db = HTML::Persistent->new({ dir => '/tmp/stuff' });
  $db->{flibber} = 'This is my comment';
  $db->{flobber} = 'This is not the same comment';
  $db->{Animals}[1] = 'dog';
  $db->{Animals}[2] = 'cat';
  $db->{Animals}[3] = 'bird';
  $node = $db->{special}{numbers};
  $node->[1] = 1.23456;
  $node->[2] = 2.34567;
  $node->[3] = 3.45678;
  print $node->[1] + $node->[2] + $node->[3];

  $db->sync(); # Update files on disk

=head1 DESCRIPTION

This provides an interface that provides convenient access to data with a syntax that is mostly comfortable
for perl users. It uses the overload and tie trick to allow both array and hash references to be acceptable
in arbitrary mix, and allows a mild language ambiguity to assign values to nodes as well as visiting new nodes.

For example, assigning a sub-node to a variable creates the necessary sub-node (if it does not already exist),
but evaluating the same in a string context will reveal the data value contained in the sub-node (or undef if
it does not exist). Evaluating in a numeric context also returns undef if the node does not exist, but forces
the string into a number if a data-value can be found (following normal perl rules).

The database should be concurrent (i.e. multiple processes can safely open the same database) but regular calls
to sync() are required since locking is only released on a sync() call, judging how often to run the sync() is
a matter for the application but it will usually be a somewhat expensive call (in the background using perl
Storable which decomposes the objects into bytecodes and writes at least one entire file). Some granularity factors
are tunable (e.g. largest whole file before splitting it down into directories and smaller files) and these may
effect the optimal sync() placement. In addition, the sync() may be seen as a transaction boundary, but the only
rollback feature is just throwing away the $db object and starting a new object (which is reasonably cheap to do).

The general intention is for medium to long lived server processes to call sync() when they are waiting for
more work (e.g. waiting for a web request) and to try to atomically complete whole requests. Also, it is generally
intended to be faster in a read-only situation (shared locks) than a read/write situation (exclusive locks).

=head2 HASH NODES

Hash nodes have a key (which can be any string) and a name (which is forced to be exactly the same as the key
at all times). The hash node can also contain data (which can be any arbitrary perl scalar, so long as "store"
can handle it).

=head3 Hash keys

To find the keys in a hash node, use either the normal keys function, or a special function hash_keys():

  $node->hash_keys()

or

  keys( %$node )

=head2 ARRAY NODES

Array nodes have a key (which must be a non-negative integer) and a name (which is arbitrarily settable).
The entire array will be created up to the maximum key (like usual for perl arrays), so it is typically sensible
not to use excessively large integers without good reason. The perl trick of backwards reading arrays using
negative numbers is not supported (but may be in future).

=head3 Arrays as scalars (count items in array)

Typical perl use of an array reference might be to use the scalar() function, it also works like:

  $node->array_scalar()

or

  scalar( @$node )

=head2 DATA VALUES

Any data may be stored at a node, but must be a scalar (using a ref for complex data is no problem).
The database does not attempt to see the internals of a given data value;
it is considered to be a single black-box item (even if it is a complex data object).
Objects may be stored as well (since most objects are a hash ref or array ref) but don't
try to store nodes of the tree within other nodes, that is certainly not supported
(although it might coincidentally work sometimes).
Objects from unrelated packages should work fine, but note that under the hood, the method
of storage is "use Storable" which has some limitations so be sure to read the "WARNING"
section of the Storable documentation.

=head2 SYMLINK

A node contains lots of ugly internal links that make it a very bad idea to attempt to
store a node inside a tree. However, sometimes the concept of storing a node inside a tree
is attractive, thus we have symlinks instead. A symlink extracts the internal path of a
node and stores in a safe object that can easily be put into the main tree.

Any attempt to store a node inside a tree, triggers off an automatic conversion to a symlink
before storage (in order to prevent the problem of having real nodes in the tree).
Reading a symlink back out of a tree silently converts it into a node again, so the DB user
should never need to directly handle symlinks. Note that using a symlink is always safe,
even if the real data has been deleted or perhaps never even existed, but the "undef" value
will be the result of attempting to read from such a node.

Symlinks do NOT automatically activate when a path goes past a place where the symlink
exists (unlike unix file system semantics). They only activate when pulled out as a node value
and used as an actual node. This example should clarify things:

   $node1 = $db->{some}{path};
   $node2 = $db->{a}{different}{path};
   $node1->set_val( $node2 ); # Silently converts to a symlink
   $node3 = $db->{some}{path}{past}{link}; # Does NOT follow symlink
   $node4 = $db->{some}{path}->val(); # Equivalent to $node2 but not same object

What this means is if you want to follow a symlink you have to either know you are expecting
one to exist in a certain place, or you have to check each step of the way to discover one.
The reason for this is efficiency... creating a node does not normally visit the database
at all, we have lazy database opening only being triggered by either $node->val() or
$node->set_val() functions. That means when a node is created we don't actually have any
idea whether that path might have crossed any symlinks. Also, for many applications those
links will only exist in well known places, or the application may not use symlinks at all.

Possibly, a slower path traversal mechanism should be supplied as standard that does
follow symlinks. This is not currently available. This would open up the need to check a
symlink pointing to another symlink, possibly along a chain, even circular chains that need
to be detected.


=head2 NODE PATH

It is often useful to convert the full node path to a string format (i.e. right back to the root)
or convert the other way, take a single string and traverse all the way out from the root.
We already have an SHA hash to munge a path but this is not typically exposed to the user
(and in general, the calculation is lazy because such a hash is only occasionally required).


=head1 TODO

Items that don't work, but really should do.


=head2 Read only mode

Open a database with a flag set such that:
 * files are always opened with strictly read permission;
 * locks on files are always read locks;
 * any attempt to set data will generate a croak() error.

This is useful in situations where it is known that no writing is required for some particular
application (e.g. output HTML pages from existing datastore). The storage system is intended to
be more efficient for multiple rapid reads than for regular writing (typical web delivery
scenario).


=head2 Shallow write mode

This would be similar to "read only mode" except that attempting to write to
the database would not cause an error, but instead keeps the written data only in memory,
without writing back to the filesystem. This is useful in situations where an HTML page
might require some rewriting (e.g. a template) before output to the end user,
however those rewritten results are temporary and we don't want to put them back into the
database for the long term.

Typical web delivery workflow would look like:

 * Collect various data model items (from this database or anywhere else)
 * Load template of web page (open in shallow write mode)
 * Inject any items into template to produce dynamic page
 * Export page to end user
 * Close database and throw away modified template


=head2 Smarter write locks

At the moment we work on a "lock everything" mentality and it's either a full read
lock or a full write lock. The effect is that only one process can be writing at any
given time, and this process must queue on the lock until all the readers are done.

This is the safe but slow design, and smarter designs can do better. There's a bunch
of ways to handle this including putting small writes into a logfile which can
safely be appended without locking (need to guarantee atomic append is possible).
Another possibility is writing versioned files (with some suffix) and using a symlink
for the real file (symlink can be moved in an atomic fashion). All of the normal
problems of ACID (Atomicity, Consistency, Isolation, Durability) come into play.


=head2 SQL back end

MySQL and PostgreSQL have become leading open source data storage and retrieval engines
so it would be attractive to allow a back-end coupling directly into an SQL database.
However, at first guess it would be very slow given that tree structures don't map into
SQL particularly neatly.


=head2 TDB back end

         https://tdb.samba.org/

Might be easier to implement than SQL, and possibly faster too. Native support
for transactions and internal locks is already provided by TDB which might improve
performance. Also, a TDB_File module already exists (without transaction support).


=head1 SEE ALSO

perltie, Storable


=head1 AUTHOR

Telford Tendys, E<lt>ttndy@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Telford Tendys

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
