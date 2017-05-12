use strict;
use warnings;
use Test::More tests => 18;
use IO::Socket::Telnet;

my $IAC = chr(255);
my $SB = chr(250);
my $SE = chr(240);

my $socket = IO::Socket::Telnet->new();
is($socket->_parse("$IAC${SB}foo$IAC$SE"), '', "full IAC / SB / ... / IAC / SE returns no text");
is($socket->_parse("hello"), "hello", "back in normal mode after IAC SB ... IAC SE");

is($socket->_parse("$IAC$SB"), '', "IAC SB returns nothing");
is($socket->_parse("foo"), '', "(IAC SB) foo returns nothing because we're appending to the subneg buffer");
is(${*$socket}{telnet_sb_buffer}, "foo", "subneg buffer is correct");
is($socket->_parse("$IAC$SE"), '', "and ending subneg doesn't generate any more output");
is($socket->_parse("there"), "there", "back in normal mode after semisplit IAC SB ... IAC SE");

is($socket->_parse($IAC), '', "IAC...");
is($socket->_parse($SB), '', "...SB...");
is($socket->_parse("bar"), '', "...bar...");
is($socket->_parse($IAC), '', "...IAC...");
is(${*$socket}{telnet_sb_buffer}, "bar", "subneg buffer is correct");
is($socket->_parse($SE), '', "...SE");

is($socket->_parse("world"), "world", "back in normal mode even after split IAC SB ... IAC SE");

is($socket->_parse("$IAC${SB}>> $IAC$IAC <<$IAC"), '', "IAC IAC inside a subneg appears to work work properly 1/2");
is(${*$socket}{telnet_sb_buffer}, ">> $IAC <<", "subneg buffer is correct");
is($socket->_parse($SE), '', "IAC IAC inside a subneg appears to work work properly 2/2");
is($socket->_parse("hello"), "hello", "back in normal mode after IAC SB ... IAC IAC ... IAC SE");

