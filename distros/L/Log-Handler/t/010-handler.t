use strict;
use warnings;
use Test::More tests => 15;
use File::Spec;
use Log::Handler;

my $rand_num = int(rand(999999));
my $logfile  = File::Spec->catfile('t', "Log-Handler-$rand_num.log");
my $log      = Log::Handler->new();

$log->add(file => {
    filename        => [ 't', "Log-Handler-$rand_num.log" ],
    fileopen        => 0,
    reopen          => 0,
    filelock        => 0,
    mode            => 'excl',
    autoflush       => 1,
    permissions     => '0664',
    timeformat      => '',
    message_layout  => 'prefix [%L] %m',
    maxlevel        => 'debug',
    minlevel        => 'emergency',
    die_on_errors   => 1,
    utf8            => 0,
    debug_trace     => 0,
    debug_mode      => 2,
    debug_skip      => 0,
});

ok(1, 'checking new');

ok(!-e $logfile,       'checking fileopen');
ok($log->is_debug,     'checking debug');
ok($log->is_info,      'checking info');
ok($log->is_notice,    'checking notice');
ok($log->is_warning,   'checking warning');
ok($log->is_warn,      'checking warn');
ok($log->is_error,     'checking error');
ok($log->is_err,       'checking err');
ok($log->is_critical,  'checking critical');
ok($log->is_crit,      'checking crit');
ok($log->is_alert,     'checking alert');
ok($log->is_emergency, 'checking emergency');
ok($log->is_emerg,     'checking emerg');
ok($log->is_fatal,     'checking fatal');

if (-e $logfile) {
    unlink($logfile) or die $!;
}
