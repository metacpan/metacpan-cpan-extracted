#!/usr/bin/env perl

#
# Test delay-loading on mbox folders.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Mbox;

use Test::More tests => 288;
use File::Compare;
use File::Copy;

#
# We will work with a copy of the original to avoid that we write
# over our test file.
#

copy $src, $cpy
    or die "Cannot create test folder $cpy: $!\n";

my $folder = Mail::Box::Mbox->new
  ( folder       => "=$cpyfn"
  , folderdir    => $workdir
  , lock_type    => 'NONE'
  , extract      => 'LAZY'
  , access       => 'rw'
  );

die "Couldn't read $cpy: $!\n"
    unless $folder;

#
# Check that the whole folder is continuous
#

my $blank = $crlf_platform ? 2 : 1;
my ($end, $msgnr) = (-$blank, 0);

foreach my $message ($folder->messages)
{   my ($msgbegin, $msgend)   = $message->fileLocation;
    my ($headbegin, $headend) = $message->head->fileLocation;
    my ($bodybegin, $bodyend) = $message->body->fileLocation;

    cmp_ok($msgbegin, "==", $end+$blank, "begin $msgnr");
    cmp_ok($headbegin, ">", $msgbegin,   "end $msgnr");
    cmp_ok($bodybegin, "==", $headend,   "glue $msgnr");
    $end = $bodyend;
    $msgnr++;
}

cmp_ok($end+$blank , "==",  -s $folder->filename, "full folder read");

#
# None of the messages should be modified.
#

my $modified = 0;
$modified ||= $_->modified foreach $folder->messages;
ok(! $modified,                                   "folder not modified");

#
# Write unmodified folder to different file.
# Because file-to-file copy of unmodified messages, the result must be
# the same.
#

my $oldsize = -s $folder->filename;

$folder->modified(1);    # force write
ok($folder->write,                                 "writing folder");
cmp_ok($oldsize, "==",  -s $folder->filename,      "expected size");

# Try to read it back

my $copy = new Mail::Box::Mbox
  ( folder       => "=$cpyfn"
  , folderdir    => $workdir
  , lock_type    => 'NONE'
  , extract      => 'LAZY'
  );

ok(defined $copy,                                   "re-reading folder");
cmp_ok($folder->messages, "==", $copy->messages,    "all messages found");

# Check also if the subjects are the same.

my @f_subjects = map {$_->head->get('subject') ||''} $folder->messages;
my @c_subjects = map {$_->head->get('subject') ||''} $copy->messages;

while(@f_subjects)
{   my $f = shift @f_subjects;
    my $c = shift @c_subjects;
    last unless $f eq $c;
}
ok(!@f_subjects,                                     "all msg-subjects found");

#
# None of the messages should be parsed yet.
#

my $parsed = 0;
$_->isParsed && $parsed++ foreach $folder->messages;
cmp_ok($parsed, "==", 0,                             "none of the msgs parsed");

#
# Check that the whole folder is continuous
#

($end, $msgnr) = (-$blank, 0);
foreach my $message ($copy->messages)
{   my ($msgbegin, $msgend)   = $message->fileLocation;
    my ($headbegin, $headend) = $message->head->fileLocation;
    my ($bodybegin, $bodyend) = $message->body->fileLocation;

#warn "($msgbegin, $msgend) ($headbegin, $headend) ($bodybegin, $bodyend)\n";
    cmp_ok($msgbegin, "==", $end+$blank, "begin $msgnr");
    cmp_ok($headbegin, ">", $msgbegin,   "end $msgnr");
    cmp_ok($bodybegin, "==", $headend,   "glue $msgnr");
    $end = $bodyend;
    $msgnr++;
}
cmp_ok($end+$blank, "==",  -s $copy->filename,      "written file size ok");

#
# None of the messages should be parsed still.
#

$parsed = 0;
$_->isParsed && $parsed++ foreach $copy->messages;
cmp_ok($parsed, "==", 0,                            "none of the msgs parsed");

#
# Force one message to be loaded.
#

my $message = $copy->message(3)->forceLoad;
ok(ref $message,                                    "force load of one msg");
my $body = $message->body;
ok($message->isParsed);

isa_ok($message, 'Mail::Message');

#
# Ask for a new field from the header, which is not taken by
# default.  The message should get parsed.
#

ok(!defined $message->head->get('xyz'));

ok(not $copy->message(2)->isParsed);
ok(defined $copy->message(2)->head->get('x-mailer'));
isa_ok($copy->message(2)->head, 'Mail::Message::Head::Complete');
ok(not $copy->message(2)->isParsed);

unlink $cpy;
