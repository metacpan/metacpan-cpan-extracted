#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
# Make sure Log::Log4perl loads
BEGIN { use_ok('Log::Log4perl', qw(:nowarn))
        or diag("Can't load Log::Log4perl package. Check to make sure the package library is correctly listed within the path.");
       
        # Suppress all logging messages, since we need clean output for unit testing.
        Log::Log4perl->init({
            "log4perl.rootLogger"                               => "DEBUG, Buffer",
            "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
            "log4perl.appender.Buffer.min_level"                => "fatal",
            "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
            "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
        });
}
require_ok('Log::Log4perl');
use Log::Log4perl qw(:easy);

# Make sure HoneyClient::Util::Config loads.
BEGIN { use_ok('HoneyClient::Util::Config', qw(getVar))
        or diag("Can't load HoneyClient::Util::Config package.  Check to make sure the package library is correctly listed within the path."); 

        # Suppress all logging messages, since we need clean output for unit testing.
        Log::Log4perl->init({
            "log4perl.rootLogger"                               => "DEBUG, Buffer",
            "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
            "log4perl.appender.Buffer.min_level"                => "fatal",
            "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
            "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
        });
        
}
require_ok('HoneyClient::Util::Config');
can_ok('HoneyClient::Util::Config', 'getVar');
use HoneyClient::Util::Config qw(getVar);

# Make sure the module loads properly, with the exportable
# functions shared.
BEGIN { use_ok('HoneyClient::Agent::Driver') or diag("Can't load HoneyClient::Agent::Driver package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Agent::Driver');
can_ok('HoneyClient::Agent::Driver', 'new');
can_ok('HoneyClient::Agent::Driver', 'drive');
can_ok('HoneyClient::Agent::Driver', 'isFinished');
can_ok('HoneyClient::Agent::Driver', 'next');
can_ok('HoneyClient::Agent::Driver', 'status');
use HoneyClient::Agent::Driver;

# Suppress all logging messages, since we need clean output for unit testing.
Log::Log4perl->init({
    "log4perl.rootLogger"                               => "DEBUG, Buffer",
    "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
    "log4perl.appender.Buffer.min_level"                => "fatal",
    "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
    "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
});

# Make sure we use the exception testing library.
require_ok('Test::Exception');
can_ok('Test::Exception', 'dies_ok');
use Test::Exception;

# Make sure Storable loads.
BEGIN { use_ok('Storable', qw(dclone)) or diag("Can't load Storable package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Storable');
can_ok('Storable', 'dclone');
use Storable qw(dclone);
}



# =begin testing
{
# Create a generic driver, with test state data.
my $driver = HoneyClient::Agent::Driver->new(test => 1);
is($driver->{test}, 1, "new(test => 1)") or diag("The new() call failed.");
isa_ok($driver, 'HoneyClient::Agent::Driver', "new(test => 1)") or diag("The new() call failed.");
}



# =begin testing
{
# Create a generic driver, with test state data.
my $driver = HoneyClient::Agent::Driver->new(test => 1);
dies_ok {$driver->drive()} 'drive()' or diag("The drive() call failed.  Expected drive() to throw an exception.");
}



# =begin testing
{
# Create a generic driver, with test state data.
my $driver = HoneyClient::Agent::Driver->new(test => 1);
dies_ok {$driver->isFinished()} 'isFinished()' or diag("The isFinished() call failed.  Expected isFinished() to throw an exception.");
}



# =begin testing
{
# Create a generic driver, with test state data.
my $driver = HoneyClient::Agent::Driver->new(test => 1);
dies_ok {$driver->next()} 'next()' or diag("The next() call failed.  Expected next() to throw an exception.");
}



# =begin testing
{
# Create a generic driver, with test state data.
my $driver = HoneyClient::Agent::Driver->new(test => 1);
dies_ok {$driver->status()} 'status()' or diag("The status() call failed.  Expected status() to throw an exception.");
}




1;
