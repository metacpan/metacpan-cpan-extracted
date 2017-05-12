#!/usr/bin/perl
use lib "lib", "t";
use MIME::Lite;
use ExtUtils::TBone;
use Utils;

# Make a tester... here are 3 different alternatives:
my $T = typical ExtUtils::TBone;                 # standard log
$MIME::Lite::VANILLA  = 1;
$MIME::Lite::PARANOID = 1;

# Begin testing:
$T->begin(2);

my $msg;

$msg  = MIME::Lite->new(From=>"me", To=>"you", Data=>"original text");
$msg->attach(Data => "attachment 1");
$msg->attach(Data => "attachment 2");
my $part = $msg->attach(Data => "attachment 3");
$part->attach(Data => "attachment 4");
$part->attach(Data => "attachment 5");

$T->msg("The message:\n".$msg->stringify);

$T->ok_eqnum(int($msg->parts), 4,
	     "Does parts() work?");

$T->ok_eqnum(int($msg->parts_DFS), 7,
	     "Does parts_DFS() work?");

$T->end;





