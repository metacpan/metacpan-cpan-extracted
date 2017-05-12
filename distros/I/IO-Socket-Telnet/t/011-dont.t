use strict;
use warnings;
use Test::More tests => 6;
use IO::Socket::Telnet;
{ no warnings 'once'; *IO::Socket::Telnet::send = sub { } }

my $IAC = chr(255);
my $DONT = chr(254);
my $ECHO = chr(1);

my $socket = IO::Socket::Telnet->new();
is($socket->_parse("$IAC$DONT$ECHO"), '', "IAC DONT ECHO returns no value");

is($socket->_parse("alpha$IAC$DONT${ECHO}beta"), 'alphabeta', "IAC DONT ECHO does not interrupt the rest of the input stream");

is($socket->_parse($IAC), '', "IAC...");
is($socket->_parse($DONT), '', "...DONT...");
is($socket->_parse($ECHO), '', "...ECHO");

is($socket->_parse("hi"), "hi", "IAC / DONT / ECHO broken up does not screw with state");

