#!/usr/bin/env perl

use strict;
use warnings;
use ZeroMQ qw/:all/;
use Time::HiRes qw(usleep nanosleep);
use Storable;
use Data::Dumper;

use Storable;
use Devel::Debug::Server;
use JSON;
use File::Spec;

# PODNAME: debugServer.pl

# ABSTRACT: The server to centralize debugging informations


my $cxt = ZeroMQ::Context->new;
my $responder = $cxt->socket(ZeroMQ::Constants::ZMQ_REP);
$responder->bind("tcp://127.0.0.1:5000");

my %processesInfos = ();

#commandes to send to process to debug (undef = nothing to do)
#each command is as below
#{command   => 'COMMAND_CODE',
#  arg1     => 'first argument if needed',
#  arg2     => 'second argument if needed',
#  arg3     => 'third argument if needed'
#  }
my %commands = ();

#a hash containing source files
my %files = ();

my $breakPointVersion = 0;
my $breakPoints = {}; #all the requested breakpoints
my $effectiveBreakpoints = {}; #all the breakpoints effectively set, with their real line number
my $lastBreakPointsUpdate = 0; #the last breakpoint list version that was propagate

#=comment  updateProcessInfo
#
#    Update informations of the process into the process table
#
#     my $programInfo = { 
#        pid          
#        name         
#        line         
#        subroutine   
#        package      
#        filename     
#        finished    
#        stackTrace   
#        variables    
#        result       
#
#    };
#=cut
sub updateProcessInfo {
    my ($infos) = @_;

    my $pid = $infos->{pid};
    $processesInfos{$pid} = $infos;

    #initialize other hashes if necessary
    if (!exists $commands{$pid}){
        $commands{$pid} = undef;
    }
    if (!exists $files{$pid}){
        $files{$pid} = {fileName => undef,
                        content => ''
                        };
    }
    my $file = $files{$pid};
    if (!defined $file->{fileName} || $file->{fileName} ne $infos->{fileName}){
        $file->{content} = $infos->{fileContent};
        $file->{fileName} = $infos->{fileName};
    }
    return $pid;
}

#=method  setRunningProcessInfo
#
#C<setRunningProcessInfo($pid);>
#update the process info when we send the 'continue' command because the process won't update its status until it id finished or it reached a breakpoint
#
#=cut

sub setRunningProcessInfo {
    my ($pid) = @_;
    my $processInfo = $processesInfos{$pid};

    my $programInfo = { 
        pid         => $processInfo->{pid} ,
        name        => $processInfo->{name} , 
        line        => '??',
        subroutine  => '??',
        package     => '??',
        fileName    => '??',
        finished    =>  $processInfo->{finished},
        halted      =>  0,
        stackTrace  => [],
        variables   => {},
        result      => '',
        fileContent => $processInfo->{fileContent} , 
        breakPointVersion => $processInfo->{breakPointVersion},
        lastEvalCommand => '',
        lastEvalResult => '',
       lastUpdateTime  => [Time::HiRes::gettimeofday()],
    };
    $processesInfos{$pid} = $programInfo;
}

#=method  getDebuggingInfos
#
#return a hash containg all debugging info + details for $pid
#
#=cut
sub getDebuggingInfos {
    my ($pid) = @_;
    
    my $returnedData = {sourceFileName      => undef,
                        sourceFileContent   => undef};

    $returnedData->{processesInfo} = \%processesInfos;

    $returnedData->{requestedBreakpoints} = $breakPoints ;
    $returnedData->{effectiveBreakpoints} = $effectiveBreakpoints;


    if (defined $pid && exists $files{$pid}){
        my $file = $files{$pid};

        $returnedData->{sourceFileName } = $file->{fileName};
        $returnedData->{sourceFileContent} = $file->{fileContent};
    }

    return $returnedData;
}

sub setBreakPoint{
    my ($command)=@_;
    my $file = $command->{arg1};
    my $lineNumber = $command->{arg2}; 
    if (! File::Spec->file_name_is_absolute( $file )){
        $file =  File::Spec->rel2abs( $file ) ;
    }

    $breakPointVersion ++;
    $breakPoints->{$file}{$lineNumber} = 1;#condition always true for now
}


#suspend process identified with $pid
sub suspend{
    my ($pid)=@_;

    if ($processesInfos{$pid}{halted} == 0){
        my $processSignaled = kill ( 2 => $pid); #send SIGINT to force process to halt 
    }
}

sub removeBreakPoint{
    my ($command)=@_;
    my $file = $command->{arg1};
    my $lineNumber = $command->{arg2}; 

    $breakPointVersion ++;
    if (exists $breakPoints->{$file} && exists $breakPoints->{$file}{$lineNumber}){
        delete $breakPoints->{$file}{$lineNumber};
    }
}

sub trace($){
    my ($text)=@_;
    open (my $fh,">>","./trace.log");
    $text = "[$$]".$text."\n";
    print $fh $text;
    close $fh;
}

sub updateEffectiveBreakpoints{
    my ($effectiveBreakpointsList) = @_;

    for my $breakpoint (@{$effectiveBreakpointsList}){
        my $file=                 $breakpoint->{file};                  
        my $requestedLineNumber =                 $breakpoint->{requestedLineNumber};
        my $effectiveLineNumber=  $breakpoint->{effectiveLineNumber};
        $effectiveBreakpoints->{$file}->{$requestedLineNumber} = $effectiveLineNumber ;
        if ($effectiveLineNumber != $requestedLineNumber){
            #we are in the case where where the requested line number wasn't on a breakable line, we correct the breakpoints info
            #only %effectiveBreakpoints keep informations about invalid breakpoints
            $effectiveBreakpoints->{$file}->{$effectiveLineNumber} = $effectiveLineNumber;
            delete $breakPoints->{$file}{$requestedLineNumber};
            $breakPoints->{$file}{$effectiveLineNumber} = 1;#condition always true for now
        }
    }
}

my $lastProcessCheck = [Time::HiRes::gettimeofday()];
sub checkProcessAlive(){
    if (Time::HiRes::tv_interval ( $lastProcessCheck)< 1){
        return; #nothing to do for now
    }

    foreach my $pid (keys %processesInfos){
        if (Time::HiRes::tv_interval ($processesInfos{$pid}{lastUpdateTime}) > 1.5 ){
             my $processSignaled = kill ( 0 => $pid); #send no signal to check process alive
             if ($processSignaled){
                $processesInfos{$pid}{lastUpdateTime} = [Time::HiRes::gettimeofday()];
             }
         }
    }
    $lastProcessCheck = [Time::HiRes::gettimeofday()];
}

#=method  propagateBreakPoints
#
#propagate new breakpoints to all processes; running processes are interrupted so they update their breakpoints.
#
#=cut
sub propagateBreakPoints {
    if ($lastBreakPointsUpdate == $breakPointVersion){
        return;
    }
    foreach my $pid (keys %processesInfos){
        if ($processesInfos{$pid}{breakPointVersion} != $lastBreakPointsUpdate
         && $processesInfos{$pid}{halted} == 0){
             $commands{$pid} = { command => $Devel::Debug::Server::RUN_COMMAND };
             my $processSignaled = kill ( 2 => $pid); #send SIGINT to force breakpoints refresh
             if ($processSignaled){
                $processesInfos{$pid}{lastUpdateTime} = [Time::HiRes::gettimeofday()];
             }
         }
    }
    $lastBreakPointsUpdate = $breakPointVersion;
}


#The main loop
print "server is started...\n";

while (1) {
    # Wait for the next request from client
    my $message = $responder->recv();

    if (defined $message){
        my $requestStr = $message->data();
        my $request = Storable::thaw($requestStr);
        my $messageToSend = undef;

        if ($request->{type} eq $Devel::Debug::Server::DEBUG_PROCESS_TYPE){ #message from a debugged process
            my $pid = updateProcessInfo($request);
            
            my $commandInfos= $commands{$pid};
            $messageToSend = {command       =>  $commandInfos,
                              fileName      => $files{$pid}->{fileName},
                              breakPoints  => $breakPoints,
                              breakPointVersion => $breakPointVersion,
                          };
            $commands{$pid} = undef; #don't send the same command twice
            if (defined $commandInfos  && defined $commandInfos->{command}
                 && $commandInfos->{command} eq $Devel::Debug::Server::RUN_COMMAND){
               setRunningProcessInfo($pid); 
            }
        } elsif ($request->{type} eq $Devel::Debug::Server::DEBUG_GUI_TYPE){ #message from the GUI
            my $command = $request->{command};
            my $pid = $request->{pid};
            if (defined $command){
                if ($command->{command} 
                    eq $Devel::Debug::Server::SET_BREAKPOINT_COMMAND){
                    setBreakPoint($command);
                }elsif ($command->{command} 
                    eq $Devel::Debug::Server::REMOVE_BREAKPOINT_COMMAND){
                    removeBreakPoint($command);
                }elsif ($command->{command} 
                    eq $Devel::Debug::Server::SUSPEND_COMMAND){
                    suspend($pid);

                }elsif(!defined $commands{$pid}){
                    $commands{$pid} = $command;
                }
            }
            
            $messageToSend = getDebuggingInfos($pid);
        } elsif ($request->{type} eq $Devel::Debug::Server::DEBUG_BREAKPOINT_TYPE){ #breakpoint has been set in debugged process
            updateEffectiveBreakpoints($request->{effectiveBreakpoints});
            $messageToSend = {message =>"NOTHING TO SAY"};
        }
 


        # Send reply back to client
        $responder->send(Storable::freeze($messageToSend));

        propagateBreakPoints();
        checkProcessAlive();
    }else{
        usleep(500);
    }

}

1;

__END__

=pod

=head1 NAME

debugServer.pl - The server to centralize debugging informations

=head1 VERSION

version 1.001

=head1 SYNOPSIS

	#on command-line
	
	#... first launch the debug server (only once)
	
	tom@house:debugserver.pl 
	
	server is started...
	
	#now launch your script(s) to debug 
	
	tom@house:debugagent.pl path/to/scripttodebug.pl #will automatically register to debug server
	tom@house:debugagent.pl path/to/scripttodebug2.pl

...now you can send debug commands with the L<Devel::Debug::Server::Client>  module

=head1 DESCRIPTION

This script launch the debug server which centralizes all debugging informations and commands for all processes. This server can be driven by a client process which uses L<Devel::Debug::Server::Client> to communicate.

Breakpoints are set/unset for all processes.
All command are asynchronous, which means you send a command to the server which will aknowledge you immediatly. You need to ask the server later to see the process state changed.

=head1 SEE ALSO

See L<Devel::Debug::Server> for more informations.

=head1 AUTHOR

Jean-Christian HASSLER <hasslerjeanchristian at gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jean-Christian HASSLER.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
