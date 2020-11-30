package IPC::Simple::Group;
# ABSTRACT: work with several processes as a group
$IPC::Simple::Group::VERSION = '0.07';

use strict;
use warnings;

use Carp;
use IPC::Simple::Channel qw();

sub new {
  my $class = shift;

  my $self = bless{
    members  => {},
    messages => IPC::Simple::Channel->new,
  }, $class;

  $self->add(@_);

  return $self;
}

sub add {
  my $self = shift;

  for (@_) {
    croak 'processes must be grouped *before* launching them'
      unless $_->is_ready;

    croak 'processes must be named to be grouped'
      unless $_->name;

    croak 'processes with a recv_cb may not be grouped'
      if $_->{cb};

    croak 'processes with a term_cb may not be grouped'
      if $_->{term_cb};
  }

  for (@_) {
    $self->{members}{ $_->{name} } = $_;
    $_->{recv_cb} = sub{ $self->{messages}->put( $_[0] ) };
    $_->{term_cb} = sub{ $self->drop( $_[0] ) };
  }
}

sub drop {
  my $self = shift;

  delete $self->{members}{ $_->{name} }
    for @_;

  unless (%{ $self->{members} }) {
    $self->{messages}->shutdown;
  }
}

sub members {
  my $self = shift;
  return values %{ $self->{members} };
}

sub launch {
  my $self = shift;
  $_->launch for $self->members;
}

sub terminate {
  my $self = shift;
  $_->terminate(@_) for $self->members;
}

sub signal {
  my ($self, $signal) = @_;
  $self->signal($signal) for $self->members;
}

sub join {
  my $self = shift;
  $_->join for $self->members;
}

sub recv {
  my $self = shift;
  $self->{messages}->recv;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Simple::Group - work with several processes as a group

=head1 VERSION

version 0.07

=head1 DESCRIPTION

The constructor for this class should be considered private, and the semantics
for instantiating this class may change.

Instead, use L<IPC::Simple/process_group> to create process groups.

Also note that processes being added to a group must fit the following criteria:

=over

=item not yet launched

=item no recv_cb

=item no term_cb

=back

=head1 METHODS

=head2 members

Returns the unordered list of L<IPC::Simple> processes within this group.

=head2 launch

Launches all of the processes in this group.

=head2 terminate

Terminates all of the processes in this group. Arguments are forwarded to
L<IPC::Simple/terminate>.

=head2 signal

Sends a signal to all members of the group. Arguments are forwarded to
L<IPC::Simple/signal>.

  $group->signal('HUP');

=head2 join

Blocks until all of the processes in this group have terminated.

=head2 recv

Returns the next message to be received from one of the processes in this group.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
