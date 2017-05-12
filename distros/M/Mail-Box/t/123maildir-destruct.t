#!/usr/bin/env perl

#
# Test reading and destructing Maildir folders.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Maildir;
use Mail::Box::Mbox;

use Test::More;
use File::Compare;
use File::Copy;

BEGIN {
   if($windows)
   {   plan skip_all => 'Filenames not compatible with Windows';
       exit 1;
   }
   plan tests => 9;
}

my $mdsrc = File::Spec->catfile($folderdir, 'maildir.src');

unpack_mbox2maildir($src, $mdsrc);

ok(Mail::Box::Maildir->foundIn($mdsrc));

my $folder = Mail::Box::Maildir->new
  ( folder       => $mdsrc
  , extract      => 'LAZY'
  , access       => 'r'
  , trace        => 'NONE'
  );

ok(defined $folder);
cmp_ok($folder->messages, "==", 45,   'all messages present');

isa_ok($folder->message(0),  'Mail::Box::Message');
ok(! $folder->message(0)->modified,   'message ok');
$_->destruct for $folder->messages(0,9);
ok(! $folder->message(0)->modified,   'message destructed');
isa_ok($folder->message(0),  'Mail::Box::Message::Destructed');
isa_ok($folder->message(0),  'Mail::Box::Message');
isa_ok($folder->message(10), 'Mail::Box::Maildir::Message');
$folder->close;
