#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;
use Test::WWW::Mechanize;

BEGIN {
    use_ok('Lighttpd::Control');
}

my $ctl = Lighttpd::Control->new(
    config_file => [qw[ t conf lighttpd.dev.conf ]],
);
isa_ok($ctl, 'Lighttpd::Control');

SKIP: {
    
skip "No lighttpd installed (or at least none found), why are you testing this anyway?", 6 
    unless eval { $ctl->binary_path };

ok(!$ctl->has_pid_file, '... no pid file yet');
ok(!$ctl->is_server_running, '... the server process is not yet running');

$ctl->start;

diag "Wait a moment for lighttpd to start";
sleep(2);

ok($ctl->has_pid_file, '... got pid file now');
ok($ctl->is_server_running, '... the server process is now running');

my $mech = Test::WWW::Mechanize->new;
$mech->get_ok('http://localhost:3333/' . $ctl->pid_file->basename);
$mech->content_contains($ctl->server_pid, '... got the content we expected');

$ctl->stop;

diag "Wait a moment for Lighttpd to stop";
sleep(2);

ok(!-e $ctl->pid_file, '... PID file has been removed by Lighttpd');
ok(!$ctl->is_server_running, '... the server process is no longer running');

}