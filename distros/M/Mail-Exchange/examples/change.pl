#!/usr/bin/perl
# This will read a msg file, add a recipient, change the displayed
# recipient list, and save the resulting message to a different file,
# which can then be opened by Outlook.

use Mail::Exchange::Message;
use Mail::Exchange::Recipient;


my $message=Mail::Exchange::Message->new("t/minimal.msg");
$message->setDisplayTo('john@doe.com; destination@somewhere.com');

my $recipient=Mail::Exchange::Recipient->new();

$recipient->setEmailAddress('john@doe.com');
$recipient->setDisplayName('John Doe <john@doe.com>');

$message->addrecipient($recipient);
$message->save("changedmessage.msg");
