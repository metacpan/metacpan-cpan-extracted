#!/usr/bin/perl       # -*-perl-*-

require 't/maildir.pl';

print "1..13\n";

okay_if(1, $folder = new Mail::Folder('maildir', full_folder()));

okay_if(2, @msgs = $folder->message_list);
okay_if(3, $#msgs == 1);
okay_if(4, ($#msgs + 1) == $folder->qty);
okay_if(5, $msgs[0] == 1);
okay_if(6, $msgs[1] == 2);
okay_if(7, $folder->current_message($folder->next_message));
okay_if(8, $folder->pack);	# 1,3 -> 1,2
okay_if(9, @msgs = $folder->message_list);
okay_if(10, $msgs[0] == 1);
okay_if(11, $msgs[1] == 2);
okay_if(12, $folder->current_message == 2);

okay_if(13, $folder->close);

1;
