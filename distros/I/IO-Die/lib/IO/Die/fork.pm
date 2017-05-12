package IO::Die;

use strict;

sub fork {
    my ($NS) = @_;

    my $pid = fork;

    $NS->__THROW('Fork') if !defined $pid;

    return $pid;
}

1;
