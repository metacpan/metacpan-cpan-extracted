#!/usr/bin/env perl
#
# Test reading of IMAP4 folders.
# The environment has some requirements:
# On Debian:
#   adduser -d /tmp/imaptest imaptest
#   /etc/cram-md5.pwd:
#       imaptest<tab>testje
#   touch /var/mail/imaptest
#   chown imaptest.users /var/mail/imaptest
#   chmod 0664           /var/mail/imaptest  # user running the tests
#   .... and a running imapd
#
# On SuSE 8.2
#   useradd -d /tmp/imaptest imaptest
#   /etc/cram-md5.pwd:
#       imaptest<tab>testje
#   touch /var/spool/mail/imaptest
#   chown imaptest.users /var/mail/imaptest
#   chmod 0664           /var/mail/imaptest  # user running the tests
#   .... and a running imapd, which requires the start of xinetd and
#        enabling the imap service via YaST2

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::IMAP4;

use Test::More;
use File::Compare;
use File::Copy;
use File::Spec::Functions;


BEGIN
{ 
   unless($ENV{MARKOV_DEVEL})
   {   plan skip_all => 'Only tested on markov\'s platform';
   }

   plan tests => 40;

}

my $user     = 'imaptest';
my $password = 'testje';
my $server   = 'localhost';
my $port     = 143;
my @connect  =
  ( username => $user, password => $password
  , server_name => $server, server_port => $port
  );

my $home     = "/tmp/$user";
my $inbox    = "/var/mail/$user";

# Prepare home directory
   -d $home
or mkdir $home
or die "Cannot create $home: $!\n";

# Prepare INBOX
copy $unixsrc, $inbox
or die "Cannot create $inbox: $!\n";

ok(Mail::Box::IMAP4->foundIn(folder => 'imap://'), 'check foundIn');

#
# The folder is read.
#

my $folder = Mail::Box::IMAP4->new
  ( @connect
  , folder       => 'INBOX'
  , lock_type    => 'NONE'
  , cache_labels => 'YES'
  );

ok(defined $folder,                   'check success open folder');
exit 1 unless defined $folder;

isa_ok($folder, 'Mail::Box::IMAP4');

cmp_ok($folder->messages , "==",  45, 'found all messages');
is($folder->organization, 'REMOTE',   'folder organization NET');

#
# Take one message.
#

my $message = $folder->message(2);
ok(defined $message,                   'take one message');
isa_ok($message, 'Mail::Box::Message');
isa_ok($message, 'Mail::Box::IMAP4::Message');

ok($message->head->isDelayed);
cmp_ok($message->recvstamp, '==', 950134500, 'try recvstamp');
cmp_ok($message->size, '==', 3931,     'try fetch size');
ok($message->head->isDelayed,          'still delayed');

#
# Take a few messages.
#

my @some = $folder->messages(3,7);
cmp_ok(@some, "==", 5,                 'take range of messages');
isa_ok($some[0], 'Mail::Box::Message');
isa_ok($some[0], 'Mail::Box::IMAP4::Message');

#
# None of the messages is parsed, yet
#

my $parsed = 0;
$parsed ||= $_->isParsed foreach $folder->messages;
cmp_ok($parsed, '==', 0, 'no messages parsed');

#
# Load a message
#

my $m34 = $folder->message(34);
ok($m34->isDelayed,                     'msg 34 delayed');
ok($m34->head->isDelayed,               'head delayed');
ok($m34->body->isDelayed,               'body delayed');
isa_ok($m34->head, 'Mail::Message::Head::Delayed');
isa_ok($m34->body, 'Mail::Message::Body::Delayed');

my $s = $m34->body->string;
$s =~ s/\r\n/\n/g;
is($s, "subscribe magick-developer\n", 'simple body');

#
# Try to delete a message
#

ok(!$folder->message(2)->deleted,       'msg 2 not yet deleted');
$folder->message(2)->delete;
ok($folder->message(2)->deleted,        'msg 2 flagged for deletion');
cmp_ok($folder->messages , "==",  45,   'deletion not performed yet');

cmp_ok($folder->messages('ACTIVE')  , "==",  44, 'less messages ACTIVE');
cmp_ok($folder->messages('DELETED') , "==",   1, 'more messages DELETED');

my $replied = 0;
$_->label('replied') && $replied++ for $folder->messages;
cmp_ok($replied, '==', 12,                       'read replied flags');

$folder->message(0)->label(replied => 1);
$replied = 0;
$_->label('replied') && $replied++ for $folder->messages;
cmp_ok($replied, '==', 13,                       'set replied flag');

#
# Take a message
#

my $m = $folder->message(8);
ok(defined $m,                                   'take message 8');
ok($m->isDelayed);
ok($m->head->isDelayed);
ok($m->body->isDelayed);

my $subject = $m->subject;
is($subject, 'Resize with Transparency',          'realized 8');
isa_ok($m->head, 'Mail::Message::Head::Complete');
ok($m->body->isDelayed);

my $body    = $m->body;
ok($body->isDelayed,                              'got some body');

$s = $body->string;
ok(defined $s,                                    'got a string');
$s =~ s/\r//g;
is(substr($s, 0, 19), "\nHi,\n\nMaybe someone");
isa_ok($body, 'Mail::Message::Body');

$folder->close(write => 'NEVER');

exit 0;
