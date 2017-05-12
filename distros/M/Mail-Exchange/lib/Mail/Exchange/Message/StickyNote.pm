package Mail::Exchange::Message::StickyNote;

use Mail::Exchange::PidTagIDs;
use Mail::Exchange::PidLidIDs;
use Mail::Exchange::Message;
use Mail::Exchange::Recipient;
use Email::Address;

=head1 NAME

Mail::Exchange::Message::StickyNote - subclass of Mail::Exchange::Message
that initializes StickyNote-specific fields

=head1 SYNOPSIS

    use Mail::Exchange::Message::StickyNote;

    $mail=Mail::Exchange::Message::StickyNote->new();

=head1 DESCRIPTION

Mail::Exchange::Message::StickyNote is a utility class derived from
Mail::Exchange::Message. When creating a new message object, it sets the
Message Class to "IPM.StickyNote" to mark this message as a sticky note
object.

=head1 EXAMPLE

    #!/usr/bin/perl
    
    use Mail::Exchange::PidLidIDs;
    use Mail::Exchange::Message::StickyNote;
    
    my $note=Mail::Exchange::Message::StickyNote->new();
    
    $note->setUnicode(1);
    
    $note->setBody("hello world");
    $note->setColor('blue');
    $note->set(PidLidNoteWidth, 600);
    $note->set(PidLidNoteHeight, 400);
    $note->set(PidLidNoteX, 100);
    $note->set(PidLidNoteY, 200);
    
    $note->save("mynote.msg");

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

$msg=Mail::Exchange::Message::StickyNote->new();

Create a new message object and initialize it to a sticky note.
=cut

sub new {
	my $class=shift;
	my $self=Mail::Exchange::Message->new();
	$self->set(PidTagMessageClass, "IPM.StickyNote");
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


=head2 setColor()

The setColor method sets the PidLidNoteColor property. It understands
color IDs as well as the color names defined in MS-OXONOTE 2.2.1.1,
which are blue, green, pink, yellow, and white.
Also, it sets the PidTagIconIndex property to C<color>+0x300, as
required by MS-OXONOTE 2.2.2.2.

=cut

my %colors=(blue => 0, green => 1, pink => 2, yellow => 3, white => 4);

sub setColor {
	my $self=shift;
	my $color=shift;
	$color=$colors{lc $color} if defined $colors{lc $color};
	$self->set(PidLidNoteColor, $color);
	$self->set(PidTagIconIndex, $color+0x300);
}
