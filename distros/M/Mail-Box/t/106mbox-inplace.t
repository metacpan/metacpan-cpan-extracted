#!/usr/bin/env perl

#
# Test writing of mbox folders using the inplace policy.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Mbox;

use Test::More tests => 116;
use File::Compare;
use File::Copy;

#
# We will work with a copy of the original to avoid that we write
# over our test file.
#

unlink $cpy;
copy $src, $cpy
    or die "Cannot create test folder $cpy: $!\n";

my $folder = Mail::Box::Mbox->new
  ( folder       => "=$cpyfn"
  , folderdir    => $folderdir
  , lock_type    => 'NONE'
  , extract      => 'LAZY'
  , access       => 'rw'
  , log          => 'NOTICES'
#, trace => 'NOTICES'
  );

die "Couldn't read $cpy: $!\n"
     unless $folder;

#
# None of the messages should be modified.
#

my $modified = 0;
$modified ||= $_->modified foreach $folder->messages;
ok(!$modified);

#
# Write unmodified folder.  This should be ready immediately.
#

ok($folder->write(policy => 'INPLACE'));
my @progress = $folder->report('PROGRESS');
ok(grep m/not changed/, @progress);

#
# All messages must still be delayed.
#

my $msgnr = 0;
foreach ($folder->messages)
{   my $body = $_->body;
    if($body->isDelayed || $body->isNested || $body->isMultipart) {ok(1)}
    else { warn "Warn: failed message $msgnr.\n"; ok(0) }
    $msgnr++;
}

#
# Now MODIFY the folder, and write it again.
#

my $modmsgnr = 30;
$folder->message($modmsgnr)->modified(1);

ok($folder->write(policy => 'INPLACE'));
ok(not $folder->modified);

#
# All before messages before $modmsgnr must still be delayed.
#

$msgnr = 0;
foreach ($folder->messages)
{   my $body = $_->body;
    my $right = ($body->isDelayed || $body->isMultipart || $body->isNested)
        ? ($msgnr < $modmsgnr) : ($msgnr >= $modmsgnr);
    ok($right,         "delayed message $msgnr");
    $msgnr++;
}

my @folder_subjects = sort map {$_->get('subject')||''} $folder->messages;
my $folder_messages = $folder->messages;

ok(not $folder->modified);
$folder->close;

# Check also if the subjects are the same.
# Try to read it back

my $copy = new Mail::Box::Mbox
  ( folder    => "=$cpyfn"
  , folderdir => $folderdir
  , lock_type => 'NONE'
  , extract   => 'ALWAYS'
  );

ok(defined $copy);
cmp_ok($copy->messages, "==", $folder_messages);

# Check also if the subjects are the same.

my @copy_subjects   = sort map {$_->get('subject')||''} $copy->messages;
my $msg12subject    = $copy->message(12)->get('subject');
ok(defined $msg12subject, "got msg12 subject");

while(@folder_subjects)
{   last unless shift(@folder_subjects) eq shift(@copy_subjects);
}
ok(!@folder_subjects);

#
# Check wether inplace rewrite works when a few messages are deleted.
#

$copy = new Mail::Box::Mbox
  ( folder       => "=$cpyfn"
  , folderdir    => $folderdir
  , lock_type    => 'NONE'
  , extract      => 'LAZY'
  , access       => 'rw'
  , log          => 'NOTICES'
#, trace => 'NOTICES'
  );

die "Couldn't read $cpyfn: $!\n"
     unless $copy;

$copy->message(-1)->delete;   # last flagged for deletion
ok($copy->message(-1)->deleted);

ok($copy->write(policy => 'INPLACE'), "write folder with fewer messsages");

$copy = new Mail::Box::Mbox
  ( folder    => "=$cpyfn"
  , folderdir => $folderdir
  , lock_type => 'NONE'
  , extract   => 'ALWAYS'
  );

ok(defined $copy,                                 "Reopen succesful");
cmp_ok($copy->messages+1, "==", $folder_messages, "1 message less");

#
# Rewrite it again, with again 1 fewer message
#

$copy->close;
ok(! defined $copy,                             "Folder is really closed");

$copy = new Mail::Box::Mbox
  ( folder    => "=$cpyfn"
  , folderdir => $folderdir
  , lock_type => 'NONE'
  , extract   => 'ALWAYS'
  , access    => 'rw'
  );

cmp_ok($copy->messages, "==", $folder_messages-1, "1 message still away");

$copy->message(10)->delete;   # some other, doesn't matter
ok($copy->message(10)->deleted);

ok($copy->write(policy => 'INPLACE'), "write folder with fewer messsages");

$copy = new Mail::Box::Mbox
  ( folder    => "=$cpyfn"
  , folderdir => $folderdir
  , lock_type => 'NONE'
  , extract   => 'ALWAYS'
  );

cmp_ok($copy->messages, "==", $folder_messages-2, "2 messages fewer");
is($copy->message(11)->get('subject'), $msg12subject, "move message");

#
# Rewrite it again, with again 1 fewer message: this time the first message
#

$copy->close;
ok(! defined $copy,                             "Folder is really closed");

$copy = new Mail::Box::Mbox
  ( folder    => "=$cpyfn"
  , folderdir => $folderdir
  , lock_type => 'NONE'
  , extract   => 'ALWAYS'
  , access    => 'rw'
  );

cmp_ok($copy->messages, "==", $folder_messages-2, "2 message still away");

$copy->message(0)->delete;    # first flagged for deletion
ok($copy->message(0)->deleted);

ok($copy->write(policy => 'INPLACE'), "write folder with fewer messsages");

$copy = new Mail::Box::Mbox
  ( folder    => "=$cpyfn"
  , folderdir => $folderdir
  , lock_type => 'NONE'
  , extract   => 'ALWAYS'
  );

cmp_ok($copy->messages, "==", $folder_messages-3, "3 messages fewer");
is($copy->message(10)->get('subject'), $msg12subject, "move message");

unlink $cpy;
