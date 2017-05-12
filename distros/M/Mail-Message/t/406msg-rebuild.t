#!/usr/bin/env perl
#
# Test rebuilding existing messages
#

use strict;
use warnings;

use Mail::Message;
use Mail::Message::Test;
use Mail::Message::Construct::Rebuild;

use Test::More;


my $has_htmlFormatText;

BEGIN {
   eval "require Mail::Message::Convert::HtmlFormatText";
   $has_htmlFormatText = not $@;
   plan tests => 55 + ($has_htmlFormatText ? 6 : 1);
}

#
# First, produce a single level multipart message to rebuild
#

my $message = Mail::Message->build
 ( To      => 'me@example.com (Me the receiver)'
 , From    => 'him@somewhere.else.nl (Original Sender)'
 , Subject => 'Test of rebuild'
 , Date    => 'Wed, 9 Feb 2000 15:44:05 -0500'

 , data     => "part 1\n"
 , data     => "part 2\n"
 );

ok(defined $message,             "build success");
ok($message->isMultipart,        "have a multipart");
cmp_ok($message->parts, '==', 2, "have two parts");

#
# Test the deletion of parts in a 1 level multipart
#

my $rebuild = $message->rebuild;
ok(defined $rebuild,             "rebuild success");
ok($rebuild==$message,           "message unchanged");

my $part = $message->body->part(0);
$part->delete;
ok($part->isDeleted,             "delete first part");

# test to keep level with one multipart

$rebuild = $message->rebuild(
  rules => [ qw/removeDeletedParts descendMultiparts/ ]);

ok(defined $rebuild,             "rebuild success");
ok($rebuild!=$message,           "message has changed");
ok($rebuild->isMultipart,        "still has a multipart");
cmp_ok($rebuild->body->parts, '==', 1, "has only one part left");
cmp_ok($message->body->parts, '==', 2, "original still has two parts");
is($rebuild->body->mimeType, 'multipart/mixed');

# test remove multipart level when only one is left

$rebuild = $message->rebuild
 ( extraRules => [ qw/removeDeletedParts removeEmptyMultiparts/ ]
 );
ok(defined $rebuild,             "rebuild success");
ok($rebuild!=$message,           "message has changed");
ok(! $rebuild->isMultipart,      "multipart level removed");
cmp_ok($message->body->parts, '==', 2, "original still has two parts");
is($rebuild->body->string, "part 2\n",   "text found");
is($rebuild->body->mimeType, 'text/plain');

# test remove all parts, which will remove level

$part = $message->body->part(1);
$part->delete;
ok($part->isDeleted,             "delete second part as well");
$rebuild = $message->rebuild
 ( extraRules => [ qw/removeDeletedParts removeEmptyMultiparts/ ]
 );
ok(!$rebuild->isMultipart,       "rebuild nothing left");
like($rebuild->decoded, qr/did not contain any parts/, 'added warning');

#
# Now, we play around with a nested message
#

$message->body->part(0)->deleted(0);
$message->body->part(1)->deleted(0);

my $nested = Mail::Message::Body::Nested->new
 ( nested  => $message );

my $message2 = Mail::Message->buildFromBody
 ( $nested
 , To      => 'me@example.com (Me the receiver)'
 , From    => 'him@somewhere.else.nl (Original Sender)'
 , Subject => 'Test of rebuild'
 , Date    => 'Wed, 9 Feb 2000 15:44:05 -0500'
 );

ok(defined $message2,            "succesfully build the message2");
ok($message2->isNested,          "succesfully build the nested message2");
ok($message2->body->nested->isMultipart, "a multipart within the nested");

$rebuild = $message2->rebuild
 ( extraRules => [ qw/removeDeletedParts removeEmptyMultiparts/ ]
 );
ok($rebuild==$message2,          "message2 unchanged");

# only remove the wrapper
$rebuild = $message2->rebuild( extraRules => [ 'flattenNesting' ] );
ok(defined $rebuild,             "rebuilding message2 success");
ok($rebuild!=$message2,          "message has changed");
ok($rebuild->isMultipart,        "wrapper removed, multipart visible");
cmp_ok($rebuild->parts, '==', 2, "both parts are present");

# remove one part of the multipart, leaving everything else unchanged

$message2->body->nested->body->part(0)->delete;
$rebuild = $message2->rebuild
 ( rules => [ qw/removeDeletedParts descendMultiparts descendNested/ ]
 );

ok(defined $rebuild,             "rebuilding from message2 success");
ok($rebuild!=$message2,          "message has changed");
isa_ok($rebuild->body, 'Mail::Message::Body::Nested');
ok($rebuild->body->nested->isMultipart, "still has a multipart");
cmp_ok($rebuild->body->nested->body->parts, '==', 1, "has only one part left");
cmp_ok($message2->body->nested->body->parts, '==', 2, "original still has two parts");

# have the multipart level to disappear

$rebuild = $message2->rebuild
 ( extraRules => [ qw/removeDeletedParts removeEmptyMultiparts
                      flattenMultiparts/ ]
 );
ok(defined $rebuild,           "rebuilding message2 without multipart success");
ok($rebuild!=$message2,        "message has changed");
isa_ok($rebuild->body, 'Mail::Message::Body::Nested');
ok(! $rebuild->body->nested->isMultipart, "multipart removed");
cmp_ok($message2->body->nested->body->parts, '==', 2, "original still has two parts");
is($rebuild->body->nested->body->string, "part 2\n", "text found in message2");

# Now delete the second multipart thing as welll.

$message2->body->nested->body->part(1)->delete;
$rebuild = $message2->rebuild
 ( extraRules => [ qw/removeDeletedParts removeEmptyMultiparts
                      flattenMultiparts/ ]
 );
ok(!$rebuild->isMultipart, "whole structure collapsed");
like($rebuild->decoded, qr/did not contain any parts/, 'added warning');

#
# More complex rules
# Create an text/plain -- text/html multipart/alternative
# and then automatically remove the html alternative.

my $alttext = Mail::Message::Body->new(data => "text version\n");

my $althtml = Mail::Message::Body->new
 ( mime_type => 'text/html'
 , data      => "<html>html version</html>\n"
 );

my $altmp   = Mail::Message::Body::Multipart->new
 ( mime_type => 'multipart/alternative'
 , parts     => [ $althtml, $alttext ]
 );

my $alt = Mail::Message->buildFromBody($altmp, To => 'you');
ok(defined $alt,                 "Succesfully created an alternative");

$rebuild = $alt->rebuild;
ok($rebuild==$alt,               "No rule matches by default");

$rebuild = $alt->rebuild(rules => [ 'textAlternativeForHtml']);
ok($rebuild==$alt,               "Already has alternative");

$rebuild = $alt->rebuild
 ( rules => [ qw/removeHtmlAlternativeToText descendMultiparts/ ] );
ok($rebuild!=$alt,               "alt must change");
ok($rebuild->isMultipart,        "alt still a multipart");
cmp_ok($rebuild->body->parts, '==', 1,"only one alternative left");
is($rebuild->body->part(0)->body->mimeType, 'text/plain'
                                 , "only text alternative survived");

# now include multipart flattening

$rebuild = $alt->rebuild
 ( rules => [ qw/removeHtmlAlternativeToText descendMultiparts
                 flattenMultiparts/ ] );
ok($rebuild!=$alt,               "flattened alt must change");
ok(!$rebuild->isMultipart,       "alt is not a multipart anymore");
is($rebuild->body->mimeType,'text/plain', "text body");

#
# Create an html message, and have this translated into a
# multipart with text alternative.
#

my $html = Mail::Message::Body->new(mime_type => 'text/html', data => <<HTML);
<html>
<h1>Hi there</h1>

<p>this is it</p>
</html>
HTML

$message = Mail::Message->buildFromBody($html, To => 'you', Subject => 'hi!');
ok(defined $message,                  "created html message");

$rebuild = $message->rebuild( rules => [ qw/textAlternativeForHtml/ ] );

# even if htmlFromText does not work, something must be returned
ok(defined $rebuild,                  "rebuild with html->text succesful");

if($has_htmlFormatText)
{   ok($rebuild!=$message,            "rebuild has changed it");
    ok($rebuild->isMultipart,         "Changed into multipart");
    my @parts = $rebuild->parts;
    is($parts[0]->body->mimeType, 'text/plain', "Found plain text");
    is($parts[1]->body->mimeType, 'text/html',  "Found html");

    is($rebuild->subject, 'hi!',       "Subject to main message");
    ok(! $parts[1]->get('subject'),    "removed subject from html");
}
else
{   ok($rebuild==$message,            "rebuild has not changed it");
}

