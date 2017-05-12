#!perl -T

use Test::More tests => 26;
use MMS::Mail::Message::Parsed;

my $message = new MMS::Mail::Message::Parsed;

is($message->header_datetime("Somedate"),"Somedate");
is($message->header_subject("Subject"),"Subject");
is($message->header_from("From"),"From");
is($message->header_to("To"),"To");
is($message->body_text("Text"),"Text");

is($message->header_datetime,"Somedate");
is($message->header_subject,"Subject");
is($message->header_from,"From");
is($message->header_to,"To");
is($message->body_text,"Text");

is_deeply($message->retrieve_attachments,[]);

is($message->phone_number("00000000000"),"00000000000");

is($message->strip_characters("\n"),"\n");

is($message->header_datetime("Somedate\n"),"Somedate");
is($message->header_subject("Subject\n"),"Subject");
is($message->header_from("From\n"),"From");
is($message->header_to("To\n"),"To");
is($message->body_text("Text\n"),"Text");

is($message->header_datetime,"Somedate");
is($message->header_subject,"Subject");
is($message->header_from,"From");
is($message->header_to,"To");
is($message->body_text,"Text");

$message->cleanse_map(undef);
$message->strip_characters('');

my $map = {     header_subject => 's/\n//g',
                body_text => 's/\n//g'
                };
$message->cleanse_map($map);

is($message->header_subject("Subject\n"),"Subject");
is($message->body_text("Text\n"),"Text");

$message->cleanse_map( {header_subject => sub { return "rob" }});
is($message->header_subject("Subject\n"),"rob");

