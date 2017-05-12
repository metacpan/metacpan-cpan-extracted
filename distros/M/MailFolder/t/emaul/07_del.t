#!/usr/bin/perl       # -*-perl-*-

require 't/emaul.pl';

print "1..18\n";

okay_if(1, $folder = new Mail::Folder('emaul', full_folder()));

okay_if(2, !$folder->label_exists(1, 'deleted'));
okay_if(3, !$folder->label_exists(3, 'deleted'));
$folder->delete_message(1, 3);
okay_if(4, $folder->label_exists(1, 'deleted'));
okay_if(5, $folder->label_exists(3, 'deleted'));
$folder->undelete_message(1, 3);
okay_if(6, !$folder->label_exists(1, 'deleted'));
okay_if(7, !$folder->label_exists(3, 'deleted'));
$folder->delete_message(3);
okay_if(8, $folder->label_exists(3, 'deleted'));
$folder->undelete_message(3);
$folder->delete_message([1, 3]);
okay_if(9, $folder->label_exists(1, 'deleted'));
okay_if(10, $folder->label_exists(3, 'deleted'));
$folder->undelete_message([1]);
okay_if(11, !$folder->label_exists(1, 'deleted'));
okay_if(12, $folder->label_exists(3, 'deleted'));
okay_if(13, $folder->current_message(3));
okay_if(14, $folder->sync == 0);
okay_if(15, !-e "$folderdir/emaul_1/3"); # should be gone now
okay_if(16, -e "$folderdir/emaul_1/1"); # make sure correct one was stomped
okay_if(17, $folder->current_message == 1);
okay_if(18, $folder->close);

1;
