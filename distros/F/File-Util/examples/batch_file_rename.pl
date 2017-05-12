# ABSTRACT: Batch-rename all files in a directory

# This code changes the file suffix of all files in a directory
# ending in *.log so that they end in *.txt
#
# Note - This example is NOT recursive.

use strict;
use warnings;
use vars qw( $dir );

# Regarding "SL" below: On Win/DOS, it is "\" and on Mac/BSD/Linux it is "/"
# File::Util will automatically detect this for you.
use File::Util qw( NL SL );

my $ftl   = File::Util->new();
my $dir   = 'some/log/directory';
my @files = $ftl->list_dir( $dir, '--files-only' );

foreach my $file ( @files ) {

   # don't change the file suffix unless it is *.log
   next unless $file =~ /log$/;

   my $newname = $file;
      $newname =~ s/\.log$/\.txt/;

   if ( rename $dir . SL . $file, $dir . SL . $newname ) {

      print qq($file -> $newname), NL
   }
   else {

      warn qq(Couldn't rename "$_" to "$newname" - $!)
   }
}

exit;
