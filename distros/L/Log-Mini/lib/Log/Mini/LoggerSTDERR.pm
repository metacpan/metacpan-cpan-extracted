package Log::Mini::LoggerSTDERR;

use strict;
use warnings;

use base 'Log::Mini::LoggerBase';

sub _print {
    my $self = shift;
    my ($message) = @_;

    print STDERR $message;
}

1;
