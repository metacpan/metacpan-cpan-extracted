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
callstack
closelog
Corinna
ctx
debug
DGRAM
emerg
ENV
env
falsy
fd
Getter
HH
HiRes
journald
IPC
LF
LoadFile
LoggerProvider
LogRecord
logrotate
macOS
msg
nERROR
NL
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
SDK
SeverityNumber
SIGHUP
str
Sys
systemd
TCP
TODO
uint
ulevel
Util
YYYY
