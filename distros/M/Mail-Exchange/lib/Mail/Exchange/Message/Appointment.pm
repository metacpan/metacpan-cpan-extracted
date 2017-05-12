package Mail::Exchange::Message::Appointment;

use Mail::Exchange::PidTagIDs;
use Mail::Exchange::PidLidIDs;
use Mail::Exchange::Message;
use Mail::Exchange::Recipient;
use Email::Address;

=head1 NAME

Mail::Exchange::Message::Appointment - subclass of Mail::Exchange::Message
that initializes Appointment-specific fields

=head1 SYNOPSIS

    use Mail::Exchange::Message::Appointment;

    $mail=Mail::Exchange::Message::Appointment->new();

=head1 DESCRIPTION

Mail::Exchange::Message::Appointment is a utility class derived from
Mail::Exchange::Message. When creating a new message object, it sets the
Message Class to "IPM.Appointment" to mark this message as an email object.

=head1 EXAMPLE

The following example creates an appointment with one organizer
(john doe) and one participant (jane dae). Be aware that Outlook needs
to be able to resolve the addresses within the current exchange server
address list, so you will have to adapt the addresses to existing
local users, or Outlook will refuse to open the .msg file, complaining
about unresolvable email addresses.

    #!/usr/bin/perl
    
    use Mail::Exchange::PidTagIDs;
    use Mail::Exchange::PidLidIDs;
    use Mail::Exchange::Message::Appointment;
    use Mail::Exchange::Message::MessageFlags;
    use Mail::Exchange::Message::RecipientFlags;
    use Mail::Exchange::Recipient;
    use Mail::Exchange::Time qw(mstime_to_unixtime unixtime_to_mstime);
    
    my $message=Mail::Exchange::Message::Appointment->new();
    
    $message->setUnicode(1);
    $message->setSender('john@example.com');
    $message->setDisplayTo("Doe, John; Dae, Jane");
    
    $message->setSubject("trying out Outlook appointments");
    $message->setBody("hello world");
    # Set the start time to 2 hours from now, and end time to 3 hours from now.
    $message->setStart(unixtime_to_mstime(time+2*3600));
    $message->setEnd(unixtime_to_mstime(time+3*3600));
    # Reminder 15 minutes before start.
    $message->set(PidLidReminderSignalTime,
    	unixtime_to_mstime(time+2*3600-15*60));
    
    $message->set(PidTagMessageFlags, mfUnsent);
    
    my $recipient=Mail::Exchange::Recipient->new();
    $recipient->setEmailAddress('john@example.com');
    $recipient->setDisplayName('Doe, John');
    # Mark John Doe as Organizer
    $recipient->set(PidTagRecipientFlags, recipSendable | recipOrganizer);
    $message->addRecipient($recipient);
    
    my $recipient=Mail::Exchange::Recipient->new();
    $recipient->setEmailAddress('jane@example.com');
    $recipient->setDisplayName('Dae, Jane');
    $recipient->set(PidTagRecipientFlags, recipSendable);
    $message->addRecipient($recipient);
    
    $message->save("appointment.msg");

=head1 METHODS
    
=cut

use strict;
use warnings;
use 5.008;

use Exporter;

use vars qw($VERSION @ISA);
@ISA=qw(Mail::Exchange::Message Exporter);

$VERSION="0.04";

=head2 new()

$msg=Mail::Exchange::Message::Appointment->new();

Create a new message object and initialize it to an appointment.
=cut

sub new {
	my $class=shift;
	my $self=Mail::Exchange::Message->new();
	$self->set(PidTagMessageClass, "IPM.Appointment");
	bless $self;
}

=head2 parse()

The parse() method is overwritten to abort, because the message type will be
read from the input file, so a plain Mail::Exchange::Message object should
be used in this case.

=cut

sub parse {
	die("parse not supported, use a Mail::Exchange::Message object");
}

=head2 setStart() 

setStart(time)

setStart sets various properties that should all contain the start date
of the appointment. C<time> must be given in microsoft format, see
C<Mail::Exchange::Time::unixtime_to_mstime>.

=cut

sub setStart {
	my $self=shift;
	my $time=shift;
	$self->set(PidTagStartDate, $time);
	$self->set(PidLidAppointmentStartWhole, $time);
	$self->set(PidLidClipStart, $time);
	$self->set(PidLidCommonStart, $time);
}

=head2 setEnd() 

setEnd(time)

setEnd sets various properties that should all contain the end date
of the appointment. C<time> must be given in microsoft format, see
C<Mail::Exchange::Time::unixtime_to_mstime>.

=cut

sub setEnd {
	my $self=shift;
	my $time=shift;
	$self->set(PidTagEndDate, $time);
	$self->set(PidLidAppointmentEndWhole, $time);
	$self->set(PidLidClipEnd, $time);
	$self->set(PidLidCommonEnd, $time);
	# This is the time the reminder should remind about,
	# not the time the alarm should go off
	# (that one is in PidLidReminderSignalTime).
	$self->set(PidLidReminderTime, $time);
}
