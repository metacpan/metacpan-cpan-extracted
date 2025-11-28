#!/usr/bin/env perl
#
# Test reading of mbox folders.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Mbox;

use Test::More;
use File::Compare;

my @src = (folder => "=$fn", folderdir => $folderdir);
ok(Mail::Box::Mbox->foundIn(@src),    'check foundIn');

#
# The folder is read.
#

my $folder = Mail::Box::Mbox->new(@src, lock_type => 'NONE', extract => 'ALWAYS');
ok defined $folder,                   'check success open folder';
defined $folder or exit 1;

cmp_ok scalar $folder->messages, '==', 45, 'none deleted';
cmp_ok $folder->nrMessages, '==', 45;
is $folder->organization, 'FILE',     'folder organization FILE';

#
# Extract one message.
#

my $message = $folder->message(2);
ok defined $message,                   'take one message';
isa_ok $message, 'Mail::Box::Message';
isa_ok $message, 'Mail::Box::Mbox::Message';

#
# Extract a few messages.
#

my @some = $folder->messages(3,7);
cmp_ok @some, "==", 5,                 'take range of messages';
isa_ok $some[0], 'Mail::Box::Message';

#
# All message should be parsed: extract => ALWAYS
#

my $parsed = 1;
$parsed &&= $_->isParsed for $folder->messages;
ok($parsed,                            'all messages parsed');

#
# Check whether all message's locations are nicely connected.
#

my $blank = $crlf_platform ? 2 : 1;

#XXX Mail::Message fileLocation changed, in the hope to keep DKIM signatures valid over storage
#    in an MBOX folder.  This may not be the right or a sufficient patch.
$blank = 0;

my ($end, $msgnr) = (-$blank, 0);
foreach $message ($folder->messages)
{   my ($msgbegin, $msgend)   = $message->fileLocation;
    my ($headbegin, $headend) = $message->head->fileLocation;
    my ($bodybegin, $bodyend) = $message->body->fileLocation;

#warn "($msgbegin, $msgend) ($headbegin, $headend) ($bodybegin, $bodyend)\n";
    cmp_ok($msgbegin, "==", $end+$blank, "begin $msgnr");
    cmp_ok($headbegin, ">", $msgbegin,   "end $msgnr");
    cmp_ok($bodybegin, "==", $headend,   "glue $msgnr");
    $end = $bodyend;

    $msgnr++;
}
cmp_ok($end+$blank, "==",  -s $folder->filename);

#
# Try to delete a message
#

ok !$folder->message(2)->deleted,       'msg2 not yet deleted';
$folder->message(2)->delete;
ok $folder->message(2)->deleted,        'flag msg for deletion';
cmp_ok $folder->messages , "==",  45,   'deletion not performed yet';

cmp_ok $folder->messages('ACTIVE')  , "==",  44, 'less messages ACTIVE';
cmp_ok $folder->messages('DELETED') , "==",   1, 'more messages DELETED';

$folder->close(write => 'NEVER');

done_testing;
