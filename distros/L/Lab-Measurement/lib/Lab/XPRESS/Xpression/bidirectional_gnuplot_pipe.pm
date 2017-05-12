package Lab::XPRESSION::Xpress::bidirectional_gnuplot_pipe;

use IPC::Run qw( start pump finish timeout );
use strict;

our $VERSION = '3.542';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless( $self, $class );

    return $self;

}

sub get_gpipe {
    my $self = shift;

    # Incrementally read from / write to scalars.
    # $in is drained as it is fed to cat's stdin,
    # $out accumulates cat's stdout
    # $err accumulates cat's stderr
    # $h is for "harness".
    my @cmd = qw( gnuplot );
    my $read;
    my $write;
    my $plot;
    my $h = start \@cmd, \$write, \$plot, \$read, timeout(10);
    local $| = 1;

    # redirect gnuplot OUTPUT via pipe to STDOUT:
    $write = "set output '|'\n";
    pump $h while length $write;    ## Wait for all input to go

    # store pipe variables in $self:
    $self->{pipe}  = $h;
    $self->{write} = \$write;
    $self->{read}  = \$read;
    $self->{plot}  = \$plot;

    return $self;

}

sub gnuplot {
    my $self = shift;
    my $cmd  = shift;
    my $pipe = $self->{pipe};
    my $read = $self->{read};
    $$read = "";
    my $write = $self->{write};

    $$write = "$cmd\n print 'EOF'\n";
    pump $pipe until $$read =~ /EOF/;    ## Wait for all input to go

    # remove EOF
    chop $$read;                         # \n
    chop $$read;                         # remove F
    chop $$read;                         # remove O
    chop $$read;                         # remove E

    return $$read;

}

sub close_gpipe {
    my $self = shift;
    finish $self->{pipe} or die "cat returned $?";

    return $self;
}

1;
