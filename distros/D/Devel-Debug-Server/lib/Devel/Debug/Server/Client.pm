use strict;
use warnings;
package Devel::Debug::Server::Client;

use Devel::Debug::Server;

# PODNAME: Client module

# ABSTRACT: the client module for the GUI or CLI client



sub refreshData {

    my $req = { type => $Devel::Debug::Server::DEBUG_GUI_TYPE
    };
    return sendCommand($req); #we just send a void command
}


#Send a command to the debug server to process whose pid is $pid. 
#This method shouldn't be used directly. 
#Returns the debug informations of the server.

#The command is of the form:
#    
#            {
#            command => $commandCode,
#            arg1 => $firstArg, #if needed
#            arg2 => $secondArg,#if needed
#            arg3 => $thirdArg,#if needed
#            };
sub sendCommand {
    my($pid,$command)= @_;
    
    Devel::Debug::Server::initZeroMQ();

    my $req = { type => $Devel::Debug::Server::DEBUG_GUI_TYPE,
                command => $command,
                pid=> $pid,
    };
    my $answer = Devel::Debug::Server::send($req);

    return $answer;
   
}

sub step {
    my ($pid) = @_;
    return Devel::Debug::Server::Client::sendCommand($pid,
            {
            command => $Devel::Debug::Server::STEP_COMMAND,
    });
}


sub breakPoint {
    my ($filePath,$lineNumber) = @_;
    return Devel::Debug::Server::Client::sendCommand(undef,
            {
            command => $Devel::Debug::Server::SET_BREAKPOINT_COMMAND,
            arg1    => $filePath,
            arg2    => $lineNumber,
    });
}

sub removeBreakPoint {
    my ($file,$line) = @_;
    return Devel::Debug::Server::Client::sendCommand(undef,
            {
            command => $Devel::Debug::Server::REMOVE_BREAKPOINT_COMMAND,
            arg1    => $file,
            arg2    => $line,
    });
}

sub run {
    my ($pid) = @_;
    return Devel::Debug::Server::Client::sendCommand($pid,
            { command => $Devel::Debug::Server::RUN_COMMAND, });
}

sub suspend {
    my ($pid) = @_;
    return Devel::Debug::Server::Client::sendCommand($pid,
            { command => $Devel::Debug::Server::SUSPEND_COMMAND });
}
sub return {
    my ($pid,$returnedValue) = @_;
    my $command = { command => $Devel::Debug::Server::RETURN_COMMAND} ;
    if (defined $returnedValue){
        $command ={ command => $Devel::Debug::Server::RETURN_COMMAND,
            arg1  => $returnedValue};
    }
    return Devel::Debug::Server::Client::sendCommand($pid,$command);
}


sub eval {
    my ($pid,$expression) = @_;
    return Devel::Debug::Server::Client::sendCommand($pid,
            { command => $Devel::Debug::Server::EVAL_COMMAND, 
              arg1    => $expression });
}
1;

__END__

=pod

=head1 NAME

Client module - the client module for the GUI or CLI client

=head1 VERSION

version 1.001

=head1 METHODS

=head2 refreshData

return all data necessary to display a debugger screen.
This contains :

* the breakpoints list ('effectiveBreakpoints' key)

* the informations for all processe ('processesInfo' key)

An exemple data structure will be as follows :

  HASH
   'effectiveBreakpoints' => HASH
      '/path/to/my/source/file.pl' => HASH  #here are the breakpoints for this file
         11 => 13
         13 => 13
         9 => 9
   'processesInfo' => HASH
      8603 => HASH      #below are the informations for process 9603
         'fileContent' => ARRAY  #here is the source code of current file
            0  'use strict;'
            1  'use warnings;'
            2  'use Time::HiRes qw(usleep nanosleep);'
            3  ''
            4  '#this dummy script is just a test program to manipulate with the debugger'
            5  ''
            6  'sub dummySubroutine($){'
            7  '    my ($value) = @_;'
            8  '    return $value++;'
            9  '}'
         'fileName' => '/path/to/my/scriptToDebug.pl' #name of current source file
         'finished' => 0  #if 1, program is finished
         'halted' => 1    #if 1, program is haltes, can set brekpoints 
                          #or inspect variables
         'lastEvalCommand' => '' #last command that was executed with "eval"
         'lastEvalResult' => ''  #result of the last "eval" command
         'line' => 13            #current line in the source file
         'name' => undef
         'package' => 'main'     #current package name
         'pid' => 8603           #pid
         'result' => undef      
         'stackTrace' => ARRAY   #stack trace
              empty array
         'subroutine' => 'main'  #subroutine name
         'variables' => HASH     #variables list
              empty hash
      8607 => HASH               "and so on for next process..."
         'fileContent' => ARRAY
            ....

=head2 step

step($pid) : send the step command to the processus of pid $pid
Return the debug informations

=head2 breakpoint

breakpoint($file,$line) : set breakpoint in $file at $line

=head2 removeBreakPoint

removeBreakPoint($file,$line)

=head2 run

run() : continue program execution until breakpoint

=head2 suspend

suspend the running process

=head2 return

return($pid,$returnedValue) : cause script of pid $pid to return of current subroutine. Optionnaly you can specify the value returned with $returnedValue.

=head2 eval

eval($pid,$expression) : eval perl code contained into $expression in the script of pid $pid. The result will be send later into the C<lastEvalResult> key of the data structure of refreshDate

=head1 SEE ALSO

L<Devel::Debug::Server>

=head1 AUTHOR

Jean-Christian HASSLER <hasslerjeanchristian at gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jean-Christian HASSLER.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
