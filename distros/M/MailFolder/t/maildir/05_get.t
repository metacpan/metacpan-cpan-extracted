#!/usr/bin/perl       # -*-perl-*-

require 't/maildir.pl';

print "1..24\n";

okay_if(1, $folder = new Mail::Folder('maildir', full_folder()));

okay_if(2, $message = $folder->get_header(1));
eval { $message = $folder->get_header(9999); };
okay_if(3, $@ =~ /exist/);
okay_if(4, $message = $folder->get_message(1));
okay_if(5, $#{$message->body} == 0);
okay_if(6, $filename = $folder->get_message_file(1));
okay_if(7, -e $filename);
eval { $folder->get_message_file(9998); };
okay_if(8, $@ =~ /exist/);
okay_if(9, $subject = $message->get('subject'));
okay_if(10, $subject eq "arf\n");

okay_if(11, $message = $folder->get_mime_header(1));
okay_if(12, ref($message) eq 'MIME::Head');
okay_if(13, $subject = $message->get('subject'));
okay_if(14, $subject eq "arf\n");

okay_if(15, $message = $folder->get_mime_message(2,
						 output_to_core => 'ALL'));
okay_if(16, ref($message) eq 'MIME::Entity');
okay_if(17, $subject = $message->get('Subject'));
okay_if(18, $subject eq "greeble\n");

okay_if(19, $parser = new MIME::Parser);
okay_if(20, $parser->output_to_core('ALL'));
okay_if(21, $message = $folder->get_mime_message(1, $parser));
okay_if(22, $subject = $message->get('Subject'));
okay_if(23, $subject eq "arf\n");

okay_if(24, $folder->close);

1;
