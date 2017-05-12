#!/usr/bin/perl       # -*-perl-*-

require 't/maildir.pl';

print "1..4\n";
  
okay_if(1, $folder = new Mail::Folder('maildir', full_folder()));
okay_if(2, $folder->qty == 2);
okay_if(3, $folder->close);

require 't/all.pl';

okay_if(4, Mail::Folder::detect_folder_type(full_folder()) eq 'maildir');

1;
