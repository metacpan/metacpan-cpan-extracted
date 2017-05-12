use strict;
use warnings;
use Test::More tests => 8;
use IO::Socket::Telnet;

my $IAC = chr(255);

my $socket = IO::Socket::Telnet->new();
is($socket->_parse("hello"), "hello", "no IAC means no telnet");

is($socket->_parse($IAC.$IAC), $IAC, "IAC IAC means IAC to outhandle");

is($socket->_parse($IAC), '', "single IAC does not have any output");
is($socket->_parse($IAC), $IAC, "IAC / IAC broken across calls works");

is($socket->_parse("world\n"), "world\n", "back in normal mode even after split IAC");

ok(defined($socket->_parse($IAC)), "single IAC defined value");

is($socket->_parse("${IAC}hello$IAC${IAC}world"), "${IAC}hello${IAC}world", "IAC IAC inside a regular string works fine");

is($socket->_parse("goodbye$IAC${IAC}world$IAC"), "goodbye${IAC}world", "IAC IAC inside a regular string works fine");
