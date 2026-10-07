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
autodie
callstack
closelog
Corinna
ctx
debug
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
IPC
iso
journald
LF
LoadFile
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
Pseudocode
Readonly
rescanned
rfc
SDK
SeverityNumber
SIGHUP
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
