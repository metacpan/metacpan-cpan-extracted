#!usr/bin/env perl

use 5.006;
use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'Test::Spelling::Comment' => '0.002' };

Test::Spelling::Comment->import();
Test::Spelling::Comment->new()->add_stopwords(<DATA>)->all_files_ok();

__DATA__
Any
async
autodie
callstack
closelog
Corinna
ctx
debug
dest
DESTROY
DGRAM
dT
emerg
EMSGSIZE
ENV
env
falsy
fd
Getter
HH
hh
hhmm
HiRes
HUP
IPC
iso
journald
LF
LoadFile
LogAny
LogDispatch
logfmt
LoggerProvider
LogRecord
logrotate
macOS
msg
nERROR
NL
nN
NOCLASS
NUL
NULs
openlog
OpenTelemetry
opentelemetry
OTEL
OTel
otel
OTLP
Params
params
postrotate
Pseudocode
Readonly
rescanned
rfc
SDK
SeverityNumber
SIG
SIGCHLD
SIGHUP
sighup
sm
str
Sys
systemd
TCP
tm
TODO
uint
ulevel
Util
xNN
YYYY
