use strict;
use warnings;
use Test::More tests => 3;
use IO::Socket::Telnet;

my @sent;
{
    no warnings 'once';
    *IO::Socket::Telnet::send = sub {
        my ($self, $text) = @_;
        push @sent, $text;
    };
}

my @got;
my $socket = IO::Socket::Telnet->new();
$socket->telnet_complex_callback(sub { push @got, pop; return });

my $IAC = chr(255);
my $SB = chr(250);
my $SE = chr(240);
my $STATUS = chr(5);
my $IS = chr(0);


is($socket->_parse("$IAC$SB$STATUS$IS$IAC$IAC$IAC$SE"), '', "subnegotiation parsed out");
is(@got, 1, "callback called");
is(pop @got, "$STATUS$IS$IAC", "callback called with reasonable arguments");

