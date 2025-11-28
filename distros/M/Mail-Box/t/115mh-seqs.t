#!/usr/bin/env perl

#
# Test mh-sequences
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Manager;

use Test::More tests => 11;
use File::Spec;

my $mhsrc = File::Spec->catfile($workdir, 'mh.src');
my $seq   = File::Spec->catfile($mhsrc, '.mh_sequences');

unpack_mbox2mh($src, $mhsrc);

# Create a sequences file.
open my $sh, ">$seq" or die "Cannot write to $seq: $!\n";

# Be warned that message number 13 has been skipped from the MH-box.
$sh->print(<<'MH_SEQUENCES');
unseen: 12-15 3 34 36 16
cur: 5
MH_SEQUENCES

$sh->close;

my $mgr = Mail::Box::Manager->new;

my $folder = $mgr->open
  ( folder       => $mhsrc
  , folderdir    => 't'
  , lock_type    => 'NONE'
  , extract      => 'LAZY'
  , access       => 'rw'
  , save_on_exit => 0
  );

die "Couldn't read $mhsrc: $!\n" unless $folder;
isa_ok($folder, 'Mail::Box::MH');

ok($folder->message(1)->label('seen'));
ok(not $folder->message(2)->label('seen'));
ok($folder->message(3)->label('seen'));

ok($folder->message(4)->label('current'));
is($folder->current->messageID, $folder->message(4)->messageID);

ok(not $folder->message(1)->label('current'));
$folder->current($folder->message(1));
ok(not $folder->message(0)->label('current'));
ok($folder->message(1)->label('current'));

$folder->modified(1);
$folder->close(write => 'ALWAYS');

open $sh, $seq or die "Cannot read from $seq: $!\n";
my @seq = <$sh>;
$sh->close;

my ($cur)    = grep /^cur\: /, @seq;
is($cur, "cur: 2\n");
my ($unseen) = grep /^unseen\: /, @seq;
is($unseen, "unseen: 3 12-15 33 35\n");
