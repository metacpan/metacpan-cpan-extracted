package Mesos::Types;
use strict;
use warnings;
use Mesos::Messages;
use Module::Runtime qw();
use Type::Library
   -base;
use Types::Standard -types;
use Type::Utils -all;

=head1 NAME

Mesos::Types

=head1 DESCRIPTION

A basic type library for Mesos classes.
This includes driver classes, all message classes used by drivers, and Mesos::Executor, and Mesos::Scheduler.
Coercions are also provided for message classes, from hash ref constructors.

=cut

my @messages = qw(
    CommandInfo
    Credential
    ExecutorID
    ExecutorInfo
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
        from HashRef, "$protobuf_class->new(\$_)";
}

class_type "Async::Interrupt";
declare $_, as InstanceOf["Mesos::$_"] for qw(
    Channel
    Dispatcher
    Executor
    ExecutorDriver
    Scheduler
    SchedulerDriver
);

coerce "Dispatcher",
    from Str, <<'__END__';
do {
    my $class = $_;
    $class = "Mesos::Dispatcher::$class" unless $class =~ s/^\+//;
    Module::Runtime::require_module($class);
    $class->new;
}
__END__

__PACKAGE__->meta->make_immutable;
1;
