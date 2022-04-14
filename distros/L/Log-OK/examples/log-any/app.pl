use strict;
use warnings;


Log::Any::Adapter->set("Log4perl");
use Log::OK {
	lvl=>"emergency",
	opt=>"verbose"
};


my $conf=q(
	log4perl.rootLogger=TRACE, A1
	log4perl.appender.A1=Log::Log4perl::Appender::Screen
	log4perl.appender.A1.layout=PatternLayout
	log4perl.appender.A1.layout.ConversionPattern=%d %-5p %c - %m%n
	log4perl.logger.com.foo=WARN
);

use Log::Log4perl;
Log::Log4perl::init(\$conf);


use Log::Any::Adapter;
use Log::Log4perl::Level;

#my $logger=Log::Log4perl->get_logger();
#$logger->level(Log::OK::LEVEL);


my $dir;
BEGIN {
	my @seg=split "/", __FILE__;
	pop @seg;
	$dir=join "/", @seg;
}

use lib $dir;


use My_Module;

My_Module::do_module_stuff();
