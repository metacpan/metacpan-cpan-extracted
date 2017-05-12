package Evo::Ee;
use Evo -Class, 'Carp croak; List::Util first';

requires 'ee_events';

# [name, cb]
has ee_data => sub { {q => [], cur => undef} };

sub ee_check ($self, $name) {
  croak qq{Not recognized event "$name"} unless first { $_ eq $name } $self->ee_events;
  $self;
}

sub on ($self, $name, $fn) {
  push $self->ee_check($name)->ee_data->{q}->@*, [$name, $fn];
  $self;
}

sub ee_add ($self, $name, $fn) {
  push $self->ee_check($name)->ee_data->{q}->@*, my $id = [$name, $fn];
  $id;
}

sub ee_remove ($self, $id) {
  my $data = $self->ee_data->{q};
  defined(my $index = first { $data->[$_] == $id } 0 .. $#$data) or croak "$id isn't a listener";
  splice $data->@*, $index, 1;
  $self;
}

sub ee_remove_current($self) {
  my ($q, $cur) = @{$self->ee_data}{qw(q cur)};
  defined(my $index = first { $q->[$_] == $cur } 0 .. $#$q) or croak "Not in the event";
  splice $q->@*, $index, 1;
  $self;
}


sub emit ($self, $name, @args) {
  my $data = $self->ee_data;
  do { local $data->{cur} = $_; $_->[1]->($self, @args) }
    for grep { $_->[0] eq $name } $self->ee_data->{q}->@*;
  $self;
}

sub ee_listeners ($self, $name) {
  grep { $_->[0] eq $name } $self->ee_data->{q}->@*;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Ee

=head1 VERSION

version 0.0403

=head1 DESCRIPTION

EventEmitter role for Evo classes

=head1 SYNOPSYS

  package main;
  use Evo;

  {

    package My::Class;
    use Evo '-Class *';
    with '-Ee';

    # define available events
    sub ee_events {qw( connection close )}

  }

  my $comp = My::Class->new();

  # subscribe on the event
  $comp->on(connection => sub($self, $id) { say "got $id" });

  # emit event
  $comp->emit(connection => 'MyID');

=head1 REQUIREMENTS

This role requires method C<ee_events> to be implemented in a derived class. It should return a list of available event names. Each invocation of L</"on"> and L</"ee_remove"> will be compared with this list and in case it doesn't exist an exception will be thrown

  # throws Not recognized event "coNNection"
  $comp->on(coNNection => sub($self, $id) { say "got $id" });

This will prevent people who use your class from the most common mistake in EventEmitter pattern.

=head1 METHODS

=head2 on

Subscbibe 

  $comp->on(connection => sub($self, @args) { say "$self got: " . join ';', @args });

The name of the event will be checked using C<ee_events>, which should be implemented by Evo class and return a list of available names

=head2 emit

Emit an event. The object will be passed to the event as the first argument,  you can provide additional argument to the subscriber

  $comp->emit(connection => 'arg1', 'arg2');

=head2 ee_add

=head2 ee_remove

Add and remove listener from the event by the name and subroutine.

  my $ref = $comp->ee_add(connection => sub {"here"});
  $comp->ee_remove($ref);

The name of the event will be checked using C<ee_events>, which should be implemented by class and return a list of available names

Don't use in the event (or weaken ref if you need to use it)

=head2 ee_remove_current

  $comp->ee_add(
    connection => sub($self) {
      $self->ee_remove_current;
    }
  );

When called in the event, remove current event. Die outside an event

=head2 ee_listeners

  my @listeners =  $comp->ee_listeners('connection');

A list of listeners of the event. Right now a name wouldn't be checked, but this can be changed in the future

=head2 ee_check

  $comp = $comp->ee_check('connection');

Check the event. If it wasn't in the derivered list returned by C<ee_events>, an exception will be thrown.

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
