#!/usr/bin/perl       # -*-perl-*-

require 't/mbox.pl';

print "1..8\n";

okay_if(1, $folder = new Mail::Folder('mbox', full_folder()));
okay_if(2, $message = $folder->get_message(1));
okay_if(3, $folder->append_message($message));
okay_if(4, $folder->sync == 0);
okay_if(5, $folder->close);

okay_if(6, $folder = new Mail::Folder('mbox', full_folder()));
okay_if(7, $folder->qty == 3);
okay_if(8, $folder->close);

1;
