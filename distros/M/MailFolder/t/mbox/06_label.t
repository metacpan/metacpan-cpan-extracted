#!/usr/bin/perl

require 't/mbox.pl';

print "1..17\n";

okay_if(1, $folder = new Mail::Folder('mbox', full_folder(),
				      NotMUA => 1));
okay_if(2, $folder->label_exists(1, 'seen'));
okay_if(3, !$folder->label_exists(2, 'seen'));
okay_if(4, $message = $folder->get_message(2));
okay_if(5, $folder->sync == 0);
okay_if(6, $folder->close);

okay_if(7, $folder = new Mail::Folder('mbox', full_folder()));
okay_if(8, $folder->label_exists(1, 'seen'));
okay_if(9, !$folder->label_exists(2, 'seen'));
okay_if(10, $message = $folder->get_message(2));
okay_if(11, $folder->label_exists(2, 'seen'));
okay_if(12, $folder->sync == 0);
okay_if(13, $folder->close);

okay_if(14, $folder = new Mail::Folder('mbox', full_folder()));
okay_if(15, $folder->label_exists(1, 'seen'));
okay_if(16, $folder->label_exists(2, 'seen'));

okay_if(17, $folder->close);

1;
