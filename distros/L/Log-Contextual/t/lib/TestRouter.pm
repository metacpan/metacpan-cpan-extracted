package TestRouter;

use Moo;
use Log::Contextual::SimpleLogger;

with 'Log::Contextual::Role::Router';

has captured => (is => 'ro', default => sub { {} });

sub before_import {
  my ($self, %export_info) = @_;
  $self->captured->{before_import} = \%export_info;
}

sub after_import {
  my ($self, %export_info) = @_;
  $self->captured->{after_import} = \%export_info;
}

sub handle_log_request {
  my ($self, %message_info) = @_;
  $self->captured->{message} = \%message_info;
}

1;
