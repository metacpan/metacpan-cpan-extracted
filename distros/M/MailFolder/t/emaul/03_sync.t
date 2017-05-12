#!/usr/bin/perl       # -*-perl-*-

require 't/emaul.pl';

print "1..22\n";

okay_if(1, $folder = new Mail::Folder('emaul', full_folder()));

system("cp $folderdir/emaul_1/1 $folderdir/emaul_1/4");
okay_if(2, $folder->sync == 1);
@msgs = $folder->message_list;
okay_if(3, $#msgs == 2);
okay_if(4, ($#msgs + 1) == $folder->qty);

okay_if(5, $folder->add_label(4, 'atest'));
okay_if(6, $folder->sync == 0);

okay_if(7, $folder->close);

okay_if(8, $folder->open("$folderdir/emaul_1"));
okay_if(9, $folder->qty == 3);
okay_if(10, $folder->label_exists(1, 'atest'));
okay_if(11, $folder->label_exists(3, 'atest'));
okay_if(12, $folder->label_exists(4, 'atest'));
okay_if(13, $folder->label_exists(1, 'one'));
okay_if(14, $folder->label_exists(3, 'three'));

okay_if(15, $folder->close);

chmod(0400, "$folderdir/emaul_1");
okay_if(16, $folder->open("$folderdir/emaul_1"));
okay_if(17, $folder->is_readonly);
$folder->delete_message(3);
okay_if(18, $folder->sync == 0);
okay_if(19, $folder->close);
okay_if(20, $folder->open("$folderdir/emaul_1"));
okay_if(21, $folder->message_exists(3));
okay_if(22, $folder->close);

1;

