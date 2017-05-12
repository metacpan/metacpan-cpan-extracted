# ABSTRACT: Recursively perform a search/replace on the file contents of a directory

# Code does a recursive batch search/replace on the content of all files
# in a given directory
#
# Note - this code skips binary files

use strict;
use warnings;
use File::Util qw( NL SL );

# will get search pattern from file named below
use constant SFILE => './sr/searchfor';

# will get replace pattern from file named below
use constant RFILE => './sr/replacewith';

# will perform batch operation in directory named below
use constant INDIR => '/foo/bar/baz';


# create new File::Util object, set File::Util to send a warning for
# fatal errors instead of dieing
my $ftl   = File::Util->new( '--fatals-as-warning' );
my $rstr  = $ftl->load_file( RFILE );
my $spat  = quotemeta $ftl->load_file( SFILE ); $spat = qr/$spat/;
my $gsbt  = 0;
my @opts  = qw/ --files-only --with-paths --recurse /;
my @files = $ftl->list_dir( INDIR, @opts );

for (my $i = 0; $i < @files; ++$i) {

   next if $ftl->is_bin( $files[$i] );

   my $sbt = 0; my $file = $ftl->load_file( $files[$i] );

   $file =~ s/$spat/++$sbt;++$gsbt;$rstr/ge;

   $ftl->write_file( file => $files[$i], content => $file );

   print $sbt ? qq($sbt replacements in $files[$i]) . NL : '';
}

print NL . <<__DONE__ . NL;
$gsbt replacements in ${\ scalar @files } files.
__DONE__

exit;
