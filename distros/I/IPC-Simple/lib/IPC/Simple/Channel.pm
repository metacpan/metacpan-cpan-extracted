package IPC::Simple::Channel;
$IPC::Simple::Channel::VERSION = '0.03';
use strict;
use warnings;

use AnyEvent;
use Moo;
use Types::Standard -types;

has waiters =>
  is => 'ro',
  isa => ArrayRef[InstanceOf['AnyEvent::CondVar']],
  default => sub{ [] };

has buffer =>
  is => 'ro',
  isa => ArrayRef,
  default => sub{ [] };

has is_shutdown =>
  is => 'rw',
  isa => Bool,
  default => 0;

sub DEMOLISH {
  my $self = shift;
  $self->shutdown;
}

sub shutdown {
  my $self = shift;

  $self->is_shutdown(1);

  # flush any remaining messages that have pending receivers
  $self->flush;

  # send undef to any remaining receivers
  $_->send for @{ $self->waiters };
}

sub size {
  my $self = shift;
  return scalar @{ $self->buffer };
}

sub put {
  my $self = shift;
  push @{ $self->buffer }, @_;
  $self->flush;
  return $self->size;
}

sub get {
  my $self = shift;
  $self->async->recv;
}

sub async {
  my $self = shift;
  my $cv = AnyEvent->condvar;

  if ($self->is_shutdown) {
    my $msg = shift @{ $self->buffer };
    $cv->send($msg);
    return $cv;
  }
  else {
    push @{ $self->waiters }, $cv;
    $self->flush;
    return $cv;
  }
}

sub flush {
  my $self = shift;
  while (@{ $self->waiters } && @{ $self->buffer }) {
    my $cv = shift @{ $self->waiters };
    $cv->send( shift @{ $self->buffer } );
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Simple::Channel

=head1 VERSION

version 0.03

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
