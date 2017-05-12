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
		Subject	=> 'Display Test for Mail::Outlook',
		Body	=> 'If you can see this mail, all well and good. You can close it now :)',
  	);

    {   # To missing
        my $outlook = Mail::Outlook->new();
        my $message = $outlook->create(Subject => 'Hello', Body => 'World');
        isa_ok($message,'Mail::Outlook::Message');
        is($message->display(),0,'message not displayed - missing To');
    }
    {   # Subject missing
        my $outlook = Mail::Outlook->new();
        my $message = $outlook->create(To => 'you@example.com', Body => 'World');
        isa_ok($message,'Mail::Outlook::Message');
        is($message->display(),0,'message not displayed - missing Subject');
    }
    {   # Body missing
        my $outlook = Mail::Outlook->new();
        my $message = $outlook->create(To => 'you@example.com', Subject => 'Hello');
        isa_ok($message,'Mail::Outlook::Message');
        is($message->display(),0,'message not displayed - missing Body');
    }

    {
        my $outlook = Mail::Outlook->new();
        my $message = $outlook->create(%hash);
        isa_ok($message,'Mail::Outlook::Message');
        is($message->display(),1,'displayed message');

        $message->delete_message;
    }
}

};

if($@ =~ /Network problems/) {
	skip "Microsoft Outlook cannot connect to the server.\n", $tests;
	exit;
}
