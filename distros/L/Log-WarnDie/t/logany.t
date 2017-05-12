#!perl -w

use warnings;
use strict;

use Test::Most;
use Test::TempDir::Tiny;
use Test::File::Contents;
use autodie qw(:all);

LOGANY: {
	eval "use Log::Any::Adapter";

	if($@) {
		plan skip_all => "Log::Any::Adapter required for checking Log::Any";
	} else {
		plan tests => 4;

		use_ok('Log::WarnDie');
		can_ok('Log::WarnDie', qw(dispatcher import unimport));

		my $filename = tempdir() . 'logany';
		Log::Any::Adapter->set('File', $filename);
		Log::WarnDie->dispatcher(Log::Any->get_logger());

		my $warn = "This warning will be displayed\n";

		warn $warn;

		my $die = "This die will not be displayed\n";
		eval {die $die};

		file_contents_like($filename, $warn, 'Verify warn message is logged');
		file_contents_like($filename, $die, 'Verify die message is logged');
	}
}
