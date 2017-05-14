use strict;
use warnings;
package Devel::Debug::Server::Agent;

use Devel::Debug::Server;
use Devel::ebug;

use Time::HiRes qw(usleep nanosleep);
use File::Spec;

    use Data::Dumper;

my $ebug = undef;
my $programName = undef;
my $breakPointsVersion = -1; #the version of the breakpoints
my $lastEvalCommand = '';
my $lastEvalResult = '';
my %breakPointsToSet = ();

sub absoluteName($){
    my ($fileName)=@_;
    if (! File::Spec->file_name_is_absolute( $fileName )){
        $fileName = File::Spec->rel2abs( $fileName ) ;
    }
    return $fileName;
}

#keep the breakpoint list up-to-date with the debug server
sub updateBreakPoints {
    my ($breakPointsServerVersion,$breakPointsList) = @_;

    if ($breakPointsServerVersion == $breakPointsVersion){
        return; #first check if there were no modification since last time
    }

    $breakPointsVersion = $breakPointsServerVersion;
    my @breakPoints = $ebug->all_break_points_with_condition();
    foreach my $breakPoint (@breakPoints) {

        my $file = absoluteName($breakPoint->{filename});
        my $line = $breakPoint->{line}; 
        my $condition = $breakPoint->{condition}; 
        #suppress all breakpoints already set but no more needed
        if (!(exists $breakPointsList->{$file} 
            && exists $breakPointsList->{$file}{$line})){
            $ebug->break_point_delete($file,$line);
        }
    }

    my $effectiveBreakpointList = [];

    my @loadedFilenames    = ();
    foreach my $loadedFile ($ebug->filenames()){
       push @loadedFilenames, absoluteName($loadedFile); 
    }
    
    #clean old list that will be rebuilt
    %breakPointsToSet = () ;
    #add all new breakpoints
    foreach my $file (keys %$breakPointsList) {
        if (grep {$_ eq $file} @loadedFilenames){
            my $bkPointList = setBreakPointForFile($file,keys %{$breakPointsList->{$file}});
            push @{$effectiveBreakpointList}, @{$bkPointList};
        }else{
            #the source file has not yet been loaded, 
            #store breakpoints and break on file loadind
            $breakPointsToSet{$file} = $breakPointsList->{$file} ;
            $ebug->break_on_load($file);
        }
    }
    sendBreakPointsInfo($effectiveBreakpointList);
    return;
}

# set breakpoints on newly loaded file $file
# return 1 if breakpoints were effectly set
# return 0 otherwise
sub setDelayedBreakPoints {
    my ($file) = @_;
    if (!exists $breakPointsToSet{$file}){
        return 0;
    }
    my $fileBreakPoints = $breakPointsToSet{$file};
    my $bkPointList = setBreakPointForFile($file,keys %{$fileBreakPoints});
    delete $breakPointsToSet{$file};
    sendBreakPointsInfo($bkPointList);
    return 1;
}

sub setBreakPointForFile($$){
    my ($file,@line)=@_;
    my $effectiveBreakpointList = [];
    foreach my $line (@line) {
        my $effectiveLineNumber = $ebug->break_point($file,$line);
        if (defined $effectiveLineNumber){
            push (@{$effectiveBreakpointList} ,
                {   file => $file, 
                    requestedLineNumber => $line, 
                    effectiveLineNumber => $effectiveLineNumber});
        }
    }
    return $effectiveBreakpointList;
}

sub trace($){
    my ($text)=@_;
    open (my $fh,">>","./trace.log");
    $text = "[$$]".$text."\n";
    print $fh $text;
    close $fh;
}

sub init{
    my($progName) = @_;
    $ebug = Devel::ebug->new;
    my $programName = $progName;
    $ebug->program($programName);
    $ebug->backend("ebug_backend_perl");
    $ebug->load;
    Devel::Debug::Server::initZeroMQ();
}

sub run {
   #no params
   my $continueRunning = 1;
   while($continueRunning){
        $ebug->run;
        $continueRunning = setDelayedBreakPoints(absoluteName($ebug->filename));
   }

}

sub loop {
    my($progName) = @_;
    
    init($progName);
    
    my $status = { 
        result  => undef,
    };
    
    my $fileName = undef;
    while (1){
        my $fileContent = undef;
        if (!defined $fileName || $fileName ne $ebug->filename()){
            my @fileLines = $ebug->codelines();
            $fileContent = \@fileLines;
            $status->{fileContent} = $fileContent ;
        }
        my $message = Devel::Debug::Server::Agent::sendAgentInfos($status);
        
        my $command = $message->{command};
        my $result = undef ;

        $fileName = $message->{fileName};

        updateBreakPoints($message->{breakPointVersion}, $message->{breakPoints});

        if (defined $command){
            my $commandName = $command->{command};

            my $arg1 = $command->{arg1};
            my $arg2 = $command->{arg2};
            my $arg3 = $command->{arg3};
            

            if ($commandName eq $Devel::Debug::Server::STEP_COMMAND) {
                clearEvalResult();
                $ebug->step;
            } elsif ($commandName eq 'n') {
                clearEvalResult();
                $ebug->next;
            } elsif ($commandName eq $Devel::Debug::Server::RUN_COMMAND) {
                clearEvalResult();
                run();
            } elsif ($commandName eq 'restart') {
                $ebug->load;
            } elsif ($commandName eq $Devel::Debug::Server::RETURN_COMMAND) {
                $ebug->return($arg1);
            } elsif ($commandName eq 'f') {
                $result = $ebug->filenames;
            } elsif ($commandName eq 'b') {
                $ebug->break_point($arg1, $arg2, $arg3);
            } elsif ($commandName eq 'd') {
                $ebug->break_point_delete($arg1, $arg2);
            } elsif ($commandName eq 'w') {
                $ebug->watch_point($arg1);
            } elsif ($commandName eq 'q') {
                exit;
            } elsif ($commandName eq 'x') {
                $lastEvalCommand = $arg1;
                $lastEvalResult = $ebug->eval("use YAML; Dump($arg1)") || "";
            } elsif ($commandName eq $Devel::Debug::Server::EVAL_COMMAND) {
                $lastEvalCommand = $arg1;
                $lastEvalResult = $ebug->eval($arg1) ;
            }
        }
        $status->{result} = $result;
        usleep(1000); #wait 1 ms
    }
}

sub clearEvalResult {
    $lastEvalCommand = '';
    $lastEvalResult  = '';
}

#we notify the server for each breakpoint effectly set, so the real line numbers are stored in the server
sub sendBreakPointsInfo {
    my($effectiveBreakPoints) = @_;
    if (scalar @{$effectiveBreakPoints} <= 0){
        return; #nothing to do
    }
    my $breakpointsInfo = { 
       type        => $Devel::Debug::Server::DEBUG_BREAKPOINT_TYPE,
       effectiveBreakpoints => $effectiveBreakPoints
    };
    return Devel::Debug::Server::send($breakpointsInfo);
}

sub sendAgentInfos {
    my($status) = @_;
    my @stackTrace = $ebug->stack_trace_human();
    my $variables = $ebug->pad();
    $variables = {} unless defined $variables;
    my $programInfo = { 
        pid         => $ebug->proc->pid ,
        name        => $programName ,
        line        => $ebug->line,
        subroutine  => $ebug->subroutine,
        package     => $ebug->package,
        fileName    => absoluteName($ebug->filename),
       finished    =>  $ebug->finished,
       halted       => 1,  #program wait debugging commands
       stackTrace  => \@stackTrace,
       variables   => $variables ,
       result      => $status->{result},
       fileContent => $status->{fileContent},
       type        => $Devel::Debug::Server::DEBUG_PROCESS_TYPE,
       breakPointVersion => $breakPointsVersion,
       lastEvalCommand => $lastEvalCommand,
       lastEvalResult => $lastEvalResult,
       lastUpdateTime  => [Time::HiRes::gettimeofday()],
    };
    return Devel::Debug::Server::send($programInfo);
}

1;

__END__

=pod

=head1 NAME

Devel::Debug::Server::Agent

=head1 VERSION

version 1.001

=head2 run

run the program until next breakpoint.

=head2 loop

Start the inifinite loop to communicate with the debug server

=head2 clearEvalResult

clear the last 'eval' command result (usefull when the program continues)

=head1 AUTHOR

Jean-Christian HASSLER <hasslerjeanchristian at gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jean-Christian HASSLER.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
