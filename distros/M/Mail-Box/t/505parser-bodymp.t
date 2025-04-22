#!/usr/bin/env perl
#
# Test the reading from file of message bodies which are multiparts
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Parser::Perl;
use Mail::Message::Body::Lines;
use Mail::Message::Body::Multipart;
use Mail::Message::Head;

use Test::More tests => 313;


my $getbodytype = sub {'Mail::Message::Body::Lines'};

###
### First pass through all messages, with correct data, if available
###

my $parser = Mail::Box::Parser::Perl->new(filename  => $src);
ok(defined $parser,                "creation of parser");

$parser->pushSeparator('From ');

my (@msgs, $msgnr);

while(1)
{   my (undef, $sep) = $parser->readSeparator;
    last unless $sep;

    $msgnr++;
    my $count = @msgs;
    like($sep, qr/^From /,                     "1 from $count");

    my $head = Mail::Message::Head->new;
    ok(defined $head,                          "1 head count");

    $head->read($parser);

    my $cl    = int $head->get('Content-Length');
    my $li    = int $head->get('Lines');

    unless($head->isMultipart)
    {   # Skip non-multipart
        Mail::Message::Body::Lines->new->read($parser, $head, undef, $cl, $li);
        next;
    }

    my $message;
    my $body = Mail::Message::Body::Multipart->new(message => \$message);

    my $mp = $head->get('Content-Type')->comment;
    if($mp =~ m/['"](.*?)["']/)
    {   $body->boundary($1);
    }

    $body->read($parser, $head, $getbodytype, $cl, $li);
    ok(defined $body,                          "1 body $count");

    my $size  = $body->size;
    my $lines = $body->nrLines;
    my $su    = $head->get('Subject');

    cmp_ok($lines, "==",  $li,                 "1 lines $count")
        if defined $li;

    $cl -= $li if $crlf_platform;
    cmp_ok($size , "==",  $cl,                 "1 size $count")
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

cmp_ok(@msgs, "==", 3);
$parser->stop;

###
### Now read the whole folder again, but without help of content-length
### and nor lines.
###

undef $parser;

$parser = Mail::Box::Parser::Perl->new(filename => $src);
$parser->pushSeparator('From ');

my $count = 0;
while(1)
{   my (undef, $sep) = $parser->readSeparator;
    last unless $sep;

    like($sep, qr/^From /,                      "2 from $count");

    my $head = Mail::Message::Head->new->read($parser);
    ok(defined $head,                           "2 head $count");

    unless($head->isMultipart)
    {   # Skip non-multipart
        Mail::Message::Body::Lines->new->read($parser, $head, undef);
        next;
    }
    my $msg = $msgs[$count];

    my $message;
    my $body = Mail::Message::Body::Multipart->new(message => \$message);
    ok(defined $body,                           "2 body $count");

    my $mp = $head->get('Content-Type')->comment;
    if($mp =~ m/['"](.*?)["']/)
    {   $body->boundary($1);
    }

    $body->read($parser, $head, $getbodytype);

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

$parser = Mail::Box::Parser::Perl->new(filename => $src);
$parser->pushSeparator('From ');

$count = 0;
while(1)
{   my (undef, $sep) = $parser->readSeparator;
    last unless $sep;

    like($sep, qr/^From /,                       "3 From $count");

    my $head = Mail::Message::Head->new->read($parser);
    ok(defined $head,                            "3 Head $count");

    unless($head->isMultipart)
    {   # Skip non-multipart
        Mail::Message::Body::Lines->new->read($parser, $head, undef);
        next;
    }

    my $msg  = $msgs[$count];
    my $message;
    my $body = Mail::Message::Body::Multipart->new(message => \$message);
    ok(defined $body,                            "3 Body $count");

    my $mp = $head->get('Content-Type')->comment;
    if($mp =~ m/['"](.*?)["']/)
    {   $body->boundary($1);
    }

    $body->read($parser, $head, $getbodytype, $msg->{size}-15, $msg->{lines}-3);

    my $su    = $head->get('Subject');
    my $size  = $body->size;
    my $lines = $body->nrLines;

    cmp_ok($size, '==', $msg->{size},            "3 size $count");
    cmp_ok($lines, '==', $msg->{lines},          "3 lines $count");

    is($su, $msg->{subject}, "3 subject $count")
        if defined $su && defined $msg->{subject};

    cmp_ok($head->names, '==', $msg->{fields},   "3 name $count");
    is($sep, $msg->{sep},                        "3 sep $count");

    $count++;
}

