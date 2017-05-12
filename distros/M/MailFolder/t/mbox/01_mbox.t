#!/usr/bin/perl       # -*-perl-*-

require 't/mbox.pl';

print "1..7\n";

okay_if(1, $folder = new Mail::Folder('mbox', full_folder()));
okay_if(2, $folder->qty == 2);
okay_if(3, $folder->close);

okay_if(4, Mail::Folder::detect_folder_type(full_folder()) eq 'mbox');

okay_if(5, $folder = new Mail::Folder('mbox', full_folder(), NFSLock => 1));
okay_if(6, $folder->qty == 2);
okay_if(7, $folder->close);

1;
