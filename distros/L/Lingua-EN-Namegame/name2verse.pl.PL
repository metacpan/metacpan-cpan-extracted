# Tim Maher

# This script, script.pl.PL, is called by the Make system, with the name of the
# script to be created, script.pl as its arg

# the contents of script.pl, except for its shebang line, is in script.0,
# which is inserted into script.pl by this script, script.pl.PL

use Config;

$pl_file = shift;

( $basename = $pl_file ) =~ s/\.pl$// or
	die "$0: Bad scriptname argument; no .pl ending!\n";
$file0="$basename.0";

open IN,  "<  $file0" or die "Can't open $file0: $!";
open OUT, "> $pl_file" or die "Can't create $pl_file: $!";
chmod (0755, "$pl_file");

print OUT $Config{startperl}, " -w\n", <IN>;
