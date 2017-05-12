use strict;
use warnings;
use Test::More tests => 7;

use_ok 'IO::Socket::Telnet';
my $socket = IO::Socket::Telnet->new();
ok($socket);
ok($socket->can('send'));
ok($socket->can('recv'));
ok($socket->can('getline'));
ok($socket->can('print'));
ok($socket->can('_parse'));

