#!/usr/bin/perl

# $Id: 03-htc-methods.t 10901 2008-05-01 20:21:28Z victor $

# This is a unit test script for the Grid::Request module. Therefore we are
# mainly checking that method calls get routed to the proper classes. To
# eliminate dependencies and isolate this module's testing from the other
# modules, we mock them with the help of the Test::MockObject module, available
# from CPAN.

use strict;
use FindBin qw($Bin);
use Log::Log4perl qw(:easy);
use Test::More tests => 335;
use Test::MockObject;
use XML::Simple;
use lib ("$Bin/../lib");
use Grid::Request::Test;

# Grid::Request uses Log::Log4perl, so we initialize a logger here in the test script.
Log::Log4perl->init("$Bin/testlogger.conf");


my @cmd_meths = qw( add_param block_size class command end_time error
                    getenv project input initialdir output name params priority
                    start_time state times email hosts opsys evictable
                    memory runtime pass_through cmd_type);

my $params_count = 0;

my $mock_command = Test::MockObject->new();
# Here we are tricking Perl into thinking the following modules have already
# been loaded. We must do this step before attempting to load the main module
# we are trying to test. See the Test::MockObject document for further details
# about the fake_module method.
#$mock_command->fake_module( 'Grid::Request::Command' );
# Now we wish to replace constructor calls (new) in such a way that they return
# the mock object. This will force the tested module to use the mock objects we
# have created.
$mock_command->fake_new( 'Grid::Request::Command' );

# Now we will mock the methods contained in the Command class.
$mock_command->mock("add_param", sub { $params_count++; } );
$mock_command->set_always("block_size", 777);
$mock_command->set_always("class", "class");
$mock_command->set_always("command", "/usr/bin/ls");
$mock_command->set_always("end_time", "00:00:05");
$mock_command->set_always("email", 'test@example.com');
$mock_command->set_always("error", "/path/to/error");
$mock_command->set_always("hosts", "testhost");
$mock_command->set_always("getenv", 1);
$mock_command->set_always("project", "SomeProject");
$mock_command->set_always("input", "/path/to/input");
$mock_command->set_always("initialdir", "/path/to/initialdir");
$mock_command->set_always("output", "/path/to/output");
$mock_command->set_always("name", "somename");
$mock_command->set_always("params", ());
$mock_command->set_always("priority", 4);
$mock_command->set_always("start_time", "00:00:01");
$mock_command->set_always("state", "running");
$mock_command->set_always("times", 5);
$mock_command->set_always("to_xml", "data");
$mock_command->set_always("opsys", "Linux");
$mock_command->set_always("evictable", "Y");
$mock_command->set_always("memory", 8);
$mock_command->set_always("runtime", 8);
$mock_command->set_always("pass_through", "X");
$mock_command->set_always("cmd_type", "htc");

use_ok("Grid::Request");
my $module = Grid::Request->new();
can_ok($module, "submit");
can_ok($module, "submit_serially");
can_ok($module, "submit_and_wait");
can_ok($module, "wait_for_request");
can_ok($module, "command_count");
can_ok($module, "new_command");


#close (STDERR);  # Close our STDERR to keep output clean for harnesses.

# Instantiate the class.
my $o = Grid::Request->new();

is( $o->_com_obj, $mock_command,
             'new() should create and store a new Command object' );

$o->add_param();
is( $params_count, 1, "Test the add_param method.");

is( $o->block_size, 777, "Test the block_size method.");
is( $o->class, "class", "Test the class method.");
is( $o->command, "/usr/bin/ls", "Test the command method.");
is( $o->email, 'test@example.com', "Test the email method.");
is( $o->end_time, "00:00:05", "Test the end_time method.");
is( $o->error, "/path/to/error", "Test the error method.");
is( $o->hosts, 'testhost', "Test the hosts method.");
is( $o->getenv, 1, "Test the getenv method.");
is( $o->project, "SomeProject", "Test the project method.");
is( $o->input, "/path/to/input", "Test the input method.");
is( $o->initialdir, "/path/to/initialdir", "Test the initialdir method.");
is( $o->output, "/path/to/output", "Test the output method.");
is( $o->name, "somename", "Test the name method.");
is( $o->params, (), "Test the params method.");
is( $o->priority, 4, "Test the priority method.");
is( $o->start_time, "00:00:01", "Test the start_time method.");
is( $o->state, "running", "Test the state method.");
is( $o->times, 5, "Test the times method.");
is( $o->opsys, "Linux", "Test the opsys method.");
is( $o->evictable, "Y", "Test the evictable method.");
is( $o->memory, 8, "Test the memory method.");
is( $o->runtime, 8, "Test the runtime method.");
is( $o->pass_through, "X", "Test the pass_through method.");
is( $o->cmd_type, "htc", "Test the cmd_type method.");

# Use the XMLin method to parse the output of the to_xml method in the
# Request module.
my $xml_in = XMLin($o->to_xml);
is( $xml_in, "data", "Test the to_xml method.");

check_if_called($mock_command, \@cmd_meths);
clear($mock_command, \@cmd_meths);


# Now test the same methods with "get_" prefixed to see if we still get the
# same information.
$o->add_param();
is( $params_count, 2, "Test the add_param method.");

is( $o->get_block_size, 777, "Test the block_size method as get_block_size.");
is( $o->get_class, "class", "Test the class method as get_class.");
is( $o->get_command, "/usr/bin/ls", "Test the command method as get_command.");
is( $o->get_email, 'test@example.com', "Test the email method as get_email.");
is( $o->get_end_time, "00:00:05", "Test the end_time method as get_end_time.");
is( $o->get_error, "/path/to/error", "Test the error method as get_error.");
is( $o->get_getenv, 1, "Test the getenv method as get_getenv.");
is( $o->get_hosts, 'testhost', "Test the hosts method as get_hosts.");
is( $o->get_project, "SomeProject", "Test the project method as get_project.");
is( $o->get_input, "/path/to/input", "Test the input method as get_input.");
is( $o->get_initialdir, "/path/to/initialdir", "Test the initialdir method " .
                                               "as get_initialdir.");
is( $o->get_output, "/path/to/output", "Test the output method as get_output.");
is( $o->get_name, "somename", "Test the name method as get_name.");
is( $o->get_params, (), "Test the params method as get_params.");
is( $o->get_priority, 4, "Test the priority method as get_priority.");
is( $o->get_start_time, "00:00:01", "Test the start_time method " .
                                    "as get_start_time.");
is( $o->get_state, "running", "Test the state method as get_state.");
is( $o->get_times, 5, "Test the times method as get_times.");
is( $o->get_opsys, "Linux", "Test the opsys method as get_opsys.");
is( $o->get_evictable, "Y", "Test the evictable method as get_evictable.");
is( $o->get_memory, 8, "Test the memory method as get_memory.");
is( $o->get_runtime, 8, "Test the runtime method as get_runtime.");
is( $o->get_pass_through, "X", "Test the pass_through method as get_pass_through.");
is( $o->get_cmd_type, "htc", "Test the cmd_type method as get_cmd_type.");


check_if_called($mock_command, \@cmd_meths);

is( $o->is_submitted, 0, "is_submitted method correct before submission.");

foreach my $method (@cmd_meths) {
    my $set_name = "set_$method";
    my $get_name = "get_$method";
    my $junk = "XXXXX";

    undef $@;
    eval {
        $o->$method($junk);
    };
    ok(defined($@), "$method causes error as setter after submit.");
    isnt($o->$method, $junk,  "$method does not work after submit. (simple accessor).");
    isnt($o->$get_name, $junk, "$method does not work after submit ('get' accessor).");

    undef $@;
    eval {
        $o->$set_name($junk);
    };
    ok(defined($@), "$set_name causes error as setter after submit.");
    isnt($o->$method, $junk,  "$set_name does not work after submit (simple accessor).");
    isnt($o->$get_name, $junk, "$set_name does not work after submit ('get' accessor).");

    undef $@;
    eval {
        $o->$get_name($junk);
    };
    ok(defined($@), "$get_name causes error as setter after submit.");
    isnt($o->$method, $junk,  "Getter w/ args, $get_name, doesn't work after submit (simple accessor).");
    isnt($o->$get_name, $junk, "Getter w/ args, $get_name, doesn't work after submit ('get' accessor).");
}

exit;

#############################################################################

sub check_if_called {
    my ($object, $meth_ref) = @_;
    # When Perl 5.8 becomes standard, we should use Class::ISA to
    # check, which will allow subclassing of the MockObject class. This also
    # applies to the clear function.
    die "Not a mock object!" unless (ref($object) eq "Test::MockObject");
    foreach my $meth (@$meth_ref) {
        is( $object->called($meth), 1, "$meth called on the right object.");
    }

}

sub clear {
    my ($object, $meth_ref) = @_;
    die "Not a mock object!" unless (ref($object) eq "Test::MockObject");
    foreach my $meth (@$meth_ref) {
        $object->clear($meth);
    }
}
