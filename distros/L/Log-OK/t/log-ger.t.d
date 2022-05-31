use strict;
use warnings;

use Test::More tests => 7;

BEGIN {use_ok "Log::OK"};

use Log::OK {
	sys=>"Log::ger",
	lvl=>"Info"
};

ok Log::OK::FATAL == 1, "Fatal OK";
ok Log::OK::ERROR == 1, "Fatal OK";
ok Log::OK::WARN == 1, "Warn OK";
ok Log::OK::INFO == 1, "Info OK";
ok !Log::OK::DEBUG, "Debug OK";
ok !Log::OK::TRACE, "Trace OK";
