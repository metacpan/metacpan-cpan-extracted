# ABSTRACT: This code removes a directory and everything in it

use strict;
use warnings;
use File::Util qw( NL );

my $ftl = File::Util->new();
my $removedir = '/path/to/directory/youwanttodelete';

my @gonners = $ftl->list_dir( $removedir, '--recurse' );

# remove directory and everything in it
@gonners = reverse sort { length $a <=> length $b } @gonners;

foreach my $gonner ( @gonners, $removedir ) {

   print "Removing $gonner ...", NL;

   -d $gonner ? rmdir $gonner || die $! : unlink $gonner || die $!;
 }

print 'Done.  w00T!', NL;

exit;
