package HTML::Persistent::array;

use strict;
use warnings;

#
# Core array nodes inside the database.
#

BEGIN
{
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
	$VERSION = '0.02';
	require Exporter;
	@ISA = qw(Exporter HTML::Persistent::base);
}

use HTML::Persistent::base;
use HTML::Persistent::sl_array;
use Carp;

sub is_array { 1; }

sub long_key
{
	my $self = shift;
	my $x = $$self;
	return( '[]' . $x->{key});
}

# Takes input as the short key, tacks on array marker
sub long_key_static
{
	my $key = shift;
	return( '[]' . $key );
}

sub key
{
	my $self = shift;
	my $x = $$self;
	return( $x->{key});
}

#
# For array, name can be anything you like.
#
sub name
{
	my $self = shift;
	my $x = $$self;
	my $name = shift;
	if( defined( $name ))
	{
		# In order to change the name, must have a writable node
		my $n = $self->writable_node();
		$n->{n} = $name;
		return( $name );
	}

	my $n = $self->readable_node();
	unless( defined( $n )) { return undef; }
	return( $n->{n});
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
	if( $n->{a}[$key]) { return( 0 ); }
	$n->{a}[$key] = 1;
	return( 1 );
}

sub has_node_flag
{
	my $self = shift;
	my $x = $$self;
	my $key = $x->{key};
	my $n = shift;
	return( $n->{a}[$key]);
}

sub create_this_node
{
	my $self = shift;
	my $x = $$self;
	my $key = $x->{key};
	my $n = shift;

	# Use an existing node if we have such a thing
	my $node = $n->{a}[$key];
	return( $node ) if defined( $node );

	# Make up a new node from scratch if necessary
	$n->{a}[$key] = $node = { k => $key };

	return( $node );
}

sub visit_this_node
{
	my $self = shift;
	my $x = $$self;
	my $key = $x->{key};
	my $n = shift;
	croak( "No key defined (array::visit_this_node)" ) unless defined( $key );
	return( $n->{a}[$key]);
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
	return $p->path() . "[ ${key} ]";
}

#
# Gets called when the array is forced to a scalar,
# e.g.   scalar( @$node )
#
# However the parent will be $node, and $self is merely an artifact of tie()
#
# Note that 0 is returned in preference to undef here -- undef implies an error
# and will be reported as an undefined variable, but 0 implies an empty array.
#
sub FETCHSIZE
{
	my $self = shift;
	my $x = $$self;
	unless( defined( $x )) { return undef; }
	my $p = $x->{p};	
	unless( defined( $p )) { return undef; }
	my $n = $p->readable_node();
	unless( defined( $n )) { return 0; }
	my $a = $n->{a};
	unless( defined( $a )) { return 0; }
	return( scalar( @$a ));	
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
	return( HTML::Persistent::sl_array->new( $x->{key}, $sl_p ));
}

# TODO: these have not been implemented,
# some of them might be useful, others probably don't care.

#                   STORESIZE this, count
#                   CLEAR this
#                   PUSH this, LIST
#                   POP this
#                   SHIFT this
#                   UNSHIFT this, LIST
#                   SPLICE this, offset, length, LIST
#                   EXTEND this, count
#                   DESTROY this
#                   UNTIE this


1;
