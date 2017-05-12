# ABSTRACT: pretty print a directory, recursively, using list_dir( "as_tree" )

# The fool-proof, dead-simple way to pretty-print a directory tree.  Caveat:
# This isn't a method for massive directory traversal, and is subject to the
# limitations inherent in stuffing an entire directory tree into RAM.  Go
# back and use bare callbacks (see other examples) if you need a more efficient,
# streaming (real-time) pretty-printer where top-level sorting is less
# important than resource constraints and speed of execution.

# set this to the name of the directory to pretty-print
my $treetrunk = '.';

use warnings;
use strict;

use lib './lib';
use File::Util qw( NL SL );

my $ftl = File::Util->new( { onfail => 'zero' } );

walk( $ftl->list_dir( $treetrunk => { as_tree => 1, recurse => 1 } ) );

exit;

sub walk
{
   my ( $branch, $depth ) = @_;

   $depth ||= 0;

   talk( $depth - 1, $branch->{_DIR_SELF_} . SL ) if $branch->{_DIR_SELF_};

   delete @$branch{ qw( _DIR_SELF_  _DIR_PARENT_ ) };

   talk( $depth, $branch->{ $_ } ) for sort { uc $a cmp uc $b } keys %$branch;
}

sub talk
{
   my ( $indent, $item ) = @_;

   return walk( $item, $indent + 1 ) if ref $item;

   print(  ( ' ' x ( $indent * 3 ) ) . ( $item || '' ) . NL );
}

