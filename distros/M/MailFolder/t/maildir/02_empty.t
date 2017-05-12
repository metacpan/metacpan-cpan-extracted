#!/usr/bin/perl       # -*-perl-*-

require 't/maildir.pl';

print "1..6\n";

okay_if(1, $folder = new Mail::Folder('maildir', empty_folder(),
				      Create => 1));

@msgs = $folder->message_list;
okay_if(2, $#msgs == -1);	# folder is empty
okay_if(3, ($#msgs + 1) == $folder->qty);
okay_if(4, !$folder->sync);	# no additions to the folder
okay_if(5, $folder->close);
@deletes = keys %{$folder->{Deletes}};
okay_if(6, $#deletes == -1);	# make sure the close closed up shop

1;
