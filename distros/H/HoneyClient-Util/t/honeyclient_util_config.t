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

# Make sure the module loads properly, with the exportable
# functions shared.
BEGIN { use_ok('HoneyClient::Util::Config', qw(getVar setVar)) 
        or diag("Can't load HoneyClient::Util::Config package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Util::Config');
can_ok('HoneyClient::Util::Config', 'getVar');
can_ok('HoneyClient::Util::Config', 'setVar');
use HoneyClient::Util::Config qw(getVar setVar);

# Suppress all logging messages, since we need clean output for unit testing.
Log::Log4perl->init({
    "log4perl.rootLogger"                               => "DEBUG, Buffer",
    "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
    "log4perl.appender.Buffer.min_level"                => "fatal",
    "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
    "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
});

# Make sure XML::XPath loads.
BEGIN { use_ok('XML::XPath') 
        or diag("Can't load XML::XPath package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('XML::XPath');
can_ok('XML::XPath', 'findnodes');
use XML::XPath;

# Make sure XML::Tidy loads
BEGIN { use_ok('XML::Tidy')
        or diag("Can't load XML::Tidy package. Check to make sure the package library is correctly listed within the path."); }
require_ok('XML::Tidy');
can_ok('XML::Tidy','tidy');
can_ok('XML::Tidy','write');
use XML::Tidy;

# Make sure Sys::Syslog loads
BEGIN { use_ok('Sys::Syslog')
        or diag("Can't load Sys::Syslog package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Sys::Syslog');
use Sys::Syslog;

# Make sure Data::Dumper loads
BEGIN { use_ok('Data::Dumper')
        or diag("Can't load Data::Dumper package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Data::Dumper');
use Data::Dumper;

# Make sure Log::Dispatch::Syslog loads
BEGIN { use_ok('Log::Dispatch::Syslog')
        or diag("Can't load Log::Dispatch::Syslog package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Log::Dispatch::Syslog');
use Log::Dispatch::Syslog;
}



# =begin testing
{
my $value = getVar(name => "address", namespace => "HoneyClient::Util::Config::Test");
is($value, "localhost", "getVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test')") 
    or diag("The getVar() call failed.  Attempted to get variable 'address' using namespace 'HoneyClient::Util::Config::Test' within the global configuration file.");

$value = getVar(name => "address", namespace => "HoneyClient::Util::Config::Test", attribute => 'default');
is($value, "localhost", "getVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', attribute => 'default')") 
    or diag("The getVar() call failed.  Attempted to get attribute 'default' for variable 'address' using namespace 'HoneyClient::Util::Config::Test' within the global configuration file.");

# This check tests to make sure getVar() is able to use valid output
# from undefined namespaces (but where some of the parent namespace is
# partially known).
$value = getVar(name => "address", namespace => "HoneyClient::Util::Config::Test::Undefined::Child", attribute => 'default');
is($value, "localhost", "getVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test::Undefined::Child', attribute => 'default')") 
    or diag("The getVar() call failed.  Attempted to get attribute 'default' for variable 'address' using namespace 'HoneyClient::Util::Config::Test::Undefined::Child' within the global configuration file.");

# This check tests to make sure getVar() returns the expected hashref
# when getting data from a target element that contains child sub-elements.
$value = getVar(name => "Yok", namespace => "HoneyClient::Util::Config::Test");
my $expectedValue = {
    'childA' => [ '12345678', 'ABCDEFGH' ],
    'childB' => [ '09876543', 'ZYXVTUWG' ],
};
is_deeply($value, $expectedValue, "getVar(name => 'Yok', namespace => 'HoneyClient::Util::Config::Test')") 
    or diag("The getVar() call failed.  Attempted to get variable 'Yok' using namespace 'HoneyClient::Util::Config::Test' within the global configuration file.");
}



# =begin testing
{
# Test setting an existing value
my $oldval = getVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test' );
setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', value => 'foobar' );
my $value = getVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test' );
is($value, 'foobar', "setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', value => 'foobar' )") 
    or diag("The setVar() call failed.  Attempted to set variable 'address' using namespace 'HoneyClient::Util::Config::Test' to 'foobar' within the global configuration file.");
setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', value => $oldval );

# Test setting an attribute
$oldval = getVar(name => 'address', attribute => 'default', namespace => 'HoneyClient::Util::Config::Test' );
setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', attribute => 'default', value => 'foobar' );
$value = getVar(name => 'address', attribute => 'default', namespace => 'HoneyClient::Util::Config::Test' );
is($value, 'foobar', "setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', attribute => 'default', value => 'foobar' )")
    or diag("The setVar() call failed.  Attempted to set 'default' attribute of variable 'address' using namespace 'HoneyClient::Util::Config::Test' to 'foobar' within the global configuration file.");
setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', attribute => 'default', value => $oldval );

# Test creating a value
setVar(name => 'zingers', namespace => 'HoneyClient::Util::Config::Test', value => 'foobar');
$value = getVar(name => 'zingers', namespace => 'HoneyClient::Util::Config::Test' );
is($value, 'foobar', "setVar(name => 'zingers', namespace => 'HoneyClient::Util::Config::Test', value => 'foobar' )") 
    or diag("The setVar() call failed.  Attempted to create variable 'zing' using namespace 'HoneyClient::Util::Config::Test' with a value of 'foobar' within the global configuration file.");

# Test creating an attribute
setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', attribute => 'zing', value => 'foobar');
$value = getVar(name => 'address', attribute => 'zing', namespace => 'HoneyClient::Util::Config::Test' );
is($value, 'foobar', "setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', attribute => 'zing', value => 'foobar' )")
    or diag("The setVar() call failed.  Attempted to create attribute 'zing' using namespace 'HoneyClient::Util::Config::Test' with a value of 'foobar' within the global configuration file.");

# Creating new namespaces
setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test::Foo::Bar', value => 'baz');
$value =  getVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test::Foo::Bar');
is($value, 'baz', "setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test::Foo::Bar', value => 'baz')")
    or diag("The setVar() call failed.  Attempted to create attribute 'address' using namespace 'HoneyClient::Util::Config::Test::Foo::Bar' with a value of 'baz' within global configuration file.");
}




1;
