#!/usr/bin/perl       # -*-perl-*-

require 't/mbox.pl';

print "1..16\n";

okay_if(1, $folder = new Mail::Folder('mbox', full_folder()));
eval { $folder->refile(3, $folder); };
okay_if(2, $@ =~ /exist/);
okay_if(3, $folder->refile(1, $folder));
okay_if(4, $folder->dup(2, $folder));
okay_if(5, $message = $folder->get_header(3));
okay_if(6, $message->get('Subject') eq "arf\n");
okay_if(7, $message = $folder->get_header(4));
okay_if(8, $message->get('Subject') eq "greeble\n");
okay_if(9, $folder->sync == 0);
okay_if(10, $folder->close);

okay_if(11, $folder = new Mail::Folder('mbox', full_folder()));
okay_if(12, $folder->qty == 3);
$message = $folder->get_header(1);
okay_if(13, $message->get('subject') eq "greeble\n");
$message = $folder->get_header(2);
okay_if(14, $message->get('subject') eq "arf\n");
$message = $folder->get_header(3);
okay_if(15, $message->get('subject') eq "greeble\n");
okay_if(16, $folder->close);

1;
