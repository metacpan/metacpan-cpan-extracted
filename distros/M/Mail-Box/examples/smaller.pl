#!/usr/bin/perl

# Demonstration on reducing the size of a folder.
#
# This code can be used and modified without restriction.
# Mark Overmeer, <mailbox@overmeer.net>, 12 jul 2003

use warnings;
use strict;
use lib ('../lib', 'lib');

use Mail::Box::Manager;
use Mail::Message;
use List::Util 'sum';

my $for_real = 0;   # set to 'true' to make changes
sub size($) { Mail::Message->shortSize($_[0]) }  # nice output of value

#
# Get the command line arguments.
#

die "Usage: $0 folder\n"
    unless @ARGV==1;

my $name   = shift @ARGV;
my $mgr    = Mail::Box::Manager->new;

my $folder = $mgr->open
  ( $name
  , access => ($for_real ? 'rw' : 'r')
  );

die "Cannot open folder $name" unless $folder;
print "** Dry run: no changes made to $name\n" unless $for_real;

my $msgs = $folder->messages;
my $size = $folder->size;
print "Folder contains $msgs messages at start, in total about ",
    size($size), " bytes\n";

foreach my $msg ($folder->messages)
{   $msg->head->removeResentGroups;
}

my $newsize = $folder->size;
print "After removal of resent groups, the folder is about ",
    size($newsize), " bytes\n";
my $resentsize = $size - $newsize;

foreach my $msg ($folder->messages)
{   $msg->head->removeListGroup;
}

my $newsize2 = $folder->size;
print "After removal of list groups, the folder is only ",
    size($newsize2), " bytes\n";
my $listsize = $newsize - $newsize2;

foreach my $msg ($folder->messages)
{   $msg->head->removeSpamGroups;
}
my $finalsize = $folder->size;
print "After removal of spam groups, the folder is only ",
    size($finalsize), " bytes\n";
my $spamsize = $newsize2 - $finalsize;

# Final statistics
sub percent($$)
{   my ($part, $size) = @_;
    sprintf "%4.1f%%  (%s)", ($part*100)/$size, size($part);
}

my $sizeheads = sum map {$_->head->size}
                       map {$_->parts}
		           $folder->messages;

print '  resent headers were   ', percent($resentsize,$size), "\n",
      '  list headers were     ', percent($listsize,$size), "\n",
      '  spam headers were     ', percent($spamsize,$size), "\n",
      '  remaining headers are ', percent($sizeheads, $size), "\n",
      '  size of bodies is     ', percent($finalsize-$sizeheads, $size), "\n";

# End
if($for_real) { $folder->close }
else          { $folder->close(write => 'NEVER') }

exit 0;
