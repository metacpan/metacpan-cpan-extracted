#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Mail::ListDetector;

my $message = Mail::Internet->new(\*STDIN);

my $list = Mail::ListDetector->new($message);

if (defined($list)) {
  print "List software: ", $list->listsoftware, "\n";
  print "List posting address: ", $list->posting_address, "\n";
  print "list name: ", $list->listname, "\n";
} else {
  print "No object returned\n";
}

exit 0;
