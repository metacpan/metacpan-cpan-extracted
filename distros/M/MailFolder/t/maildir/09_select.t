#!/usr/bin/perl       # -*-perl-*-

require 't/maildir.pl';

$select_nofind = sub { return($_[0]->get('subject') eq 'wontfind'); };

$select_greeble = sub { return($_[0]->get('subject') eq "greeble\n"); };

$select_all = sub { return 1; };

print "1..10\n";

okay_if(1, $folder = new Mail::Folder('maildir', full_folder()));
@msgs = $folder->select($select_nofind);
okay_if(2, $#msgs == -1);
@msgs = $folder->select($select_all);
okay_if(3, $#msgs == 1);
okay_if(4, $msgs[0] == 1);
okay_if(5, $msgs[1] == 2);
@msgs = $folder->select($select_greeble);
okay_if(6, $#msgs == 0);
okay_if(7, $msgs[0] == 2);
@msgs = $folder->inverse_select($select_greeble);
okay_if(8, $#msgs == 0);
okay_if(9, $msgs[0] == 1);
okay_if(10, $folder->close);

1;
