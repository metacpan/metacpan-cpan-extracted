#!/usr/bin/perl       # -*-perl-*-

require 't/mbox.pl';

print "1..12\n";

okay_if(1, $folder = new Mail::Folder('mbox', empty_folder(),
				      Create => 1));

@msgs = $folder->message_list;
okay_if(2, $#msgs == -1);	# folder is empty
okay_if(3, ($#msgs + 1) == $folder->qty);
okay_if(4, !$folder->sync);	# no additions to the folder
okay_if(5, $folder->close);
@deletes = keys %{$folder->{Deletes}};
okay_if(6, $#deletes == -1);	# make sure the close closed up shop

okay_if(7, unlink(empty_folder()));
okay_if(8, $folder = new Mail::Folder('AUTODETECT', empty_folder(),
				      Create => 1,
				      DefaultFolderType => 'mbox'));
@msgs = $folder->message_list;
okay_if(9, $#msgs == -1);	# folder is empty
okay_if(10, !$folder->sync);
okay_if(11, -z empty_folder());
okay_if(12, $folder->close);

1;
