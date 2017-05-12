#!/usr/bin/env perl
#
# Test reading of IMAP4 folders.
# The environment has some requirements:
# On Debian:
#   adduser -d /tmp/imaptest imaptest
#   /etc/cram-md5.pwd:
#       imaptest<tab>testje
#   touch /var/mail/imaptest
#   chown $USER /var/mail/imaptest    # user running the tests
#   .... and a running imapd
#
# On SuSE 8.2
#   useradd -d /tmp/imaptest imaptest
#   /etc/cram-md5.pwd:
#       imaptest<tab>testje
#   touch /var/spool/mail/imaptest
#   chown $USER /var/spool/mail/imaptest    # user running the tests
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
   if(!$ENV{USER} || $ENV{USER} ne 'markov')
   {   plan skip_all => 'Only tested on markov\'s platform';
   }

   plan tests => 18;

}

my $user     = 'imaptest';
my $password = 'testje';
my $server   = 'localhost';
my $port     = 143;
my @connect  = ( username => $user, password => $password
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

#
# The folder is read.
#

my $folder = Mail::Box::IMAP4->new
  ( @connect
  , folder       => 'INBOX'
  , lock_type    => 'NONE'
  , access       => 'rw'
  );

ok(defined $folder,                   'check success open folder');
exit 1 unless defined $folder;

ok($folder->writeable);
cmp_ok($folder->messages , "==",  45, 'found all messages');

my $msg = Mail::Message->build(From => 'me', data => "Hi\n");
ok(defined $msg,                       'build new message to append');

isa_ok($msg, 'Mail::Message');
my $m = $folder->addMessage($msg);
isa_ok($m, 'Mail::Box::IMAP4::Message', 'coercion successful');
isa_ok($msg, 'Mail::Box::IMAP4::Message');

ok(!defined $m->unique,                 'ids only for "native" messages');
cmp_ok($folder->messages , "==",  46,   'found the new message');

#
# Play around with the message, and see nothing breaks
#

ok($m->label('reply' => 1));
ok($m->label('reply'));
ok($m->label('reply' => 0));
ok(!$m->label('reply'));

is($m->get('From'), 'me');
is($m->body->string, "Hi\n");

# Now try to save it, and reopen

ok($folder->close,                    'closing folder');

$folder = Mail::Box::IMAP4->new
  ( @connect
  , folder       => 'INBOX'
  , lock_type    => 'NONE'
  , access       => 'r'
  );

ok(defined $folder,                   'check success re-open folder');
cmp_ok($folder->messages , "==",  46, 'found one more messages');
