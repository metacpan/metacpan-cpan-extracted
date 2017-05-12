use strict;
use warnings;

use English;
use Test::More tests => 11;

BEGIN {
	use_ok('Getopt::CallingName');
}

use Getopt::CallingName;

test_get_name();

sub test_get_name {
	# This is deliberately local rather than my!
	local $PROGRAM_NAME = '/foo/bar/hello_world.perl';

	is(Getopt::CallingName::_get_name(), 'hello_world');

	is(Getopt::CallingName::_get_name( name_prefix => "hello_" ), 'world');

	is(Getopt::CallingName::_get_name( name_prefix => "goodbye_" ), 'hello_world');

	is(Getopt::CallingName::_get_name( method_prefix => "oi_" ), 'oi_hello_world');

	is(Getopt::CallingName::_get_name( method_suffix => "_aye" ), 'hello_world_aye');

	# Other examples of $PROGRAM_NAME values:  full path without extension,
        #                                          filename with ext,
        #                                          filename without ext,
	#                                          relative path with ext
        #                                          relative path without ext
	foreach (qw(/foo/bar/hello_world hello_world.perl hello_world bar/hello_world.perl bar/hello_world)) {
		$PROGRAM_NAME = $_;
		is(Getopt::CallingName::_get_name(), 'hello_world');
	}

}

