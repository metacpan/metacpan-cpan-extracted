package TestTime;

use Distributed::Process;
use Distributed::Process::Worker;

our @ISA = qw/ Distributed::Process::Worker /;

sub to_be_timed {

    my $self = shift;
    # do something silly (and lengthy)
    my ($n) = $self->client()->id() =~ /(\d+)/;
    $n ||= 1;
    $self->result("got this as params: @_");
    $self->result("sleeping for $n seconds");
    sleep $n;
}

sub run {
    my $self = shift;
    $self->time(to_be_timed => qw/ bammbamm pebbles fred /);
}

1;
