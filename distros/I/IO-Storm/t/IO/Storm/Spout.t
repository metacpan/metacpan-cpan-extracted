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
use Test::More tests => 2;
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

BEGIN { use_ok('IO::Storm::Spout'); }
my $spout = IO::Storm::Spout->new( { _stdin => $stdin, _json => $json } );

# emit
push( @stdin_retval, '[2]' );
push( @stdin_retval, 'end' );
sub test_spout_emit { $spout->emit( ["test"] ); }
stdout_is(
    \&test_spout_emit,
    '{"command":"emit","tuple":["test"]}' . "\nend\n",
    'spout->emit() prints right output'
);

# cleanup pid file
unlink($$);

done_testing();