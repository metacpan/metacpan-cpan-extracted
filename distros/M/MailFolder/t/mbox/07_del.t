#!/usr/bin/perl       # -*-perl-*-

require 't/mbox.pl';

print "1..14\n";

okay_if(1, $folder = new Mail::Folder('mbox', full_folder()));

okay_if(2, !$folder->label_exists(1, 'deleted'));
okay_if(3, !$folder->label_exists(2, 'deleted'));
$folder->delete_message(1, 2);
okay_if(4, $folder->label_exists(1, 'deleted'));
okay_if(5, $folder->label_exists(2, 'deleted'));
$folder->undelete_message(1, 2);
okay_if(6, !$folder->label_exists(1, 'deleted'));
okay_if(7, !$folder->label_exists(2, 'deleted'));
$folder->delete_message(2);
okay_if(8, $folder->label_exists(2, 'deleted'));
okay_if(9, $folder->current_message(2));
okay_if(10, $folder->sync == 0);
okay_if(11, $folder->current_message == 1);

okay_if(12, $folder = new Mail::Folder('mbox', full_folder()));
okay_if(13, $folder->qty == 1);
okay_if(14, $folder->close);

1;
