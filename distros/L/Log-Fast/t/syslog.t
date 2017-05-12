use warnings;
use strict;
use Test::More;
use Socket;

use Log::Fast;


if ($^O =~ /Win/xms) {
    plan skip_all => 'not availaible on Windows';
} else {
    plan tests => 19;
}


use constant PATH => "/tmp/log.$$.sock";

socket my $Srv, AF_UNIX, SOCK_DGRAM, 0  or die "socket: $!";
bind $Srv, sockaddr_un(PATH)            or die "bind: $!";
END { unlink PATH }
sub _log()  { sysread $Srv, my $buf, 8192 or die "sysread: $!"; return $buf }

our $LOG = Log::Fast->new({
    type    => 'unix',
    path    => PATH,
});

my $H = qr/\A<11>\w\w\w [ \d]\d \d\d:\d\d:\d\d syslog\.t\[$$\]:/ms;


$LOG->ERR('msg');
like _log, qr/$H msg\z/ms,          'defaults';

$LOG->config({
    add_timestamp   => 0,
    add_hostname    => 0,
    add_pid         => 0,
});
$H = qr/\A<11>syslog\.t:/ms;
$LOG->ERR('msg');
like _log, qr/$H msg\z/ms,          'minimum features';

$H = qr/\A<12>syslog\.t:/ms;
$LOG->WARN('msg');
like _log, qr/$H msg\z/ms,          'levels: WARN';
$H = qr/\A<13>syslog\.t:/ms;
$LOG->NOTICE('msg');
like _log, qr/$H msg\z/ms,          'levels: NOTICE';
$H = qr/\A<14>syslog\.t:/ms;
$LOG->INFO('msg');
like _log, qr/$H msg\z/ms,          'levels: INFO';
$H = qr/\A<15>syslog\.t:/ms;
$LOG->DEBUG('msg');
like _log, qr/$H msg\z/ms,          'levels: DEBUG';

use Sys::Syslog qw( LOG_DAEMON LOG_AUTH LOG_USER );
$LOG->config({ facility => LOG_DAEMON });
$H = qr/\A<27>syslog\.t:/ms;
$LOG->ERR('msg');
like _log, qr/$H msg\z/ms,          'facilities: daemon';
$LOG->config({ facility => LOG_AUTH });
$H = qr/\A<35>syslog\.t:/ms;
$LOG->ERR('msg');
like _log, qr/$H msg\z/ms,          'facilities: auth';
$LOG->config({ facility => LOG_USER });
$H = qr/\A<11>syslog\.t:/ms;
$LOG->ERR('msg');
like _log, qr/$H msg\z/ms,          'facilities: user';

$LOG->config({ add_timestamp => 1 });
$H = qr/\A<11>\w\w\w [ \d]\d \d\d:\d\d:\d\d syslog\.t:/ms;
$LOG->ERR('msg');
like _log, qr/$H msg\z/ms,          'feature: timestamp';
$LOG->config({ add_timestamp => 0 });

use Sys::Hostname;
$LOG->config({ add_hostname => 1 });
$H = qr/\A<11>\Q${\ hostname }\E syslog\.t:/ms;
$LOG->ERR('msg');
like _log, qr/$H msg\z/ms,          'feature: hostname (default)';
$LOG->config({ hostname => 'myhost' });
$H = qr/\A<11>myhost syslog\.t:/ms;
$LOG->ERR('msg');
like _log, qr/$H msg\z/ms,          'feature: hostname (user-defined)';
$LOG->config({ add_hostname => 0 });

$LOG->ident('myapp');
$H = qr/\A<11>myapp:/ms;
$LOG->ERR('msg');
like _log, qr/$H msg\z/ms,          'ident';

is $LOG->ident(), 'myapp',          'current ident without change';
is $LOG->ident('myapp2'), 'myapp',  'previous ident on change';
is $LOG->ident('myapp'), 'myapp2',  'previous ident on change';

$LOG->config({ add_pid => 1 });
$H = qr/\A<11>myapp\[$$\]:/ms;
$LOG->ERR('msg');
like _log, qr/$H msg\z/ms,          'feature: pid (default)';
$LOG->config({ pid => 31337 });
$H = qr/\A<11>myapp\[31337\]:/ms;
$LOG->ERR('msg');
like _log, qr/$H msg\z/ms,          'feature: pid (user-defined)';
$LOG->config({ add_pid => 0 });

$LOG->config({
    prefix          => '%S %D %T [%L]%_%P->%F %%',
    facility        => LOG_DAEMON,
    add_timestamp   => 1,
    add_hostname    => 1,
    hostname        => 'somehost',
    ident           => 'тест',
    add_pid         => 1,
    pid             => 65535,
});
$H = qr/\A<31>\w\w\w [ \d]\d \d\d:\d\d:\d\d somehost тест\[65535\]:/ms;
my $P = qr/\d+\.\d{5} 20\d\d-\d\d-\d\d \d\d:\d\d:\d\d \[DEBUG\] main-> %/ms;
$LOG->DEBUG('сообщение');
my $msg = _log;
utf8::decode($msg);
like $msg, qr/$H ${P}сообщение\z/ms,          'everything (prefix, features, unicode)';

