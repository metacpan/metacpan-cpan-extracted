#!/usr/bin/perl		# -*-perl-*-

require 't/maildir.pl';

print "1..40\n";

okay_if(1, $folder = new Mail::Folder('maildir', full_folder(),
				      NotMUA => 1));
okay_if(2, $folder->label_exists(1, 'replied'));
okay_if(3, $folder->label_exists(1, 'flagged'));
okay_if(4, !$folder->label_exists(1, 'deleted'));
okay_if(5, !$folder->label_exists(1, 'seen'));
okay_if(6, $file = $folder->get_message_file(1));
okay_if(7, $folder->sync == 0);
okay_if(8, $folder->close);

okay_if(9, $folder = new Mail::Folder('maildir', full_folder()));
okay_if(10, $folder->label_exists(1, 'replied'));
okay_if(11, $folder->label_exists(1, 'flagged'));
okay_if(12, !$folder->label_exists(1, 'deleted'));
okay_if(13, !$folder->label_exists(1, 'seen'));
okay_if(14, !$folder->label_exists(2, 'replied'));
okay_if(15, !$folder->label_exists(2, 'flagged'));
okay_if(16, !$folder->label_exists(2, 'deleted'));
okay_if(17, !$folder->label_exists(2, 'seen'));
okay_if(18, $folder->sync == 0);
okay_if(19, $file = $folder->get_message_file(1));
okay_if(20, (split(/:/, $file, 2))[1] eq '2,FR');
okay_if(21, $file = $folder->get_message_file(2));
okay_if(22, $file !~ /:/);
okay_if(23, $folder->get_message(1));
okay_if(24, $folder->get_message(2));
okay_if(25, $folder->sync == 0);
okay_if(26, $folder->close);

okay_if(27, $folder = new Mail::Folder('maildir', full_folder()));
okay_if(28, $folder->label_exists(1, 'replied'));
okay_if(29, $folder->label_exists(1, 'flagged'));
okay_if(30, !$folder->label_exists(1, 'deleted'));
okay_if(31, $folder->label_exists(1, 'seen'));
okay_if(32, !$folder->label_exists(2, 'replied'));
okay_if(33, !$folder->label_exists(2, 'flagged'));
okay_if(34, !$folder->label_exists(2, 'deleted'));
okay_if(35, $folder->label_exists(2, 'seen'));
okay_if(36, $file = $folder->get_message_file(1));
okay_if(37, (split(/:/, $file, 2))[1] eq '2,FRS');
okay_if(38, $file = $folder->get_message_file(2));
okay_if(39, (split(/:/, $file, 2))[1] eq '2,S');

okay_if(40, $folder->close);

1;
