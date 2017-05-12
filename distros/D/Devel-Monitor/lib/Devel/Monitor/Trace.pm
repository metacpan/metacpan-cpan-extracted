package Devel::Monitor::Trace;
use strict;
use warnings;
 
use Devel::Monitor::Common qw(:all);

sub new {
    my ($class) = @_;
    my $self = {};
    bless($self => $class);
    $self->{_traceItems} = [];
    return $self;
}

sub push {
    my $self = shift;
    my $varRef = shift;
    my $source = shift;
    my $trace = Devel::Monitor::TraceItem->new($varRef,$source);
    push(@{$self->{_traceItems}},$trace);
}

sub pop {
    my $self = shift;
    pop @{$self->{_traceItems}};
}

sub getTraceItems {
    return shift->{_traceItems};   
}

sub getCircularPath {
    my $self = shift;
    my $tmp = '';
    my $isFirst = 1; 
    foreach my $trace (@{$self->{_traceItems}}) {
        if ($isFirst) {
            $tmp .= $trace->getVarRef();
            $isFirst = 0;
        } else {
            $tmp .= $trace->getSource() if $trace->getSource();
        }
    }
    return $tmp;
}

sub dump {
    my $self = shift;
    my $i = 1;
    foreach my $trace (@{$self->{_traceItems}}) {
        if ($trace->getSource()) {
            Devel::Monitor::Common::printMsg($i.' - Source   : '.$trace->getSource()."\n".
                                               '    Item     : '.$trace->getVarRef()."\n");
        } else {
            Devel::Monitor::Common::printMsg($i.' - Item     : '.$trace->getVarRef()."\n");
        }
        $i++;
    }     
}

1;