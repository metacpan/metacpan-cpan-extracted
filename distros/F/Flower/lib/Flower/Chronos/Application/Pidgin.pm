package Flower::Chronos::Application::Pidgin;

use strict;
use warnings;

use base 'Flower::Chronos::Application::Base';

sub run {
    my $self = shift;
    my ($info) = @_;

    return
      unless $info->{role} =~ m/conversation/
      && $info->{class} =~ m/Pidgin/;

    $info->{application} = 'Pidgin';
    $info->{category}    = 'im';

    ($info->{contact}) = $info->{name} =~ m/"(.*?)"/;

    return 1;
}

1;
