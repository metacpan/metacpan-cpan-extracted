package Flower::Chronos::Logger::Stdout;

use strict;
use warnings;

use base 'Flower::Chronos::Logger::Base';
#use Data::Printer;
#use JSON ();

sub log {
    my $self = shift;
    my ($info) = @_;

    return $info;


}

1;
