package Flower::Interface;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';
use Mojolicious::Plugin::SimpleSession;

# This action will render a template
sub root {
  my $self   = shift;
  my $config = $self->config();

  my $count = $self->stash->{session}->{count};
     $count++;

  $self->stash->{session}->{count} = $count;

  $self->stash->{nodes} = $config->{nodes};

  $self->render();
}

1;
