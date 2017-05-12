#!/usr/bin/env perl

#==============================================================================
#
#         FILE: Component.t
#
#  DESCRIPTION: Test the IO::Storm::Bolt class.
#
#==============================================================================

use strict;
use warnings;

use Data::Dumper;
use IO::Storm::Tuple;
use Test::MockObject;
use Test::More tests => 9;
use Test::Output;
use Log::Log4perl qw(:easy);
use JSON::XS;
Log::Log4perl->easy_init($ERROR);

my $stdin        = Test::MockObject->new();
my @stdin_retval = ();
my $json         = JSON::XS->new->allow_blessed->convert_blessed->canonical;

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

BEGIN { use_ok('IO::Storm::Bolt'); }
my $bolt = IO::Storm::Bolt->new( { _stdin => $stdin, _json => $json } );
my $result;

# read_tuple
push( @stdin_retval,
    '{"id":"test_id","stream":"test_stream","comp":"test_comp","tuple":["test"],"task":"test_task"}'
);
push( @stdin_retval, 'end' );
push( @stdin_retval, '[2]' );
push( @stdin_retval, 'end' );
$result = $bolt->read_task_ids;
is( @{ $bolt->_pending_commands }[0]->{id},
    'test_id', 'read_tuple->id returns test_id' );
my $tuple = $bolt->read_tuple;
is( ref($tuple), 'IO::Storm::Tuple', 'read_tuple returns tuple' );
is( $tuple->id,  'test_id',          'read_tuple->id returns test_id' );

# ack
sub test_ack { $bolt->ack($tuple); }
stdout_is(
    \&test_ack,
    '{"command":"ack","id":"test_id"}' . "\nend\n",
    'bolt->ack() prints right output'
);

# fail
sub test_fail { $bolt->fail($tuple); }
stdout_is(
    \&test_fail,
    '{"command":"fail","id":"test_id"}' . "\nend\n",
    'bolt->fail() prints right output'
);

# emit
push( @stdin_retval, '[2]' );
push( @stdin_retval, 'end' );
sub test_bolt_emit_no_args { $bolt->emit( ["test"], {} ); }
stdout_is(
    \&test_bolt_emit_no_args,
    '{"anchors":[],"command":"emit","tuple":["test"]}' . "\nend\n",
    'bolt->emit() prints right output'
);
push( @stdin_retval, '[2]' );
push( @stdin_retval, 'end' );
sub test_bolt_emit_stream { $bolt->emit( ["test"], { stream => 'foo' } ); }
stdout_is(
    \&test_bolt_emit_stream,
    '{"anchors":[],"command":"emit","stream":"foo","tuple":["test"]}'
        . "\nend\n",
    'bolt->emit({stream => foo}) prints right output'
);
push( @stdin_retval, '[2]' );
push( @stdin_retval, 'end' );

sub test_bolt_emit_anchors {
    $bolt->emit( ["test"], { anchors => [ "1", "2" ] } );
}
stdout_is(
    \&test_bolt_emit_anchors,
    '{"anchors":["1","2"],"command":"emit","tuple":["test"]}' . "\nend\n",
    'bolt->emit({anchors => ["1", "2"]}) prints right output'
);

# cleanup pid file
unlink($$);

done_testing();