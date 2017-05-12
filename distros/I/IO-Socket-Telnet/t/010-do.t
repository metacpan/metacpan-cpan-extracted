use strict;
use warnings;
use Test::More tests => 6;
use IO::Socket::Telnet;
{ no warnings 'once'; *IO::Socket::Telnet::send = sub { } }

my $IAC = chr(255);
my $DO = chr(253);
my $ECHO = chr(1);

my $socket = IO::Socket::Telnet->new();
is($socket->_parse("$IAC$DO$ECHO"), '', "IAC DO ECHO returns no value");

is($socket->_parse("alpha$IAC$DO${ECHO}beta"), 'alphabeta', "IAC DO ECHO does not interrupt the rest of the input stream");

is($socket->_parse($IAC), '', "IAC...");
is($socket->_parse($DO), '', "...DO...");
is($socket->_parse($ECHO), '', "...ECHO");

is($socket->_parse("hi"), "hi", "IAC / DO / ECHO broken up does not screw with state");

