package HTML::Persistent::sl_array;

use strict;
use warnings;

BEGIN
{
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
	$VERSION = '0.02';
	require Exporter;
	@ISA = qw(Exporter HTML::Persistent::sl_base);
}

use Carp;

#
# Symlink array, very simple object, cannot be used for much.
# Must convert back from symlink to real node before use.
#

sub new
{
	my $class = shift;
	my $self  = {};
	my $k = shift;
	carp( "Array symlink must have a key" ) unless defined( $k );
	$self->{k} = $k; # Key for array, should be number
	my $p = shift;
	carp( "Array symlink must have a parent" ) unless defined( $p );
	$self->{p} = $p; # Parent must exist
	bless( $self, $class );
	return $self;
}

#
# Pass the db as a parameter, we follow up the chain and reconstruct
# the node based on a full path, and return that node
#
sub to_node
{
	my $self = shift;
	my $db = shift;
	my $p = $self->{p};
	my $n = $p->to_node( $db );
	my $k = $self->{k};
	return( $n->[ $k ]);
}

1;

