use strict;
use warnings;

use Test::More tests => 13;

BEGIN {use_ok "Log::OK"};


use Log::OK {
	sys=>"Log::Dispatch",
	lvl=>"error"
};


ok Log::OK::EMERGENCY == 1, "Emergency OK";
ok Log::OK::EMERG == 1, "Emergency OK";
ok Log::OK::ALERT == 1, "Alert OK";
ok Log::OK::CRITICAL == 1, "Critical OK";
ok Log::OK::CRIT == 1, "Critical OK";
ok Log::OK::ERROR == 1, "Error OK";
ok Log::OK::ERR == 1, "Error OK";
ok !Log::OK::WARNING, "Warning OK";
ok !Log::OK::WARN, "Warning OK";
ok !Log::OK::NOTICE, "Notice OK";
ok !Log::OK::INFO, "Info OK";
ok !Log::OK::DEBUG, "Debug OK";
