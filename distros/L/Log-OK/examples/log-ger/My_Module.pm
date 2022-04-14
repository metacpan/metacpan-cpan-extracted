package My_Module;
use strict;
use warnings;


use Log::ger;
use Log::OK {
	lvl=>"info"
};


sub do_module_stuff {
	Log::OK::FATAL and log_fatal("Fatal");
	Log::OK::ERROR and log_error("Error");
	Log::OK::WARN and  log_warn("Warning");
	Log::OK::INFO and  log_info("Info");
	Log::OK::DEBUG and log_debug("Debug");
	Log::OK::TRACE and log_trace("Trace");
}
1;
