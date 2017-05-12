# ABSTRACT: pretty print a directory, recursively, using callbacks, fancy

# Subject to the limitations of alphabetical sorting.  For the fool-proof
# method, see pretty_print_a_directory_using_as_tree.pl (which also uses
# callbacks behind the scenes)  Hint: that callback is tucked away within the
# guts of File::Util and externally exposed as the listdir "as_tree" option

# set this to the name of the directory to pretty-print
my $treetrunk = '.';

use warnings;
use strict;

use lib './lib';
use File::Util;

my $ftl = File::Util->new( { onfail => 'zero' } );

$ftl->list_dir( $treetrunk => { callback => \&callback, recurse => 1 } );

exit;

sub callback
{
   my ( $dir, $subdirs, $files, $depth ) = @_;

   my $header = sprintf
      '| IN %s - %d sub-directories | %d files | %d DEEP',
      $dir,
      scalar @$subdirs,
      scalar @$files,
      $depth;

   pprint( $depth, '+' . ( '-' x 70 ) );
   pprint( $depth,  $header );
   pprint( $depth, '+' . ( '-' x 70 ) );

   pprint( $depth, "  SUBDIRS IN $dir" );
   pprint( $depth, "    - none" ) unless @$subdirs;
   pprint( $depth, "    - $_" ) for @$subdirs;

   pprint( $depth, "  FILES in $dir" );
   pprint( $depth, "    - none" ) unless @$files;
   pprint( $depth, "    - $_" ) for @$files;

   print "\n";

   return;
}

sub pprint
{
   my ( $indent, $text ) = @_;
   print( ( ' ' x ( $indent * 3 ) ) . $text . "\n" );
}

