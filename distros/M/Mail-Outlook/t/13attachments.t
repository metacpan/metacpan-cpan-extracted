#!/usr/bin/perl -w
use strict;

use Cwd;
use Test::More tests => 3;
	
use lib 't/testlib';

my $tests = 3;

eval {

SKIP: {
	eval "use Typelibs";
	skip "Microsoft Outlook doesn't appear to be installed\n", $tests	if($@);

	my $vers = Typelibs::ExistsTypeLib('Microsoft Outlook');
	skip "Microsoft Outlook doesn't appear to be installed\n", $tests	unless($vers);

	eval "use Mail::Outlook";
	skip "Unable to make a connection to Microsoft Outlook\n", $tests	if($@);

	my %hash = (
		To		=> 'you@example.com',
		Cc		=> 'Them <them@example.com>',
		Bcc		=> 'Us <us@example.com>; anybody@example.com',
		Subject	=> 'Attachments Test for Mail::Outlook',
		Body	=> 'There should be 3 separate attachments with this mail. If you can see this mail, all well and good. You can close it now :)',
  	);

	my $outlook = Mail::Outlook->new();
	my $message = $outlook->create(%hash);
	isa_ok($message,'Mail::Outlook::Message');

    my $cwd = getcwd;
   	$message->Attach("$cwd/MANIFEST","$cwd/Changes","$cwd/t/13attachments.t");
    is($message->display(),1,'displayed message - 3 attachments');

   	$message->Attach("$cwd/t/01load.t");
   	$message->Body('There should be 4 separate attachments with this mail. If you can see this mail, all well and good. You can close it now :)');
    is($message->display(),1,'displayed message - 4 attachments');

    $message->delete_message;
}

};

if($@ =~ /Network problems/) {
	skip "Microsoft Outlook cannot connect to the server.\n", $tests;
	exit;
}
