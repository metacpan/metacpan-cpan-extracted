#!/usr/bin/perl
use lib "lib", "t";
use MIME::Lite;
use Test::More tests => 2;
use Utils;

$MIME::Lite::VANILLA  = 1;
$MIME::Lite::PARANOID = 1;

my $msg;

$msg  = MIME::Lite->new(From => "me", To => "you");
$msg->attach(Path => "boguscmd |");
$msg->attach(Data => "Hello");
$msg->attach(Path => "<path.to.missing.file");
eval { $msg->verify_data };

like($@, qr/path\.to\.missing\.file/, "we detected a missing file");

$msg  = MIME::Lite->new(From=>"me", To=>"you");
$msg->attach(Data => "Hello");
eval { $msg->verify_data };

ok(!$@, "we detected NO missing file");
