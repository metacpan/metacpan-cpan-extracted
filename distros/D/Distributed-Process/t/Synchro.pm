package Synchro;

use Distributed::Process;
use Distributed::Process::Worker;

our @ISA = qw/ Distributed::Process::Worker /;

sub run {

    my $self = shift;
    my ($n) = $self->client()->id() =~ /(\d+)/;

    sleep $n * 2;
    $self->result('before synchro');
    $self->synchro('synchro');
    $self->result('after synchro');
}

1;
