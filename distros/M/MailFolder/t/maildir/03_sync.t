#!/usr/bin/perl       # -*-perl-*-

require 't/maildir.pl';

print "1..11\n";

okay_if(1, $folder = new Mail::Folder('maildir', full_folder()));

okay_if(2, $folder->sync == 0);
okay_if(3, $folder->qty == 2);
okay_if(4, $folder->close);

chmod(0500, full_folder());
okay_if(5, $folder->open(full_folder()));
okay_if(6, $folder->is_readonly);
$folder->delete_message(2);
okay_if(7, $folder->sync == 0);
okay_if(8, $folder->close);
okay_if(9, $folder->open(full_folder()));
okay_if(10, $folder->message_exists(2));
okay_if(11, $folder->close);

1;

