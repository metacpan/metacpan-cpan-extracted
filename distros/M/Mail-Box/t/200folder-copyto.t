#!/usr/bin/env perl
#
# Test folder-to-folder copy
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Manager;

use Test::More tests => 28;
use File::Copy;
use IO::Scalar;

copy $src, $cpy or die "Copy failed";

#
# Build a complex system with MH folders and sub-folders.
#

my $mgr    = Mail::Box::Manager->new;

my $folder = $mgr->open($cpy, lock_type => 'NONE');
ok(defined $folder);

unlink qw/a b c d e/;

my $A = $mgr->open('a', type => 'mh', create => 1, access => 'w'
  , lock_type => 'NONE');
ok(defined $A);

$mgr->copyMessage($A, $folder->message($_)) for 0..9;

my $b = $A->openSubFolder('b', create => 1, access => 'w');
ok(defined $b);
$mgr->copyMessage($b, $folder->message($_)) for 10..19;
cmp_ok($b->messages, "==", 10);
$b->close;

my $c = $A->openSubFolder('c', create => 1, access => 'w');
ok(defined $c);
$mgr->copyMessage($c, $folder->message($_)) for 20..29;

my $d = $c->openSubFolder('d', create => 1, access => 'w');
ok(defined $c);
$mgr->copyMessage($d, $folder->message($_)) for 30..39;

$d->close;
$c->close;
$A->close;

$folder->close;
cmp_ok($mgr->openFolders , "==",  0, 'all folders closed');

#
# Convert the built MH structure into MBOX
#

$A = $mgr->open('a', access => 'rw', lock_type => 'NONE');
ok($A, 'Open MH folder a');

my @sub = sort $A->listSubFolders;
cmp_ok(@sub, "==", 2,                      "a has two subfolders");
is($sub[0], 'b',                           "   named b");
is($sub[1], 'c',                           "   and c");

my $e = $mgr->open('e', type => 'mbox', create => 1, access => 'rw',
   lock_type => 'NONE');
cmp_ok($A->messages, "==", 10,              "e has 10 messages");

$A->message($_)->delete for 3,4,8;
ok(defined $A->copyTo($e, select => 'ALL', subfolders => 0));
cmp_ok($e->messages, "==", 10);
$e->delete;

$e = $mgr->open('e', type => 'mbox', create => 1, access => 'rw',
   lock_type => 'NONE');
ok(defined $A->copyTo($e, select => 'DELETED', subfolders => 0));
cmp_ok($e->messages, "==", 3);
$e->delete;

$e = $mgr->open('e', type => 'mbox', create => 1, access => 'rw',
   lock_type => 'NONE');
ok(defined $A->copyTo($e, select => 'ACTIVE', subfolders => 'FLATTEN'));
cmp_ok($e->messages, "==", 37);
$e->delete;

$e = $mgr->open('e', type => 'mbox', create => 1, access => 'rw',
   lock_type => 'NONE');
ok(defined $e,                          "e is opened again");

ok(defined $A->copyTo($e, select => 'ACTIVE', subfolders => 'RECURSE'),
                                        "copyTo reports success");
cmp_ok($e->messages, "==", 7,           "e contains 7 messages");

my @subs = sort $e->listSubFolders;
cmp_ok(@subs, "==", 2,                  "e still has two subfolders");
is($subs[0], 'b',                       "   named b");
is($subs[1], 'c',                       "   and c");

$b = $e->openSubFolder('b');
ok(defined $b,                          "opened subfolder b of e");
isa_ok($b, 'Mail::Box::Mbox',           "   which is a MBOX");
cmp_ok($b->messages , "==",  10,        "   and contains 10 messages");

ok($b->close,                           "b is closed");                         

$e->delete;
$A->delete;
