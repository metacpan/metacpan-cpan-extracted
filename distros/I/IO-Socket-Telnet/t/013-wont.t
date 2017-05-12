use strict;
use warnings;
use Test::More tests => 6;
use IO::Socket::Telnet;
{ no warnings 'once'; *IO::Socket::Telnet::send = sub { } }

my $IAC = chr(255);
my $WONT = chr(252);
my $ECHO = chr(1);

my $socket = IO::Socket::Telnet->new();
is($socket->_parse("$IAC$WONT$ECHO"), '', "IAC WONT ECHO returns no value");

is($socket->_parse("alpha$IAC$WONT${ECHO}beta"), 'alphabeta', "IAC WONT ECHO does not interrupt the rest of the input stream");

is($socket->_parse($IAC), '', "IAC...");
is($socket->_parse($WONT), '', "...WONT...");
is($socket->_parse($ECHO), '', "...ECHO");

is($socket->_parse("hi"), "hi", "IAC / WONT / ECHO broken up does not screw with state");

