#!/usr/bin/perl       # -*-perl-*-

require 't/mbox.pl';

print "1..14\n";

okay_if(1, $folder = new Mail::Folder('mbox', full_folder()));
@statary = stat(full_folder());
okay_if(2, ($statary[2] & 0777) == 0600);

system("cat " . seed_folder() . " >>" . full_folder());
okay_if(3, $folder->sync == 2);
@statary = stat(full_folder());
okay_if(4, ($statary[2] & 0777) == 0600);
@msgs = $folder->message_list;
okay_if(5, $#msgs == 3);
okay_if(6, ($#msgs + 1) == $folder->qty);

okay_if(7, $folder->close);

chmod(0444, full_folder());
okay_if(8, $folder->open(full_folder()));
okay_if(9, $folder->is_readonly);
$folder->delete_message(4);
okay_if(10, $folder->sync == 0);
okay_if(11, $folder->close);
okay_if(12, $folder->open(full_folder()));
okay_if(13, $folder->message_exists(4));
okay_if(14, $folder->close);

1;
