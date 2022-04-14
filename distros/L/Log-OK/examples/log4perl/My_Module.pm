package My_Module;
use strict;
use warnings;


use Log::Log4perl;
my $log=Log::Log4perl->get_logger;

use Log::OK;


sub do_module_stuff {
	
	Log::OK::FATAL and $log->fatal("Fatal");
	Log::OK::ERROR and $log->error("Error");
	Log::OK::WARN and  $log->warn("Warning");
	Log::OK::INFO and  $log->info("Info");
	Log::OK::DEBUG and $log->debug("Debug");
	Log::OK::TRACE and $log->trace("Trace");
}

1;
