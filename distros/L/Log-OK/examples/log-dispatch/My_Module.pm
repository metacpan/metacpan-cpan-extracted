package My_Module;
use strict;
use warnings;


use Log::OK {
	lvl=>"info"
};


sub do_module_stuff {
	
	Log::OK::EMERGENCY and $GLOBAL::logger->emergency("Emergency");
	Log::OK::ALERT and $GLOBAL::logger->alert("Alert");
	Log::OK::CRITICAL and $GLOBAL::logger->critical("Critical");
	Log::OK::ERROR and $GLOBAL::logger->error("Error");
	Log::OK::WARN and  $GLOBAL::logger->warn("Warning");
	Log::OK::NOTICE and $GLOBAL::logger->notice("notice");
	Log::OK::INFO and  $GLOBAL::logger->info("Info");
	Log::OK::DEBUG and $GLOBAL::logger->debug("Debug");
}

1;
