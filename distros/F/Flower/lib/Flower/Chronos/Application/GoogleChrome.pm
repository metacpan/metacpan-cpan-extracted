package Flower::Chronos::Application::GoogleChrome;

use strict;
use warnings;

use base 'Flower::Chronos::Application::Chromium';

use URI;

sub run {
    my $self = shift;
    my ($info) = @_;

    return
         unless $info->{role} =~ m/browser/
      && $info->{name} =~ m/Google Chrome/
      && $info->{class} =~ m/Google-chrome/;

    $info->{application} = 'Google Chrome';
    $info->{category}    = 'browser';

    $info->{url} = $self->_find_current_url('google-chrome');

    return 1;
}

1;

