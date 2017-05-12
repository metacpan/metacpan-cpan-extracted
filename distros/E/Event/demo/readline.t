#!/usr/bin/env perl -w

#
# Test script to combine Term::Readline::Gnu and Event.
# Derived from the ptksh+ script by A. Bohnet which comes
# with Term::Readline::Gnu.
#
# The script does nothing more than just demonstrating how
# Term::Readline::Gnu can be combined with event loops built
# by using the Event module.
#
# The running event loop can be visualized by using the
# option -idle.
#
# J. Stenzel (perl@jochen-stenzel.de)
#

# check perl version
require 5.008;

# pragmata
use strict;

# load modules
use Event;
use Getopt::Long;
use File::Basename;
use Term::ReadLine;


# inits and declarations
my ($script, %options)=basename($0);

# get options
GetOptions(\%options, "idle");

# init readline
my $term=new Term::ReadLine($script);
my $attribs=$term->Attribs;
$term->callback_handler_install("$script> ", \&processLine);

# store output buffer in a scalar (for print)
my $outstream=$attribs->{'outstream'};

# install STDIN handler
Event->io(
	  desc   => 'STDIN handler',                             # description;
	  fd     => \*STDIN,                                     # handle;
	  poll   => 'r',	                                 # wait for income;
	  cb     => sub {&{$attribs->{'callback_read_char'}}()}, # callback;
	  repeat => 1,                                           # keep alive after events;
	 );

# install an additional idle task just to demonstrate that the loop works fine, if necessary
Event->idle(
	    desc   => 'idle task',               # description;
	    prio   => 5,                         # low priority;
	    min    => 1,                         # minimal pending time in seconds;
	    max    => 5,                         # invoked after at least this number of seconds;
	    cb     => sub {print $outstream "\n\n[Trace] Idle task is running.\n\n"}, # callback;
	    repeat => 1,                         # keep alive after events;
	   ) if exists $options{'idle'};

# enter event loop
Event::loop();


# handle a line completely read
sub processLine
 {
  # get line
  my ($line)=@_;

  # anyhing to process?
  if (defined $line)
    {
     # do something
     print $outstream "[Trace] $line\n";
     $term->add_history($line) if $line ne '';
    }
  else
    {
     # well done
     print $outstream "\n";
     $term->callback_handler_remove();
     $_->cancel for Event::all_watchers;
    }
 }
