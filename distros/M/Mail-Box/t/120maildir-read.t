#!/usr/bin/env perl

#
# Test reading of Maildir folders.
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
}

my $mdsrc = File::Spec->catfile($workdir, 'maildir.src');

unpack_mbox2maildir($src, $mdsrc);

ok(Mail::Box::Maildir->foundIn($mdsrc));

my $folder1 = Mail::Box::Maildir->new(
	folder       => $mdsrc,
	extract      => 'LAZY',
	access       => 'r',
	trace        => 'NONE',
);

ok defined $folder1, 'open maildir';
isa_ok($folder1, 'Mail::Box::Maildir');

cmp_ok($folder1->messages, "==", 45);
is($folder1->organization, 'DIRECTORY');

#
# Count drafts (from Tools.pm flags)
#

my $drafts = 0;
$_->label('draft') && $drafts++ for $folder1->messages;
cmp_ok $drafts, "==", 8, 'a few drafts';

#
# No single head should be read now, because extract == LAZY
# the default.
#

my $heads = 0;
foreach ($folder1->messages)
{  $heads++ unless $_->head->isDelayed;
}
cmp_ok($heads, "==", 0, 'all heads delayed');

#
# Loading a header should not be done unless really necessary.
#

my $message = $folder1->message(7);
ok $message->head->isDelayed, 'addressing does not load';

ok $message->filename ;   # already known, but should not trigger header
ok $message->head->isDelayed, 'filename does not load';

#
# Nothing should be parsed yet
#

my $parsed = 0;
foreach ($folder1->messages)
{  $parsed++ if $_->isParsed;
}
cmp_ok $parsed, "==", 0, 'none of the messages are parsed';

#
# Trigger one message to get read.
#

ok $message->body->string;       # trigger body loading.
ok $message->isParsed;

#
# Test taking header
#

$message = $folder1->message(8);
ok(defined $message->head->get('subject'));
ok(not $message->isParsed);
is(ref $message->head, 'Mail::Message::Head::Complete');

# This shouldn't cause any parsings: we do lazy extract, but Mail::Box
# will always take the `Subject' header for us.

my @subjects = map { chomp; $_ }
                  map {$_->head->get('subject') || '<undef>' }
                     $folder1->messages;

$parsed = 0;
$heads  = 0;
foreach ($folder1->messages)
{  $parsed++ unless $_->isDelayed;
   $heads++  unless $_->head->isDelayed;
}
cmp_ok($parsed, "==", 1);  # message 7
cmp_ok($heads, "==", 45);

#
# The subjects must be the same as from the original Mail::Box::Mbox
# There are some differences with new-lines at the end of headerlines
#

my $mbox = Mail::Box::Mbox->new(
	folder      => $src,
	lock_type   => 'NONE',
	access      => 'r',
);

my @fsubjects = map { chomp; $_ }
                   map { $_->head->get('subject') || '<undef>' }
                      $mbox->messages;

$mbox->close;

my %subjects;
$subjects{$_}++ for @subjects;
$subjects{$_}-- for @fsubjects;

my $missed = 0;
foreach (keys %subjects)
{   $missed++ if $subjects{$_};
    warn "Still left: $_ ($subjects{$_}x)\n" if $subjects{$_};
}
ok !$missed, 'all subjects found';

#
# Check if we can read a body.
#

my $msg3 = $folder1->message(3);
ok defined $msg3, 'message 4';
my $body = $msg3->body;
ok defined $body, '... has a body';
cmp_ok @$body, "==", 42, '... expected nr lines';       # check expected number of lines in message 4.

# Some maildir messages are labeled as 'DELETED', so close() wants to write it.
$folder1->close(write => 'NEVER');

#
# Now with partially lazy extract.
#

my $parse_size = 5000;
my $folder2 = Mail::Box::Maildir->new(
	folder    => $mdsrc,
	lock_type => 'NONE',
	extract   => $parse_size, # messages > $parse_size bytes stay unloaded.
	access    => 'rw',
);

ok defined $folder2, 'opened maildir';
cmp_ok $folder2->messages, "==", 45, '... all messages found';

$parsed     = 0;
$heads      = 0;
my $mistake = 0;
foreach ($folder2->messages)
{   $parsed++  unless $_->isDelayed;
    $heads++   unless $_->head->isDelayed;
    $mistake++ if !$_->isDelayed && $_->size > $parse_size;
}

ok ! $mistake, '... no mistakes';
ok ! $parsed,  '... all delayed msgs';   # The new messages
ok ! $heads,   '... all delayed heads';

$folder2->message($_)->head->get('subject') for 5..13;
ok 1, 'collect subject from 5..13';

$parsed  = 0;
$heads   = 0;
$mistake = 0;
foreach ($folder2->messages)
{   $parsed++  unless $_->isDelayed;
    $heads++   unless $_->head->isDelayed;
    $mistake++ if !$_->isDelayed && $_->body->size > $parse_size;
}

ok ! $mistake, '... no mistakes';
cmp_ok $parsed , "==",  7, '... some parsed';
cmp_ok $heads , "==",  9, '... all heads';

$folder2->close;

# No clean-dir: see how it behaves when the folder is not explictly
# closed before the program terminates.  Terrible things can happen
# during auto-cleanup
#clean_dir $mdsrc;

done_testing;
