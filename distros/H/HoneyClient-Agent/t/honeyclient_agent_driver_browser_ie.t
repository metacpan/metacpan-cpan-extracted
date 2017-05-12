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
BEGIN { use_ok('HoneyClient::Agent::Driver::Browser::IE') or diag("Can't load HoneyClient::Agent::Driver::Browser::IE package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Agent::Driver::Browser::IE');
can_ok('HoneyClient::Agent::Driver::Browser::IE', 'new');
can_ok('HoneyClient::Agent::Driver::Browser::IE', 'drive');
can_ok('HoneyClient::Agent::Driver::Browser::IE', 'isFinished');
can_ok('HoneyClient::Agent::Driver::Browser::IE', 'next');
can_ok('HoneyClient::Agent::Driver::Browser::IE', 'status');
can_ok('HoneyClient::Agent::Driver::Browser::IE', 'getNextLink');
use HoneyClient::Agent::Driver::Browser::IE;

# Suppress all logging messages, since we need clean output for unit testing.
Log::Log4perl->init({
    "log4perl.rootLogger"                               => "DEBUG, Buffer",
    "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
    "log4perl.appender.Buffer.min_level"                => "fatal",
    "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
    "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
});

# Make sure Win32::Job loads.
BEGIN { use_ok('Win32::Job') or diag("Can't load Win32::Job package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Win32::Job');
use Win32::Job;

# Make sure ExtUtils::MakeMaker loads.
BEGIN { use_ok('ExtUtils::MakeMaker', qw(prompt)) or diag("Can't load ExtUtils::MakeMaker package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('ExtUtils::MakeMaker');
can_ok('ExtUtils::MakeMaker', 'prompt');
use ExtUtils::MakeMaker qw(prompt);
}



# =begin testing
{
# Generate a notice, to clarify our assumptions.
diag("");
diag("About to run basic IE-specific browser tests.");
diag("Note: These tests *require* network connectivity and");
diag("*expect* IE to be installed at the following location.");
diag("");

my $processExec = getVar(name      => "process_exec",
                         namespace => "HoneyClient::Agent::Driver::Browser::IE");
my $processName = getVar(name      => "process_name",
                         namespace => "HoneyClient::Agent::Driver::Browser::IE");

diag("Process Name:\t\t'" . $processName . "'");
diag("Process Location:\t'" . $processExec . "'");
diag("");
diag("If IE is installed in a different location or has a different executable name,");
diag("then please answer *NO* to the next question and update your etc/honeyclient.xml");
diag("file, changing the 'process_name' and 'process_exec' elements in the");
diag("<HoneyClient/><Agent/><Driver/><Browser/><IE/> section.");
diag("");
diag("Then, once updated, re-run these tests.");
diag("");

my $question;
$question = prompt("# Do you want to run these tests?", "yes");
if ($question !~ /^y.*/i) {
    exit;
}

my $ie = HoneyClient::Agent::Driver::Browser::IE->new(test => 1);
is($ie->{test}, 1, "new(test => 1)") or diag("The new() call failed.");
isa_ok($ie, 'HoneyClient::Agent::Driver::Browser::IE', "new(test => 1)") or diag("The new() call failed.");

diag("");
diag("About to drive IE to a specific website for *exactly* " . $ie->{timeout} . " seconds.");
diag("Note: Please do *NOT* close the browser manually; the test code should close it automatically.");
diag("");

$question = prompt("# Which website should IE browse to?", "http://www.google.com");
$ie->drive(url => $question);

diag("");
$question = prompt("# Did IE properly render the page and automatically exit?", "yes");
if ($question !~ /^y.*/i) {
    diag("");
    diag("Check your network connectivity and verify that you can manually browse this page in IE.");
    diag("Then, re-run these tests.");
    diag("");
    diag("If the tests still do not work, please submit a ticket to:");
    diag("http://www.honeyclient.org/trac/newticket");
    diag("");
    fail("The drive() call failed.");
}
}




1;
