use Test::More tests=>1;

BEGIN{ use_ok( "IO::Socket::Socks" ); }
warn "$IO::Socket::Socks::SOCKET_CLASS v".("$IO::Socket::Socks::SOCKET_CLASS"->VERSION)." used as base class\n";
