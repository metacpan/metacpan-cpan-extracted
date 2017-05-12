package Session;

use strict;
use warnings;

use Distributed::Process;
use Distributed::Process::Worker;
our @ISA = qw/ Distributed::Process::Worker /;

sub run {

    my $self = shift;
    $self->result('ok');
}

1;
