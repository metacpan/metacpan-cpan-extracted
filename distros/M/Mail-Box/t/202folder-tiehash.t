#!/usr/bin/env perl

#
# Test access to folders using ties on hashes.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Mbox;
use Mail::Box::Tie::HASH;
use Mail::Message::Construct;

use Test::More tests => 101;

#
# The folder is read.
#

my $folder = Mail::Box::Mbox->new
  ( folder    => $src
  , folderdir => 't'
  , lock_type => 'NONE'
  , extract   => 'ALWAYS'
  , access    => 'rw'
  );

ok(defined $folder);

tie my(%folder), 'Mail::Box::Tie::HASH', $folder;
cmp_ok(keys %folder , "==",  45);
ok(! defined $folder{not_existing});

my @keys = keys %folder;
foreach (@keys)
{   ok(defined $folder{$_});
    my $msg = $folder{$_};
    is($folder{$_}->messageID, $_);
}

my $msg   = $folder->message(4);
my $msgid = $msg->messageID;
is($msg, $folder{$msgid});

# delete $folder[2];    works for 5.6, but not for 5.5
ok(!$folder->message(4)->deleted);
cmp_ok(keys %folder , "==",  45);
$folder{$msgid}->delete;
ok($folder->message(4)->deleted);
cmp_ok(keys %folder , "==",  44);

# Double messages will not be added.
{  no warnings 'uninitialized';
   $folder{ (undef) } = $folder{$msgid}->clone;
}

cmp_ok(keys %folder , "==",  44);

# Different message, however, will be added.
my $newmsg = Mail::Message->build(data => [ 'empty' ]);
$folder{undef} = $newmsg;
cmp_ok($folder->messages , "==",  46);
cmp_ok(keys %folder , "==",  45);

$folder->close(write => 'NEVER');
exit 0;
