#!perl -T

use Test::More tests => 29;
use MMS::Mail::Message;

my $mms = new MMS::Mail::Message;

is($mms->header_datetime("Somedate\n"),"Somedate\n");
is($mms->header_subject("Subject\n"),"Subject\n");
is($mms->header_from("From\n"),"From\n");
is($mms->header_to("To\n"),"To\n");
is($mms->header_received_from("Received From\n"),"Received From\n");
is($mms->body_text("Text\n"),"Text\n");

is($mms->header_datetime,"Somedate\n");
is($mms->header_subject,"Subject\n");
is($mms->header_from,"From\n");
is($mms->header_to,"To\n");
is($mms->header_received_from,"Received From\n");
is($mms->body_text,"Text\n");

is($mms->strip_characters("\n"),"\n");

is($mms->header_datetime("Somedate\n"),"Somedate");
is($mms->header_subject("Subject\n"),"Subject");
is($mms->header_from("From\n"),"From");
is($mms->header_to("To\n"),"To");
is($mms->header_received_from("Received From\n"),"Received From");
is($mms->body_text("Text\n"),"Text");

is($mms->header_datetime,"Somedate");
is($mms->header_subject,"Subject");
is($mms->header_from,"From");
is($mms->header_to,"To");
is($mms->header_received_from,"Received From");
is($mms->body_text,"Text");

my $attach = [];
is($mms->attachments($attach),$attach);

$mms->cleanse_map(undef);
$mms->strip_characters('');

my $map = { 	header_subject => 's/\n//g',
		body_text => 's/\n//g'
		};
$mms->cleanse_map($map);

is($mms->header_subject("Subject\n"),"Subject");
is($mms->body_text("Text\n"),"Text");

$mms->cleanse_map( {header_subject => sub { return "rob" }});
is($mms->header_subject("Subject\n"),"rob");

