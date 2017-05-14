use strict;
use warnings;
package Devel::Debug::Server;

use ZeroMQ qw/:all/;
use Time::HiRes qw(usleep nanosleep);
use Storable;

my $NO_COMMAND = 'no_command';
our $READY_COMMAND = 'ready_command';
our $RUN_COMMAND = 'r';
our $STEP_COMMAND = 's';
our $WAIT_COMMAND = 'WAIT_CMD';
our $SET_BREAKPOINT_COMMAND = 'b';
our $REMOVE_BREAKPOINT_COMMAND = 'remove_command';
our $RETURN_COMMAND = 'return';
our $EVAL_COMMAND = 'e';
our $SUSPEND_COMMAND = 'suspend';

our $DEBUG_PROCESS_TYPE = 'DEBUG_PROCESS';
our $DEBUG_GUI_TYPE = 'DEBUG_GUI';
our $DEBUG_BREAKPOINT_TYPE = 'DEBUG_BREAKPOINT_GUI';

my $requester = undef;

# ABSTRACT: communication module for debuging processes


sub initZeroMQ{
    if (!defined $requester){
        my $cxt = ZeroMQ::Context->new;
        $requester = $cxt->socket(ZeroMQ::Constants::ZMQ_REQ);
        $requester->connect("tcp://127.0.0.1:5000");
    }
}


sub send {
    my($data) = @_;

    my $programInfoStr = Storable::freeze($data);
    $requester->send($programInfoStr);

    my $reply = $requester->recv()->data();
    return Storable::thaw($reply);    
}


1;

=pod

=head1 NAME

Devel::Debug::Server - communication module for debuging processes

=head1 VERSION

version 1.001

=head1 SYNOPSIS

	#on command-line
	
	#... first launch the debug server (only once)
	
	tom@house:debugServer.pl 
	
	server is started...
	
	#now launch your script(s) to debug 
	
	tom@house:debugAgent.pl path/to/scriptToDebug.pl
	
	#in case you have arguments
	
	tom@house:debugAgent.pl path/to/scriptToDebug.pl arg1 arg2 ...
	
	#now you can send debug commands with the Devel::Debug::Server::Client module
    #in your debuggerGUI.pl...
	$debugData = Devel::Debug::Server::Client::refreshData(); #$debugData contains all debugging processes infos
	
	#get the debug infos for process $processToDebugPID
	$processInfos = $debugData->{processesInfo}{$processToDebugPID};
	
	#check if process is halted
	if($processInfos->{halted} == 1){
	    print("process is halted.\n");
	}
	
	#check if process is finished
	
	if($processInfos->{finished} == 1){
	    print("process is finished.\n");
	}
	
	#set a breakpoint on line 9
	Devel::Debug::Server::Client::breakPoint($pathToPerlFile,9);
	#remove breakpoint line 14
	Devel::Debug::Server::Client::removeBreakPoint($scriptPath,14);
	
	#now run the process
	Devel::Debug::Server::Client::run($processToDebugPID)
	
	#return from current subroutine
	Devel::Debug::Server::Client::return($processToDebugPID);
	
	#eval an expression in the process context
	Devel::Debug::Server::Client::eval($processToDebugPID,'$variable = 0');
	
	#now time to do one step
	Devel::Debug::Server::Client::step($processToDebugPID);
	
	#suspend a running process
	Devel::Debug::Server::Client::suspend($processToDebug); 

=head1 DESCRIPTION

This module provide a server for debugging multiples perl processes.

Lots of debugging modules a available for perl (graphical and non graphical), their are all directly attached to the debugged script.
This implies the following limitation : 
  - it is not easy to debug multiple processes (10 processes implies 10 debugging shell windows)
  - it is not easy to debug forking processes 
  - it is not easy to automate breakpoints. breakpoints should be set again at each script execution (and automation is not trivial)

This module aims at providing an debugging engine so that we can provide a debugger equivalent the jvm one where you can observe and halt each jvm thread as you want but working with perl processes instead of jvm threads. Every debugging processes connect to the debugging server providing runtime informations and receiving breakpoint list to set.

This module aims at providing a convenient base be to develop one or more GUI client to control this debug server.

Currently there are no GUI clients available.

One can launch one server and debug as many processes as he wants :
- all debugging informations are centralized by the server
- all debugging commands are sent by the server when it receives a client request

For example, the tests script "01-debug-script.t" launch a debug server and 3 processes. All processes are being debugged at the same time (breakpoints are set for all processes).

=head1 Architecture

There is one client process that send commands and retrieve data from the server process ; the tests scripts are client processes. 
Server process receives messages from the processes to debug and gives them commands. The server can also send signal in order to check if a process is alive or to halt it (like ctrl+C on perl debugger).
The processes to debug register automatically to the server on startup and wait for command (at least the run command).
All communications are managed using simple messages on localhost:5000 (zeroMq library).

    ------------------ ZMQ   ----------------  ZMQ   --------------------
    | client process | ----> |server process|<-------|process to debug 1|
    ------------------       |  (port 5000) |        --------------------
                             ----------------                       
                                            ^  ZMQ --------------------
                                            -------|process to debug 2|
                                                   --------------------

=head1 Asynchrounous design

All communications between all component are asynchronous in order nobody waits for a dead process.
This means all command are sent without waiting the result. 

For example :
- client process sends a "eval" command to the server and server aknowledges the message
- then server is waiting for the target process to request some new commands to send the "eval" (updating its informations the same way)
- process to debug execute the "eval" command and generates a new request to the server to update the "lastEvalResult" for this PID in server process memory
- next time client process will call "refreshData", it will get the process informations with "eval" command result.

As a conclusion, client process need to regular call "refreshData" to maintain usefull information on screen.

=head1 Limitations :

Works only for linux systems (should be possible to make it works for windows)
No GUI client available today.
It doesn't manage for now forking processes.
It doesn't manage threads.

=head1 SEE ALSO

L<Devel::Debug::Server::Client>

L<debugAgent.pl>

L<debugServer.pl>

=head1 AUTHOR

Jean-Christian HASSLER <hasslerjeanchristian at gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jean-Christian HASSLER.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
 
# PODNAME: Devel::Debug::Server

# ABSTRACT: Multi process debugging
 
