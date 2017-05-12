#!/usr/bin/perl

# $Id: Command.t 10901 2008-05-01 20:21:28Z victor $

# This is a unit test script for the Grid::Request::Command module.

use strict;
use FindBin qw($Bin); # To make finding our other modules easy.
use Log::Log4perl;
use lib "$Bin/../lib";
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
#use Test::More qw(no_plan);
use Test::More tests => 89;

# First we will see if we can successfully load the tested module.
use_ok( 'Grid::Request::Command' );

my $o;

# Eliminate annoying warning about single usage.
if ($^W) {
    %Grid::Request::Command::VALID_STATE =
    %Grid::Request::Command::VALID_STATE;
}
my %valid_states = %Grid::Request::Command::VALID_STATE;

# Instantiate the class.
eval {
    $o = Grid::Request::Command->new();
};

ok($@, "Test bad constructor call.");

eval {
    $o = Grid::Request::Command->new( project => "someproject" );
};
ok(!($@), "Test minimal constructor call. $@");

my @params = $o->params;
is (scalar(@params), 0, "Test params method.");
$o->{params} = [1, 2, 3];
@params = $o->params;
is (scalar(@params), 3, "Test params method with multiple params set.");

# Clear the params before proceeding with furhter tests.
$o->{params} = [];

$o->add_param("param1");
is (scalar($o->params), 1, "Test add_param method.");
$o->add_param("key2", "param2");
is (scalar($o->params), 2, "Test subsequent add_param (with key).");
$o->add_param("key3", "param3", "FASTA");
is (scalar($o->params), 3, "Test subsequent add_param (with key & type).");

@params = $o->params;
ok(($params[0]->value() eq "param1") && ($params[0]->type() eq "PARAM"),
    "Test data for simple param."); 
ok(($params[1]->value() eq "param2") && ($params[1]->type() eq "PARAM") &&
   ($params[1]->key() eq "key2"),
    "Test data for param with key."); 
ok(($params[2]->value() eq "param3") && ($params[2]->type() eq "FASTA") &&
   ($params[2]->key() eq "key3"),
    "Test data for param with key and type."); 
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
is(scalar($o->params), 4, "Test add_param with hashref containing only value (lc).");
$o->add_param( {VALUE => "value2" } );
is(scalar($o->params), 5, "Test add_param with hashref containing only value (uc).");
$o->add_param( {VaLuE => "value3" } );
is(scalar($o->params), 6, "Test add_param with hashref only value (mixed).");


eval {
    $o->add_param( { value => "value4",
                     type  => "BADTYPE",
                     key   => "key4" } );
};
is(scalar($o->params), 6, "add_param with full hashref and bad type fails.");

my $count=4;
foreach my $type qw(PARAM DIR FILE FASTA) { 
    $o->add_param( {value => "value$count",
                    type  => $type,
                    key   => "key$count" } );

    is(scalar($o->params), $count+3, "add_param with full hashref and type $type.");
    $count++;
}

is ($o->project, "someproject", "Test username getter.");
$o->project("someproject2");
is ($o->project, "someproject2", "Test username setter.");

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

$o->{input} = "/path/to/input";
is ($o->input, "/path/to/input", "Test input getter.");
$o->input("/path/to/input2");
is ($o->input, "/path/to/input2", "Test input setter.");

$o->{initialdir} = "/path/to/initialdir";
is ($o->initialdir, "/path/to/initialdir", "Test initialdir getter.");
$o->initialdir("/path/to/initialdir2");
is ($o->initialdir, "/path/to/initialdir2", "Test initialdir setter.");

$o->{length} = 1;
is ($o->length, 1, "Test length getter.");
$o->length(2);
is ($o->length, 2, "Test length setter.");

$o->{libc} = "2.2";
is ($o->libc, "2.2", "Test libc getter.");
$o->libc("2.3");
is ($o->libc, "2.3", "Test libc setter.");

$o->{name} = "somename";
is ($o->name, "somename", "Test name getter.");
$o->name("newname");
is ($o->name, "newname", "Test name setter.");

is ($o->opsys, "Linux", "Test opsys getter defaults to Linux.");
$o->opsys("Solaris");
is ($o->opsys, "Solaris", "Test opsys setter (to Solaris).");
$o->opsys("Alpha");
is ($o->opsys, "Alpha", "Test opsys setter (to Alpha).");
$o->opsys("XXXXX");
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

my $username = getpwuid($<);
#$o->{username} = $username;
is ($o->username, $username, "Test username getter (default is set).");
$o->username("someuser");
is ($o->username, "someuser", "Test username setter.");


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
is($struct->{config}->{opSys}, "Alpha", "OpSys has the right value.");
ok(exists($struct->{output}), "XML document has 'output'.");
is($struct->{output}, "/path/to/output2", "Output has the right value.");
ok(exists($struct->{error}), "XML document has 'error'.");
is($struct->{error}, "/path/to/err2", "Error has the right value.");
ok(exists($struct->{username}), "XML document has 'username'.");
is($struct->{username}, "someuser", "Username has the right value.");
ok(exists($struct->{times}), "XML document has 'times'.");
is($struct->{times}, 2, "Times has the right value.");
ok(exists($struct->{type}), "XML document has 'type'.");
is($struct->{type}, "htc", "Type has the right value.");

# Testing the params is too clumsy, so we use the is_deeply to do a deep
# comparison of the reference data structure and what we parsed from the
# to_xml method.

# This is the reference structure.
my $ref = {
          'executable' => '/some/path/to/exe',
          'project' => 'someproject2',
          'config' => {
                        'getenv' => 0,
                        'length' => 2,
                        'opSys' => 'Alpha'
                      },
          'output' => '/path/to/output2',
          'initialDir' => '/path/to/initialdir2',
          'error' => '/path/to/err2',
          'name' => 'newname',
          'param' => [
                       {
                         'value' => 'param1',
                         'type' => 'PARAM'
                       },
                       {
                         'value' => 'param2',
                         'key' => 'key2',
                         'type' => 'PARAM'
                       },
                       {
                         'value' => 'param3',
                         'key' => 'key3',
                         'type' => 'FASTAFILE'
                       },
                       {
                         'value' => 'value1',
                         'type' => 'PARAM'
                       },
                       {
                         'value' => 'value2',
                         'type' => 'PARAM'
                       },
                       {
                         'value' => 'value3',
                         'type' => 'PARAM'
                       },
                       {
                         'value' => 'value4',
                         'key' => 'key4',
                         'type' => 'PARAM'
                       },
                       {
                         'value' => 'value5',
                         'key' => 'key5',
                         'type' => 'DIR'
                       },
                       {
                         'value' => 'value6',
                         'key' => 'key6',
                         'type' => 'FILE'
                       },
                       {
                         'value' => 'value7',
                         'key' => 'key7',
                         'type' => 'FASTAFILE'
                       },
                     ],
          'username' => "someuser",
          'times' => '2',
          'type' => 'htc'
        };

is_deeply($struct, $ref, "Deep comparison shows parsed XML & " .
                         "reference data match.");

exit;
