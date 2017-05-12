use Test::More tests => 4;
use Mail::DomainKeys::Key::Public;

use strict;


SKIP: {
	(-e "t/connected") or
		skip("need connectivity", 4);

	my $pubk = fetch Mail::DomainKeys::Key::Public(
		Protocol => "dns", Domain => "yahoo.com", Selector => "s1024");

	ok(defined $pubk, "got the key...");
	isa_ok($pubk, "Mail::DomainKeys::Key::Public");
	is($pubk->type, "rsa", "and the correct type... ");
	is($pubk->cork->size, 128, "and the correct size!");
}
