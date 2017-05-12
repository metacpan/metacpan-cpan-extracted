package Mesos::Dispatcher::Pipe;
use Moo;
use namespace::autoclean;
extends 'Mesos::Dispatcher';

=head1 NAME

Mesos::Dispatcher::Pipe

=head1 DESCRIPTION

A Mesos::Dispatcher implementation which uses a Unix pipe for dispatching.

This class is intended for subclassing, as it requires an event loop(such
as AnyEvent) to handle reading from the pipe.

=cut

after recv => sub { shift->read_pipe };

1;
