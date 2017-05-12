#!/usr/bin/perl       # -*-perl-*-

require 't/emaul.pl';

print "1..16\n";

okay_if(1, $folder = new Mail::Folder('emaul', full_folder()));

@msgs = $folder->message_list;
okay_if(2, ($#msgs + 1) == $folder->qty);
okay_if(3, $folder->qty == 2);
okay_if(4, $msgs[0] == 1);
okay_if(5, $msgs[1] == 3);
okay_if(6, $folder->current_message($folder->next_message));
okay_if(7, $folder->pack);	# 1,3 -> 1,2
okay_if(8, @msgs = $folder->message_list);
okay_if(9, ($#msgs + 1) == $folder->qty);
okay_if(10, $msgs[0] == 1);
okay_if(11, $msgs[1] == 2);
okay_if(12, -e "$folderdir/emaul_1/$msgs[0]");
okay_if(13, -e "$folderdir/emaul_1/$msgs[1]");
okay_if(14, !-e "$folderdir/emaul_1/3");
okay_if(15, $folder->current_message == 2);

okay_if(16, $folder->close);

1;
