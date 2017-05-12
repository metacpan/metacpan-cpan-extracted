#!/usr/bin/perl       # -*-perl-*-

require 't/mbox.pl';

print "1..18\n";

okay_if(1, $folder = new Mail::Folder('mbox', full_folder()));

okay_if(2, @msgs = $folder->message_list);
okay_if(3, $message = $folder->get_message(2));
okay_if(4, $folder->append_message($message));
okay_if(5, $folder->delete_message(2));
okay_if(6, $folder->current_message(3));
okay_if(7, $folder->sync == 0);
okay_if(8, @msgs = $folder->message_list);
okay_if(9, $folder->qty == 2);
okay_if(10, $msgs[0] == 1);
okay_if(11, $msgs[1] == 3);
okay_if(12, $folder->pack);	# 1,3 -> 1,2
okay_if(13, @msgs = $folder->message_list);
okay_if(14, $folder->qty == 2);
okay_if(15, $msgs[0] == 1);
okay_if(16, $msgs[1] == 2);
okay_if(17, $folder->current_message == 2);

okay_if(18, $folder->close);

1;
