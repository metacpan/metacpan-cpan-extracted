package Mesos::Role::ExecutorDriver;
use strict;
use warnings;
use Mesos;
use Types::Standard qw(Str);
use Type::Params qw(validate);
use Mesos::Types qw(:all);
use Mesos::Utils qw(import_methods);

use Moo::Role;
import_methods('Mesos::XS::ExecutorDriver');

=head1 NAME

Mesos::Role::ExecutorDriver - role for perl Mesos executor drivers

=cut

sub BUILD { shift->xs_init(@_) }

requires qw(
    xs_init
    start
    stop
    abort
    join
    run
    sendStatusUpdate
    sendFrameworkMessage
);

has executor => (
    is       => 'ro',
    isa      => Executor,
    required => 1,
);

sub run {
    my ($self) = @_;
    $self->start;
    $self->join;
}

around sendStatusUpdate => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(validate(\@args, TaskStatus));
};

around sendFrameworkMessage => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(validate(\@args, Str));
};

=head1 METHODS

=over 4

=item new(executor => $executor)

=item Status start()

=item Status stop()

=item Status abort()

=item Status join()

=item Status run()

=item Status sendStatusUpdate($status)

=item Status sendFrameworkMessage($data)

=back

=cut


1;
