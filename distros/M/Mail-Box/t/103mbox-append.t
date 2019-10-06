#!/usr/bin/env perl

#
# Test appending messages on Mbox folders.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Manager;
use Mail::Message::Construct;

use Test::More tests => 32;
use File::Compare;
use File::Copy;

#
# We will work with a copy of the original to avoid that we write
# over our test file.
#

my $empty = File::Spec->catfile($workdir, 'empty');

copy $src, $cpy
    or die "Cannot create test folder $cpy: $!\n";
unlink $empty;

my $mgr = Mail::Box::Manager->new;

my @fopts =
  ( lock_type    => 'NONE'
  , extract      => 'LAZY'
  , access       => 'rw'
  , save_on_exit => 0
  );

my $folder = $mgr->open
  ( folder    => "=$cpyfn"
  , folderdir => $workdir
  , @fopts
  );

die "Couldn't read $cpy: $!\n"
    unless $folder;

cmp_ok($folder->messages, "==", 45);

# Add a message which is already in the opened folder.  This should
# be ignored.

$folder->addMessage($folder->message(3)->clone);
cmp_ok($folder->messages, "==", 45);

#
# Create an Mail::Message and add this to the open folder.
#

my $msg = Mail::Message->build
  ( From    => 'me@example.com'
  , To      => 'you@anywhere.aq'
  , Subject => 'Just a try'
  , data    => [ "a short message\n", "of two lines.\n" ]
  );

ok(defined $msg,                                "message build successful");
my @appended = $mgr->appendMessage("=$cpyfn", $msg);
cmp_ok($folder->messages, "==", 46,             "message extends folder");
cmp_ok(scalar @appended, "==", 1,               "coerced message returned");
isa_ok($appended[0], 'Mail::Box::Message');

cmp_ok($mgr->openFolders, "==", 1);
$mgr->close($folder);
cmp_ok($mgr->openFolders, "==", 0,              "folder is closed");

my $msg2 = Mail::Message->build
  ( From      => 'me_too@example.com'
  , To        => 'yourself@anywhere.aq'
  , Subject   => 'Just one more try'
  , data      => [ "a short message\n", "of two lines.\n" ]
  );

my $old_size = -s $cpy;

@appended = $mgr->appendMessage($cpy, $msg2
  , lock_type => 'NONE'
  , extract   => 'LAZY'
  , access    => 'rw'
  );
cmp_ok(@appended, "==", 1);

cmp_ok($mgr->openFolders, "==", 0);
ok($old_size != -s $cpy);

$folder = $mgr->open
  ( folder    => "=$cpyfn"
  , folderdir => $workdir
  , @fopts
  , access    => 'rw'
  );

ok($folder);
cmp_ok($folder->messages, "==", 47);

my $sec = $mgr->open
  ( folder    => '=empty'
  , folderdir => $workdir
  , @fopts
  , create    => 1
  );

ok(defined $sec,                         "open newly created empty folder");
exit unless defined $sec;

cmp_ok($sec->messages, "==", 0,          "no messages in new folder");
cmp_ok($mgr->openFolders, "==", 2,       "but the manager knows it is created");

my $move = $folder->message(1);
ok(defined $move,                        "select a message to be moved");

my @moved = $mgr->moveMessage($sec, $move);
cmp_ok(@moved, "==", 1,                  "one message has been moved");
isa_ok($moved[0], 'Mail::Box::Message');
is($moved[0]->folder->name, $sec->name);

ok($move->deleted);
cmp_ok($folder->messages, "==", 47);
cmp_ok($sec->messages, "==", 1);

my $copy   = $folder->message(2);
ok(defined $copy);
die unless defined $copy;

my @copied = $mgr->copyMessage($sec, $copy);
cmp_ok(@copied, "==", 1);
isa_ok($copied[0], 'Mail::Box::Message');
ok(!$copy->deleted);
cmp_ok($folder->messages, "==", 47);
cmp_ok($sec->messages, "==", 2);
ok($sec->modified);

$folder->close;
$sec->close;

ok(-f $empty);
ok(-s $empty);

unlink $empty;
