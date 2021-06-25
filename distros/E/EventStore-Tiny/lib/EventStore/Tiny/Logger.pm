package EventStore::Tiny::Logger;

use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Class::Tiny {
    print_target => sub {select}, # Selected output file handle
};

sub log_event ($self, $event) {

    # Stringify
    use Data::Dump 'dump';
    my $data    = keys(%{$event->data}) ? dump $event->data : 'NO DATA';
    my $output  = $event->name . ": $data";

    # Print to given print handle
    return $self->print_target->print("$output\n");
}

sub log_cb ($self, @args) {

    # Create a new logger if called as a package procedure
    $self = EventStore::Tiny::Logger->new(@args) unless ref $self;

    # Create a logging callback function
    return sub {$self->log_event(shift)};
}

1;

=pod

=encoding utf-8

=head1 NAME

EventStore::Tiny::Logger

=head1 REFERENCE

EventStore::Tiny::Logger implements the following attributes and methods.

=head2 print_target

    $log->print_target(*{STDERR});

Set or get the print target of this logger. By default it uses the L<"select"|perlfunc/"select RBITS,WBITS,EBITS,TIMEOUT">ed file handle (normally STDOUT) but everything with a print method will do.

=head2 log_event

    $log->log_event($event);

Logs the type name together with a dump of the concrete data of the given event to its L<print_target>.

=head2 log_cb

    # As a method
    $store->logger($log->log_cb);

    # As a procedure
    $store->logger(EventStore::Tiny::log_cb);

Generates a subref which can be used as a L<logger|EventStore::Tiny/logger> of an event store. If called as a method, it returns a subref which uses the current Logger (together with the set L<print_target>). If called as a procedure or class method, it returns a closure to the log method of a fresh anonymous Logger instance.

=head1 SEE ALSO

L<EventStore::Tiny>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2021 Mirko Westermeier (mail: mirko@westermeier.de)

Released under the MIT License (see LICENSE.txt for details).

=cut
