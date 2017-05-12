#!/usr/bin/perl       # -*-perl-*-

require 't/emaul.pl';

print "1..62\n";

okay_if(1, $folder = new Mail::Folder('emaul', full_folder(),
				      NotMUA => 1));
okay_if(2, $folder->qty == 2);

okay_if(3, $folder->label_exists(1, 'one'));
okay_if(4, $folder->label_exists(3, 'three'));
okay_if(5, $folder->label_exists(1, 'atest'));
okay_if(6, $folder->label_exists(3, 'atest'));
okay_if(7, !$folder->label_exists(1, 'three'));
okay_if(8, !$folder->label_exists(3, 'one'));
okay_if(9, !$folder->label_exists(1, 'arf'));
okay_if(10, $folder->delete_label(1, 'one'));
okay_if(11, $folder->clear_label('atest') == 2);
okay_if(12, $folder->delete_label(3, 'three'));

okay_if(13, $folder->add_label(1, 'arf'));
okay_if(14, $folder->label_exists(1, 'arf'));
okay_if(15, $folder->add_label(1, 'greeble'));
$folder->add_label(1, 'zort');
@labels = $folder->list_labels(1);
okay_if(16, $#labels == 2);
okay_if(17, scalar $folder->list_labels(1) == 3);
okay_if(18, $folder->delete_label(1, 'arf'));
okay_if(19, !$folder->label_exists(1, 'arf'));
@msgs = $folder->select_label('arf');
okay_if(20, $#msgs == -1);
okay_if(21, scalar $folder->select_label('arf') == 0);
@msgs = $folder->select_label('zort');
okay_if(22, $#msgs == 0);
okay_if(23, scalar $folder->select_label('zort') == 1);

okay_if(24, $folder->clear_label('zort'));
okay_if(25, !$folder->label_exists(1, 'zort'));

okay_if(26, $folder->add_label(3, 'blah'));
@labels = sort $folder->list_all_labels;
okay_if(27, $#labels == 1);
okay_if(28, ($labels[0] eq 'blah'));
okay_if(29, ($labels[1] eq 'greeble'));
okay_if(30, scalar $folder->list_all_labels == 2);

okay_if(31, $folder->first_labeled_message('blah') == 3);
okay_if(32, !$folder->first_labeled_message('none'));
okay_if(33, $folder->last_labeled_message('greeble') == 1);
okay_if(34, !$folder->last_labeled_message('none'));
okay_if(35, $folder->next_labeled_message(1, 'blah') == 3);
okay_if(36, $folder->prev_labeled_message(3, 'greeble') == 1);

okay_if(37, $folder->close);

okay_if(38, $folder = new Mail::Folder('emaul', full_folder()));
okay_if(39, $folder->label_exists(1, 'one'));
okay_if(40, $folder->label_exists(3, 'three'));
okay_if(41, $folder->label_exists(1, 'atest'));
okay_if(42, $folder->label_exists(3, 'atest'));
okay_if(43, !$folder->label_exists(1, 'arf'));
okay_if(44, !$folder->label_exists(1, 'greeble'));
okay_if(45, !$folder->label_exists(1, 'zort'));
okay_if(46, !$folder->label_exists(3, 'blah'));
okay_if(47, $folder->add_label(1, 'arf'));
okay_if(48, $folder->add_label(1, 'greeble'));
okay_if(49, $folder->add_label(1, 'zort'));
okay_if(50, $folder->add_label(3, 'blah'));
okay_if(51, $folder->sync == 0);
okay_if(52, $folder->close);

okay_if(53, $folder = new Mail::Folder('emaul', full_folder()));
okay_if(54, $folder->label_exists(1, 'one'));
okay_if(55, $folder->label_exists(3, 'three'));
okay_if(56, $folder->label_exists(1, 'atest'));
okay_if(57, $folder->label_exists(3, 'atest'));
okay_if(58, $folder->label_exists(1, 'arf'));
okay_if(59, $folder->label_exists(1, 'greeble'));
okay_if(60, $folder->label_exists(1, 'zort'));
okay_if(61, $folder->label_exists(3, 'blah'));
okay_if(62, $folder->close);

1;
