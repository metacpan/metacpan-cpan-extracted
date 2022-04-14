use strict;
use warnings;
use feature "say";

use Log::ger::Output "Screen";
use Log::ger::Util;

use Log::OK {
	lvl=>"fatal",
	opt=>"verbose"
};

Log::ger::Util::set_level(Log::OK::LEVEL);

my $dir;
BEGIN {
	my @seg=split "/", __FILE__;
	pop @seg;
	$dir=join "/", @seg;
}
use lib $dir;


use My_Module;







My_Module::do_module_stuff();

