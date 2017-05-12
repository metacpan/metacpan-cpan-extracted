package Flower::Chronos::Application::Skype;

use strict;
use warnings;

use base 'Flower::Chronos::Application::Base';

sub run {
    my $self = shift;
    my ($info) = @_;

    return
         unless $info->{role} =~ m/ConversationsWindow/
      && $info->{class} =~ m/Skype/
      && $info->{name} =~ m/Skype/;

    $info->{application} = 'Skype';
    $info->{category}    = 'im';

    ($info->{contact}) = $info->{name} =~ m/^"(?:\[\d+\])?(.*?) - Skype/;

    return 1;
}

1;
