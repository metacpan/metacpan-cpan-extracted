package Lab::Data::Analysis;
#ABSTRACT: Analyze data from 'Trace' files
$Lab::Data::Analysis::VERSION = '3.881';
use v5.20;

use strict;
use Clone qw(clone);
use warnings;
use Carp;
use Data::Dumper;

# default config values, copied to $self->{CONFIG} initially

our $DEFAULT_CONFIG = {
    use_ftell     => 0,    # use ftell/fsetpos for positioning
    clone_headers => 1,    # clone run/file headers into events
    combined_gpib => 0,    # also combine GPIB from all streams
};

our $_DefaultAnalyzer = {
    1 => {                 # order in which to check for match
        MATCH =>
            '(?i)^Lab::Instrument::(TDS|TPS|TBS)(1\d\d\d|2\d\d\d?)(B|C)?::',
        TYPE => 'Lab::Data::Analysis::TekTDS',
        COMMENT =>
            'Tektronix TDS/TPS/TBS 1000 and 2000 series, TDS200 series, oscilloscopes'
    },
    2 => {
        MATCH   => '(?i)^Lab::Instrument::DPO4\d\d\d(A-C)?::',
        TYPE    => 'Lab::Data::Analysis::TekDPO',
        COMMENT => 'Tektronix DPO4000 series oscilloscopes',
    },

    3 => {
        MATCH   => '(?i)^Lab::Instrument::WR\d+::',
        TYPE    => 'Lab::Data::Analysis::WaveRunner',
        COMMENT => 'LeCroy WaveRunner series oscilloscopes',
    },
};

our $_LOADED = {};


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless $self, $class;

    my ( $file, $tail ) = $self->_check_args( \@_, qw(file) );
    $self->{FILE}       = undef;
    $self->{FH}         = undef;
    $self->{INDEX}      = undef;
    $self->{CONFIG}     = {};
    $self->{FILEHEADER} = undef;
    $self->{RUNHEADER}  = undef;

    # set up the default config variables
    foreach my $k ( keys( %{$DEFAULT_CONFIG} ) ) {
        $self->{CONFIG}->{$k} = $DEFAULT_CONFIG->{$k};
    }

    # override default config with user-provided parameters
    foreach my $k ( keys( %{$tail} ) ) {
        next unless exists $self->{CONFIG}->{$k};
        $self->{CONFIG}->{$k} = $tail->{$k};
    }

    $self->open($file) if defined($file);

    return $self;
}

################ internal routines ########################

# calling argument parsing; this is an extension of the
# _check_args and _check_args_strict routines in Instrument.pm,
# allowing more flexibility in how routines are called.
# In particular  routine(a=>1,b=>2,..) and
# routine({a=>1,b=>2,..}) can both be used.

# note: if this code does not properly recognize the syntax,
# then you have to use the {key=>value...} form.

# calling:
#   ($par1,$par2,$par3,$tail) = $self->_check_args(\@_,qw(par1 par2 par3));
# or, for compatibility:
#   ($par1,$par2,$par3,$tail) = $self->_check_args(\@_,[qw(par1 par2 par3)]);

# can also call without the $self-> pointer, since not used.

sub _check_args {
    my $self = shift;
    my $args;

    if ( ref($self) eq 'ARRAY' ) {
        $args = $self;
    }
    else {
        $args = shift;
    }
    my $params = [@_];
    $params = $params->[0] if ref( $params->[0] ) eq 'ARRAY';
    my $arguments = {};

    if ( $#{$args} == 0 && ref( $args->[0] ) eq 'HASH' ) {    # case 3
        %{$arguments} = ( %{ $args->[0] } );
    }
    else {
        my $simple = 1;
        if ( $#{$args} & 1 == 1 ) {    # must have even # arguments
            my $found = {};
            for ( my $j = 0; $j <= $#{$args}; $j += 2 ) {
                if ( ref( $args->[$j] ) ne '' ) {    # a ref for a key? no
                    $simple = 1;
                    last;
                }
                foreach my $p ( @{$params} ) {       # named param
                    $simple = 0 if $p eq $args->[$j];
                }
                if ( exists( $found->{ $args->[$j] } ) ) {   # key used 2x? no
                    $simple = 1;
                    last;
                }
                $found->{ $args->[$j] } = 1;
            }
        }

        if ($simple) {                                       # case 1
            my $i = 0;
            my $j = 0;
            foreach my $arg ( @{$args} ) {
                if ( defined @{$params}[$i] ) {
                    $arguments->{ @{$params}[$i] } = $arg;
                    $i++;
                }
                else {
                    $arguments->{"_tail$j"} = $arg;
                    $j++;
                }
            }
        }
        else {    # case 2
            %{$arguments} = ( @{$args} );
        }
    }

    my @return_args = ();

    foreach my $param ( @{$params} ) {
        if ( exists $arguments->{$param} ) {
            push( @return_args, $arguments->{$param} );
            delete $arguments->{$param};
        }
        else {
            push( @return_args, undef );
        }
    }

    push( @return_args, $arguments );

    if (wantarray) {
        return @return_args;
    }
    else {
        return $return_args[0];
    }
}

sub _check_args_strict {
    my $self = shift;
    my $args;

    if ( ref($self) eq 'ARRAY' ) {
        $args = $self;
    }
    else {
        $args = shift;
    }
    my $params = [@_];
    $params = $params->[0] if ref( $params->[0] ) eq 'ARRAY';

    my @result = _check_args( $args, $params );

    my $num_params = @result - 1;

    for ( my $i = 0; $i < $num_params; ++$i ) {
        if ( not defined $result[$i] ) {
            croak("missing mandatory argument '$params->[$i]'");
        }
    }

    if (wantarray) {
        return @result;
    }
    else {
        return $result[0];
    }
}

# get file position, make use of CONFIG option

sub _tell {
    my $self = shift;
    croak("no file open") unless defined $self->{FH};
    if ( $self->{CONFIG}->{use_ftell} ) {
        return $self->{FH}->getpos();
    }
    else {
        return $self->{FH}->tell();
    }
}

# set file absolute position, making use of CONFIG option
# ignores any 'whence' parameter

sub _seek {
    my $self = shift;
    my $p    = shift;
    croak("no file open") unless defined $self->{FH};
    if ( $self->{CONFIG}->{use_ftell} ) {
        return $self->{FH}->setpos($p);
    }
    else {
        return $self->{FH}->seek( $p, 0 );
    }
}


sub open {
    my $self = shift;
    my ( $file, $tail ) = _check_args_strict( \@_, 'file' );

    croak("input file '$file' does not exist") unless -e $file;
    croak("input file '$file' not readable")   unless -r $file;

    $self->{FH}->close() if defined $self->{FH};

    $self->{FH} = IO::File->new( $file, "r" );
    croak("unable to open file '$file' for reading")
        unless defined $self->{FH};
    $self->{FILE}       = $file;
    $self->{FILE_BEGIN} = $self->_tell();                # beginning position
    $self->{INDEX}      = undef;
    $self->{FSTAT}      = [ ( $self->{FH}->stat() ) ];

}


sub rewind {
    my $self = shift;
    my ($tail) = _check_args( \@_ );

    croak("tracefile not opened") unless defined $self->{FH};

    $self->_seek( $self->{FILE_BEGIN} );
}


sub MakeIndex {
    my $self = shift;
    my ($tail) = _check_args( \@_ );

    my $fh = $self->{FH};
    croak("no tracefile opened") unless defined $fh;

    my $iloc = $self->_tell();
    my $p    = $self->{FILE_BEGIN};

    $self->_seek($p);    # beginning
    $self->{INDEX}           = {};
    $self->{INDEX}->{RUN}    = {};
    $self->{INDEX}->{STREAM} = {};
    $self->{RUN}             = undef;
    $self->{EVENT}           = undef;
    my $run = 0;
    my $n   = 1;

    while (<$fh>) {
        my $pnext = $self->_tell();
        if ( !/^(\d+)(.)(.*)\s*$/ ) {
            carp("Error parsing trace file at line $n: $_");
            $p = $pnext;
            next;
        }
        my $str  = $1 + 0;
        my $cc   = $2;
        my $rest = eval($3);

        if ( !exists( $self->{INDEX}->{STREAM}->{$str} ) ) {
            $self->{INDEX}->{STREAM}->{$str}            = {};
            $self->{INDEX}->{STREAM}->{$str}->{COMMENT} = {};
            $self->{INDEX}->{STREAM}->{$str}->{NUMBER}  = $str;
        }

        if ( $cc ne '<' && $cc ne '>' ) {

            if ( $cc eq '*' ) {
                if ( $rest =~ /^Lab::[\w\:]+::new\s/i ) {
                    $self->{INDEX}->{STREAM}->{$str}->{CONNECT} = $rest;
                }
                elsif ( $rest =~ /^start\s+run\s*(\d+)\s*\\?\@\s*([\d\.]+)/i )
                {
                    $run = $1 + 0;
                    my $t0 = $2;
                    carp("duplicate run '$run' at line $n")
                        if exists $self->{INDEX}->{RUN}->{$run};
                    if ( !defined( $self->{RUN} ) ) {
                        $self->{RUN}   = $run;
                        $self->{EVENT} = 0;
                    }
                    $self->{INDEX}->{RUN}->{$run}              = {};
                    $self->{INDEX}->{RUN}->{$run}->{POSITION}  = $p;
                    $self->{INDEX}->{RUN}->{$run}->{STARTTIME} = $t0;
                    $self->{INDEX}->{RUN}->{$run}->{EVENT}     = {};
                }
                elsif ( $rest
                    =~ /^event\s*(\d+)\s*run\s*(\d+)\s*\\?\@\s*([\d\.]+)/i ) {
                    carp("event found outside of its run at line $n")
                        unless $run == $2 + 0;
                    my $event = $1 + 0;
                    my $te    = $3;
                    carp("duplicate event '$event', run '$run' at line $n")
                        if exists $self->{INDEX}->{RUN}->{$run}->{EVENT}
                        ->{$event};
                    $self->{INDEX}->{RUN}->{$run}->{EVENT}->{$event} = {};
                    $self->{INDEX}->{RUN}->{$run}->{EVENT}->{$event}
                        ->{POSITION} = $p;
                    $self->{INDEX}->{RUN}->{$run}->{EVENT}->{$event}->{TIME}
                        = $te;
                }
                elsif ( $rest =~ /^stop\s+run(\d+)\s.*\\?\@\s*([\d\.]+)/i ) {
                    carp("run # mismatch at start/stop at line $n")
                        unless $run == $1 + 0;
                    $run = $1 + 0;
                    my $t1 = $2;
                    $self->{INDEX}->{RUN}->{$run}->{STOPTIME} = $t1;
                    $run = 0;
                }
                else {
                    carp(
                        "ignoring unknown control sequence at line $n: $rest"
                    );
                }
            }
            elsif ( $cc eq '|' ) {
                $self->{INDEX}->{STREAM}->{$str}->{COMMENT}->{$p} = $rest;
            }
            else {
                carp("unknown trace control char at line $n\n");
            }
        }
        $p = $pnext;
        $n++;
    }
    $self->_seek($iloc);
}


sub PrintIndex {
    my $self = shift;
    my ( $print_events, $tail ) = _check_args( \@_, qw(print_events) );

    if ( !defined( $self->{INDEX} ) ) {
        carp "No index generated yet";
        return;
    }

    my $dirty = 0;
    foreach my $str ( sort( keys( %{ $self->{INDEX}->{STREAM} } ) ) ) {
        next if $str == 0;
        if ( !$dirty ) {
            print "======= DATA STREAMS ==========\n";
            $dirty = 1;
        }
        my $text = $self->{INDEX}->{STREAM}->{$str}->{CONNECT};
        $text =~ s/\\"/"/g;

        my $len = length($text);
        my $j   = 0;
        while ( $j == 0 || $j < $len ) {
            print "$str :" if $j == 0;
            print "\t", substr( $text, $j, 64 ) if $j < $len;
            print "\n";
            $j += 64;
        }

        #	print "$str\t",$self->{INDEX}->{STREAM}->{$str}->{CONNECT},"\n";
        my $d2 = 0;
        foreach my $c (
            sort( keys( %{ $self->{INDEX}->{STREAM}->{$str}->{COMMENT} } ) ) )
        {
            $d2 = 1;
            print "\t", $self->{INDEX}->{STREAM}->{$str}->{COMMENT}->{$c},
                "\n";
        }
        print "\n" if $d2;
    }
    print "\n" if $dirty;
    $dirty = 0;

    foreach my $run ( sort( keys( %{ $self->{INDEX}->{RUN} } ) ) ) {
        if ( !$dirty ) {
            print "=======      RUNS    ==========\n";
            $dirty = 1;
        }
        my (@e) = ( keys( %{ $self->{INDEX}->{RUN}->{$run}->{EVENT} } ) );
        my $t0 = localtime( $self->{INDEX}->{RUN}->{$run}->{STARTTIME} );
        my $t1;
        $t1 = localtime( $self->{INDEX}->{RUN}->{$run}->{STOPTIME} )
            if exists( $self->{INDEX}->{RUN}->{$run}->{STOPTIME} );
        if ( !defined($t1) ) {    # use file modification time
            $t1 = localtime( $self->{FSTAT}->[9] ) . '?';
        }
        printf(
            "RUN %08d :\t% 8d events\t(%s)..(%s)\n", $run, $#e + 1, $t0,
            $t1
        );

        if ( defined($print_events) && $print_events ) {
            print "\t   EVENT\t FILE POSITION  \t   TIME\n";
            foreach my $ev ( sort(@e) ) {
                $t0 = localtime(
                    $self->{INDEX}->{RUN}->{$run}->{EVENT}->{$ev}->{TIME} );
                my $pos = $self->{INDEX}->{RUN}->{$run}->{EVENT}->{$ev}
                    ->{POSITION};
                printf( "\t% 8d\t% 16d\t%s\n", $ev, $pos, $t0 );
            }
            print "\n";
        }

    }
    print "\n" if $dirty;

}


sub ReadEvent {
    my $self = shift;
    my ( $stream, $inrun, $inevent, $tail )
        = _check_args( \@_, qw(stream run event) );

    # turn stream selection into an array ref, however passed.
    my $streams = {};
    if ( defined($stream) ) {
        if ( ref($stream) eq '' ) {
            $stream = [$stream];
        }

        foreach my $s ( @{$stream} ) {
            $streams->{$s} = 1;
        }
        $streams->{0} = 1
            unless exists( $tail->{no_global} ) && !$tail->{no_global};
    }

    my $fh = $self->{FH};
    croak("data file is not open") unless defined $fh;

    if ( defined($inrun) || defined($inevent) ) {
        return undef
            unless
            defined( $self->FindEvent( run => $inrun, event => $inevent ) );
    }

    my $p  = $self->_tell();
    my $ev = {
        GPIB       => [],
        COMMENT    => [],
        STREAM     => {},
        FILEHEADER => undef,
        RUNHEADER  => undef,
        CONFIG     => clone( $self->{CONFIG} ),
    };

    if ( !defined( $self->{INDEX} ) ) {

        my $inevent = 0;

        while (<$fh>) {
            chomp;
            my $pnext = $self->_tell();
            if ( !/^(\d+)(.)(.*)\s*$/ ) {
                carp("Error parsing trace file: $_");
                $p = $pnext;
                next;
            }
            my $str  = $1 + 0;
            my $cc   = $2;
            my $rest = eval($3);

            if ( $cc eq '*' ) {
                if ( $rest =~ /^Lab::[\w\:]+::new\s/i ) {
                    ;
                }
                elsif ( $rest =~ /^start\s+run\s*(\d+)\s*\\?\@\s*([\d\.]+)/i )
                {
                    last if $inevent;
                }
                elsif ( $rest
                    =~ /^event\s*(\d+)\s*run\s*(\d+)\s*\\?\@\s*([\d\.]+)/i ) {
                    last if $inevent;

                    $inevent        = 1;
                    $ev->{EVENT}    = $1 + 0;
                    $ev->{RUN}      = $2 + 0;
                    $ev->{TIME}     = $3;
                    $ev->{POSITION} = $p;
                    if ( $self->{CONFIG}->{clone_headers} ) {
                        $ev->{FILEHEADER} = clone( $self->{FILEHEADER} )
                            if defined $self->{FILEHEADER};
                        $ev->{RUNHEADER} = clone( $self->{RUNHEADER} )
                            if defined $self->{RUNHEADER};
                    }
                }
                elsif ( $rest =~ /^stop\s+run(\d+)\s.*\\?\@\s*([\d\.]+)/i ) {
                    last if $inevent;
                }
                else {
                    carp("ignoring unknown control sequence: $rest");
                }
            }
            elsif ( $cc eq '|' ) {
                if ( $inevent
                    && ( !defined($stream) || exists( $streams->{$str} ) ) ) {

                    push( @{ $ev->{COMMENT} }, $rest );
                    $ev->{STREAM}->{$str} = {
                        COMMENT => [],
                        GPIB    => [],
                        NUMBER  => $str,
                        CONFIG  => clone( $self->{CONFIG} ),
                    } unless exists $ev->{STREAM}->{$str};
                    push( @{ $ev->{STREAM}->{$str}->{COMMENT} }, $rest );
                }
            }
            elsif ( $cc eq '<' || $cc eq '>' ) {
                if ( $inevent
                    && ( !defined($stream) || exists( $streams->{$str} ) ) ) {
                    push( @{ $ev->{GPIB} }, $cc . $rest )
                        if $self->{CONFIG}->{combine_gpib};
                    $ev->{STREAM}->{$str} = {
                        COMMENT => [],
                        GPIB    => [],
                        NUMBER  => $str,
                        CONFIG  => clone( $self->{CONFIG} ),
                    } unless exists $ev->{STREAM}->{$str};
                    push( @{ $ev->{STREAM}->{$str}->{GPIB} }, $cc . $rest );
                }
            }
            else {
                carp("unknown trace control char '$cc'\n");
            }
            $p = $pnext;
        }

        return undef unless $inevent;
        $self->_seek($p);
        $self->{RUN}   = $ev->{RUN};
        $self->{EVENT} = $ev->{EVENT};

    }
    else {
        my $run   = $self->{RUN};
        my $event = $self->{EVENT} + 1;
        return undef unless exists $self->{INDEX}->{RUN}->{$run};
        return undef
            unless exists $self->{INDEX}->{RUN}->{$run}->{EVENT}->{$event};
        my $pev
            = $self->{INDEX}->{RUN}->{$run}->{EVENT}->{$event}->{POSITION};
        $ev->{RUN}      = $run;
        $ev->{EVENT}    = $self->{EVENT} = $event;
        $ev->{POSITION} = $pev;
        $ev->{TIME}
            = $self->{INDEX}->{RUN}->{$run}->{EVENT}->{$event}->{TIME};
        $ev->{STREAM}  = {};
        $ev->{GPIB}    = [];
        $ev->{COMMENT} = [];
        $ev->{CONFIG}  = clone( $self->{CONFIG} );

        if ( $self->{CONFIG}->{clone_headers} ) {
            $ev->{FILEHEADER} = clone( $self->{FILEHEADER} )
                if defined $self->{FILEHEADER};
            $ev->{RUNHEADER} = clone( $self->{RUNHEADER} )
                if defined $self->{RUNHEADER};
        }

        $self->_seek($pev);
        my $foo = <$fh>;
        my $p;
        while (<$fh>) {
            $p = $self->_tell();
            if ( !/^(\d+)(.)(.*)\s*$/ ) {
                carp("Error parsing trace file at line : $_");
                next;
            }
            my $str  = $1 + 0;
            my $cc   = $2;
            my $rest = eval($3);

            last if $cc eq '*';
            next unless !defined($stream) || exists( $streams->{$str} );
            $ev->{STREAM}->{$str} = {
                COMMENT => [],
                GPIB    => [],
                NUMBER  => $str,
                CONFIG  => clone( $self->{CONFIG} ),
            } unless exists $ev->{STREAM}->{$str};

            if ( $cc eq '|' ) {
                push( @{ $ev->{COMMENT} },                   $rest );
                push( @{ $ev->{STREAM}->{$str}->{COMMENT} }, $rest );
            }
            elsif ( $cc eq '>' || $cc eq '<' ) {
                push( @{ $ev->{GPIB} }, $cc . $rest )
                    if $self->{CONFIG}->{combine_gpib};
                push( @{ $ev->{STREAM}->{$str}->{GPIB} }, $cc . $rest );
            }
            else {
                carp("unknown trace control char '$cc'\n");
            }
        }
    }
    $self->_seek($p);    # position at start of next event/control line
    return $ev;
}


sub ReadFileHeader {
    my $self = shift;
    my ( $in, $tail ) = _check_args( \@_, 'shift' );

    my $fh = $self->{FH};
    croak("No trace file open") unless defined $fh;

    my $shift = 0;
    if ( defined($in) && $in =~ /^\s*(Y|T|[1-9])/i ) {
        $shift = 1;
    }
    $self->{FILEHEADER} = undef;

    my $ipos = $self->_tell();

    my $p = $self->{FILE_BEGIN};
    $self->_seek($p);
    my $hdr = {};

    $hdr->{POSITION} = $p;
    $hdr->{STREAM}   = {};

    while (<$fh>) {
        my $pnext = $self->_tell();
        if ( !/^(\d+)(.)(.*)\s*$/ ) {
            carp("Error parsing trace file : $_");
            $p = $pnext;
            next;
        }
        my $str  = $1 + 0;
        my $cc   = $2;
        my $rest = eval($3);

        $hdr->{STREAM}->{$str} = {
            COMMENT => [],
            GPIB    => [],
            NUMBER  => $str,
            CONNECT => undef,
        } unless exists $hdr->{STREAM}->{$str};

        if ( $cc eq '*' ) {
            last if $rest =~ /^start\s+run/i;
            last if $rest =~ /^event/i;
            last if $rest =~ /^stop/i;
            if ( $rest =~ /^Lab::/i ) {
                $hdr->{STREAM}->{$str}->{CONNECT} = $rest;
            }
            else {
                carp("ignoring unknown control sequence: $rest");
            }
        }
        elsif ( $cc eq '|' ) {
            push( @{ $hdr->{STREAM}->{$str}->{COMMENT} }, $rest );
        }
        elsif ( $cc eq '<' || $cc eq '>' ) {
            push( @{ $hdr->{STREAM}->{$str}->{GPIB} }, $cc . $rest );
        }
        else {
            carp("unknown trace control char '$cc' at line\n");
        }
        $p = $pnext;
    }
    if ($shift) {
        $self->_seek($p);
    }
    else {
        $self->_seek($ipos);
    }
    $self->{FILEHEADER} = $hdr;
    return $hdr;
}


sub ReadRunHeader {
    my $self = shift;
    my ( $selrun, $tail ) = _check_args( \@_, qw(run) );

    my $fh = $self->{FH};
    croak("no tracefile opened") unless defined $fh;

    my $hdr = {
        STREAM => {},
    };
    my $ipos = $self->_tell();

    if ( defined( $self->{INDEX} ) && defined($selrun) ) {
        if ( exists( $self->{INDEX}->{RUN}->{$selrun} ) ) {
            $self->_seek( $self->{INDEX}->{RUN}->{$selrun}->{POSITION} );
            $self->{RUN} = $selrun;
        }
        else {
            return undef;
        }
    }
    else {

        my $p        = $ipos;
        my $foundrun = 0;

        while (<$fh>) {
            my $pnext = $self->_tell();

            if ( !/^(\d+)(.)(.*)\s*$/ ) {
                carp("Error parsing trace file : $_");
                next;
            }
            my $str  = $1 + 0;
            my $cc   = $2;
            my $rest = eval($3);

            if ( $cc eq '*' ) {
                if ( $rest =~ /^start\s+run\s*(\d+)\s*\\?\@\s*([\d\.]+)/i ) {
                    my $run = $1 + 0;
                    if ( !defined($selrun) || $selrun == $run ) {
                        $foundrun = 1;
                        $self->{RUN} = $run;
                        last;
                    }
                }
            }
            $p = $pnext;
        }
        if ( !$foundrun ) {
            $self->_seek($ipos);
            return undef;
        }
        $self->_seek($p);
    }

    my $p = $self->_tell();
    while (<$fh>) {
        my $pnext = $self->_tell();

        if ( !/^(\d+)(.)(.*)\s*$/ ) {
            carp("Error parsing trace file: $_");
            next;
        }
        my $str  = $1 + 0;
        my $cc   = $2;
        my $rest = eval($3);

        $hdr->{STREAM}->{$str} = {
            COMMENT => [],
            GPIB    => [],
            NUMBER  => $str,
        } unless exists $hdr->{STREAM}->{$str};

        if ( $cc eq '*' ) {
            if ( $rest =~ /^start\s+run\s*(\d+)\s*\\?\@\s*([\d\.]+)/i ) {
                my $run = $1 + 0;
                last if $self->{RUN} != $run;

                $hdr->{RUN}       = $run;
                $hdr->{POSITION}  = $p;
                $hdr->{STARTTIME} = $2;

            }
            elsif ( $rest =~ /^(event|stop|Lab::)/i ) {
                last;
            }
            else {
                carp("ignoring unknown control sequence  : $rest");
            }
        }
        elsif ( $cc eq '|' ) {
            push( @{ $hdr->{STREAM}->{$str}->{COMMENT} }, $rest );
        }
        elsif ( $cc eq '>' || $cc eq '<' ) {
            push( @{ $hdr->{STREAM}->{$str}->{GPIB} }, $cc . $rest );
        }
        else {
            carp("unknown trace control char '$cc'\n");
        }
        $p = $pnext;
    }
    $self->_seek($p);

    $self->{RUNHEADER} = $hdr;
    return $hdr;
}


sub FindEvent {
    my $self = shift;
    my ( $run, $event, $tail ) = _check_args( \@_, 'run', 'event' );

    if ( !defined($run) || $run <= 0 ) {
        $run = $self->{RUN};
    }
    if ( !defined($run) || $run <= 0 ) {
        carp("invalid run (undef? <=0?)");
        return undef;
    }

    if ( exists( $self->{INDEX} ) ) {
        return undef unless exists $self->{INDEX}->{RUN}->{$run};
        my (@ev)
            = ( sort( keys( %{ $self->{INDEX}->{RUN}->{$run}->{EVENT} } ) ) );
        if ( !defined($event) ) {
            if ( defined( $self->{EVENT} ) ) {
                $event = $self->{EVENT} + 1;
            }
            else {
                $event = 0;
            }
        }
        if ( $event == 0 ) {
            $event = $ev[0];
        }
        elsif ( $event < 0 ) {
            $event = $ev[$event];
        }
        return undef
            unless exists $self->{INDEX}->{RUN}->{$run}->{EVENT}->{$event};
        my $p = $self->{INDEX}->{RUN}->{$run}->{EVENT}->{$event}->{POSITION};
        $self->_seek($p);
        return $p;
    }
    else {
        my $fh = $self->{FH};
        croak("no file opened") unless defined $fh;

        my $p          = $self->_tell();
        my $pstart     = $p;
        my $foundrun   = 0;
        my $foundevent = 0;
        my $wrapped    = 0;

        if ( !defined($event) ) {
            if ( defined( $self->{EVENT} ) ) {
                $event = $self->{EVENT} + 1;
            }
            else {
                $event = 0;
            }
        }
        $event = 0 if $event < 0;

        while ( !$wrapped ) {
            while (<$fh>) {
                my $pnext = $self->_tell();
                last if $pnext == $pstart;    # wrapped the file

                if ( !/^(\d+)(.)(.*)\s*$/ ) {
                    carp("Error parsing trace file: $_");
                    next;
                }
                my $str  = $1 + 0;
                my $cc   = $2;
                my $rest = eval($3);

                if ( $cc eq '*' ) {
                    if (
                        $rest =~ /^start\s+run\s*(\d+)\s*\\?\@\s*([\d\.]+)/i )
                    {
                        my $gotrun = $1 + 0;
                        if ( $foundrun && ( $gotrun != $run ) )
                        {    # ran off the end of desired run, wrap
                            $foundrun = 0;
                            last;
                        }
                        $foundrun = ( $gotrun == $run );
                    }
                    elsif ( $rest =~ /^event\s*(\d+)\s*run\s*(\d+)/i ) {
                        my $gotev  = $1 + 0;
                        my $gotrun = $2 + 0;
                        if ( $foundrun && ( $gotrun != $run ) )
                        {    # ran off the end of desired run, wrap
                            $foundrun = 0;
                            last;
                        }
                        $foundrun = ( $gotrun == $run );
                        if ($foundrun) {
                            $foundevent = 1
                                if $event == 0 || $event == $gotev;
                            last if $foundevent;
                        }
                    }
                    elsif ( $rest =~ /^stop\s+run\s*(\d+)/i ) {
                        my $gotrun = $1 + 0;
                        if ($foundrun)
                        {    # ran off the end of desired run, wrap
                            $foundrun = 0;
                            last;    # wrap the file
                        }
                    }
                }
                $p = $pnext;
            }
            last if $wrapped;
            last if $foundrun && $foundevent;
            $wrapped = 1;
            $p       = $self->{FILE_BEGIN};
            $self->_seek($p);
        }
        if ( !$foundrun || !$foundevent ) {
            $self->_seek($pstart);
            return undef;
        }
        $self->{RUN}   = $run;
        $self->{EVENT} = $event;
        $self->_seek($p);
        return $p;
    }
}


sub PrintDefaultAnalyzer {
    my $self = shift;
    my ( $in, $tail ) = _check_args( \@_, 'stream' );

    my $stream;
    if ( defined($in) ) {
        $stream = {};
        if ( ref($in) eq 'ARRAY' ) {
            $stream->{$in} = 1;
        }
        elsif ( ref($in) eq '' ) {
            $stream->{$in} = 1;
            foreach my $k ( keys( %{$tail} ) ) {
                next unless $k =~ /^_tail\d+$/;
                $stream->{ $tail->{$k} } = 1;
            }
        }
        else {
            croak("parameter type mismatch");
        }
    }

    $self->ReadFileHeader() unless defined $self->{FILEHEADER};

    my $dirty = 0;
    foreach my $s ( sort( keys( %{ $self->{FILEHEADER}->{STREAM} } ) ) ) {
        next if $s == 0;
        next if defined($stream) && !exists( $stream->{$s} );
        my $aType = $self->_findDefAnalyzer($s);
        next unless defined $aType;

        print "Stream\tAnalyzer\n" unless $dirty;
        $dirty = 1;
        print "  $s  \t$aType\n";
    }
    print "\n" if $dirty;
}


sub ConnectAnalyzer {
    my $self = shift;
    my ( $instr, $inmod, $tail ) = _check_args( \@_, qw(stream module) );

    $self->ReadFileHeader() unless defined $self->{FILEHEADER};
    foreach my $str ( keys( %{ $self->{FILEHEADER}->{STREAM} } ) ) {
        next if $str == 0;
        if ( !defined($instr) || $instr == $str ) {
            my $defmod = $self->_findDefAnalyzer($str);
            if ( defined($inmod) ) {
                if (   $inmod !~ /::/
                    && !-e "$inmod.pm"
                    && defined($defmod)
                    && $defmod =~ /::${inmod}$/ ) {    # default short name
                    $inmod = $defmod;
                }
            }
            else {
                $inmod = $self->_findDefAnalyzer($str);
            }
            if ( !defined($inmod) ) {
                carp("No analysis module defined for stream $str");
                return;
            }
            if ( !exists( $_LOADED->{$inmod} ) ) {
                eval("use $inmod;");
                croak($@) if $@;
                $_LOADED->{$inmod} = 1;
            }
            my $strhdr = $self->{FILEHEADER}->{STREAM}->{$str};

            $self->{FILEHEADER}->{STREAM}->{$str}->{ANALYSIS} = []
                unless
                exists $self->{FILEHEADER}->{STREAM}->{$str}->{ANALYSIS};

            my $a;
            eval( '$a = ' . $inmod . '->new(stream=>$strhdr);' );
            croak("error connecting analyzer $inmod") unless defined $a;
            push(
                @{ $self->{FILEHEADER}->{STREAM}->{$str}->{ANALYSIS} },
                $a
            );
        }
    }
}

sub _findDefAnalyzer {
    my $self = shift;
    my $str  = shift;
    return undef if $str == 0;
    $self->ReadFileHeader() unless defined $self->{FILEHEADER};
    return undef unless exists $self->{FILEHEADER}->{STREAM}->{$str};

    my $con = $self->{FILEHEADER}->{STREAM}->{$str}->{CONNECT};

    foreach my $aNum ( sort( keys( %{$_DefaultAnalyzer} ) ) ) {
        my $aMatch = $_DefaultAnalyzer->{$aNum}->{MATCH};
        next unless $con =~ /$aMatch/;
        my $aType = $_DefaultAnalyzer->{$aNum}->{TYPE};
        return $aType;
    }
    return undef;
}


sub Analyze {
    my $self = shift;
    my ( $event, $opts, $str, $tail )
        = _check_args( \@_, 'event', 'options', 'stream' );

    if ( !defined($event) || ref($event) ne 'HASH' ) {
        carp("bad/missing event");
        return undef;
    }
    return undef unless exists $self->{FILEHEADER};
    return undef unless exists $self->{FILEHEADER}->{STREAM};
    $opts = {} unless defined $opts;

    my $stream;

    if ( defined($str) ) {
        if ( ref($str) eq 'ARRAY' ) {
            $stream = {};
            foreach my $s ( @{$str} ) {
                $stream->{$s} = 1;
            }
        }
        elsif ( ref($str) eq '' ) {
            $stream = { $str => 1 };
            foreach my $k ( sort( keys( %{$tail} ) ) ) {
                next unless $k =~ /^_tail\d+/i;
                next unless $tail->{$k} =~ /^\d+$/;
                $stream->{ $tail->{$k} } = 1;
                delete( $tail->{$k} );
            }
        }
        else {
            carp("bad stream parameter");
        }
    }

    #
    # scan through the streams, skipping ones we don't analyze
    #

    foreach my $s ( sort( keys( %{ $self->{FILEHEADER}->{STREAM} } ) ) ) {
        if ( !defined($stream) || exists( $stream->{$s} ) ) {
            next
                unless exists $self->{FILEHEADER}->{STREAM}->{$s}->{ANALYSIS};

            # if multiple analyses are connected, do them in sequence

            foreach
                my $a ( @{ $self->{FILEHEADER}->{STREAM}->{$s}->{ANALYSIS} } )
            {
                $event = $a->Analyze( $event, $opts );
                if ( !defined($event) ) {
                    carp( "Stream $s analysis " . ref($a) . " failed" );
                    return undef;
                }
            }
        }
    }

    return $event;
}

1;    # End of Lab::Data::Analysis

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Data::Analysis - Analyze data from 'Trace' files

=head1 VERSION

version 3.881

=head1 SYNOPSIS

    use Lab::Data::Analysis;

    my $t = Lab::Data::Analysis->new();

    $t->open($tracefile);

    RANDOM ACCESS:

    $t->MakeIndex();
 
    $t->PrintIndex();

    my $fhdr = $t->ReadFileHeader();

    my $rhdr = $t->ReadRunHeader(run=>3);

    my $ev = $t->ReadEvent(run=>3, event=>77);

    
    ... do analysis...



    SEQUENTIAL:

    my $fhdr = $t->ReadFileHeader();

    while (defined($rhdr = $t->ReadRunHeader()) {
       
        print "Run: ",$rhdr->{RUN},"\n";

        while (defined($ev = $t->ReadEvent()) {
             
            print "Event: ", $ev->{EVENT}, "\n";

            do analysis...
        }
    }


    Note that "random access" and "sequential" can be mixed,
    if you keep track of the file position. 

=head1 SUBROUTINES/METHODS

=head2 new

my $t = Lab::Data::Analysis->new();    # do 'open' later

my $t = Lab::Data::Analysis->new($tracefile);

my $t = Lab::Data::Analysis->new( file => $tracefile,
                                  ...options );

=head2 open

$t->open($file);

$t->open(file=>$file, ...);

Open a trace file for reading. 

=head2 rewind

$t->rewind();

Position to beginning of file for sequential access. 

Not sure that this is really needed: ReadFileHeader() automatically
goes to the beginning of the file; ReadRunHeader(run=>firstrun) should
read the header of the first run in the file, and leave the file
positioned to start reading events.  

=head2 MakeIndex

$t->MakeIndex();

Compile an index of Runs/Events in a tracefile, for later use.

Be warned: this may take some time for large files.

=head2 PrintIndex

$t->PrintIndex();

Print an index of the tracefile, showing locations of runs/events, etc.

=head2 ReadEvent

my $event = $t->ReadEvent();

my $event = $t->ReadEvent($stream);

my $event = $t->ReadEvent([$stream1[, $stream2...]]);

my $event = $t->ReadEvent(stream=>$stream);

my $event = $t->ReadEvent(stream=>[$stream1[,$stream2...]]);

Also can use a no_global=>1 option to exclude the 'global' (stream=0) stream,
which just has comments. Adding run=>$run, event=>$event parameters causes
FindEvent(run=>..., event=>...) to be called before reading the event. 

Read an event, starting at the current file position. This may
involve skipping over (and ignoring) lines until reaching the next EVENT 
line. The event is returned in a hash structure, containing the
raw data in all data streams for the event, up to the following EVENT
marker, the "STOP RUN" marker, or the end of the file.

Returns 'undef' if no more events remain in the file.

Data streams can be selected by passing $stream parameter, 
and multiple streams by passing reference to an array.

=head2 ReadFileHeader

my $hdr = $t->ReadFileHeader([$shift]);

my $hdr = $t->ReadFileHeader(shift=>$shift);

Read the header of the data file (before the start of the
first run), and store in a hashref.  If '$shift' is true
(=1,'yes', 'true') then leave the file positioned after
the file header.  The 'shift' parameter is usually not
needed, because ReadRunHeader will just read from the
start of the file to the first run. 

If 'shift' is not specified, then the file position is
restored to where it was prior to the ReadFileHeader
call, which can be useful if the file header is 
read later in the analysis. 

=head2 ReadRunHeader

my $rhdr = $t->ReadRunHeader();

my $rhdr = $t->ReadRunHeader($run);

my $rhdr = $t->ReadRunHeader(run=>$run);

Reads the header information between the start of run and the first
event. If the run number is not given, reads from the current file
position until the run is found. Returns undef if the file is not
found. 

Returns a hashref with the information, and leaves the file
positioned at the first event of the run.

=head2 FindEvent

$t->FindEvent($run,$event);

$t->FindEvent(run=>$run, event=>$event);

Find the specified event in the specified run (if run=undef or <=0, then
use current run). Returns undef if the event is not found, otherwise
returns the file position and leaves the file positioned so that ReadEvent
will read the specified event.

If event is undefined, defaults to the 'next event'; for files that
have been indexed event=-1 returns the LAST event (-2 next to last, etc).
Without an index event < 0 is treated as event=0. 

Note that this routine is MUCH more efficient if an index is created.

=head2 PrintDefaultAnalyzer

$t->PrintDefaultAnalyzer([$stream, $stream,...]);

$t->PrintDefaultAnalyzer(stream=>[$stream1,$stream2,...]);

Print the 'default' analyzer modules for the selected streams
(default = 'all streams'). If the file header has not yet been
read, this routine reads the file header to get the setup information
about the data streams. 

=head2 ConnectAnalyzer

$t->ConnectAnalyzer([[$stream],$module]);

$t->ConnectAnalyzer(stream=>$stream, module=>$module);

Connect an analysis module to a data stream. If the stream
is unspecified, try to connect to all data streams. If
the module is unspecified, try to use a 'default' module
for the stream.  Note that connecting multiple analysis 
modules to a stream results in the module being called
in sequence, using the result from the previous
analysis module. 

Default modules are in Lab::Data::Analysis:: ...

=head2 Analyze

my $ev = $t->Analyze($ev[,$options,[,$stream1,$stream2,...]);

my $ev = $t->Analyze(event=>$ev[, stream=>$stream1][,analyzeroptions=>..]);

my $ev = $t->Analyze(event=>$ev[, stream=>[$stream1,$stream2,...]
           [, analyzeroptions=>]);

runs the analysis chain on the given event, for the given streams
(default: all streams).  The event is returned with analysis
data added to the hashref.  Options for the analyzer (in the
key=>value form) can be passed if the hash calling form is used.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2016       Charles Lane
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
