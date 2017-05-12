# test for fix of https://rt.cpan.org/Ticket/Display.html?id=73569

use Test::More tests => 2;
use IO::Socket::INET;

use lib 't/lib';
use LSF;

my $server = make_server('tcp');

ok($server->{listener}, "listen") or diag("listen failed: $!");

my $logger = $server->connect($CLASS => LOG_AUTH, LOG_INFO, 'localhost', 'test');

my $initial_sock = $logger->_get_sock;

for (1 .. 100) {
    $logger->set_receiver($server->proto, $server->address);
    $server->accept();
}

is($logger->_get_sock, $initial_sock, "sock fd is recycled across reconnections")
    or diag sprintf "sock went from %d to %d\n", $initial_sock, $logger->_get_sock;

# vim: filetype=perl
1;
