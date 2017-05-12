
package HTML::Persistent::base;

use strict;
use warnings;

#
# Base class of the database.
# These object methods get inhereted by most everything else, thus not too many assumptions
# can be made here w.r.t. what features are available. Overloading happens here!!
#

use overload
	'""' => \&to_str,
	'0+' => \&to_num,
	'@{}' => \&array_ref,
	'%{}' => \&hash_ref;

use Carp;
use Digest::SHA qw(sha1_hex);
use HTML::Persistent::sl_base;
use Scalar::Util 'blessed';

sub new
{
	my $class = shift;
	my $x     = {};
	my $self  = \$x;
	my $par = shift;
	if( defined( $par ))
	{
		my $y = $$par;
		$x->{p} = $par;
		my $r = $y->{r};
		unless( defined( $r )) { $r = $par; }
		$x->{r} = $r;
	}
	bless( $self, $class );
	return $self;
}

sub to_num { return( 1 ); } # Only useful to test for boolean defined/undefined

sub to_str
{
	croak( "Avoid implicit string conversion; always explicitly get value, name or ref" );
}

sub long_key { '!!'; }
sub key { ''; }

sub sha1
{
	my $self = shift;
	my $x = $$self;
	my $sha = $x->{sha1};
	return( $sha ) if defined( $sha ); # Cache for faster operation
	my $k = $self->long_key();
	my $p = $x->{p};
	if( defined( $p ))
	{
		$sha = sha1_hex( $p->sha1() . $k );
	}
	else
	{
		$sha = sha1_hex( $k );
	}
	$x->{sha1} = $sha;
	return( $sha );
}

sub name { undef; }

# ---=== For debugging ===---
sub dump_list;
sub dump_list
{
	my $self = shift;
	my $x = $$self;
	my $p = $x->{p};
	if( defined( $p )) { $p->dump_list(); }
	my $r = ref( $self );
	my $n = $self->name();
	unless( defined( $n )) { $n = ''; }
	print STDERR $self->long_key(), "\t", $self->sha1(), "\t$n\n";
}

sub TIEHASH
{
	my $class = shift;
	my $self = shift;
	my $r = $class->new( $self );
	return $r;
}

sub TIEARRAY
{
	my $class = shift;
	my $self = shift;
	my $r = $class->new( $self );
	return $r;
}
                                                                                           
sub array_ref
{
	my @a;
	my $self = shift;
	tie @a, 'HTML::Persistent::array', $self;
	return( \@a );
}

sub hash_ref
{
	my %h;
	my $self = shift;
	tie %h, 'HTML::Persistent::hash', $self;
	return( \%h );
}

sub is_hash { 0; }
sub is_array { 0; }

#
# Real data fetch is deferred, this merely remembers the key we have seen
# (and it also remembers the class, but that's already done by now).
#
sub FETCH
{
	my $self = shift;
	my $key = shift;
	my $x = $$self;
	$x->{key} = $key;
	return( $self );
}

#
# STORE does not defer operation, save the key and then go into a node search
# to find or create a writable node. Generally also ends up throwing away the
# current object right after the store is completed.
#
sub STORE
{
	my $self = shift;
	my $key = shift;
	my $value = shift;
	my $x = $$self;
	$x->{key} = $key;
	return( $self->set_val( $value ));
}

#
# Follow back up the chain recursively and try to find a data node.
#
# There are two types of node:
# -- nodes that are split
#    in which case a dummy value of "1" is inserted into the parent data
#    and then the sha1 is calculated and a new item is loaded into cache.
#
# -- nodes that are not split
#    in which case the real item is inserted into the parent data,
#    and we don't need to calculate the sha1 (hopefully faster).
#
# STRUCTURE OF A NODE (not blessed)
#
# {
#   h  => {},    # Hash data items
#   a  => [],    # Array data items
#   n => '',     # Name of this node
#   v => '',     # value of this node
#   s => 1,      # Set to 1 if split, or missing completely if not split
# }
#
# Under $h->{} and $a->[] will be more nodes of the same structure
#
sub writable_node;
sub writable_node
{
	my $self = shift;
	my $x = $$self;

	# Fast path!
	# If we already have sha1 calculated, and also if that value is already cached
	# then job's been done before so return the value right out of the cache.
	my $r = $x->{r};
	unless( defined( $r )) { $r = $self; }

	{
		my $sha1 = $x->{sha1};
		if( defined( $sha1 ))
		{
			my $rx = $$r;
			my $cache = $rx->{cache};
			my $cent = $cache->{$sha1};
			if( defined( $cent ) and $cent->{lockw})
			{
				# Found it!
				# Send back existing data node.
				# Unsplit node always considered dirty, split node can get dirty when flag is set
				my $n = $cent->{n};
				unless( $n->{s}) { $cent->{dirty} = 1; }
				return( $n );
			}
		}
	}

	# Slow path...
	# We don't already have this item, so we must get a data node from the parent
	# ...once the parent node is available, we try to inject ourselves into that node
	# which involves two different situations depending on whether the parent data node is split or not.

	my $p = $x->{p};
	unless( defined( $p ))
	{
		# print STDERR "Creating node with no parent\n";
		my $n = $self->create_this_node();
		# print STDERR "Newly created node is $n\n";
		return( $n );
	}

	my $pn = $p->writable_node();
	if( $pn->{s})
	{
		# OK, we need a split so get sha1, load up the cache and flag the node
		if( $self->flag_this_node( $pn ))
		{
			# Need to dirty flag the parent because it changed
			my $pcent = $r->load_cache( $p->sha1()); # Should be quick
			$pcent->{dirty} = 1;
			# Also dirty flag the child which we just created from empty
			my $cent = $r->load_cache( $self->sha1());
			$cent->{dirty} = 1;
			my $n = $cent->{n};
			$n->{k} = $x->{key};
			return( $n );
		}
		# Only root node does cache loads
		my $cent = $r->load_cache( $self->sha1());
		unless( defined( $cent )) { return( undef ); }
		# Flag all unsplit nodes as dirty straight away
		my $n = $cent->{n};
		unless( $n->{s}) { $cent->{dirty} = 1; }
		return( $n );
	}

	# Easy situation with no splits (chain onto parent).
	return( $self->create_this_node( $pn ));
}

#
# Read-only for root of tree, load the cache with a readable version.
# Should not get called unless the cache is empty.
#
sub visit_this_node
{
	my $self = shift;
	my $x = $$self;
	my $n = shift;
	my $sha1 = $self->sha1();
	my $cent = $self->load_cache_ro( $sha1 );
	unless( defined( $cent )) { return undef; }
	# Send back existing data node.
	return( $cent->{n});
}

sub readable_node;
sub readable_node
{
	my $self = shift;
	my $x = $$self;

	# Fast path! Same as writable_node() above.
	my $r = $x->{r};
	unless( defined( $r )) { $r = $self; }

	my $sha1 = $x->{sha1};
	if( defined( $sha1 ))
	{
		my $rx = $$r;
		my $cache = $rx->{cache};
		my $cent = $cache->{$sha1};
		if( defined( $cent ))
		{
			# Found it! Don't care about lockr or lockw here.
			# Send back existing data node.
			return( $cent->{n});
		}
	}

	# Slow path... we cannot create new items because this is read only.

	my $p = $x->{p};
	unless( defined( $p ))
	{
		return( $self->visit_this_node());
	}

	my $pn = $p->readable_node();
	unless( defined( $pn )) { return undef; }
	if( $pn->{s})
	{
		# In the case of a split, check first to see if it is flagged.
		# If a flag is found then we want to load a read-only cache item.
		$sha1 = $self->sha1();
		if( $self->has_node_flag( $pn ))
		{
			# Only root node does cache loads
			my $cent = $r->load_cache_ro( $sha1 );
			return( $cent->{n});
		}
		return undef; # Not flagged, nothing found.
	}

	# Easy situation with no splits (just search parent).
	return( $self->visit_this_node( $pn ));
}

sub val
{
	my $self = shift;
	my $n = $self->readable_node();
	unless( defined( $n )) { return undef; }
	my $value = $n->{v};
	#
	# Symlinks are silently converted back into nodes.
	#
	if( blessed( $value ) and $value->isa( "HTML::Persistent::sl_base" ))
	{
		my $x = $$self;
		my $r = $x->{r}; # Root of tree

		# carp( "Convert symlink back into a node" );
		# Symlink needs to be re-grafted to the root
		$value = $value->to_node( $r );
	}
	return( $value );
}

sub set_val
{
	my $self = shift;
	my $value = shift;
	my $n = $self->writable_node();
	#
	# Don't store nodes inside the tree... that would be bad.
	# Silently convert to a symlink, and store that instead (safer).
	#
	if( blessed( $value ) and $value->isa( "HTML::Persistent::base" ))
	{
		# carp( "Convert node to a symlink for storage" );
		$value = $value->to_symlink();
	}
	$n->{v} = $value;
	return( $value );
}

#
# Arguably these break the object encapsulation, but a node can be
# used either way, or both ways, so might as well put them here.
#
sub hash_keys
{
	my $self = shift;
	my @a = ();

	my $n = $self->readable_node();
	unless( defined( $n )) { return( @a ); }
	my $h = $n->{h};
	unless( defined( $h )) { return( @a ); }
	@a = keys( %$h );
	return( @a );
}

sub array_scalar
{
	my $self = shift;

	my $n = $self->readable_node();
	unless( defined( $n )) { return undef; }
	my $a = $n->{a};
	unless( defined( $a )) { return undef; }
	return( scalar( @$a ));
}

#
# Should delete the node... TODO.
#
sub delete_me
{
	die( "Not done yet" );
}

#
# Convert node into HTML object,
# supports the import/export of HTML structured data.
#
sub html
{
	require HTML::Persistent::HTML;

	my $self = shift;
	my $h = HTML::Persistent::HTML->new( $self );
	return( $h );
}

#
# Convert into a symlink.
# Typically we don't expect the user to call this directly.
#
sub to_symlink
{
	return( HTML::Persistent::sl_base->new());
}

#
# Step up to parent (or undef if there is no parent).
# Can be useful for backtracking a path.
#
sub get_parent
{
	my $self = shift;
	my $x = $$self;
	return( $x->{p});
}

1;
