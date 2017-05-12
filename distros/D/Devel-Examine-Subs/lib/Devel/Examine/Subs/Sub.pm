package Devel::Examine::Subs::Sub;
use 5.008;
use strict;
use warnings;

our $VERSION = '1.69';

use Data::Dumper;

BEGIN {

    # we need to do some trickery for DTS due to a circular install

    eval {
        require Devel::Trace::Subs;
    };

    eval {
        import Devel::Trace::Subs qw(trace);
    };

    if (! defined &trace){
        *trace = sub {};
    }
};

sub new {
    
    trace() if $ENV{TRACE};

    my $class = shift;
    my $data = shift;
    my $name = shift;

    my $self = bless {}, $class;

    $self->{data} = $data;
    $self->{data}{name} = $name || '';

    return $self;
}
sub name {
    
    trace() if $ENV{TRACE};
    
    my $self = shift;
    return $self->{data}{name};
}
sub start {
    
    trace() if $ENV{TRACE};
    
    my $self = shift;
    return $self->{data}{start};
}
sub end {
    
    trace() if $ENV{TRACE};
    
    my $self = shift;
    return $self->{data}{end};
}
sub line_count {
    
    trace() if $ENV{TRACE};
    
    my $self = shift;
    return $self->{data}{num_lines};
}
sub lines {
    
    trace() if $ENV{TRACE};

    my $self = shift;

    my @line_linenum;

    if ($self->{data}{lines_with}){
        my $lines_with = $self->{data}{lines_with};
        
        for (@$lines_with){
            for my $num (keys %$_){
                push @line_linenum, "$num: $_->{$num}";
            }
        }
    }

    return \@line_linenum;
}
sub code {
    
    trace() if $ENV{TRACE};

    my $self = shift;

    my $code = $self->{data}{code};

    return $code;
}
1;
