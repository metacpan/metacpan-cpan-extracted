#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More 'no_plan';

use IO::Pipe;

use Doit;

sub get_pid { $$ }
sub get_random_numbers { map { int(rand(10)) } (1..10) }
sub context { wantarray }
sub exception { die "with something" }
sub exception_ref { die [qw(die with ref)] }

sub create_simple_server () {
    my $to_remote_pipe = IO::Pipe->new;
    my $from_remote_pipe = IO::Pipe->new;

    my $pid = fork;
    die $! if !defined $pid;
    if ($pid == 0) {
	$to_remote_pipe->reader;
	$from_remote_pipe->writer;
	Doit::RPC::SimpleServer->new(Doit->init, $to_remote_pipe, $from_remote_pipe)->run;
	exit;
    }
    $to_remote_pipe->writer;
    $from_remote_pipe->reader;
    my $rpc = Doit::RPC::Client->new($from_remote_pipe, $to_remote_pipe);
    isa_ok $rpc, 'Doit::RPC';

    ($rpc, $pid);
}

{
    my($rpc, $pid) = create_simple_server;

    my $got_pid = $rpc->call_remote(qw(call get_pid)); # XXX context not right yet
    is $got_pid, $pid, 'got pid of remote worker';

    my @random_numers = $rpc->call_remote(qw(call get_random_numbers));
    is scalar(@random_numers), 10;

    my $array_context;
    $array_context = $rpc->call_remote(qw(call context));
    ok !$array_context;
    ($array_context) = $rpc->call_remote(qw(call context));
    ok $array_context;

    eval { $rpc->call_remote(qw(call exception)) };
    like $@, qr{^with something};

    eval { $rpc->call_remote(qw(call exception_ref)) };
    is_deeply $@, [qw(die with ref)];

    my $got_bye = $rpc->call_remote('exit');
    is $got_bye, 'bye-bye'; # XXX really?

    waitpid $pid, 0; # should not hang
}

__END__
