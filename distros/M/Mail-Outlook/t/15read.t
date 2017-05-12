#!/usr/bin/perl -w
use strict;
no strict 'subs';

use Test::More tests => 37;

use lib 't/testlib';

my $tests = 37;

eval {

SKIP: {
    skip "Mail reading tests disabled. To enable them please set \$ENV{PRIVATE_TESTS} to a true value.\n", $tests unless($ENV{PRIVATE_TESTS});

	eval "use Typelibs";
	skip "Microsoft Outlook doesn't appear to be installed\n", $tests	if($@);

	my $vers = Typelibs::ExistsTypeLib('Microsoft Outlook');
	skip "Microsoft Outlook doesn't appear to be installed\n", $tests	unless($vers);

	eval "use Mail::Outlook";
	skip "Unable to make a connection to Microsoft Outlook\n", $tests	if($@);

	eval "use Win32::OLE::Const 'Microsoft Outlook'";
	skip "Unable to make a connection to Microsoft Outlook\n", $tests	if($@);

    {
    	my $outlook = Mail::Outlook->new();
    	isa_ok($outlook,'Mail::Outlook');
        my $folder  = $outlook->folder();
    	is($folder,undef);
    }

    {
    	my $outlook = Mail::Outlook->new('Inbox');
    	isa_ok($outlook,'Mail::Outlook');
        my $folder  = $outlook->folder();
    	isa_ok($folder,'Mail::Outlook::Folder');
        my $message = $folder->first();
    	isa_ok($message,'Mail::Outlook::Message');
    }

    {
    	my $outlook = Mail::Outlook->new(olFolderInbox);
    	isa_ok($outlook,'Mail::Outlook');
        my $folder  = $outlook->folder();
    	isa_ok($folder,'Mail::Outlook::Folder');
        my $message = $folder->first();
    	isa_ok($message,'Mail::Outlook::Message');
    }

    {
    	my $outlook = Mail::Outlook->new();
    	isa_ok($outlook,'Mail::Outlook');
        my $folder  = $outlook->folder(olFolderInbox);
    	isa_ok($folder,'Mail::Outlook::Folder');
        my $message = $folder->first();
    	isa_ok($message,'Mail::Outlook::Message');
    }

    {
    	my $outlook = Mail::Outlook->new();
    	isa_ok($outlook,'Mail::Outlook');
        my $folder  = $outlook->folder('Inbox');
    	isa_ok($folder,'Mail::Outlook::Folder');
        my $message = $folder->first;
    	isa_ok($message,'Mail::Outlook::Message');
        TestMessage($message);

        my $subject = $message->Subject();
        ok($subject,'got a subject string');

        $message = $folder->next();
    	isa_ok($message,'Mail::Outlook::Message');

        $message = $folder->previous();
    	isa_ok($message,'Mail::Outlook::Message');
        TestMessage($message);
        is($message->Subject(),$subject,'subjects matched');

        $message = $folder->last();
    	isa_ok($message,'Mail::Outlook::Message');
        $message = $folder->next();
    	is($message,undef,'nothing after the last message');

        $message = $folder->first();
    	isa_ok($message,'Mail::Outlook::Message');
        $message = $folder->previous();
    	is($message,undef,'nothing before the first message');

        $message = $folder->first();
        TestMessage($message);
    }
}

};

if($@ =~ /Network problems/) {
	skip "Microsoft Outlook cannot connect to the server.\n", $tests;
	exit;
}

sub TestMessage {
    my $m = shift;

#printf STDERR "[first]\nTo: [%s]\nSubject: [%s]\n", $m->To(), $m->Subject();
#printf STDERR "From: [%s]\n\n", $m->SenderName();
#printf STDERR "Sent: [%s]\n\n", $m->Sent();
#printf STDERR "Received: [%s]\n\n", $m->Received();


    like($m->To(),qr/\w+/,'To matched a text string');
    like($m->SenderName(),qr/\w+/,'From matched a text string');
    like($m->Subject(),qr/\w+/,'Subject matched a text string');
    like($m->Sent(),qr!\d+/\d+\/\d+ \d+:\d+:\d+!,'Sent matched a date/time string');
    like($m->Received(),qr!\d+/\d+\/\d+ \d+:\d+:\d+!,'Received matched a date/time string');
}
