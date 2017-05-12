#!/usr/bin/perl -w
use strict;

use Cwd;
use Test::More tests => 8;

use lib 't/testlib';

my $tests = 8;

eval {

SKIP: {
	eval "use Typelibs";
	skip "Microsoft Outlook doesn't appear to be installed\n", $tests	if($@);

	my $vers = Typelibs::ExistsTypeLib('Microsoft Outlook');
	skip "Microsoft Outlook doesn't appear to be installed\n", $tests	unless($vers);

	eval "use Mail::Outlook";
	skip "Unable to make a connection to Microsoft Outlook\n", $tests	if($@);

	my $outlook;
	eval { $outlook = Mail::Outlook->new(); };
	if($@ || !$outlook) {
		skip "Unable to make a connection to Microsoft Outlook\n", $tests;
		exit;
	}
	isa_ok($outlook,'Mail::Outlook');

	my $message;
	eval { $message = $outlook->create(); };
	if($@ || !$message) {
		skip "Unable to make a connection to Microsoft Outlook\n", $tests;
		exit;
	}
	isa_ok($message,'Mail::Outlook::Message');

	$message->To('you@example.com');
	$message->Cc('Them <them@example.com>');
	$message->Bcc('Us <us@example.com>; anybody@example.com');
	$message->Subject('Blah Blah Blah');
	$message->Body('Yadda Yadda Yadda');

	is($message->To(),'you@example.com');
	is($message->Cc(),'Them <them@example.com>');
	is($message->Bcc(),'Us <us@example.com>; anybody@example.com');
	is($message->Subject(),'Blah Blah Blah');
	is($message->Body(),'Yadda Yadda Yadda');

    my $cwd = getcwd;
	$message->Attach("$cwd/MANIFEST");
	my @attachments = $message->Attach();
	is_deeply(\@attachments,["$cwd/MANIFEST"]);
}

};

if($@ =~ /Network problems/) {
	skip "Microsoft Outlook cannot connect to the server.\n", $tests;
	exit;
}
