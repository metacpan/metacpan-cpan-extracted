#!/usr/bin/env perl
#
# Test body-structure capturing for IMAP servers

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Message;
use Mail::Message::Body::Lines;
use Mail::Server::IMAP4::Fetch;

use Test::More tests => 44;

my $msif = 'Mail::Server::IMAP4::Fetch';

my $msg = Mail::Message->build
 ( From    => 'I myself and me <me@localhost>'
 , To      => 'you@example.com'
 , Date    => 'now'
 , Subject => 'Life of Brian'
 , 'Message-ID' => 'unique'

 , data    => [ "two\n", "lines\n" ]
 );

ok($msg, "First, simple message built");

my $f = $msif->new($msg);
isa_ok($f, $msif);
ok($f->part() == $f);
ok(!defined $f->part('1'));

#use Data::Dumper;
#print Dumper $f;

is($f->fetchBody(0)."\n", <<__BODY, '...body');
("TEXT" "PLAIN" ("charset" "utf-8") "<unique>" NIL "8BIT" 10 2)
__BODY

is($f->fetchBody(1)."\n", <<__BODYSTRUCT, '...bodystruct');
("TEXT" "PLAIN" ("charset" "utf-8") "<unique>" NIL "8BIT" 10 2 NIL ("inline") NIL)
__BODYSTRUCT

is($f->fetchEnvelope."\n", <<__ENVELOPE, '...envelope');
("now" "Life of Brian" ("I myself and me" NIL "me" "localhost") NIL NIL (NIL NIL "you" "example.com") NIL NIL NIL "<unique>")
__ENVELOPE

#
# Simple multipart
#

my $data = Mail::Message::Body::Lines->new
 ( mime_type => 'audio/mpeg3'
 , transfer_encoding => 'base64'
 , charset   => 'utf8'
 , data      => "ABBA\n"
 );

my $mp = Mail::Message->build
 ( From      => 'me'
 , Date      => 'now'
 , Subject   => 'multi'
 , 'Message-ID' => 'unique'

 , data      => [ "two\n", "lines\n" ]
 , attach    => $data
 );

ok(defined $mp, "Simple multipart");

$f = $msif->new($mp);
isa_ok($f, $msif);

ok($f->part() == $f);

is($f->fetchBody(0)."\n", <<__BODY, '...body');
(("TEXT" "PLAIN" ("charset" "utf-8") NIL NIL "8BIT" 10 2)("AUDIO" "MPEG3" () NIL NIL "BASE64" 5 1) "MIXED")
__BODY

is($f->fetchBody(1)."\n", <<__BODYSTRUCT, '...bodystruct');
(("TEXT" "PLAIN" ("charset" "utf-8") NIL NIL "8BIT" 10 2 NIL ("inline") NIL)("AUDIO" "MPEG3" () NIL NIL "BASE64" 5 1 NIL ("attachment") NIL) "MIXED")
__BODYSTRUCT

is($f->fetchEnvelope."\n", <<__ENVELOPE, '...envelope');
("now" "multi" NIL NIL NIL NIL NIL NIL NIL "<unique>")
__ENVELOPE

ok($f->part('1'), "Has two parts");
ok($f->part('2'));
ok(!$f->part('3'));
ok(!$f->part('1.1'));

my $g = $f->part('2');
isa_ok($g, $msif);

is($g->fetchBody(0)."\n", <<__BODY, '...body');
("AUDIO" "MPEG3" () NIL NIL "BASE64" 5 1)
__BODY

is($g->fetchBody(1)."\n", <<__BODYSTRUCT, '...bodystruct');
("AUDIO" "MPEG3" () NIL NIL "BASE64" 5 1 NIL ("attachment") NIL)
__BODYSTRUCT

is($g->fetchEnvelope."\n", <<__ENVELOPE, '...envelope');
(NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL)
__ENVELOPE

#
# All fields in an envelope
#

                                                                                
my $a = Mail::Message->build
 ( From => 'FROM <from@from.home>'
 , To   => 'TO <to@to.home>'
 , Cc   => 'CC <cc@cc.home>'
 , Bcc  => 'BCC <bcc@bcc.home>'
 , Sender => 'SENDER <sender@sender.home>'
 , 'Reply-To' => 'RT <replyto@rt.home>'
 , Date => 'today'
 , Subject => 'subject'
 , 'Content-Type' => 'video/vhs'
 , 'Content-Disposition' => 'attachment; filename="private-video.ras"; size=100'
 , 'Content-Language' =>  'nl-NL, nl-BE'
 , 'Content-Description' => 'blue movie'
 , 'Message-ID' => 'unique-id-123'
 , data => "BINARY data for video"
 );

ok(defined $a, "Full envelope");
#$a->print(\*STDERR);

##### get should become study
## my $s = $a->study('Content-Disposition');
## isa_ok($s, 'Mail::Message::Field::Structured');

my $s = $a->head->get('Content-Disposition');
isa_ok($s, 'Mail::Message::Field');

is($s->attribute('filename'), 'private-video.ras', '...one attr');
my %attrs = $s->attributes;
cmp_ok(keys %attrs, '==', 2, '...nr attrs');
is($attrs{filename}, 'private-video.ras', '...filename');
is($attrs{size}, 100, '...size');

$f = $msif->new($a);
isa_ok($f, $msif);

is($f->fetchBody(0)."\n", <<__BODY, "...body");
("VIDEO" "VHS" () "<unique-id-123>" "blue movie" "BASE64" 29 1)
__BODY

is($f->fetchBody(1)."\n", <<__BODYSTRUCT, "...bodystruct");
("VIDEO" "VHS" () "<unique-id-123>" "blue movie" "BASE64" 29 1 NIL ("attachment" "filename" "private-video.ras" "size" "100") "nl-NL, nl-BE")
__BODYSTRUCT

is($f->fetchEnvelope."\n", <<__ENVELOPE, "...envelope");
("today" "subject" ("FROM" NIL "from" "from.home") ("SENDER" NIL "sender" "sender.home") ("RT" NIL "replyto" "rt.home") ("TO" NIL "to" "to.home") ("CC" NIL "cc" "cc.home") ("BCC" NIL "bcc" "bcc.home") NIL "<unique-id-123>")
__ENVELOPE

#
# Nested
#

my $b = Mail::Message->build
 ( To => 'someelse@somewhere.aq'
 , 'Message-Id' => 'newid'
 , Date   => 'tomorrow'
 , attach => $msg
 );

ok(defined $b, "Constructed nested message");

isa_ok($b, 'Mail::Message');
ok($b->isNested, 'check structure');

$f = $msif->new($b);
isa_ok($f, $msif);

#$b->print(\*STDERR);

is($f->fetchBody(0)."\n", <<__BODY, "...body");
("MESSAGE" "RFC822" () "<newid>" NIL "8BIT" 212 ("now" "Life of Brian" ("I myself and me" NIL "me" "localhost") NIL NIL (NIL NIL "you" "example.com") NIL NIL NIL "<unique>") ("TEXT" "PLAIN" ("charset" "utf-8") "<unique>" NIL "8BIT" 10 2) 11)
__BODY

is($f->fetchBody(1)."\n", <<__BODYSTRUCT, "...bodystruct");
("MESSAGE" "RFC822" () "<newid>" NIL "8BIT" 212 ("now" "Life of Brian" ("I myself and me" NIL "me" "localhost") NIL NIL (NIL NIL "you" "example.com") NIL NIL NIL "<unique>") ("TEXT" "PLAIN" ("charset" "utf-8") "<unique>" NIL "8BIT" 10 2 NIL ("inline") NIL) 11 NIL ("inline") NIL)
__BODYSTRUCT

is($f->fetchEnvelope."\n", <<__ENVELOPE, "...envelope");
("tomorrow" NIL NIL NIL NIL (NIL NIL "someelse" "somewhere.aq") NIL NIL NIL "<newid>")
__ENVELOPE

#$b->print(\*STDERR);

$g = $f->part('1');
ok(defined $g, "nested info");

isa_ok($g, $msif);
ok($f != $g);

is($g->fetchBody(0)."\n", <<__BODY, "...body");
("TEXT" "PLAIN" ("charset" "utf-8") "<unique>" NIL "8BIT" 10 2)
__BODY

is($g->fetchBody(1)."\n", <<__BODYSTRUCT, "...bodystruct");
("TEXT" "PLAIN" ("charset" "utf-8") "<unique>" NIL "8BIT" 10 2 NIL ("inline") NIL)
__BODYSTRUCT

is($g->fetchEnvelope."\n", <<__ENVELOPE, "...envelope");
("now" "Life of Brian" ("I myself and me" NIL "me" "localhost") NIL NIL (NIL NIL "you" "example.com") NIL NIL NIL "<unique>")
__ENVELOPE

