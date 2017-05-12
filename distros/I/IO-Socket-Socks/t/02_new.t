use Test::More tests=>3;

BEGIN{ use_ok( "IO::Socket::Socks" ); }

my $socks = new IO::Socket::Socks();
ok( defined($socks), "new()");
isa_ok( $socks, "IO::Socket::Socks");

