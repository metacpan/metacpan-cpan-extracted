#!/usr/bin/perl       # -*-perl-*-

require 't/emaul.pl';

print "1..22\n";

okay_if(1, $folder = new Mail::Folder('emaul', full_folder(),
				      NotMUA => 1));
okay_if(2, $folder->qty == 2);
okay_if(3, $folder->current_message == 1);
okay_if(4, $folder->next_message == 3);
okay_if(5, $folder->next_message($folder->current_message) == 3);
okay_if(6, $folder->current_message($folder->next_message));
okay_if(7, $folder->current_message == 3);
okay_if(8, $folder->prev_message == 1);
okay_if(9, $folder->prev_message(3) == 1);
okay_if(10, $folder->first_message == 1);
okay_if(11, $folder->last_message == 3);
okay_if(12, !$folder->prev_message(1));
okay_if(13, !$folder->next_message(3));
okay_if(14, $folder->close);

okay_if(15, $folder = new Mail::Folder('emaul', full_folder()));
okay_if(16, $folder->current_message == 1);
okay_if(17, $folder->current_message($folder->next_message));
okay_if(18, $folder->sync == 0);
okay_if(19, $folder->close);

okay_if(20, $folder = new Mail::Folder('emaul', full_folder()));
okay_if(21, $folder->current_message == 3);
okay_if(22, $folder->close);

1;
