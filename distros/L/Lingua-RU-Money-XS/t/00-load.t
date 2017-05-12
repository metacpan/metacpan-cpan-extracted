use strict;
use warnings;

use FindBin;
use lib ("lib", "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch");

use Test::Spec;
describe "Test valid import for: " => sub {
	it "Lingua::RU::Money::XS" => sub {
		use_ok('Lingua::RU::Money::XS');
	};
};

runtests unless caller;
