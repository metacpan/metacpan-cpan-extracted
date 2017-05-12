#!/usr/bin/perl

# Demonstrates how to select some messages from one folder, and move
# them to a different folder.  In this case, the first argument is
# the existing folder, the second will contain the messages larger
# than the specified size:
#
#       takelarge.pl infolder outfolder minsize

# *******************************************************************
# * WARNING: the content of infolder will be reduced!!! Don't do this
# *          on your real folders.... it's only a demo
# *******************************************************************

# This code can be used and modified without restriction.
# Mark Overmeer, <mailbox@overmeer.net>, 9 nov 2001

use warnings;
use strict;
use lib '..', '.';

use Mail::Box::Manager 2.00;

#
# Get the command line arguments.
#

die "Usage: $0 folder-from folder-to size\n"
    unless @ARGV==3;

my ($infile, $outfile, $size) = @ARGV;

#
# Open the folder
#

my $mgr    = Mail::Box::Manager->new;

my $inbox  = $mgr->open
  ( $infile
  , access    => 'rw'      # to update deleted
  , extract   => 'ALWAYS'  # read all bodies immediately: faster
  );

die "Cannot open $infile to read: $!\n"
    unless defined $inbox;

my $outbox = $mgr->open
  ( $outfile
  , access   => 'a'        # append,
  , create   => 1          # create if not existent
  );

die "Cannot open $outfile to write: $!\n"
    unless defined $outbox;

foreach my $message ($inbox->messages)
{   next if $message->size < $size;

    $mgr->moveMessage($outbox, $message);
    print 'Moved "',$message->get('Subject') || '<no subject>'
       ,  '": ', $message->size, " bytes.\n";
}

#
# Finish
#

#$inbox->close;
#$outbox->close;
$mgr->closeAllFolders;
