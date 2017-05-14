#!/usr/bin/perl

# This is a unit test script for the Grid::Request::Command module.

# $Id: Command.t 10901 2008-05-01 20:21:28Z victor $


use strict;
use FindBin qw($Bin); # To make finding our other modules easy.
use Log::Log4perl;
use lib "$Bin/../lib";
use Grid::Request::HTC;
use XML::Simple;

# Initialization Section. Using a special logger configuration that
# does not send anything to the screen (only to a log file).
Log::Log4perl::init("$Bin/testlogger.conf");

# Close STDERR, because we don't want warnings and output to STDERR
# to polute our testing output. Not sure, but it might screw up any
# testing harness we may be using. For this reason, let's be safe and
# just close STDERR (we'll be generating lots of warnings and errors
# with the tests below).
close (STDERR);

# During maintenance, it may be helpful to use no_plan, and then change the
# the real number of tests, once that number is known.
use Test::More tests => 77;

# First we will see if we can successfully load the tested module.
use_ok( 'Grid::Request::Command' );

my $o;

# Eliminate annoying warning about single usage.
if ($^W) {
    %Grid::Request::Command::VALID_STATE =
    %Grid::Request::Command::VALID_STATE;
}
my %valid_states = %Grid::Request::Command::VALID_STATE;

eval {
    $o = Grid::Request::Command->new();
};
ok(!($@), "Test minimal constructor call. $@");

my $config_file = Grid::Request::HTC->config();
my $config = Config::IniFiles->new(-file => $config_file);
my $tempdir = $config->val("request", "tempdir");

can_ok($o, "tempdir");
$o->tempdir($tempdir);
is($o->tempdir(), $tempdir, "Can retrieve the set temporary directory.");

my @params = $o->params;
is (scalar(@params), 0, "Test params method.");
$o->{params} = [1, 2, 3];
@params = $o->params;
is (scalar(@params), 3, "Test params method with multiple params set.");

# Clear the params before proceeding with furhter tests.
$o->{params} = [];

$o->add_param("param1");
is (scalar($o->params), 1, "Test add_param method.");
$o->add_param("param2");
is (scalar($o->params), 2, "Test subsequent add_param.");

@params = $o->params;
ok(($params[0]->value() eq "param1") && ($params[0]->type() eq "PARAM"),
    "Test data for simple param."); 
ok(($params[1]->value() eq "param2") && ($params[1]->type() eq "PARAM"),
    "Test data for 2nd param."); 
eval {
    $o->add_param("param4", "key4", "BADTYPE");
};
isnt(scalar($o->params), 4, "Test subsequent add_param (with bad type).");
eval {
    $o->add_param();
};
isnt(scalar($o->params), 4, "Test add_param invocation with no arguments.");

$@ = undef;
eval {
    $o->add_param( {} );
};
ok($@, "add_param invocation with empty hashref causes error.");
isnt(scalar($o->params), 4, "Test add_param invocation with empty hashref.");
$o->add_param( {value => "value1" } );
is(scalar($o->params), 3, "Test add_param with hashref containing only value (lc).");
$o->add_param( {VALUE => "value2" } );
is(scalar($o->params), 4, "Test add_param with hashref containing only value (uc).");
$o->add_param( {VaLuE => "value3" } );
is(scalar($o->params), 5, "Test add_param with hashref only value (mixed).");


eval {
    $o->add_param( { value => "value4",
                     type  => "BADTYPE",
                     key   => "key4" } );
};
is(scalar($o->params), 5, "add_param with full hashref and bad type fails.");

my $count=5;
foreach my $type qw(PARAM DIR FILE ARRAY) { 
    my $value;
    if ($type eq "FILE") {
        $value = "$Bin/test_data/entries_with_whitespace.txt";
    } elsif ($type eq "DIR") {
        $value = "$Bin/test_data/test_dir";
    } elsif ($type eq "ARRAY") {
        $value = [1,2,3];
    } else {
        $value = "value";
    }
    $o->add_param( {value => $value,
                    type  => $type,
                    key   => "key$count" } );

    is(scalar($o->params), ++$count, "add_param with full hashref and type $type.");
}

$o->project("someproject");
is ($o->project, "someproject", "Test project getter.");
$o->project("someproject2");
is ($o->project, "someproject2", "Test project setter.");

$o->{class} = "someclass";
is ($o->class, "someclass", "Test class getter.");
$o->class("someclass2");
is ($o->class, "someclass2", "Test class setter.");

$o->{command} = "/usr/bin/ls";
is ($o->command, "/usr/bin/ls", "Test command getter.");
$o->command("/some/path/to/exe");
is ($o->command, "/some/path/to/exe", "Test command setter.");

$o->{end_time} = "00:00:05";
is($o->end_time, "00:00:05", "Test end_time getter.");
# This should fail now because we are not an authorized caller
# of end_time as a setter. Only the ProxyServer module should be
# able to set.
eval {
    $o->end_time("00:00:06");
};
ok(defined($@), "Proper rejection of end_time as a setter.");

$o->{error} = "/path/to/err";
is ($o->error, "/path/to/err", "Test error getter.");
$o->error("/path/to/err2");
is ($o->error, "/path/to/err2", "Test error setter.");

$o->{getenv} = 1;
is ($o->getenv, 1, "Test getenv getter.");
$o->getenv(2);
is ($o->getenv, 1, "Test getenv setter with another integer (non-zero).");
$o->getenv("string"); # Should still evaluate to true.
is ($o->getenv, 1, "Test getenv setter with a string (true).");
$o->getenv(0);        # Should still evaluate to true.
is ($o->getenv, 0, "Test getenv setter with 0 value.");

$o->{initialdir} = "/path/to/initialdir";
is ($o->initialdir, "/path/to/initialdir", "Test initialdir getter.");
$o->initialdir("/path/to/initialdir2");
is ($o->initialdir, "/path/to/initialdir2", "Test initialdir setter.");

$o->name("somename");
is ($o->name, "somename", "Test name getter.");
$o->name("newname");
is ($o->name, "newname", "Test name setter.");

is ($o->opsys, "Linux", "Test opsys getter defaults to Linux.");
$o->opsys("Solaris");
is ($o->opsys, "Solaris", "Test opsys setter (to Solaris).");
eval {
    $o->opsys("XXXXX");
};
ok($@, "Bad opsys causes an error.");
isnt($o->opsys, "XXXXX", "Test opsys setter (with bad opsys).");

$o->{output} = "/path/to/output";
is ($o->output, "/path/to/output", "Test output getter.");
$o->output("/path/to/output2");
is ($o->output, "/path/to/output2", "Test output setter.");

$o->{priority} = 5;
is ($o->priority, 5, "Test priority getter.");
$o->priority(1);
is ($o->priority, 1, "Test priority setter.");

$o->{start_time} = "00:00:05";
is($o->start_time, "00:00:05", "Test start_time getter.");
eval {
    $o->start_time("00:00:06");
};
ok(defined($@), "Proper rejection of start_time as a setter.");

# Test the state method.
for my $state (sort keys %valid_states) {
    $o->{state} = $state;
    is ($o->state, $state, "Test state getter (with $state).");

    # Set the state back to empty string in directly to prepare for an
    # set attempt.
    $o->{state} = "";
    $@ = undef;
    eval {
        $o->state($state);
    };
}

$o->{times} = 1;
is ($o->times, 1, "Test times getter.");
$o->times(2);
is ($o->times, 2, "Test times setter.");

# Test the to_xml method by calling the method, and parsing the results
# to see if they make sense. We test this method last after we have
# exercised all the other methods so we can have the most complete XML
# document possible.
my $xml;
eval {
    $xml = $o->to_xml;
};
ok(!$@, "to_xml did not die.");

my $struct = XMLin($xml);

ok(exists($struct->{executable}), "XML document has 'executable'.");
is($struct->{executable}, "/some/path/to/exe", "Executable has the right value.");
ok(exists($struct->{project}), "XML document has 'project'.");
is($struct->{project}, "someproject2", "project has the right value.");
ok(exists($struct->{config}), "XML document has 'config'.");
is(ref($struct->{config}), "HASH", "Config contains a hash.");
ok(exists($struct->{config}->{opSys}), "Config contains opSys.");
is($struct->{config}->{opSys}, "Solaris", "Opsys has the right value.");
ok(exists($struct->{output}), "XML document has 'output'.");
is($struct->{output}, "/path/to/output2", "Output has the right value.");
ok(exists($struct->{error}), "XML document has 'error'.");
is($struct->{error}, "/path/to/err2", "Error has the right value.");
ok(exists($struct->{times}), "XML document has 'times'.");
is($struct->{times}, 2, "Times has the right value.");
ok(exists($struct->{type}), "XML document has 'type'.");
is($struct->{type}, "mw", "Type has the right value.");

exit;
