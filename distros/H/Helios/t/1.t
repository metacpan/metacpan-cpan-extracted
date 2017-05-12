# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Helios.t'

# 2012-05-20:  Added tests for Helios::Error::BaseError, 
# Helios::Error::DatabaseError, Helios::Error::InvalidArg, 
# Helios::Error::LoggingError, Helios::Error, Helios::LogEntry::Levels,
# Helios::LogEntry, Helios::Logger, Helios::Logger::Internal, 
# Helios::ConfigParam, Helios::JobHistory, Helios::MetajobBurstService, and
# Helios::TestService.
# 2012-08-04:  Added tests for Helios::Config and Helios::Error::ConfigError.
# [LH] [2015-08-14]: Changed all CRLF endings to Unix-style LF endings.

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 19;
BEGIN { 
	# check the exception framework
	use_ok('Helios::Error::BaseError');
	use_ok('Helios::Error::Warning');
	use_ok('Helios::Error::Fatal');
	use_ok('Helios::Error::FatalNoRetry');
	use_ok('Helios::Error::DatabaseError');
	use_ok('Helios::Error::InvalidArg');
	use_ok('Helios::Error::LoggingError');
	use_ok('Helios::Error::ConfigError');
	use_ok('Helios::Error');

	# config
	use_ok('Helios::Config');
	
	# logging
	use_ok('Helios::LogEntry::Levels');
	use_ok('Helios::LogEntry');
	use_ok('Helios::Logger');
	use_ok('Helios::Logger::Internal');

	# collective data classes
	use_ok('Helios::ConfigParam');
	use_ok('Helios::JobHistory');

	# service classes
	use_ok('Helios::Service');
	use_ok('Helios::MetajobBurstService');
	use_ok('Helios::TestService');
	
};

#########################
