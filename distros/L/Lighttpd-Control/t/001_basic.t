#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;
use Test::WWW::Mechanize;

BEGIN {
    use_ok('Lighttpd::Control');
}

my $ctl = Lighttpd::Control->new(
    config_file => [qw[ t conf lighttpd.dev.conf ]],
    pid_file    => 'lighttpd.control.pid',
);
isa_ok($ctl, 'Lighttpd::Control');

SKIP: {
    
skip "No lighttpd installed (or at least none found), why are you testing this anyway?", 6 
    unless eval { $ctl->binary_path };

ok(!$ctl->is_server_running, '... the server process is not yet running');

ok($ctl->has_pid_file, '... no pid file yet');
is($ctl->pid_file->basename, 'lighttpd.control.pid', '... got the pid file');

ok(!$ctl->has_server_pid, '... no pid yet');

$ctl->start;

diag "Wait a moment for lighttpd to start";
sleep(2);

ok($ctl->has_server_pid, '... got pid now');

ok($ctl->is_server_running, '... the server process is now running');

my $mech = Test::WWW::Mechanize->new;
$mech->get_ok('http://localhost:3333/' . $ctl->pid_file->basename);
$mech->content_contains($ctl->server_pid, '... got the content we expected');

$ctl->stop;

ok(!$ctl->has_server_pid, '... no longer have a pid');

diag "Wait a moment for Lighttpd to stop";
sleep(2);

ok(!-e $ctl->pid_file, '... PID file has been removed by Lighttpd');
ok(!$ctl->is_server_running, '... the server process is no longer running');

}