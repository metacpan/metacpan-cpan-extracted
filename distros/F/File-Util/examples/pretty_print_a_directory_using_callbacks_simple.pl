# ABSTRACT: pretty print a directory, recursively, using callbacks

# Subject to the limitations of alphabetical sorting.  For the fool-proof
# method, see pretty_print_a_directory_using_as_tree.pl (which also uses
# callbacks behind the scenes)  Hint: that callback is tucked away within the
# guts of File::Util and externally exposed as the listdir "as_tree" option

# set this to the name of the directory to pretty-print
my $treetrunk = '.';

use warnings;
use strict;

use lib './lib';
use File::Util qw( NL );

my $ftl = File::Util->new( { onfail => 'zero' } );
my @tree;

$ftl->list_dir( $treetrunk => { callback => \&callback, recurse => 1 } );

print for sort { uc ltrim( $a ) cmp uc ltrim( $b ) } @tree;

exit;

sub callback
{
   my ( $dir, $subdirs, $files, $depth ) = @_;

   stash( $depth, $_ ) for sort { uc $a cmp uc $b } @$subdirs, @$files;

   return;
}

sub stash
{
   my ( $indent, $text ) = @_;
   push( @tree, ( ' ' x ( $indent * 3 ) ) . $text . NL );
}

sub ltrim { my $trim = shift @_; $trim =~ s/^\s+//; $trim }

