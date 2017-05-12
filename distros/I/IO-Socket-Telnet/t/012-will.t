use strict;
use warnings;
use Test::More tests => 6;
use IO::Socket::Telnet;
{ no warnings 'once'; *IO::Socket::Telnet::send = sub { } }

my $IAC = chr(255);
my $WILL = chr(251);
my $ECHO = chr(1);

my $socket = IO::Socket::Telnet->new();
is($socket->_parse("$IAC$WILL$ECHO"), '', "IAC WILL ECHO returns no value");

is($socket->_parse("alpha$IAC$WILL${ECHO}beta"), 'alphabeta', "IAC WILL ECHO does not interrupt the rest of the input stream");

is($socket->_parse($IAC), '', "IAC...");
is($socket->_parse($WILL), '', "...WILL...");
is($socket->_parse($ECHO), '', "...ECHO");

is($socket->_parse("hi"), "hi", "IAC / WILL / ECHO broken up does not screw with state");

