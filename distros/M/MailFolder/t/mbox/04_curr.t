#!/usr/bin/perl       # -*-perl-*-

require 't/mbox.pl';

print "1..12\n";

okay_if(1, $folder = new Mail::Folder('mbox', full_folder()));

okay_if(2, $folder->qty == 2);
okay_if(3, $folder->current_message == 1);
okay_if(4, $folder->next_message == 2);
okay_if(5, $folder->next_message($folder->current_message) == 2);
okay_if(6, $folder->current_message($folder->next_message));
okay_if(7, $folder->current_message == 2);
okay_if(8, $folder->prev_message == 1);
okay_if(9, $folder->prev_message($folder->current_message) == 1);
okay_if(10, $folder->first_message == 1);
okay_if(11, $folder->last_message == 2);

okay_if(12, $folder->close);

1;
