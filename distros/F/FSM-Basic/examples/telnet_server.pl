#!/usr/bin/perl

use strict;
use warnings;
use feature qw( say );
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use IO::All;

use FindBin;
use lib "$FindBin::Bin/../lib";
use FSM::Basic;
use JSON;

my %to_subst = (
    __ENPROMPT__ => 'Admin# ',
    __PROMPT__   => 'User> '
);

my $file_def = shift;
my $json     = io( $file_def )->slurp;

foreach my $subst ( keys %to_subst )
{
    $json =~ s/$subst/$to_subst{$subst}/g;
}

my $states = from_json( $json );

my $peer  = shift       // '127.0.0.1:2323';
my $debug = $ENV{DEBUG} // 0;

my $server = io( $peer )->fork;

my $ppid = $$;
say "server starting pn $peer ppid=$ppid" if $debug;

# the fork occur here (= change PID)
my $connection = $server->accept;

my $fsm = FSM::Basic->new( $states, 'accept' );
say $FSM::Basic::VERSION;
my $pid    = $$;
my $enable = 0;
say Dumper( $fsm->{states_list}{accept} ) if $debug > 1;
$connection->print( "User Access Verification\n\nPassword: " );    # it is not part of the FSM

my $final = 0;
my $out;
while ( my $line = $connection->getline() )
{
    $line =~ s/\r\n$//;
    ( $final, $out ) = $fsm->run( $line );
    say "line=<$line> final flag=<$final> output=<$out>  state name=<$fsm->{state}>" if $debug;
    say "stack cmd=" . Dumper( $fsm->{stack_cmd} )                                   if $debug > 1;
    say "state content=" . Dumper( $fsm->{states_list}{$fsm->{state}} )              if $debug > 2;
    last                                                                             if $final;
    $connection->print( $out );
}

say "ending on client with PID=$pid" if $debug;
$connection->close;
kill 9, $ppid if $final == 2;
