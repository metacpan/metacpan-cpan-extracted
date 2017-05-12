#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
# Make sure ExtUtils::MakeMaker loads.
BEGIN { use_ok('ExtUtils::MakeMaker', qw(prompt)) or diag("Can't load ExtUtils::MakeMaker package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('ExtUtils::MakeMaker');
can_ok('ExtUtils::MakeMaker', 'prompt');
use ExtUtils::MakeMaker qw(prompt);

# Generate a notice, to clarify our assumptions.
diag("About to run basic unit tests.");
diag("Note: These tests *expect* VMware Server or VMware GSX to be installed and running on this system beforehand.");

my $question;
$question = prompt("# Do you want to run basic tests?", "yes");
if ($question !~ /^y.*/i) {
    exit;
}

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

# Suppress all logging messages, since we need clean output for unit testing.
Log::Log4perl->init({
    "log4perl.rootLogger"                               => "DEBUG, Buffer",
    "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
    "log4perl.appender.Buffer.min_level"                => "fatal",
    "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
    "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
});

# Make sure the module loads properly, with the exportable
# functions shared.
BEGIN { use_ok('HoneyClient::Manager::VM') or diag("Can't load HoneyClient::Manager:VM package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Manager::VM');
can_ok('HoneyClient::Manager::VM', 'init');
can_ok('HoneyClient::Manager::VM', 'destroy');
use HoneyClient::Manager::VM;

# Make sure HoneyClient::Util::SOAP loads.
BEGIN { use_ok('HoneyClient::Util::SOAP', qw(getServerHandle getClientHandle)) or diag("Can't load HoneyClient::Util::SOAP package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Util::SOAP');
can_ok('HoneyClient::Util::SOAP', 'getServerHandle');
can_ok('HoneyClient::Util::SOAP', 'getClientHandle');
use HoneyClient::Util::SOAP qw(getServerHandle getClientHandle);

# Make sure File::Basename loads.
BEGIN { use_ok('File::Basename', qw(dirname basename)) or diag("Can't load File::Basename package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('File::Basename');
can_ok('File::Basename', 'dirname');
can_ok('File::Basename', 'basename');
use File::Basename qw(dirname basename);

# Make sure File::Copy::Recursive loads.
BEGIN { use_ok('File::Copy::Recursive', qw(dircopy pathrmdir)) or diag("Can't load File::Copy::Recursive package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('File::Copy::Recursive');
can_ok('File::Copy::Recursive', 'dircopy');
can_ok('File::Copy::Recursive', 'pathrmdir');
use File::Copy::Recursive qw(dircopy pathrmdir);

# Make sure Data::Dumper loads.
BEGIN { use_ok('Data::Dumper') or diag("Can't load Data::Dumper package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Data::Dumper');
use Data::Dumper;

# Make sure File::stat loads.
BEGIN { use_ok('File::stat') or diag("Can't load File::stat package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('File::stat');
use File::stat;

# Make sure Digest::MD5 loads.
BEGIN { use_ok('Digest::MD5', qw(md5_hex)) or diag("Can't load Digest::MD5 package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Digest::MD5');
can_ok('Digest::MD5', 'md5_hex');
use Digest::MD5 qw(md5_hex);

# Make sure DateTime::HiRes loads.
BEGIN { use_ok('DateTime::HiRes') or diag("Can't load DateTime::HiRes package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('DateTime::HiRes');
use DateTime::HiRes;

# Make sure Fcntl loads.
BEGIN { use_ok('Fcntl', qw(O_RDONLY)) or diag("Can't load Fcntl package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Fcntl');
use Fcntl qw(O_RDONLY);

# Make sure VMware::VmPerl loads.
BEGIN { use_ok('VMware::VmPerl', qw(VM_EXECUTION_STATE_ON VM_EXECUTION_STATE_OFF VM_EXECUTION_STATE_STUCK VM_EXECUTION_STATE_SUSPENDED)) or diag("Can't load VMware::VmPerl package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('VMware::VmPerl');
use VMware::VmPerl qw(VM_EXECUTION_STATE_ON VM_EXECUTION_STATE_OFF VM_EXECUTION_STATE_STUCK VM_EXECUTION_STATE_SUSPENDED);

# Make sure VMware::VmPerl::Server loads.
BEGIN { use_ok('VMware::VmPerl::Server') or diag("Can't load VMware::VmPerl::Server package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('VMware::VmPerl::Server');
use VMware::VmPerl::Server;

# Make sure VMware::VmPerl::ConnectParams loads.
BEGIN { use_ok('VMware::VmPerl::ConnectParams') or diag("Can't load VMware::VmPerl::ConnectParams package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('VMware::VmPerl::ConnectParams');
use VMware::VmPerl::ConnectParams;

# Make sure VMware::VmPerl::VM loads.
BEGIN { use_ok('VMware::VmPerl::VM') or diag("Can't load VMware::VmPerl::VM package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('VMware::VmPerl::VM');
use VMware::VmPerl::VM;

# Make sure VMware::VmPerl::VM loads.
BEGIN { use_ok('VMware::VmPerl::Question') or diag("Can't load VMware::VmPerl::Question package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('VMware::VmPerl::Question');
use VMware::VmPerl::Question;

# Make sure threads loads.
BEGIN { use_ok('threads') or diag("Can't load threads package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('threads');
use threads;

# Make sure threads::shared loads.
BEGIN { use_ok('threads::shared') or diag("Can't load threads::shared package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('threads::shared');
use threads::shared;

# Make sure Thread::Queue loads.
BEGIN { use_ok('Thread::Queue') or diag("Can't load Thread::Queue package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Thread::Queue');
use Thread::Queue;

# Make sure Thread::Semaphore loads.
BEGIN { use_ok('Thread::Semaphore') or diag("Can't load Thread::Semaphore package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Thread::Semaphore');
use Thread::Semaphore;

diag("About to run extended tests.");
# Generate a notice, to inform the tester that these tests are not
# exactly quick.
diag("Note: These extended tests will take *significant* time to complete (10-30 minutes).");

$question = prompt("# Do you want to run extended tests?", "no");
if ($question !~ /^y.*/i) {
    exit;
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Test init() method.
$URL = HoneyClient::Manager::VM->init();
is($URL, "http://localhost:$PORT/HoneyClient/Manager/VM", "init()") or diag("Failed to start up the VM SOAP server.  Check to see if any other daemon is listening on TCP port $PORT.");
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Test destroy() method.
is(HoneyClient::Manager::VM->destroy(), 1, "destroy()") or diag("Unable to terminate VM SOAP server.  Be sure to check for any stale or lingering processes.");
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
   
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Make sure the test VM is stopped.
    $som = $stub->stopVM(config => $testVM);
    
    # Test isRegisteredVM() method.
    $som = $stub->isRegisteredVM(config => $testVM);
    
    # The test VM should be registered.
    ok($som->result, "isRegisteredVM(config => '$testVM')") or diag("The isRegisteredVM() call failed.  If ($testVM) is still registered, be sure to unregister it manually.");

    # Make sure the test VM is unregistered.
    $som = $stub->unregisterVM(config => $testVM);

    # Test isRegisteredVM() method.
    $som = $stub->isRegisteredVM(config => $testVM);

    # The test VM should not be registered.
    ok(!$som->result, "isRegisteredVM(config => '$testVM')") or diag("The isRegisteredVM() call failed.  If ($testVM) is still registered, be sure to unregister it manually.");
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Test enumerate() method.
    $som = $stub->enumerate();

    # The test VM should be listed in the output.
    my @list = $som->paramsall;
    like(join(' ', @list), "/$testVM/", "enumerate()") or diag("The enumerate() call failed.  Attempted to register VM ($testVM), but the VM was not listed in the output of enumerate().");
    
    # Unregister the test VM.
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Test getStateVM() method.
    $som = $stub->getStateVM(config => $testVM);

    # The test VM should be off.
    is($som->result, VM_EXECUTION_STATE_OFF, "getStateVM(config => '$testVM')") or diag("The getStateVM() call failed.  Attempted to register VM ($testVM), but the VM state was not reported as OFF.");
    
    # Unregister the test VM.
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Test startVM() method.
    $som = $stub->startVM(config => $testVM);
    ok($som->result, "startVM(config => '$testVM')");

    # The test VM should be on.
    $som = $stub->getStateVM(config => $testVM);

    # Since the test VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $testVM);
        # Fetch the state again, to see if it's now ON.
        $som = $stub->getStateVM(config => $testVM);
    }
    is($som->result, VM_EXECUTION_STATE_ON, "startVM(config => '$testVM')") or diag("The startVM() call failed.  Attempted to start VM ($testVM), but the VM state was not reported as ON.");
    
    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register and start the test VM.
    $som = $stub->registerVM(config => $testVM);
    $som = $stub->startVM(config => $testVM);

    # Test stopVM() method.
    $som = $stub->stopVM(config => $testVM);
    ok($som->result, "stopVM(config => '$testVM')");

    # The test VM should be on.
    $som = $stub->getStateVM(config => $testVM);
    is($som->result, VM_EXECUTION_STATE_OFF, "stopVM(config => '$testVM')") or diag("The stopVM() call failed.  Attempted to stop VM ($testVM), but the VM state was not reported as OFF.");
    
    # Unregister the test VM.
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register and start the test VM.
    $som = $stub->registerVM(config => $testVM);
    $som = $stub->startVM(config => $testVM);

    # Test rebootVM() method.
    $som = $stub->rebootVM(config => $testVM);
    ok($som->result, "rebootVM(config => '$testVM')");

    # The test VM should be on.
    $som = $stub->getStateVM(config => $testVM);

    # Since the test VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $testVM);
        # Fetch the state again, to see if it's now ON.
        $som = $stub->getStateVM(config => $testVM);
    }
    is($som->result, VM_EXECUTION_STATE_ON, "rebootVM(config => '$testVM')") or diag("The rebootVM() call failed.  Attempted to reboot VM ($testVM), but the VM state was not reported as ON.");
    
    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register and start the test VM.
    $som = $stub->registerVM(config => $testVM);
    $som = $stub->startVM(config => $testVM);

    # Test suspendVM() method.
    $som = $stub->suspendVM(config => $testVM);
    ok($som->result, "suspendVM(config => '$testVM')");

    # The test VM should be suspended.
    $som = $stub->getStateVM(config => $testVM);
    is($som->result, VM_EXECUTION_STATE_SUSPENDED, "suspendVM(config => '$testVM')") or diag("The suspendVM() call failed.  Attempted to suspend VM ($testVM), but the VM state was not reported as SUSPENDED.");

    # Wake, stop, and unregister the test VM.
    $som = $stub->startVM(config => $testVM);
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Get the test VM's parent directory,
    # in order to create a temporary clone VM.
    my $testVMDir = dirname($testVM);
    my $cloneVMDir = dirname($testVMDir) . "/test_vm_clone";
    my $cloneVM = $cloneVMDir . "/" . basename($testVM);

    # Test fullCloneVM() method.
    $som = $stub->fullCloneVM(src_config => $testVM, dest_dir => $cloneVMDir);
    # Check to see if the clone's absolute file path is returned.
    is($som->result, $cloneVM, "fullCloneVM(src_config => '$testVM', dest_dir => '$cloneVMDir')");

    # Wait a small amount of time for the asynchronous clone
    # to complete.
    sleep (15);

    # The clone VM should be on.
    $som = $stub->getStateVM(config => $cloneVM);

    # Since the clone VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $cloneVM);
        # Fetch the state again, to see if it's now ON.
        $som = $stub->getStateVM(config => $cloneVM);
    }
    is($som->result, VM_EXECUTION_STATE_ON, "fullCloneVM(src_config => '$testVM', dest_dir => '$cloneVMDir')") or diag("The fullCloneVM() call failed.  Attempted to fully clone VM ($testVM) at ($cloneVM), but the cloned VM state was not reported as ON.");
  
    # Destroy the clone VM.
    $som = $stub->destroyVM(config => $cloneVM);

    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
   
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Make sure the test VM is registered.
    $som = $stub->registerVM(config => $testVM);

    # Test getNameVM() method.
    $som = $stub->getNameVM(config => $testVM);

    # The test VM should not be registered.
    is($som->result, "testVM", "getNameVM(config => '$testVM')") or diag("The getNameVM() call failed.  Expected VM ($testVM) to have the name \"testVM\".");
    
    # Unregister the test VM. 
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Get the current name of the test VM.
    $som = $stub->getNameVM(config => $testVM);
    my $oldName = $som->result;

    # Set the new name of the test VM.
    my $newName = "newVM";
    # Test setNameVM() method.
    $som = $stub->setNameVM(config => $testVM, name => $newName);
    is($som->result, $newName, "setNameVM(config => '$testVM', name => '$newName')") or diag("The setNameVM() call failed.  Attempted to change the test VM ($testVM) name of \"$oldName\" to \"$newName\".");

    # Check to make sure the new name is set.
    $som = $stub->getNameVM(config => $testVM);
    is($som->result, $newName, "setNameVM(config => '$testVM', name => '$newName')") or diag("The setNameVM() call failed.  Attempted to change the test VM ($testVM) name of \"$oldName\" to \"$newName\".");

    # Restore the old test VM name and unregister the test VM.
    $som = $stub->setNameVM(config => $testVM, name => $oldName);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Get the MAC address of the test VM.
    # Test getMACaddrVM() method.
    $som = $stub->getMACaddrVM(config => $testVM);

    # The exact MAC address of the VM will change from system to system,
    # so we check to make sure the result looks like a valid MAC address.
    like($som->result, "/[0-9a-f][0-9a-f]\:[0-9a-f][0-9a-f]\:[0-9a-f][0-9a-f]\:[0-9a-f][0-9a-f]\:[0-9a-f][0-9a-f]\:[0-9a-f][0-9a-f]/", "getMACaddrVM(config => '$testVM')") or diag("The getMACaddrVM() call failed.  Attempted to retrieve the MAC address of test VM ($testVM).");

    # Unregister the test VM.
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register and start the test VM.
    $som = $stub->registerVM(config => $testVM);
    $som = $stub->startVM(config => $testVM);

    # Wait 10 seconds, for the DHCP server to give the testVM
    # a DHCP lease.
    sleep (10);

    # Get the IP address of the test VM.
    # Test getIPaddrVM() method.
    $som = $stub->getIPaddrVM(config => $testVM);

    # The exact IP address of the VM will change from system to system,
    # so we check to make sure the result looks like a valid IP address.
    like($som->result, "/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/", "getIPaddrVM(config => '$testVM')") or diag("The getIPaddrVM() call failed.  Attempted to retrieve the IP address of test VM ($testVM).");

    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
   
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Make sure the test VM is stopped and unregistered.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);

    # Test registerVM() method.
    $som = $stub->registerVM(config => $testVM);
    ok($som->result, "registerVM(config => '$testVM')") or diag("The registerVM() call failed.");

    # The test VM should be registered.
    $som = $stub->isRegisteredVM(config => $testVM);
    ok($som->result, "registerVM(config => '$testVM')") or diag("The registerVM() call failed.  If ($testVM) is still registered, be sure to unregister it manually.");

    # Unregister the test VM.
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
   
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Make sure the test VM is stopped and registered.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->registerVM(config => $testVM);

    # Test unregisterVM() method.
    $som = $stub->unregisterVM(config => $testVM);
    ok($som->result, "unregisterVM(config => '$testVM')") or diag("The unregisterVM() call failed.");

    # The test VM should be registered.
    $som = $stub->isRegisteredVM(config => $testVM);
    ok(!$som->result, "unregisterVM(config => '$testVM')") or diag("The unregisterVM() call failed.  If ($testVM) is still registered, be sure to unregister it manually.");
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
   
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Make sure the test VM is stopped and unregistered.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);

    # The only consistent way to get a VM into a stuck state,
    # is to manually copy a VM into a new directory, register it,
    # and then proceed to start it.  VMware Server / GSX will immediately
    # ask if we'd like to create a new identifier before
    # moving on.

    # Get the test VM's parent directory,
    # in order to create a temporary clone VM.
    my $testVMDir = dirname($testVM);
    my $cloneVMDir = dirname($testVMDir) . "/test_vm_clone";
    my $cloneVM = $cloneVMDir . "/" . basename($testVM);

    # Make the destDir.
    if (!dircopy($testVMDir, $cloneVMDir)) {
        fail("answerVM()");
        diag("Could not copy test VM directory ($testVMDir) for testing answerVM() method.");
    } else {
        # Update clone VM data permissions...
        chmod(oct(700), $cloneVM);
        chmod(oct(700), glob($cloneVMDir . "/*.nvram"));
        chmod(oct(600), glob($cloneVMDir . "/*.vms*"));
        chmod(oct(600), glob($cloneVMDir . "/*REDO*"));
    }

    # Register the clone VM.
    $som = $stub->registerVM(config => $cloneVM);

    # Start the clone VM.
    # Test answerVM() method.
    $som = $stub->startVM(config => $cloneVM);
    ok($som->result, "answerVM(config => '$cloneVM')") or diag("The answerVM() call failed.");

    # Destroy the clone VM.
    $som = $stub->destroyVM(config => $cloneVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Get the test VM's parent directory,
    # in order to create a temporary clone VM.
    my $testVMDir = dirname($testVM);
    my $cloneVMDir = dirname($testVMDir) . "/test_vm_clone";
    my $cloneVM = $cloneVMDir . "/" . basename($testVM);

    # Clone the test VM.
    $som = $stub->fullCloneVM(src_config => $testVM, dest_dir => $cloneVMDir);

    # Wait a small amount of time for the asynchronous clone
    # to complete.
    sleep (15);

    # The clone VM should be on.
    $som = $stub->getStateVM(config => $cloneVM);

    # Since the clone VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $cloneVM);
    }

    # Destroy the clone VM.
    $som = $stub->destroyVM(config => $cloneVM);

    # Test destroyVM() method.
    ok($som->result, "destroyVM(config => '$cloneVM')") or diag("The destroyVM() call failed.");

    # Check to make sure the clone VM is unregistered.
    $som = $stub->isRegisteredVM(config => $cloneVM);
    ok(!$som->result, "destroyVM(config => '$cloneVM')") or diag("The destroyVM() call failed.  If ($cloneVM) is still registered, be sure to unregister it manually.");

    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # In order to test the setMasterVM() method,
    # we're going to clone the test VM, then set the clone
    # as a master VM, and finally, check to make sure
    # the corresponding permissions were set in the
    # clone, as per master VM specification.

    # Get the test VM's parent directory,
    # in order to create a temporary clone VM.
    my $testVMDir = dirname($testVM);
    my $cloneVMDir = dirname($testVMDir) . "/test_vm_clone";
    my $cloneVM = $cloneVMDir . "/" . basename($testVM);

    # Create the clone VM.
    $som = $stub->fullCloneVM(src_config => $testVM, dest_dir => $cloneVMDir);

    # Wait a small amount of time for the asynchronous clone
    # to complete.
    sleep (15);

    # The clone VM should be on.
    $som = $stub->getStateVM(config => $cloneVM);

    # Since the clone VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $cloneVM);
    }

    # Set the clone as a master VM.
    $som = $stub->setMasterVM(config => $cloneVM);

    # Test setMasterVM() method.
    ok($som->result, "setMasterVM(config => '$cloneVM')") or diag("The setMasterVM() call failed.");

    my $mode = undef;
    foreach (glob($cloneVMDir . "/*.vmdk*"),
             glob($cloneVMDir . "/*.vms*"),
             glob($cloneVMDir . "/*.vme*")) {
        $mode = sprintf("%04o", stat($_)->mode & 07777);
        is($mode, "0440", "setMasterVM(config => '$cloneVM')") or diag("The setMasterVM() call failed.  Expected file ($_) to be mode 0440, but it was mode $mode instead.");
    }

    # Destroy the clone VM.
    $som = $stub->destroyVM(config => $cloneVM);

    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # In order to test the quickCloneVM() method,
    # we're going to fully clone the test VM, then set the 
    # newly created clone as a master VM, and finally, 
    # create a secondary quick clone from the master VM.

    # Get the test VM's parent directory,
    # in order to create a temporary master and clone VM.
    my $testVMDir = dirname($testVM);
    my $masterVMDir = dirname($testVMDir) . "/test_vm_master";
    my $cloneVMDir = dirname($testVMDir) . "/test_vm_clone";
    my $masterVM = $masterVMDir . "/" . basename($testVM);
    my $cloneVM = $cloneVMDir . "/" . basename($testVM);

    # Create the master VM.
    $som = $stub->fullCloneVM(src_config => $testVM, dest_dir => $masterVMDir);

    # Wait a small amount of time for the asynchronous clone
    # to complete.
    sleep (60);

    # The master VM should be on.
    $som = $stub->getStateVM(config => $masterVM);

    # Since the master VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $masterVM);
    }

    # Set the master VM as a true master.
    $som = $stub->quickCloneVM(src_config => $masterVM, dest_dir => $cloneVMDir);
   
    # Test quickCloneVM() method.
    is($som->result, $cloneVM, "quickCloneVM(src_config => '$masterVM', dest_dir => '$cloneVMDir')") or diag("The quickCloneVM() call failed.");
    
    # Wait a small amount of time for the asynchronous clone
    # to complete.
    sleep (60);
    
    # The clone VM should be on.
    $som = $stub->getStateVM(config => $cloneVM);

    # Since the clone VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $cloneVM);
        # Fetch the state again, to see if it's now ON.
        $som = $stub->getStateVM(config => $cloneVM);
    }
    is($som->result, VM_EXECUTION_STATE_ON, "quickCloneVM(src_config => '$masterVM', dest_dir => '$cloneVMDir')") or diag("The quickCloneVM() call failed.  Attempted to quick clone VM ($masterVM) at ($cloneVM), but the cloned VM state was not reported as ON.");

    # Destroy the clone and master VM.
    $som = $stub->destroyVM(config => $cloneVM);
    $som = $stub->destroyVM(config => $masterVM);

    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Get the test VM's parent directory,
    # in order to create a temporary clone VM.
    my $testVMDir = dirname($testVM);
    my $cloneVMDir = dirname($testVMDir) . "/test_vm_clone";
    my $cloneVM = $cloneVMDir . "/" . basename($testVM);

    # Specify where the snapshot should be created.
    my $snapshot = dirname($testVMDir) . "/test_vm_clone.tar.gz";

    # In order to test the snapshotVM() method, we create
    # a full clone VM, power it on, create a snapshot, and
    # then revert the clone back to the snapshot.

    # Create the clone VM.
    $som = $stub->fullCloneVM(src_config => $testVM, dest_dir => $cloneVMDir);

    # Wait a small amount of time for the asynchronous clone
    # to complete.
    sleep (30);

    # The clone VM should be on.
    $som = $stub->getStateVM(config => $cloneVM);

    # Since the clone VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $cloneVM);
    }
 
    # Snapshot the running clone.
    $som = $stub->snapshotVM(config => $cloneVM, snapshot_file => $snapshot);

    # Test snapshotVM() method.
    is($som->result, $snapshot, "snapshotVM(config => '$cloneVM', snapshot_file => '$snapshot')") or diag("The snapshotVM() call failed.");

    # Wait a small amount of time for the asynchronous snapshot
    # to complete.
    sleep (45);

    # Now, revert the VM using the snapshot.
    $som = $stub->revertVM(config => $cloneVM, snapshot_file => $snapshot);
    is($som->result, $cloneVM, "snapshotVM(config => '$cloneVM', snapshot_file => '$snapshot')") or diag("The snapshotVM() call failed.");
    
    # Wait a small amount of time for the asynchronous revert
    # to complete.
    sleep (60);

    # Make sure the clone VM is started.
    $som = $stub->getStateVM(config => $cloneVM);
    $som = $stub->startVM(config => $cloneVM);

    # Wait for the clone VM to be started.
    sleep (60);

    # The clone VM should be on.
    $som = $stub->getStateVM(config => $cloneVM);

    # Since the clone VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $cloneVM);
        # Fetch the state again, to see if it's now ON.
        $som = $stub->getStateVM(config => $cloneVM);
    }
    is($som->result, VM_EXECUTION_STATE_ON, "snapshotVM(config => '$cloneVM', snapshot_file => '$snapshot')") or diag("The snapshotVM() call failed.  Attempted to snapshot VM ($cloneVM), but the VM state was not reported as ON.");

    # Destroy the clone VM.
    $som = $stub->destroyVM(config => $cloneVM);

    # Destroy the snapshot.
    unlink $snapshot;

    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}



# =begin testing
{
# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Get the test VM's parent directory,
    # in order to create a temporary clone VM.
    my $testVMDir = dirname($testVM);
    my $cloneVMDir = dirname($testVMDir) . "/test_vm_clone";
    my $cloneVM = $cloneVMDir . "/" . basename($testVM);

    # Specify where the snapshot should be created.
    my $snapshot = dirname($testVMDir) . "/test_vm_clone.tar.gz";

    # In order to test the revertVM() method, we create
    # a full clone VM, power it on, create a snapshot, and
    # then revert the clone back to the snapshot.

    # Create the clone VM.
    $som = $stub->fullCloneVM(src_config => $testVM, dest_dir => $cloneVMDir);

    # Wait a small amount of time for the asynchronous clone
    # to complete.
    sleep (30);

    # The clone VM should be on.
    $som = $stub->getStateVM(config => $cloneVM);

    # Since the clone VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $cloneVM);
    }
 
    # Snapshot the running clone.
    $som = $stub->snapshotVM(config => $cloneVM, snapshot_file => $snapshot);

    # Wait a small amount of time for the asynchronous snapshot
    # to complete.
    sleep (60);

    # Now, revert the VM using the snapshot.
    $som = $stub->revertVM(config => $cloneVM, snapshot_file => $snapshot);

    # Test revertVM() method.
    is($som->result, $cloneVM, "revertVM(config => '$cloneVM', snapshot_file => '$snapshot')") or diag("The revertVM() call failed.");
    
    # Wait a small amount of time for the asynchronous revert
    # to complete.
    sleep (60);

    # Make sure the clone VM is started.
    $som = $stub->getStateVM(config => $cloneVM);
    $som = $stub->startVM(config => $cloneVM);

    # Wait a small amount of time for the start to occur.
    sleep (60);

    # The clone VM should be on.
    $som = $stub->getStateVM(config => $cloneVM);

    # Since the clone VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $cloneVM);
        # Fetch the state again, to see if it's now ON.
        $som = $stub->getStateVM(config => $cloneVM);
    }
    is($som->result, VM_EXECUTION_STATE_ON, "revertVM(config => '$cloneVM', snapshot_file => '$snapshot')") or diag("The revertVM() call failed.  Attempted to revert VM ($cloneVM) using snapshot file ($snapshot), but the VM state was not reported as ON.");

    # Destroy the clone VM.
    $som = $stub->destroyVM(config => $cloneVM);

    # Destroy the snapshot.
    unlink $snapshot;

    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}
}




1;
