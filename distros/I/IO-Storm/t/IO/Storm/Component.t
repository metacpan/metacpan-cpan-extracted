#!/usr/bin/env perl

#==============================================================================
#
#         FILE: Component.t
#
#  DESCRIPTION: Test the IO::Storm::Component class.
#
#==============================================================================

use strict;
use warnings;

use Data::Dumper;
use IO::Storm::Tuple;
use Test::MockObject;
use Test::More tests => 15;
use Test::Output;
use Log::Log4perl qw(:easy);
use JSON::XS;
Log::Log4perl->easy_init($ERROR);

# Make Test::More work with UTF-8 errors
if ( Test::Builder->VERSION < 2 ) {
    foreach my $method (qw(output failure_output)) {
        binmode Test::More->builder->$method(), ':encoding(UTF-8)';
    }
}

my $stdin        = Test::MockObject->new();
my @stdin_retval = ();

$stdin->mock(
    'getline',
    sub {
        my $line = shift(@stdin_retval);
        if ( defined($line) ) {
            return $line . "\n";
        }
        else {
            return "";
        }
    }
);

BEGIN { use_ok('IO::Storm::Component'); }

### Component tests

my $component = IO::Storm::Component->new( { _stdin => $stdin } );
$component->_json->canonical;
my $result;

# Test read_message with simple data
push( @stdin_retval, '{"test":"test"}' );
push( @stdin_retval, 'end' );
$result = $component->read_message;
is( $result->{test}, "test", 'read_message() returns test output' );

# read_task_ids
push( @stdin_retval, '{"test":"test0"}' );
push( @stdin_retval, 'end' );
push( @stdin_retval, '[2]' );
push( @stdin_retval, 'end' );
$result = $component->read_task_ids;
is( ref($result), 'ARRAY', 'read_task_ids() returns array' );
is( $result->[0], '2',     'read_task_ids() return correct value' );

# read_command
$component = IO::Storm::Component->new( { _stdin => $stdin } );
$component->_json->canonical;
push( @stdin_retval, '{"test":"test0"}' );
push( @stdin_retval, 'end' );
$result = $component->read_command;
is( ref($result), 'HASH', 'read_command() returns array' );

# read_tuple
$component = IO::Storm::Component->new( { _stdin => $stdin } );
$component->_json->canonical;
push( @stdin_retval,
    '{"id":"test_id","stream":"test_stream","comp":"test_comp","tuple":["test"],"task":"test_task"}'
);
push( @stdin_retval, 'end' );
push( @stdin_retval, '[2]' );
push( @stdin_retval, 'end' );
$result = $component->read_task_ids;
is( @{ $component->_pending_commands }[0]->{id},
    'test_id', 'read_tuple->id returns test_id' );
my $tuple = $component->read_tuple;
is( ref($tuple), 'IO::Storm::Tuple', 'read_tuple returns tuple' );
is( $tuple->id,  'test_id',          'read_tuple->id returns test_id' );

# read_handshake
push( @stdin_retval,
    '{"pidDir":"./","conf":"test_conf","context":"test_context"}' );
push( @stdin_retval, 'end' );
sub test_read_handshake { $result = $component->read_handshake; }
stdout_is(
    \&test_read_handshake,
    '{"pid":' . $$ . '}' . "\nend\n",
    'read_handshake() returns right output'
);
is( @{$result}[0], 'test_conf',    'read_handshake returns correct conf' );
is( @{$result}[1], 'test_context', 'read_handshake returns correct context' );

# send_message
sub test_send_message { $component->send_message( { test => "test" } ); }
stdout_is(
    \&test_send_message,
    '{"test":"test"}' . "\nend\n",
    'send_message() returns test output'
);

# send_message (with utf8)
sub test_send_message_utf8 {
    $component->send_message( { utf8 => "\x{263a}" } );
}
stdout_is(
    \&test_send_message_utf8,
    "{\"utf8\":\"\x{263a}\"}" . "\nend\n",
    "send_message() returns \x{263a} output"
);

# sync
sub test_sync { $component->sync; }
stdout_is(
    \&test_sync,
    '{"command":"sync"}' . "\nend\n",
    'sync() returns right output'
);

# log
sub test_log { $component->log('test_msg'); }
stdout_is(
    \&test_log,
    '{"command":"log","msg":"test_msg"}' . "\nend\n",
    'log() returns right output'
);

# cleanup pid file
unlink($$);

done_testing();
