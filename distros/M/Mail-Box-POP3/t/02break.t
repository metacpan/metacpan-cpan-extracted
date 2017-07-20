#!/usr/bin/env perl

use strict;
use warnings;

use Mail::Box::POP3::Test;
use Mail::Box::Test;

use File::Basename qw(dirname);
use File::Spec     ();

use Test::More;
$ENV{MARKOV_DEVEL} or plan skip_all => "tests are fragile, skipped";

use_ok('Mail::Transport::POP3');

my $here         = dirname __FILE__;
my $original     = File::Spec->catdir($here, 'original');
my $popbox       = File::Spec->catdir($here, 'popbox');

copy_dir($original, $popbox);
my ($server, $port) = start_pop3_server($popbox);
my $receiver = start_pop3_client($port);

isa_ok($receiver, 'Mail::Transport::POP3');

my $socket = $receiver->socket;
ok($socket, "Could not get socket of POP3 server");
print $socket "EXIT\n"; # make server exit on QUIT

$receiver->message($_) foreach $receiver->ids;
$receiver->deleteFetched;

print $socket "BREAK\n"; # force breaking of connection
ok($receiver->disconnect, 'Failed to properly disconnect from server');

my @message = <$popbox/????>;
cmp_ok(scalar(@message) ,'==', 0, 'Did not remove messages at QUIT');
ok(rmdir($popbox), "Failed to remove $popbox directory: $!");

is(join('', <$server>), <<EOD, 'Statistics contain unexpected information');
2
APOP 2
BREAK 1
DELE 4
EXIT 1
NOOP 6
QUIT 1
RETR 4
STAT 2
UIDL 2
EOD

done_testing;
