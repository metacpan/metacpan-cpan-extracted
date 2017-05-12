# ABSTRACT: manually pretty print a directory, recursively

# This example shows a manual walker and descender.  It is inferior
# to the prety_print_a_directory_using_callbacks* scripts, and takes
# more time/effort/code.  This example script is limited: it can
# only walk single top-level directories-- moral of the story: using
# callbacks is the clearly superior option.
#
# This example is here less for exhibition as a good example, and
# much more for exhibition about how not-to-walk directories.  Take
# a look at the other examples instead ;-)

# set this to the name of the directory to pretty-print
my $treetrunk = '/tmp';

use strict;
use warnings;

use File::Util qw( NL );
my $indent = '';
my $ftl    = File::Util->new();
my $opts   = {
   with_paths    => 1,
   sl_after_dirs => 1,
   no_fsdots     => 1,
   as_ref        => 1,
   onfail        => 'zero'
};

my $filetree  = {};
my( $subdirs, $sfiles ) = $ftl->list_dir( $treetrunk => $opts );

$filetree = [{
   $treetrunk => [ sort { uc $a cmp uc $b } @$subdirs, @$sfiles ]
}];

descend( $filetree->[0]{ $treetrunk }, scalar @$subdirs );

walk( @$filetree );

exit;

sub descend {

   my( $parent, $dirnum ) = @_;

   for ( my $i = 0; $i < $dirnum; ++$i ) {

      my $current = $parent->[ $i ];

      next unless -d $current;

      my( $subdirs, $sfiles ) = $ftl->list_dir( $current => $opts );

      map { $_ = $ftl->strip_path( $_ ) } @$sfiles;

      splice @$parent, $i, 1,
      { $current => [ sort { uc $a cmp uc $b } @$subdirs, @$sfiles ] };

      descend( $parent->[$i]{ $current }, scalar @$subdirs );
   }

   return $parent;
}

sub walk {

   my $dir = shift @_;

   foreach ( @{ [ %$dir ]->[1] } ) {

      my $mem = $_;

      if ( ref $mem eq 'HASH' ) {

         print $indent . $ftl->strip_path([ %$mem ]->[0]) . '/', NL;

         $indent .= ' ' x 3; # increase indent

         walk( $mem );

         $indent = substr( $indent, 3 ); # decrease indent

      } else { print $indent . $mem, NL }
   }
}

