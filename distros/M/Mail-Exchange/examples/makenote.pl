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
