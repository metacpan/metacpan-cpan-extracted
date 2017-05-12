#!/usr/bin/perl -w
use strict;

use Test::More tests => 6;
	
use lib 't/testlib';

my $tests = 6;

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
		Subject	=> 'Blah Blah Blah',
		Body	=> 'Yadda Yadda Yadda',
  	);

	my $outlook = Mail::Outlook->new();
	my $message = $outlook->create(%hash);
	isa_ok($message,'Mail::Outlook::Message');

	is($message->To(),'you@example.com');
	is($message->Cc(),'Them <them@example.com>');
	is($message->Bcc(),'Us <us@example.com>; anybody@example.com');
	is($message->Subject(),'Blah Blah Blah');
	is($message->Body(),'Yadda Yadda Yadda');
}

};

if($@ =~ /Network problems/) {
	skip "Microsoft Outlook cannot connect to the server.\n", $tests;
	exit;
}
