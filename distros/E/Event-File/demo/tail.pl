#!/usr/bin/perl -w

use Event::File;
use strict;

Event::File->tail(
		  cb => sub {
		    my ($me, $line) = @_;
		    print "Got: $line\n";
		  },
		  file => 'read_file',

		  endfile_cb => sub {
		    print "end of file.\n";
		  },

		  timeout => 20,

		  timeout_cb => sub {
                    my $watcher = shift;
		    print "an timeout happened. ID: " . $watcher->id . "\n";
                    print "Unlooping\n";
                    $watcher->unloop(10);
		  }
	       );

my $result = Event::loop;

print "\n\nFinished with result: $result\n\n";
