

use Test::More tests => 2;

BEGIN { use_ok( 'Fuse::PerlSSH::FS' ); }

SKIP: {
	skip("Currently, new() connects to a remote host and we have to test-host in the ENV", 1);

	my $object = Fuse::PerlSSH::FS->new(
		host => 'example.com',
		user => 'foo',
	);
	isa_ok ($object, 'Fuse::PerlSSH::FS');
};
