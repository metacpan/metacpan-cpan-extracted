#!/usr/bin/env perl
#
# Test access to folders using ties.
#

use strict;
use warnings;

use Mail::Box::Mbox          ();
use Mail::Box::Tie::ARRAY    ();
use Mail::Message::Construct ();

use Mail::Box::Test;
use Test::More;

#
# The folder is read.
#

my $folder = Mail::Box::Mbox->new(
	folder    => $src,
	folderdir => 't',
	lock_type => 'NONE',
	extract   => 'ALWAYS',
	access    => 'r',
);

ok defined $folder, 'open folder';
cmp_ok $folder->messages, "==", 45, '... found all messages';

tie my(@folder), 'Mail::Box::Tie::ARRAY', $folder;
cmp_ok @folder , "==",  45, '... also via tie';

is $folder->message(4), $folder[4];

ok ! $folder->message(2)->deleted, 'try delete in folder interface';
$folder[2]->delete;
ok $folder->message(2)->deleted, '... is deleted';
cmp_ok @folder , "==",  45, '... still visible';

ok ! $folder->message(3)->deleted, 'try delete via array interface';
my $d3 = delete $folder[3];
ok defined $d3;
ok $folder->message(3)->deleted;

# Double messages will not be added.
my $m = push @folder, $folder[1]->clone;
cmp_ok $m, "==", 45, 'ignore clone';
cmp_ok @folder, "==", 45;

# Different message, however, will be added.
my $newmsg = Mail::Message->build(data => []);
my $l = push @folder, $newmsg;
cmp_ok $l, '==', 46, 'push new message';
cmp_ok scalar $folder->messages , "==", 46, 'added message via ARRAY interface';
cmp_ok scalar @folder , "==",  46;

$folder->close(write => 'NEVER');

done_testing;
