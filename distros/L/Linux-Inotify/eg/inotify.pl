#!/usr/bin/perl

use strict;
use warnings;
use Carp;
use English;
use Linux::Inotify;

if (@ARGV == 0) {
   croak("You have to add to the command line the files and/or directories you want to watch.\n");
}

# setup
my $notifier = Linux::Inotify->new();
my @watches;
for (@ARGV) {
   my $watch = $notifier->add_watch($ARG, Linux::Inotify::ALL_EVENTS);
   push(@watches, $watch);
}

# report first 20 reads
for(1..20) {
   my @events = $notifier->read();
   for (@events) {
      $ARG->print();
      # recurse into subdirs
      if ($ARG->{mask} & Linux::Inotify::ISDIR && \
          $ARG->{mask} & Linux::Inotify::CREATE) {
	 my $watch = $ARG->add_watch();
	 push(@watches, $watch);
      }
   }
}

# cleanup
for (@watches) {
   $ARG->remove();
}
$notifier->close();

