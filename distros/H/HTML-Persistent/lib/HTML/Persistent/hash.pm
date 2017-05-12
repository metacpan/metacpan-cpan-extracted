package HTML::Persistent::hash;

use strict;
use warnings;

BEGIN
{
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
	$VERSION = '0.02';
	require Exporter;
	@ISA = qw(Exporter HTML::Persistent::base);
}

use HTML::Persistent::base;
use HTML::Persistent::sl_hash;
use Carp;

sub is_hash { 1; }

sub long_key
{
	my $self = shift;
	my $x = $$self;
	return( '{}' . $x->{key});
}

# Takes input as the short key, tacks on hash marker
sub long_key_static
{
	my $key = shift;
	return( '{}' . $key );
}

sub key
{
	my $self = shift;
	my $x = $$self;
	return( $x->{key});
}

#
# For hash, name is always the key, cannot be edited.
#
sub name
{
	my $self = shift;
	my $x = $$self;
	my $name = shift;
	if( defined( $name ))
	{
		if( $name ne $x->{key})
		{
			croak( "Illegal attempt to modify hash key" );
		}
	}
	return( $x->{key});
}

#
# Returns 1 if the flag changed, or 0 if nothing was modified
#
sub flag_this_node
{
	my $self = shift;
	my $x = $$self;
	my $key = $x->{key};
	my $n = shift;
	if( $n->{h}{$key}) { return( 0 ); }
	$n->{h}{$key} = 1;
	return( 1 );
}

sub has_node_flag
{
	my $self = shift;
	my $x = $$self;
	my $key = $x->{key};
	my $n = shift;
	return( $n->{h}{$key});
}

sub create_this_node
{
	my $self = shift;
	my $x = $$self;
	my $key = $x->{key};
	my $n = shift;

	croak( "No key defined (hash::create_this_node)" ) unless defined( $key );
	# use Data::Dumper; print Dumper( $n );

	# Use an existing node if we have such a thing
	my $node = $n->{h}{$key};
	return( $node ) if defined( $node );

	# Make up a new node from scratch if necessary
	$n->{h}{$key} = $node = { k => $key };

	return( $node );
}

sub visit_this_node
{
	my $self = shift;
	my $x = $$self;
	my $key = $x->{key};
	my $n = shift;
	croak( "No key defined (hash::visit_this_node)" ) unless defined( $key );
	return( $n->{h}{$key});
}

#
# For debugging
#
sub path
{
	my $self = shift;
	my $x = $$self;
	my $key = $x->{key};

	# quote escapes
	$key =~ s{\\}{\\\\};
	$key =~ s{'}{'\\};
	my $p = $x->{p};
	return $p->path() . "{ '${key}' }";
}

#
# We don't have a convenient way to revisit a hash and find the next value,
# so what we do is just stick all the values into a temporary variable and
# clock them out one at a time. Maybe this is dodgy...
#
sub FIRSTKEY
{
	my $self = shift;
	my $x = $$self;
	unless( defined( $x )) { return( undef ); }
	my $p = $x->{p};
	unless( defined( $p )) { return( undef ); }
	my $a = $x->{allkeys} = [ $p->hash_keys()];
	return( shift( @$a ));
}

#
# We actually ignore the key we are given, and just insist on giving what
# we have already decided is the next key. This could be improved.
#
sub NEXTKEY
{
	my $self = shift;
	my $key = shift;
	my $x = $$self;
	unless( defined( $x )) { return( undef ); }
	my $a = $x->{allkeys};
	unless( defined( $a )) { return( undef ); }
	return( shift( @$a ));
}

#
# Delete a single hash item out of the node
#
# Return value is simply undef if nothing was deleted and 1 if something was deleted
# Cannot properly return deleted nodes because they no longer reference anything.
# Could return the key for the referenced node maybe, would that be useful?
#
sub DELETE
{
	my $self = shift;
	my $x = $$self;
	unless( defined( $x )) { return( undef ); }
	my $p = $x->{p};
	unless( defined( $p )) { return( undef ); }
	my $n = $p->writable_node();
	unless( defined( $n )) { return( undef ); }
	#
	# We have the node ready, if not split then this is easy
	# but if it is split then we need to keep deleting
	#
	my $h = $n->{h};
	unless( defined( $h )) { return( undef ); }
	if( $n->{s})
	{
		my @tmp = delete $h->{@_};
		while( scalar( @tmp ) and scalar( @_ ))
		{
			my $key = shift( @_ );
			my $flag = shift( @tmp );
			next unless $flag;
			print STDERR "TODO: cleanup split node {$key}\n";
		}
		return( 1 );
	}

	# Easy method
	my @tmp = delete @$h{@_};
	if( scalar( @tmp )) { return( 1 ); }
	return( undef );
}

#
# Convert into a symlink.
# Typically we don't expect the user to call this directly.
#
sub to_symlink
{
	my $self = shift;
	my $x = $$self;
	unless( defined( $x )) { return( undef ); }
	my $p = $x->{p};
	unless( defined( $p )) { return( undef ); }
	my $sl_p = $p->to_symlink();
	return( HTML::Persistent::sl_hash->new( $x->{key}, $sl_p ));
}

1;

