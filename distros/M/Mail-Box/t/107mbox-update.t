#!/usr/bin/env perl

#
# Test appending messages on Mbox folders.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Manager;

use Test::More tests => 4;
use File::Copy;

#
# We will work with a copy of the original to avoid that we write
# over our test file.
#

unlink $cpy;
copy $src, $cpy
    or die "Cannot create test folder $cpy: $!\n";

my $mgr = Mail::Box::Manager->new;

my @fopts =
  ( lock_type    => 'NONE'
  , extract      => 'LAZY'
  , access       => 'rw'
  , save_on_exit => 0
  );

my $folder = $mgr->open
  ( folder    => "=$cpyfn"
  , folderdir => $folderdir
  , @fopts
  );

die "Couldn't read $cpy: $!\n"
    unless $folder;

cmp_ok($folder->messages, "==", 45);

my $msg = Mail::Message->build
 ( From => 'me', To => 'you', Subject => 'Hello!'
 , data => [ "one line\n" ]
 );
ok(defined $msg);

my $filename = $folder->filename;
die "Cannot open $filename: $!"
   unless open OUT, '>>', $filename;

print OUT $msg->head->createFromLine;
$msg->print(\*OUT);
close OUT;

cmp_ok($folder->messages, "==", 45);
$folder->update;
cmp_ok($folder->messages, "==", 46);

$folder->close;
