#!/usr/bin/perl       # -*-perl-*-

require 't/emaul.pl';

print "1..5\n";

okay_if(1, $folder = new Mail::Folder('emaul', full_folder()));
okay_if(2, $message = $folder->get_message(1));
okay_if(3, $folder->append_message($message));
okay_if(4, -e full_folder() . "/4");
okay_if(5, $folder->close);

1;
