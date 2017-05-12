package HTML::Persistent::sl_base;

use strict;
use warnings;

#
# Symbolic link base object.
#

BEGIN
{
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
	$VERSION = '0.02';
	require Exporter;
	@ISA = qw(Exporter);
}

use Carp;

# Symlink placeholder object for base DB. No work is done here.

sub new
{
	my $class = shift;
	my $self  = {};
	bless( $self, $class );
	return $self;
}

#
# Pass the db as a parameter, and hand it right back again.
#
sub to_node
{
	my $self = shift;
	my $db = shift;
	return( $db );
}

1;

