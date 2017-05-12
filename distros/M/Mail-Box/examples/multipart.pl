#!/usr/bin/perl

# Print the types of messages in the folder.  Multi-part messages will
# be shown with all their parts.
#
# This code can be used and modified without restriction.
# Mark Overmeer, <mailbox@overmeer.net>, 9 nov 2001

use warnings;
use strict;
use lib '..', '.';

use Mail::Box::Manager 2.00;

sub show_type($;$);

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
   , extract    => 'LAZY'   # never take the body unless needed
   );                       #  which saves memory and time.

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

    show_type $message;
}

sub show_type($;$)
{   my $msg    = shift;
    my $indent = (shift || '') . '    ';   # increase indentation

    print $indent, " type=", $msg->get('Content-Type'), ', '
      , $msg->size, " bytes\n";

    if($msg->isMultipart)
    {   foreach my $part ($msg->parts)
        {   show_type $part, $indent;
        }
    }
}

#
# Finish
#

$folder->close;

