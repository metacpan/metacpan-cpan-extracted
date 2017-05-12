#!/usr/bin/env perl
#
# Test the reading from file of message bodies which have their content
# stored in external files as long as the folder is open.

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Parser::Perl;
use Mail::Message::Body::File;
use Mail::Message::Head;

use Test::More tests => 945;


# MO: I do not know whether there is an other way to get this to work
# on Windows without error messages.
my $trusted = $Mail::Message::crlf_platform;

###
### First carefully read the first message
###

my $parser = Mail::Box::Parser::Perl->new(filename => $src, trusted =>$trusted);
ok(defined $parser,                "creation of parser");

$parser->pushSeparator('From ');
my ($where, $sep) = $parser->readSeparator;
cmp_ok($where, "==", 0,            "begin at file-start");
ok(defined $sep,                   "reading first separator");

like($sep, qr/^From /,             "correctness first separator")
    if defined $sep;

my $head = Mail::Message::Head->new;
ok(defined $head);

$head->read($parser);
ok(defined $head);
ok($head,                          "overloaded boolean");

my $hard_coded_lines_msg0  = 33;
my $hard_coded_length_msg0 = 1280;

my $binary_size = $hard_coded_length_msg0
      + ($crlf_platform ? $hard_coded_lines_msg0 : 0);

my $length = int $head->get('Content-Length');
cmp_ok($length, "==", $binary_size, "first message size");

my $lines  = int $head->get('Lines');
cmp_ok($lines, "==", $hard_coded_lines_msg0,   "first message lines");

my $body = Mail::Message::Body::File->new;
$body->read($parser, $head, undef, $length, $lines);
ok(defined $body,                    "reading of first body");

cmp_ok($body->size, "==", $hard_coded_length_msg0,   "size of body");
my @lines = $body->lines;
cmp_ok(@lines, "==", $lines,         "lines of body");

#
# Try to read the rest of the folder, with specified content-length
# and lines if available.
#

my @msgs;

push @msgs,  # first message already read.
 { fields => scalar $head->names
 , lines  => $hard_coded_lines_msg0
 , size   => $hard_coded_length_msg0
 , sep    => $sep
 , subject=> $head->get('subject')
 };

while(1)
{   my ($where, $sep) = $parser->readSeparator;
    last unless $sep;

    my $count = @msgs;
    like($sep, qr/^From /,                     "1 from $count");

    $head = Mail::Message::Head->new;
    ok(defined $head,                          "1 head count");

    $head->read($parser);

    my $cl    = int $head->get('Content-Length');
    my $li    = int $head->get('Lines');
    my $su    = $head->get('Subject');

    $body = Mail::Message::Body::File->new
        ->read($parser, $head, undef, $cl, $li);
    ok(defined $body,                          "1 body $count");

    my $size  = $body->size;
    my $lines = $body->nrLines;

    cmp_ok($li , "==",  $lines,                "1 lines $count")
        if defined $li;

    $cl -= $li if $crlf_platform;
    cmp_ok($cl , "==",  $size,                 "1 size $count")
        if defined $cl;

    my $msg = 
     { size   => $size
     , lines  => $lines
     , fields => scalar $head->names
     , sep    => $sep
     , subject=> $su
     };

    push @msgs, $msg;
}

cmp_ok(@msgs, "==", 45);
$parser->stop;

###
### Now read the whole folder again, but without help of content-length
### and nor lines.
###

undef $parser;

$parser = Mail::Box::Parser::Perl->new(filename => $src, trusted => $trusted);
$parser->pushSeparator('From ');

my $count = 0;
while($sep = $parser->readSeparator)
{   my $msg = $msgs[$count];

    like($sep, qr/^From /,                      "2 from $count");

    $head     = Mail::Message::Head->new->read($parser);
    ok(defined $head,                           "2 head $count");

    $body = Mail::Message::Body::File->new->read($parser, $head, undef);
    ok(defined $body,                           "2 body $count");

    my $su    = $head->get('Subject');
    my $size  = $body->size;
    my $lines = $body->nrLines;

    cmp_ok($size, "==",  $msg->{size},           "2 size $count");
    cmp_ok($lines, "==",  $msg->{lines},         "2 lines $count");

    is($su, $msg->{subject},                     "2 subject $count")
        if defined $su && defined $msg->{subject};

    cmp_ok($head->names , "==",  $msg->{fields}, "2 names $count");
    is($sep, $msg->{sep},                        "2 sep $count");

    $count++;
}

$parser->stop;

###
### Now read the whole folder again, but with deceiving values for
### content-length and lines
###

undef $parser;

$parser = Mail::Box::Parser::Perl->new(filename => $src, trusted => $trusted);
$parser->pushSeparator('From ');

$count = 0;
while(1)
{   my ($where, $sep) = $parser->readSeparator;
    last unless $sep;

    my $msg = $msgs[$count];

    like($sep, qr/^From /,                       "3 From $count");

    $head     = Mail::Message::Head->new->read($parser);
    ok(defined $head,                            "3 Head $count");

    $body = Mail::Message::Body::File->new;
    $body->read($parser, $head, undef, $msg->{size}-15, $msg->{lines}-3);
    ok(defined $body,                            "3 Body $count");

    my $su    = $head->get('Subject');
    my $size  = $body->size;
    my $lines = $body->nrLines;

    # two messages contain one trailing blank, which is removed because
    # of the wrong number of lines.  The will have an extra OK.
    my $wrong = $count==14 || $count==18;

    cmp_ok($size, '==', $msg->{size},            "3 size $count")
        unless $wrong;

    cmp_ok($lines, '==', $msg->{lines},          "3 lines $count")
        unless $wrong;

    is($su, $msg->{subject}, "3 subject $count")
        if defined $su && defined $msg->{subject};

    cmp_ok($head->names, '==', $msg->{fields},   "3 name $count");
    is($sep, $msg->{sep},                        "3 sep $count");

    $count++;
}

