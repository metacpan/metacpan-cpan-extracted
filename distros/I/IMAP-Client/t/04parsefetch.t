use Test::More tests => 165;

#################### DEBUGGING TOOL - NOT FOR TESTING (start)
sub dump_fetch(%) {
    my %base = @_;
    foreach my $msgid (keys %base) {
	return 0 unless ($base{$msgid});
	print "(MSGID = $msgid)\n";
	my %ret = %{$base{$msgid}};
	foreach my $key (keys %ret) {
	    if ($key eq "ENVELOPE") {
		foreach my $key2 (keys %{$ret{$key}}) {
		    print "ENVELOPE: $key2: $ret{$key}->{$key2}\n";
		}
	    } elsif ($key eq 'FLAGS') {
		print "FLAGS: ",join(' ',@{$ret{$key}}),"\n";
	    } elsif (($key eq 'BODYSTRUCTURE') || ($key eq 'BODY')) {
		foreach my $subkey (keys %{$ret{$key}}) {
		    if (($subkey =~ /^\d+$/)||
			($subkey eq 'EXT_PARAMETERS') ||
			($subkey eq 'PARAMETERS') ||
			($subkey eq 'DISPOSITION')) {
			foreach my $subkey2 (keys %{$ret{$key}->{$subkey}}) {
			    if (($subkey2 =~ /^\d+$/) ||
				($subkey2 eq 'EXT_PARAMETERS') ||
				($subkey2 eq 'PARAMETERS') ||
				($subkey2 eq 'DISPOSITION')) {
				foreach my $subkey3 (keys %{$ret{$key}->{$subkey}->{$subkey2}}) {
				    print "$key: $subkey: $subkey2: $subkey3: $ret{$key}->{$subkey}->{$subkey2}->{$subkey3}\n";
				}
			    } else {
				print "$key: $subkey: $subkey2: $ret{$key}->{$subkey}->{$subkey2}\n";
			    }
			}
		    } else {
			print "$key: $subkey: $ret{$key}->{$subkey}\n";
		    }
		}
	    } else {
		print "$key: $ret{$key}\n";
	    }
	}
    }
    return(1);
}
#################### DEBUGGING TOOL - NOT FOR TESTING (end)


# Prep (verified by previous tests)
our @message;
use IMAP::Client;
my $imap = IMAP::Client->new;
my %r;


##############################################################
# Test Set 1 (cyrus)
# Basic message
##############################################################
@message = ('* 2 FETCH (FLAGS (\Seen) UID 1847 INTERNALDATE "15-Apr-2005 16:07:17 -0400" ENVELOPE ("Fri, 15 Apr 2005 15:54:59 -0400" "cyrus-sasl issues" (("webserver" NIL "webserver" "generic.server.com")) ((NIL NIL "owner-cyrus-sasl" "lists.andrew.cmu.edu")) (("webserver" NIL "webserver" "generic.server.com")) ((NIL NIL "cyrus-sasl" "lists.andrew.cmu.edu")) NIL NIL NIL "<aslakuewlieuo479n.c34yncoal7435b@generic.server.com>") BODYSTRUCTURE ("TEXT" "PLAIN" ("CHARSET" "US-ASCII" "FORMAT" "flowed") NIL NIL "7BIT" 615 26 NIL NIL NIL) BODY ("TEXT" "PLAIN" ("CHARSET" "US-ASCII" "FORMAT" "flowed") NIL NIL "7BIT" 615 26) BODY[1]<10> {22}'."\r\n",'one be so kinda as to )'."\r\n",'. OK Completed (0.000 sec)');
%r = $imap->parse_fetch(@message);
ok(%r) or print $imap->error;
is($r{2}->{'FLAGS'}->[0], '\Seen');
is($r{2}->{'UID'}, 1847);
is($r{2}->{'INTERNALDATE'}, '15-Apr-2005 16:07:17 -0400');
is($r{2}->{'ENVELOPE'}->{'FROM'}, 'webserver <webserver@generic.server.com>');
is($r{2}->{'ENVELOPE'}->{'TO'}, '<cyrus-sasl@lists.andrew.cmu.edu>');
is($r{2}->{'ENVELOPE'}->{'CC'}, undef);
is($r{2}->{'ENVELOPE'}->{'BCC'}, undef);
is($r{2}->{'ENVELOPE'}->{'SENDER'}, '<owner-cyrus-sasl@lists.andrew.cmu.edu>');
is($r{2}->{'ENVELOPE'}->{'REPLYTO'}, 'webserver <webserver@generic.server.com>');
is($r{2}->{'ENVELOPE'}->{'INREPLYTO'}, undef);
is($r{2}->{'ENVELOPE'}->{'SUBJECT'}, 'cyrus-sasl issues');
is($r{2}->{'ENVELOPE'}->{'DATE'}, 'Fri, 15 Apr 2005 15:54:59 -0400');
is($r{2}->{'ENVELOPE'}->{'MESSAGEID'}, 'aslakuewlieuo479n.c34yncoal7435b@generic.server.com');
is($r{2}->{'BODYSTRUCTURE'}->{1}->{'LINES'}, 26);
is($r{2}->{'BODYSTRUCTURE'}->{1}->{'SIZE'}, 615);
is($r{2}->{'BODYSTRUCTURE'}->{1}->{'CONTENTTYPE'},'TEXT/PLAIN');
is($r{2}->{'BODYSTRUCTURE'}->{1}->{'PARAMETERS'}->{'CHARSET'}, 'US-ASCII');
is($r{2}->{'BODYSTRUCTURE'}->{1}->{'PARAMETERS'}->{'FORMAT'}, 'flowed');
is($r{2}->{'BODYSTRUCTURE'}->{1}->{'ENCODING'}, '7BIT');
is($r{2}->{'BODY'}->{1}->{'LINES'}, 26);
is($r{2}->{'BODY'}->{1}->{'SIZE'}, 615);
is($r{2}->{'BODY'}->{1}->{'CONTENTTYPE'},'TEXT/PLAIN');
is($r{2}->{'BODY'}->{1}->{'PARAMETERS'}->{'CHARSET'}, 'US-ASCII');
is($r{2}->{'BODY'}->{1}->{'PARAMETERS'}->{'FORMAT'}, 'flowed');
is($r{2}->{'BODY'}->{1}->{'ENCODING'}, '7BIT');
is($r{2}->{'BODY'}->{1}->{'OFFSET'}, '10');
is($r{2}->{'BODY'}->{1}->{'BODYSIZE'}, '22');
is($r{2}->{'BODY'}->{1}->{'BODY'}, 'one be so kinda as to ');


##############################################################
# Test Set 2
# Multipart message
# Tests: multipart (text + html) message
##############################################################
@message = ('* 592 FETCH (FLAGS (\Seen \Answered) UID 2437 INTERNALDATE "30-Nov-2005 15:20:02 -0500" ENVELOPE ("Wed, 30 Nov 2005 17:06:54 -0300" "message to the list" (("John Doe" NIL "john.doe" "anonymous.edu")) ((NIL NIL "cyrus-sasl-bounces" "lists.andrew.cmu.edu")) (("John Doe Reply" NIL "john.doe.reply" "anonymous.edu")) ((NIL NIL "cyrus-sasl" "lists.andrew.cmu.edu")) NIL NIL NIL "<49871298456$496028485982847.00@DKEBU2R81L3M>") BODYSTRUCTURE (("TEXT" "PLAIN" ("CHARSET" "iso-8859-1") NIL NIL "QUOTED-PRINTABLE" 348 25 NIL NIL NIL)("TEXT" "HTML" ("CHARSET" "iso-8859-1") NIL NIL "QUOTED-PRINTABLE" 3203 105 NIL NIL NIL) "ALTERNATIVE" ("BOUNDARY" "----=_NextPart_000_001_698543068.4385822") NIL NIL) BODY (("TEXT" "PLAIN" ("CHARSET" "iso-8859-1") NIL NIL "QUOTED-PRINTABLE" 348 25)("TEXT" "HTML" ("CHARSET" "iso-8859-1") NIL NIL "QUOTED-PRINTABLE" 3203 105) "ALTERNATIVE"))'."\r\n",'. OK Completed (0.000 sec)');

%r = $imap->parse_fetch(@message);
ok(%r) or print $imap->error;
is($r{592}->{'FLAGS'}->[0], '\Seen');
is($r{592}->{'FLAGS'}->[1], '\Answered');
is($r{592}->{'UID'}, 2437);
is($r{592}->{'INTERNALDATE'}, '30-Nov-2005 15:20:02 -0500');
is($r{592}->{'ENVELOPE'}->{'FROM'}, 'John Doe <john.doe@anonymous.edu>');
is($r{592}->{'ENVELOPE'}->{'TO'}, '<cyrus-sasl@lists.andrew.cmu.edu>');
is($r{592}->{'ENVELOPE'}->{'CC'}, undef);
is($r{592}->{'ENVELOPE'}->{'BCC'}, undef);
is($r{592}->{'ENVELOPE'}->{'SENDER'}, '<cyrus-sasl-bounces@lists.andrew.cmu.edu>');
is($r{592}->{'ENVELOPE'}->{'REPLYTO'}, 'John Doe Reply <john.doe.reply@anonymous.edu>');
is($r{592}->{'ENVELOPE'}->{'INREPLYTO'}, undef);
is($r{592}->{'ENVELOPE'}->{'SUBJECT'}, 'message to the list');
is($r{592}->{'ENVELOPE'}->{'DATE'}, 'Wed, 30 Nov 2005 17:06:54 -0300');
is($r{592}->{'ENVELOPE'}->{'MESSAGEID'}, '49871298456$496028485982847.00@DKEBU2R81L3M');
is($r{592}->{'BODYSTRUCTURE'}->{'CONTENTTYPE'}, 'MULTIPART/ALTERNATIVE');
is($r{592}->{'BODYSTRUCTURE'}->{'EXT_PARAMETERS'}->{'BOUNDARY'}, '----=_NextPart_000_001_698543068.4385822');
is($r{592}->{'BODYSTRUCTURE'}->{1}->{'LINES'}, 25);
is($r{592}->{'BODYSTRUCTURE'}->{1}->{'SIZE'}, 348);
is($r{592}->{'BODYSTRUCTURE'}->{1}->{'CONTENTTYPE'},'TEXT/PLAIN');
is($r{592}->{'BODYSTRUCTURE'}->{1}->{'PARAMETERS'}->{'CHARSET'}, 'iso-8859-1');
is($r{592}->{'BODYSTRUCTURE'}->{1}->{'ENCODING'}, 'QUOTED-PRINTABLE');
is($r{592}->{'BODYSTRUCTURE'}->{2}->{'LINES'}, 105);
is($r{592}->{'BODYSTRUCTURE'}->{2}->{'SIZE'}, 3203);
is($r{592}->{'BODYSTRUCTURE'}->{2}->{'CONTENTTYPE'},'TEXT/HTML');
is($r{592}->{'BODYSTRUCTURE'}->{2}->{'PARAMETERS'}->{'CHARSET'}, 'iso-8859-1');
is($r{592}->{'BODYSTRUCTURE'}->{2}->{'ENCODING'}, 'QUOTED-PRINTABLE');
is($r{592}->{'BODY'}->{'CONTENTTYPE'}, 'MULTIPART/ALTERNATIVE');
is($r{592}->{'BODY'}->{1}->{'LINES'}, 25);
is($r{592}->{'BODY'}->{1}->{'SIZE'}, 348);
is($r{592}->{'BODY'}->{1}->{'CONTENTTYPE'},'TEXT/PLAIN');
is($r{592}->{'BODY'}->{1}->{'PARAMETERS'}->{'CHARSET'}, 'iso-8859-1');
is($r{592}->{'BODY'}->{1}->{'ENCODING'}, 'QUOTED-PRINTABLE');
is($r{592}->{'BODY'}->{2}->{'LINES'}, 105);
is($r{592}->{'BODY'}->{2}->{'SIZE'}, 3203);
is($r{592}->{'BODY'}->{2}->{'CONTENTTYPE'},'TEXT/HTML');
is($r{592}->{'BODY'}->{2}->{'PARAMETERS'}->{'CHARSET'}, 'iso-8859-1');
is($r{592}->{'BODY'}->{2}->{'ENCODING'}, 'QUOTED-PRINTABLE');

##############################################################
# Test Set 3 (cyrus)
# Attachment
# Tests: Attachments/MIXED parts
##############################################################
@message = ('* 1112 FETCH (FLAGS (\Seen) UID 82144 INTERNALDATE " 9-Nov-2005 10:17:05 -0400" ENVELOPE ("Wed, 7 Nov 2005 20:04:05 -0400" "Sample subject line where we are now" (("asdfman" NIL "asdfasdf" "asdfasdf.com")) (("asdfman" NIL "asdfasdf" "asdfasdf.com")) (("asdfman" NIL "asdfasdf" "asdfasdf.com")) ((NIL NIL "foobar" "barfoo.net")) NIL NIL NIL "<SK45JFUDSAKJRFDEKW.SIVKWEG4@mailer.asdfasdf.com>") BODYSTRUCTURE (("TEXT" "PLAIN" ("CHARSET" "iso-8859-1") NIL NIL "QUOTED-PRINTABLE" 3355 19 NIL NIL NIL)("APPLICATION" "OCTET-STREAM" ("NAME" "filename withspace.txt") NIL NIL "BASE64" 35734 NIL ("ATTACHMENT" ("FILENAME" "filename withspace.txt")) NIL) "MIXED" ("BOUNDARY" "====12347509845013.572843310984657====") NIL NIL) BODY (("TEXT" "PLAIN" ("CHARSET" "iso-8859-1") NIL NIL "QUOTED-PRINTABLE" 3355 19)("APPLICATION" "OCTET-STREAM" ("NAME" "filename withspace.txt") NIL NIL "BASE64" 35734) "MIXED"))'."\r\n",'. OK Completed (0.000 sec)');

%r = $imap->parse_fetch(@message);
ok(%r) or print $imap->error;
is($r{1112}->{'FLAGS'}->[0], '\Seen');
is($r{1112}->{'UID'}, 82144);
is($r{1112}->{'INTERNALDATE'}, ' 9-Nov-2005 10:17:05 -0400');
is($r{1112}->{'ENVELOPE'}->{'FROM'}, 'asdfman <asdfasdf@asdfasdf.com>');
is($r{1112}->{'ENVELOPE'}->{'TO'}, '<foobar@barfoo.net>');
is($r{1112}->{'ENVELOPE'}->{'CC'}, undef);
is($r{1112}->{'ENVELOPE'}->{'BCC'}, undef);
is($r{1112}->{'ENVELOPE'}->{'SENDER'}, 'asdfman <asdfasdf@asdfasdf.com>');
is($r{1112}->{'ENVELOPE'}->{'REPLYTO'}, 'asdfman <asdfasdf@asdfasdf.com>');
is($r{1112}->{'ENVELOPE'}->{'INREPLYTO'}, undef);
is($r{1112}->{'ENVELOPE'}->{'SUBJECT'}, 'Sample subject line where we are now');
is($r{1112}->{'ENVELOPE'}->{'DATE'}, 'Wed, 7 Nov 2005 20:04:05 -0400');
is($r{1112}->{'ENVELOPE'}->{'MESSAGEID'}, 'SK45JFUDSAKJRFDEKW.SIVKWEG4@mailer.asdfasdf.com');
is($r{1112}->{'BODYSTRUCTURE'}->{'CONTENTTYPE'}, 'MULTIPART/MIXED');
is($r{1112}->{'BODYSTRUCTURE'}->{'EXT_PARAMETERS'}->{'BOUNDARY'}, '====12347509845013.572843310984657====');
is($r{1112}->{'BODYSTRUCTURE'}->{1}->{'LINES'}, 19);
is($r{1112}->{'BODYSTRUCTURE'}->{1}->{'SIZE'}, 3355);
is($r{1112}->{'BODYSTRUCTURE'}->{1}->{'CONTENTTYPE'},'TEXT/PLAIN');
is($r{1112}->{'BODYSTRUCTURE'}->{1}->{'PARAMETERS'}->{'CHARSET'}, 'iso-8859-1');
is($r{1112}->{'BODYSTRUCTURE'}->{1}->{'ENCODING'}, 'QUOTED-PRINTABLE');
is($r{1112}->{'BODYSTRUCTURE'}->{2}->{'SIZE'}, 35734);
is($r{1112}->{'BODYSTRUCTURE'}->{2}->{'CONTENTTYPE'},'APPLICATION/OCTET-STREAM');
is($r{1112}->{'BODYSTRUCTURE'}->{2}->{'PARAMETERS'}->{'NAME'}, 'filename withspace.txt');
is($r{1112}->{'BODYSTRUCTURE'}->{2}->{'DISPOSITION'}->{'ATTACHMENT'}->{'FILENAME'}, 'filename withspace.txt');
is($r{1112}->{'BODYSTRUCTURE'}->{2}->{'ENCODING'}, 'BASE64');
is($r{1112}->{'BODY'}->{'CONTENTTYPE'}, 'MULTIPART/MIXED');
is($r{1112}->{'BODY'}->{1}->{'LINES'}, 19);
is($r{1112}->{'BODY'}->{1}->{'SIZE'}, 3355);
is($r{1112}->{'BODY'}->{1}->{'CONTENTTYPE'},'TEXT/PLAIN');
is($r{1112}->{'BODY'}->{1}->{'PARAMETERS'}->{'CHARSET'}, 'iso-8859-1');
is($r{1112}->{'BODY'}->{1}->{'ENCODING'}, 'QUOTED-PRINTABLE');
is($r{1112}->{'BODY'}->{2}->{'SIZE'}, 35734);
is($r{1112}->{'BODY'}->{2}->{'CONTENTTYPE'},'APPLICATION/OCTET-STREAM');
is($r{1112}->{'BODY'}->{2}->{'PARAMETERS'}->{'NAME'}, 'filename withspace.txt');
is($r{1112}->{'BODY'}->{2}->{'ENCODING'}, 'BASE64');

##############################################################
# Test Set 4
# forwarded-as-attachment message with 2 original attachments
# Tests: multiple depth layers/MIXED parts/attachments
##############################################################
@message = ('* 2773 FETCH (FLAGS (\Recent \Seen) UID 84583 INTERNALDATE "20-Dec-2025 16:47:33 -0500" ENVELOPE ("Tue, 20 Dec 2025 16:47:25 -0500" "testing (fwd)" (("Sammuel IMAPs" NIL "IMAPss" "sam.com")) (("Johnny Emails" NIL "emailj" "doe.com")) (("Johnny Emails" NIL "emailj" "doe.com")) ((NIL NIL "janedo" "others.com")) NIL NIL NIL "<C4E39A6421682D937C33DCA4@desktop.others.com>") BODYSTRUCTURE (("TEXT" "PLAIN" ("CHARSET" "us-ascii" "FORMAT" "flowed") NIL NIL "7BIT" 425 21 NIL ("INLINE" NIL) NIL)(("TEXT" "PLAIN" ("CHARSET" "us-ascii") NIL NIL "7BIT" 52 3 NIL NIL NIL)("IMAGE" "JPEG" ("NAME" "Photo_121705_001.jpg") NIL NIL "BASE64" 65330 NIL NIL NIL)("IMAGE" "JPEG" ("NAME" "Photo_121705_002.jpg") NIL NIL "BASE64" 74430 NIL NIL NIL) "MIXED" ("BOUNDARY" "==========71E85D905E941D38D283==========") NIL NIL) "MIXED" ("BOUNDARY" "==========8F8D58A2EAD61ADC46B3==========") NIL NIL) BODY (("TEXT" "PLAIN" ("CHARSET" "us-ascii" "FORMAT" "flowed") NIL NIL "7BIT" 425 21)(("TEXT" "PLAIN" ("CHARSET" "us-ascii") NIL NIL "7BIT" 52 3)("IMAGE" "JPEG" ("NAME" "Photo_121705_001.jpg") NIL NIL "BASE64" 65330)("IMAGE" "JPEG" ("NAME" "Photo_121705_002.jpg") NIL NIL "BASE64" 74430) "MIXED") "MIXED"))'."\r\n",'1234 OK Completed (0.000 sec)');

%r = $imap->parse_fetch(@message);

ok(%r) or print $imap->error;

is($r{2773}->{'FLAGS'}->[0], '\Recent');
is($r{2773}->{'FLAGS'}->[1], '\Seen');
is($r{2773}->{'UID'}, 84583);
is($r{2773}->{'INTERNALDATE'}, "20-Dec-2025 16:47:33 -0500");
is($r{2773}->{'ENVELOPE'}->{'FROM'}, 'Sammuel IMAPs <IMAPss@sam.com>');
is($r{2773}->{'ENVELOPE'}->{'TO'}, '<janedo@others.com>');
is($r{2773}->{'ENVELOPE'}->{'CC'}, undef);
is($r{2773}->{'ENVELOPE'}->{'BCC'}, undef);
is($r{2773}->{'ENVELOPE'}->{'SENDER'}, 'Johnny Emails <emailj@doe.com>');
is($r{2773}->{'ENVELOPE'}->{'REPLYTO'}, 'Johnny Emails <emailj@doe.com>');
is($r{2773}->{'ENVELOPE'}->{'INREPLYTO'}, undef);
is($r{2773}->{'ENVELOPE'}->{'SUBJECT'}, 'testing (fwd)');
is($r{2773}->{'ENVELOPE'}->{'DATE'}, 'Tue, 20 Dec 2025 16:47:25 -0500');
is($r{2773}->{'ENVELOPE'}->{'MESSAGEID'}, 'C4E39A6421682D937C33DCA4@desktop.others.com');
is($r{2773}->{'BODYSTRUCTURE'}->{'CONTENTTYPE'}, 'MULTIPART/MIXED');
is($r{2773}->{'BODYSTRUCTURE'}->{'EXT_PARAMETERS'}->{'BOUNDARY'}, '==========8F8D58A2EAD61ADC46B3==========');
is($r{2773}->{'BODYSTRUCTURE'}->{1}->{'LINES'}, 21);
is($r{2773}->{'BODYSTRUCTURE'}->{1}->{'SIZE'}, 425);
is($r{2773}->{'BODYSTRUCTURE'}->{1}->{'CONTENTTYPE'},'TEXT/PLAIN');
is($r{2773}->{'BODYSTRUCTURE'}->{1}->{'PARAMETERS'}->{'CHARSET'}, 'us-ascii');
is($r{2773}->{'BODYSTRUCTURE'}->{1}->{'PARAMETERS'}->{'FORMAT'}, 'flowed');
is($r{2773}->{'BODYSTRUCTURE'}->{1}->{'ENCODING'}, '7BIT');
is($r{2773}->{'BODYSTRUCTURE'}->{1}->{'DISPOSITION'}->{'INLINE'}, '');
is($r{2773}->{'BODYSTRUCTURE'}->{2}->{'CONTENTTYPE'}, 'MULTIPART/MIXED');
is($r{2773}->{'BODYSTRUCTURE'}->{2}->{'EXT_PARAMETERS'}->{'BOUNDARY'}, '==========71E85D905E941D38D283==========');
is($r{2773}->{'BODYSTRUCTURE'}->{2}->{1}->{'LINES'}, 3);
is($r{2773}->{'BODYSTRUCTURE'}->{2}->{1}->{'SIZE'}, 52);
is($r{2773}->{'BODYSTRUCTURE'}->{2}->{1}->{'CONTENTTYPE'},'TEXT/PLAIN');
is($r{2773}->{'BODYSTRUCTURE'}->{2}->{1}->{'PARAMETERS'}->{'CHARSET'}, 'us-ascii');
is($r{2773}->{'BODYSTRUCTURE'}->{2}->{1}->{'PARAMETERS'}->{'FORMAT'}, undef);
is($r{2773}->{'BODYSTRUCTURE'}->{2}->{1}->{'ENCODING'}, '7BIT');
is($r{2773}->{'BODYSTRUCTURE'}->{2}->{2}->{'SIZE'}, 65330);
is($r{2773}->{'BODYSTRUCTURE'}->{2}->{2}->{'CONTENTTYPE'},'IMAGE/JPEG');
is($r{2773}->{'BODYSTRUCTURE'}->{2}->{2}->{'PARAMETERS'}->{'NAME'}, 'Photo_121705_001.jpg');
is($r{2773}->{'BODYSTRUCTURE'}->{2}->{2}->{'ENCODING'}, 'BASE64');

is($r{2773}->{'BODYSTRUCTURE'}->{2}->{3}->{'SIZE'}, 74430);
is($r{2773}->{'BODYSTRUCTURE'}->{2}->{3}->{'CONTENTTYPE'},'IMAGE/JPEG');
is($r{2773}->{'BODYSTRUCTURE'}->{2}->{3}->{'PARAMETERS'}->{'NAME'}, 'Photo_121705_002.jpg');
is($r{2773}->{'BODYSTRUCTURE'}->{2}->{3}->{'ENCODING'}, 'BASE64');
is($r{2773}->{'BODY'}->{'CONTENTTYPE'}, 'MULTIPART/MIXED');
is($r{2773}->{'BODY'}->{1}->{'LINES'}, 21);
is($r{2773}->{'BODY'}->{1}->{'SIZE'}, 425);
is($r{2773}->{'BODY'}->{1}->{'CONTENTTYPE'},'TEXT/PLAIN');
is($r{2773}->{'BODY'}->{1}->{'PARAMETERS'}->{'CHARSET'}, 'us-ascii');
is($r{2773}->{'BODY'}->{1}->{'PARAMETERS'}->{'FORMAT'}, 'flowed');
is($r{2773}->{'BODY'}->{1}->{'ENCODING'}, '7BIT');
is($r{2773}->{'BODY'}->{2}->{'CONTENTTYPE'}, 'MULTIPART/MIXED');
is($r{2773}->{'BODY'}->{2}->{1}->{'LINES'}, 3);
is($r{2773}->{'BODY'}->{2}->{1}->{'SIZE'}, 52);
is($r{2773}->{'BODY'}->{2}->{1}->{'CONTENTTYPE'},'TEXT/PLAIN');
is($r{2773}->{'BODY'}->{2}->{1}->{'PARAMETERS'}->{'CHARSET'}, 'us-ascii');
is($r{2773}->{'BODY'}->{2}->{1}->{'PARAMETERS'}->{'FORMAT'}, undef);
is($r{2773}->{'BODY'}->{2}->{1}->{'ENCODING'}, '7BIT');
is($r{2773}->{'BODY'}->{2}->{2}->{'SIZE'}, 65330);
is($r{2773}->{'BODY'}->{2}->{2}->{'CONTENTTYPE'},'IMAGE/JPEG');
is($r{2773}->{'BODY'}->{2}->{2}->{'PARAMETERS'}->{'NAME'}, 'Photo_121705_001.jpg');
is($r{2773}->{'BODY'}->{2}->{2}->{'ENCODING'}, 'BASE64');

is($r{2773}->{'BODY'}->{2}->{3}->{'SIZE'}, 74430);
is($r{2773}->{'BODY'}->{2}->{3}->{'CONTENTTYPE'},'IMAGE/JPEG');
is($r{2773}->{'BODY'}->{2}->{3}->{'PARAMETERS'}->{'NAME'}, 'Photo_121705_002.jpg');
is($r{2773}->{'BODY'}->{2}->{3}->{'ENCODING'}, 'BASE64');

