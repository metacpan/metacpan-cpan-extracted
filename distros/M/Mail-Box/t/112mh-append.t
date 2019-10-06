#!/usr/bin/env perl
#
# Test appending messages on MH folders.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Manager;
use Mail::Message::Construct;

use Test::More tests => 10;
use File::Compare;
use File::Copy;

my $mhsrc = File::Spec->catfile($workdir, 'mh.src');

unpack_mbox2mh($src, $mhsrc);

my $mgr = Mail::Box::Manager->new;

my $folder = $mgr->open
  ( folder       => $mhsrc
  , lock_type    => 'NONE'
  , extract      => 'LAZY'
  , access       => 'rw'
  , save_on_exit => 0
  );

die "Couldn't read $mhsrc: $!\n"
    unless $folder;

# We checked this in other scripts before, but just want to be
# sure we have enough messages again.

cmp_ok($folder->messages, "==", 45);

# Add a message which is already in the opened folder.  However, the
# message heads are not yet parsed, hence the message can not be
# ignored.

my $message3 = $folder->message(3);
ok($message3->isDelayed);
my $added = $message3->clone;
ok(!$message3->isDelayed);

$folder->addMessage($added);
cmp_ok($folder->messages, "==", 45);

ok(not $message3->deleted);
ok($added->deleted);

#
# Create an Mail::Message and add this to the open folder.
#

my $msg = Mail::Message->build
  ( From    => 'me@example.com'
  , To      => 'you@anywhere.aq'
  , Subject => 'Just a try'
  , data    => [ "a short message\n", "of two lines.\n" ]
  );

$mgr->appendMessage($mhsrc, $msg);
cmp_ok($folder->messages, "==", 46);

cmp_ok($mgr->openFolders, "==", 1);
$mgr->close($folder);      # changes are not saved.
cmp_ok($mgr->openFolders, "==", 0);

$mgr->appendMessage($mhsrc, $msg
  , lock_type  => 'NONE'
  , extract    => 'LAZY'
  , access     => 'rw'
  , keep_index => 1
  );

ok(-f File::Spec->catfile($mhsrc, "47"));  # skipped 13, so new is 46+1
