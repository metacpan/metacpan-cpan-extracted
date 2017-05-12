#!/usr/bin/env perl

#
# Test writing of maildir folders.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Maildir;

use Test::More;
use File::Compare;
use File::Copy;

BEGIN {
   if($windows)
   {   plan skip_all => 'Filenames not compatible with Windows';
       exit 1;
   }
   plan tests => 45;
}

my $mdsrc = File::Spec->catfile($folderdir, 'maildir.src');

clean_dir $mdsrc;
unpack_mbox2maildir($src, $mdsrc);

my $folder = Mail::Box::Maildir->new
  ( folder       => $mdsrc
  , extract      => 'LAZY'
  , access       => 'rw'
  );

ok(defined $folder);

ok($folder->message(40)->label('accepted'),        "40 accepted");
ok(!$folder->message(41)->label('accepted'),       "41 not accepted");

#
# Count files flagged for deletion  (T flag)
#

my $to_be_deleted =0;
$_->deleted && $to_be_deleted++  foreach $folder->messages;
cmp_ok($to_be_deleted, "==", 7);

$folder->close;

#
# Reopen the folder and see whether the messages flagged for deletion
# are away.
#

$folder = new Mail::Box::Maildir
  ( folder       => $mdsrc
  , extract      => 'LAZY'
  , access       => 'rw'
  );

cmp_ok($folder->messages, "==", 38);

my $msg6 = $folder->message(6);
like($msg6->filename , qr/:2,$/);
ok(!$msg6->label('draft'));
ok(!$msg6->label('flagged'));
ok(!$msg6->label('replied'));
ok(!$msg6->label('seen'));
ok(!$msg6->modified);

my $msg12 = $folder->message(12);
like($msg12->filename , qr/:2,DFRS$/);
ok($msg12->label('draft'));
ok($msg12->label('flagged'));
ok($msg12->label('replied'));
ok($msg12->label('seen'));

ok(!$msg12->label(flagged => 0));
ok(!$msg12->label('flagged'));
like($msg12->filename , qr/:2,DRS$/);

ok(!$msg12->label(draft => 0));
ok(!$msg12->label('draft'));
like($msg12->filename , qr/:2,RS$/);

ok(!$msg12->label(seen => 0));
ok(!$msg12->label('seen'));
like($msg12->filename , qr/:2,R$/);

ok($msg12->label(flagged => 1));
ok($msg12->label('flagged'));
like($msg12->filename , qr/:2,FR$/);

ok(!$msg12->label(flagged => 0, replied => 0));
ok(!$msg12->label('flagged'));
ok(!$msg12->label('replied'));
like($msg12->filename , qr/:2,$/);

ok(!$msg12->modified);

#
# Test accepting and unaccepting
#

# test are only run on unix, so we can simply use '/'s
is($msg12->filename, 't/folders/maildir.src/cur/110000010.l.43:2,');
ok($msg12->label('accepted'),                      "12 accepted");
cmp_ok($msg12->label(accepted => 0), '==', 0,      'un-accept a message');
ok(! $msg12->label('accepted'));
is($msg12->filename, 't/folders/maildir.src/new/110000010.l.43:2,');
ok(!$msg12->modified);   # message is not modified
ok($folder->modified);   # ... but the folder is modified
                         #     (which implies nothing)
cmp_ok($msg12->label(accepted => 1), '==', 1,      'accept the message');
ok($msg12->label('accepted'));
is($msg12->filename, 't/folders/maildir.src/cur/110000010.l.43:2,');

ok(! $folder->message(-1)->label('accepted'));
$folder->message(-1)->accept;
ok($folder->message(-1)->label('accepted'));

$folder->close;
clean_dir $mdsrc;
