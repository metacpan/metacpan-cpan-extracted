package Mesos::Types;
use strict;
use warnings;

=head1 NAME

Mesos::Types

=head1 DESCRIPTION

A basic type library for Mesos classes.
This includes driver classes, all message classes used by drivers, and Mesos::Executor, and Mesos::Scheduler.
Coercions are also provided for message classes, from hash ref constructors.

=cut

use Type::Library
   -base;
use Type::Utils -all;
use Types::Standard -types;
use Mesos::Messages;

my @messages = qw(
    Credential
    ExecutorID
    Filters
    FrameworkInfo
    OfferID
    Request
    SlaveID
    TaskID
    TaskInfo
    TaskStatus
);

for my $message (@messages) {
    my $protobuf_class = "Mesos::$message";
    class_type $message, {class => $protobuf_class};
    coerce $message,
        from HashRef, via { $protobuf_class->new($_) };
}

class_type "Async::Interrupt";
role_type  $_, {role => "Mesos::Role::$_"} for qw(Scheduler Executor SchedulerDriver ExecutorDriver Channel);


__PACKAGE__->meta->make_immutable;

1;
