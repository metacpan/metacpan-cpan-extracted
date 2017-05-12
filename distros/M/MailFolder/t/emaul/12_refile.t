#!/usr/bin/perl       # -*-perl-*-

require 't/emaul.pl';

print "1..18\n";

okay_if(1, $folder = new Mail::Folder('emaul', full_folder()));
eval { $folder->refile(2, $folder); };
okay_if(2, $@ =~ /exist/);
okay_if(3, $folder->refile(1, $folder));
okay_if(4, $message = $folder->get_header(4));
okay_if(5, $message->get('Subject') eq "arf\n");
okay_if(6, -e "$folderdir/emaul_1/1");
okay_if(7, -e "$folderdir/emaul_1/3");
okay_if(8, -e "$folderdir/emaul_1/4");
okay_if(9, $folder->sync == 0);
okay_if(10, !-e "$folderdir/emaul_1/1");
okay_if(11, -e "$folderdir/emaul_1/3");
okay_if(12, -e "$folderdir/emaul_1/4");
okay_if(13, $folder->dup(3, $folder));
okay_if(14, $message = $folder->get_header(5));
okay_if(15, $message->get('Subject') eq "greeble\n");
okay_if(16, -e "$folderdir/emaul_1/3");
okay_if(17, -e "$folderdir/emaul_1/5");
okay_if(18, $folder->close);

1;
