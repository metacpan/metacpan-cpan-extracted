#!/usr/bin/env perl
#
# Test writing of MH folders.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::MH;
use Mail::Box::Mbox;

use Test::More tests => 54;
use File::Compare;
use File::Copy;

my $mhsrc = File::Spec->catfile($folderdir, 'mh.src');

clean_dir $mhsrc;
unpack_mbox2mh($src, $mhsrc);

my $folder = new Mail::Box::MH
  ( folder     => $mhsrc
  , lock_type  => 'NONE'
  , extract    => 'LAZY'
  , access     => 'rw'
  , keep_index => 1
  );

ok(defined $folder);
cmp_ok($folder->messages, "==", 45);

my $msg3 = $folder->message(3);

# Nothing yet...

$folder->modified(1);
$folder->write(renumber => 0);

ok(compare_lists [sort {$a cmp $b} listdir $mhsrc],
            [sort {$a cmp $b} '.index', '.mh_sequences', 1..12, 14..46]
  );

$folder->modified(1);
$folder->write(renumber => 1);

ok(compare_lists [sort {$a cmp $b} listdir $mhsrc],
            [sort {$a cmp $b} '.index', '.mh_sequences', 1..45]
  );

$folder->message(2)->delete;
ok($folder->message(2)->isDelayed);
ok(defined $folder->message(3)->get('subject')); # load, creates index

$folder->write;
ok(compare_lists [sort {$a cmp $b} listdir $mhsrc],
            [sort {$a cmp $b} '.index', '.mh_sequences', 1..44]
  );

cmp_ok($folder->messages, "==", 44);

$folder->message(8)->delete;
ok($folder->message(8)->deleted);
cmp_ok($folder->messages, "==", 44);

$folder->write;
cmp_ok($folder->messages, "==", 43);
foreach ($folder->messages) { ok(! $_->deleted) }

$folder->close;

clean_dir $mhsrc;
