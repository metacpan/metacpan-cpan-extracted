#!/usr/bin/perl

# Demonstration on how to use the manager to open folders, and then
# to print the headers of each message.
#
# This code can be used and modified without restriction.
# Mark Overmeer, <mailbox@overmeer.net>, 9 nov 2001

use warnings;
use strict;
use lib '..', '.';

use Mail::Box::Manager 2.00;

#
# Get the command line arguments.
#

die "Usage: $0 folderfile\n"
    unless @ARGV==1;

my $filename = shift @ARGV;

#
# Open the folder
#

my $mgr    = Mail::Box::Manager->new;

my $folder = $mgr->open
   ( $filename
   , extract => 'LAZY'   # never take the body unless needed
   );                    #  which saves memory and time.

die "Cannot open $filename: $!\n"
    unless defined $folder;

#
# List all messages in this folder.
#

my @messages = $folder->messages;
print "Mail folder $filename contains ", scalar @messages, " messages:\n";

my $counter  = 1;
foreach my $message (@messages)
{   printf "%3d. ", $counter++;
    print $message->get('Subject') || '<no subject>', "\n";
}

#
# Finish
#

$folder->close;
