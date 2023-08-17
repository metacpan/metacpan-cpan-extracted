package Lab::Connection::Trace;
#ABSTRACT: Trace communication with instruments
$Lab::Connection::Trace::VERSION = '3.881';
use v5.20;

use warnings;
use strict;

use Role::Tiny;

use YAML::XS;
use Data::Dumper;
use autodie;
use Carp;
use IO::File;
use Exporter 'import';

our @EXPORT = qw( OpenTraceFile Comment SetRun StartRun StopRun
    NextRun NextEvent MuteTrace );

our $TraceChannels = 0;
our $TraceFH;
our $TraceRun   = 0;
our $TraceEvent = 0;
our $TraceMute  = 0;    # global mute

#our $TraceFile;


sub OpenTraceFile {
    my $file = shift;
    $file = shift
        if ( ref($file) ne '' );    # in case called $self->OpenTraceFile

    $Lab::Connection::Trace::TraceChannels = 0;
    $Lab::Connection::Trace::TraceFH       = IO::File->new("> $file");

    #    $Trace::TraceFile = $file;
}


around 'new' => sub {
    my $orig  = shift;
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;

    # getting fields and _permitted from parent class
    my $self = $class->$orig(@_);

    $self->_construct($class);

    if ( defined($Lab::Connection::Trace::TraceFH) ) {
        $Lab::Connection::Trace::TraceChannels++;
        $self->{TraceChan} = $Lab::Connection::Trace::TraceChannels;
        $self->{TraceMute} = 0;    # per-channel mute

        # this is where the info about what instrument is
        # using which connection is written.

        my $parent = $class;
        $parent =~ s/::Trace$//;
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Indent = 0;
        local $Data::Dumper::Useqq  = 1;

        #$self->_trace('*',"new $parent (".Dumper(@_).")");

        for ( my $i = 0; $i < 10; $i++ ) {
            my ( $pack, $file, $line, $subr ) = caller($i);
            next unless $subr =~ /^Lab::Instrument::(\w+)::new$/i;
            $self->_trace( '*', "$subr (" . Dumper(@_) . ")" );
            last;
        }

    }

    return $self;

};

around Write => sub {
    my $orig    = shift;
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }
    $self->_trace( '>', $options->{command} );
    return $self->$orig($options);
};

around Read => sub {
    my $orig    = shift;
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }
    my $retval = $self->$orig($options);
    $self->_trace( '<', $retval );
    return $retval;
};

around BrutalRead => sub {
    my $orig    = shift;
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }

    my $retval = $self->$orig($options);
    $self->_trace( '<', $retval );
    return $retval;

};

around Clear => sub {
    my $orig = shift;
    my $self = shift;
    $self->_trace( '*', 'CLEAR' );

    return $self->$orig(@_);
};

sub _trace {
    my $self      = shift;
    my $direction = shift;
    my $text      = shift;
    return
        unless defined($Lab::Connection::Trace::TraceFH)
        && defined( $self->{TraceChan} );
    return unless defined($text);
    return if $self->{TraceMute};
    return if $Lab::Connection::Trace::TraceMute;

    # text could be binary, encapsulate if needed
    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Useqq  = 1;

    print $Lab::Connection::Trace::TraceFH sprintf(
        '%02d%s%s' . "\n", $self->{TraceChan}, $direction,
        Dumper($text)
    );
}


sub Comment {
    my $self = shift;
    my $text;
    my $chan = 0;

    # fail quietly if trace not set up

    if ( ref($self) ne '' ) {
        $chan = $self->{TraceChan};
        return unless defined $chan;
        $text = shift;
    }
    else {
        $text = $self;
    }
    return unless defined $text;

    return unless defined $Lab::Connection::Trace::TraceFH;

    chomp($text);
    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Useqq  = 1;
    print $Lab::Connection::Trace::TraceFH
        sprintf( '%02d%s%s' . "\n", $chan, '|', Dumper($text) );
}



sub SetRun {
    my $run = shift;
    $run = shift if ref($run) ne '';    # in case of $self->SetRun($run);

    $Lab::Connection::Trace::TraceRun   = $run - 1;   # increment when started
    $Lab::Connection::Trace::TraceEvent = 0;
}


sub StartRun {
    return unless defined $Lab::Connection::Trace::TraceFH;

    my $text = shift;
    $text = '' unless defined($text);
    $text = shift if ( ref($text) ne '' );    # $self->RunStart($text)
    my $run = shift;
    if ( !defined($run) ) {
        $run = ++$Lab::Connection::Trace::TraceRun;
    }
    $Lab::Connection::Trace::TraceEvent = 0;
    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Useqq  = 1;

    $text = sprintf(
        'START RUN%04d @%d %s',
        $run, time(), $text
    );
    print $Lab::Connection::Trace::TraceFH
        sprintf( '%02d%s%s' . "\n", 0, '*', Dumper($text) );
}


sub StopRun {
    return unless defined $Lab::Connection::Trace::TraceFH;

    my $run   = $Lab::Connection::Trace::TraceRun;
    my $event = $Lab::Connection::Trace::TraceEvent;
    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Useqq  = 1;

    my $text = sprintf(
        'STOP RUN%04d after %d events @%d',
        $run, $event, time()
    );
    print $Lab::Connection::Trace::TraceFH
        sprintf( '%02d%s%s' . "\n", 0, '*', Dumper($text) );
}


sub NextRun {
    my $comment = shift;
    $comment = ''    unless defined $comment;
    $comment = shift unless ref($comment) eq '';

    return unless defined $Lab::Connection::Trace::TraceFH;
    StopRun();
    StartRun($comment);
}


sub NextEvent {
    return unless defined $Lab::Connection::Trace::TraceFH;

    my $ev  = ++$Lab::Connection::Trace::TraceEvent;
    my $run = $Lab::Connection::Trace::TraceRun;

    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Useqq  = 1;
    my $text = sprintf(
        'EVENT %04d RUN%04d @%d',
        $ev, $run, time()
    );
    print $Lab::Connection::Trace::TraceFH
        sprintf( '%02d%s%s' . "\n", 0, '*', Dumper($text) );
    return $ev;
}


sub MuteTrace {
    my $self = shift;
    my $in   = $self;
    $in = shift if ref($self) ne '';

    my $mute;
    if ( $in =~ /^\s*(T|Y|ON|[1-9])/i ) {
        $mute = 1;
    }
    elsif ( $in =~ /^\s*(F|N|0|OF)/i ) {
        $mute = 0;
    }
    else {
        carp("MuteTrace boolean '$in' invalid, ignored");
        return;
    }

    if ( ref($self) ne '' ) {
        $self->{TraceMute} = $mute;
    }
    else {
        $Lab::Connection::Trace::TraceMute = $mute;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Connection::Trace - Trace communication with instruments

=head1 VERSION

version 3.881

=head1 SYNOPSIS

This module
is designed to provide a simple, compact record of messages sent to and
received from an instrument, suitable for later analysis.  The trace file
has one line per message. Examples:

01>"DAT:STAR 1"
01>"HEAD 1"
01>"DAT?"
01<":DATA:ENCDG RPBINARY;DESTINATION REFC;SOURCE CH1;START 1;STOP 2500;WIDTH 1"
01>"HEAD 0"
01>"DAT:SOU?"
01<CH1
01>"*RST"

Each connection gets a 'connection number' prefix (01 in example above),
followed by a single character to indicate commands written TO the
instrument (>), replies read FROM the instrument (<), communication setup
commands (*) or user comments (|).  The quoting is provided by
Data::Dumper, with Useqq=1, so that included spaces, nonprintible chars,
etc are properly escaped and quoted. 

This module is mostly useful for instruments that return a lot of data
with complex configuration, so that an optimum DAQ strategy is "record
it all, sort it out later". Digital oscilloscopes, for example, although
the module is set up so that one can combine oscilloscopes, pulse 
generators, power suppplies, meters, etc., and yield a single trace
file. 

Perl modules for parsing/decoding the trace file are needed, and 
may be specific to particular instruments. 

=head2 OpenTraceFile

use Lab::Connection::Trace;

OpenTraceFile('tracefilename');

Opens a new trace file, reseting the trace channel count. You should
call this routine before opening device channels to instruments, so that
the connections get logged to the trace file. 

=head2 Opening Connections

use Lab::Instrument::HP34401A;

my $m = new Lab::Instrument::HP34401A(
    connection_type => 'LinuxGPIB::Trace',
    ...
);

=head2 Comment

use Lab::Connection::Trace;

Comment('global comment');  

puts  00|"global comment" in trace file

$m = new Lab::Instrument:HP34401A (connection_type=>'LinuxGPIB::Trace',..);  

$m->connection->Comment('meter comment');  

puts 01|"meter comment" in the trace file, if the HP34410A is the 
first instrument using a 'Trace' connection. 

=head1 Data organization

The trace data file can be divided into 'runs' and 'events',
where run = 1..Nrun and event = 1..Nevnts

Use SetRun(nrun) to set an initial run number,
StartRun('comment') to start a run (and reset event number)
NextEvent() to go to the next event, and
StopRun() to end a run.

NextRun() increments run number and resets event number. 

Example:
    SetRun(12);            # first run is number 12
    StartRun('test run dozen');  # comment stored in start run marker
    NextEvent();
    ...take data             # run 12 event 1
    NextEvent();
    ... take data            # run 12 event 2
    NextEvent();
    ... take data            # run 12 event 3
    NextRun('dozen+1');      # end run 12, start run 13. with comment
    ... take data            # run 13 event 1
    NextEvent();             
    ... take data            # run 13 event 2
    StopRun();               # write end of run marker.

These routines are provided for convenience when using Trace output
as a means of storing measurement data.

=head2 SetRun

SetRun($n);

Set the run number that will be used for the next
run to be started.

=head2 StartRun

Insert a global comment to indicate the start of an acquisition
run sequence

StartRun($comment[,$runnum]);

If $runnum is provided, does a SetRun($runnum) first, otherwise
the current run is incremented and the event number reset.

=head2 StopRun

StopRun();

Insert a line in the trace file indicating that the run has stopped.

=head2 NextRun

NextRun($comment);

Stop current run, starts new run.

=head2 NextEvent

$thisevent = NextEvent();

Puts an 'event' marker in the trace file, increments event number
and returns the event number that was just started.

=head2 MuteTrace

$instrument->connection->MuteTrace($mute);  # per-instrument

MuteTrace($mute); # global

Mute the tracing or unmute; $mute = 'True/1-9/Y/On' gives muted,
$mute = 'False/0/N/Off' turns off muting.

Muting does not apply to Comment entries, or to Run Start/Stop
or Event entries. 

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2016       Charles Lane
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
