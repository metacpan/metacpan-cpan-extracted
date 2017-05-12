use Test::More tests => 1;

print "bail out! Script file is missing!" unless
	use_ok( "Mac::iPhoto::Shell" );
