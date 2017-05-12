#!/usr/bin/perl

# Create a new appointment from scratch. Note the email addresses have to be
# valid for your Exchange server, or Outlook will refuse opening the
# created file.

use Mail::Exchange::PidTagIDs;
use Mail::Exchange::PidLidIDs;
use Mail::Exchange::Message::Appointment;
use Mail::Exchange::Message::MessageFlags;
use Mail::Exchange::Message::RecipientFlags;
use Mail::Exchange::Recipient;
use Mail::Exchange::Time qw(mstime_to_unixtime unixtime_to_mstime);

my $message=Mail::Exchange::Message::Appointment->new();

$message->setUnicode(1);
$message->setSender('john@doe.com');
$message->setDisplayTo("Doe, John, Dae, Jane");

$message->setSubject("trying out Outlook appointments");
$message->setBody("hello world");

$message->setStart(unixtime_to_mstime(time+2*3600));
$message->setEnd(unixtime_to_mstime(time+3*3600));

$message->set(PidLidReminderSignalTime, unixtime_to_mstime(time+2*3600-15*60));

$message->set(PidTagMessageFlags, mfUnsent);

my $recipient=Mail::Exchange::Recipient->new();
$recipient->setEmailAddress('john@doe.com');
$recipient->setDisplayName('Doe, John');
$recipient->set(PidTagRecipientFlags, recipSendable | recipOrganizer);
$message->addRecipient($recipient);

my $recipient=Mail::Exchange::Recipient->new();
$recipient->setEmailAddress('jane@dae.com');
$recipient->setDisplayName('Dae, Jane');
$recipient->set(PidTagRecipientFlags, recipSendable);
$message->addRecipient($recipient);

$message->save("appointment.msg");
