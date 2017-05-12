package Flower::Chronos::Application::Thunderbird;

use strict;
use warnings;

use base 'Flower::Chronos::Application::Base';

sub run {
    my $self = shift;
    my ($info) = @_;

    return unless $info->{class} =~ m/(?:Thunderbird|Icedove)"$/;

    $info->{application} = 'Thunderbird';
    $info->{category}    = 'email';

    return 1;
}

1;
