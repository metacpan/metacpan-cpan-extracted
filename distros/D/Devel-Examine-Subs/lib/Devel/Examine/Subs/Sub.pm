package Devel::Examine::Subs::Sub;
use 5.008;
use strict;
use warnings;

our $VERSION = '1.70';

use Data::Dumper;

BEGIN {

    # we need to do some trickery for Devel::Trace::Subs due to circular
    # referencing, which broke CPAN installs. DTS does nothing if not presented,
    # per this code

    eval {
        require Devel::Trace::Subs;
        import Devel::Trace::Subs qw(trace);
    };

    if (! defined &trace){
        *trace = sub {};
    }
}

sub new {
    trace() if $ENV{TRACE};

    my ($class, $data, $name) = @_;

    my $self = bless {}, $class;

    $self->{data} = $data;
    $self->{data}{name} = $name || '';

    return $self;
}
sub name {
    trace() if $ENV{TRACE};
    return $_[0]->{data}{name};
}
sub start {
    trace() if $ENV{TRACE};
    return $_[0]->{data}{start};
}
sub end {
    trace() if $ENV{TRACE};
    return $_[0]->{data}{end};
}
sub line_count {
    trace() if $ENV{TRACE};
    return $_[0]->{data}{num_lines};
}
sub lines {
    trace() if $ENV{TRACE};

    my ($self) = @_;

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
    return $_[0]->{data}{code};
}

1;
