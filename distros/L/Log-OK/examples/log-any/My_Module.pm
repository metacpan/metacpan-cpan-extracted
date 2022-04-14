package My_Module;
use strict;
use warnings;


use Log::Any qw($log);

use Log::OK {
	lvl=>2
};


sub do_module_stuff {
	
	Log::OK::EMERGENCY and $log->emergency("Emergency");
	Log::OK::ALERT and $log->fatal("Fatal");
	Log::OK::ERROR and $log->error("Error");
	Log::OK::WARN and  $log->warn("Warning");
	Log::OK::INFO and  $log->info("Info");
	Log::OK::DEBUG and $log->debug("Debug");
	Log::OK::TRACE and $log->trace("Trace");
}

1;
