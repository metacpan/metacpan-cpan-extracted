#!/usr/bin/perl -w
use strict;

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

	my %hash = (
		To		=> 'you@example.com',
		Cc		=> 'Them <them@example.com>',
		Bcc		=> 'Us <us@example.com>; anybody@example.com',
		Subject	=> 'Send Test for Mail::Outlook',
		Body	=> 'You shouldnt see this mail, if you do then just close it :)',
  	);

    {   # To missing
        my $outlook = Mail::Outlook->new();
        my $message = $outlook->create(Subject => 'Hello', Body => 'World');
        isa_ok($message,'Mail::Outlook::Message');
        is($message->send(),0,'message not displayed - missing To');
    }
    {   # Subject missing
        my $outlook = Mail::Outlook->new();
        my $message = $outlook->create(To => 'you@example.com', Body => 'World');
        isa_ok($message,'Mail::Outlook::Message');
        is($message->send(),0,'message not displayed - missing Subject');
    }
    {   # Body missing
        my $outlook = Mail::Outlook->new();
        my $message = $outlook->create(To => 'you@example.com', Subject => 'Hello');
        isa_ok($message,'Mail::Outlook::Message');
        is($message->send(),0,'message not displayed - missing Body');
    }

    {
        my $outlook = Mail::Outlook->new();
        my $message = $outlook->create(%hash);
        isa_ok($message,'Mail::Outlook::Message');
        my $res = $message->send();
        if($res == 1) {
            ok(1,'sent message');
        } elsif($res == 2) {
            ok(1,'message was cancelled by user');
        } else {
            is($res,1,'something went wrong!');
        }
    }
}

};

if($@ =~ /Network problems/) {
	skip "Microsoft Outlook cannot connect to the server.\n", $tests;
	exit;
}
