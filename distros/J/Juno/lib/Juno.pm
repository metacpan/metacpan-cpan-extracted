use strict;
use warnings;
package Juno;
# ABSTRACT: Asynchronous event-driven checking mechanism
$Juno::VERSION = '0.010';
use Moo;
use MooX::Types::MooseLike::Base qw<Str Num ArrayRef HashRef>;
use Sub::Quote;
use Class::Load 'load_class';
use namespace::sweep;

with 'MooseX::Role::Loggable';

has hosts => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub { [] },
);

has interval => (
    is      => 'ro',
    isa     => Num,
    default => sub {10},
);

has after => (
    is      => 'ro',
    isa     => Num,
    default => sub {0},
);

has prop_attributes => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub { [ qw<hosts interval after> ] },
);

has checks => (
    is       => 'ro',
    isa      => HashRef[HashRef],
    required => 1,
);

has check_objects => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_check_objects {
    my $self   = shift;
    my %checks = %{ $self->checks };
    my @checks = ();

    foreach my $check ( keys %checks ) {
        my $class = "Juno::Check::$check";
        load_class($class);

        my %check_data = %{ $checks{$check} };

        foreach my $prop_key ( @{ $self->prop_attributes } ) {
            exists $check_data{$prop_key}
                or $check_data{$prop_key} = $self->$prop_key;
        }

        push @checks, $class->new(
            %check_data,
            logger => $self->logger,
        );
    }

    return \@checks;
}

sub run {
    my $self = shift;

    foreach my $check ( @{ $self->check_objects } ) {
        $self->log( 'Running', ref $check );
        $check->run();
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Juno - Asynchronous event-driven checking mechanism

=head1 VERSION

version 0.010

=head1 SYNOPSIS

This runs an asynchronous checker on two servers (I<jack> and I<jill>), running
an HTTP test every 10 seconds with an additional I<Host> header.

    my $juno = Juno->new(
        hosts    => [ 'jack', 'jill' ],
        interval => 10,
        checks   => {
            HTTP => {
                headers => {
                    { 'Host', 'example.com' },
                },

                on_result => sub {
                    my $result = shift;
                    ...
                },
            },
        },
    );

    # makes juno run in the background
    $juno->run;

=head1 DESCRIPTION

Juno is a hub of checking methods (HTTP, Ping, SNMP, etc.) meant to provide
developers with an asynchronous event-based checking agent that has callable
events for the each check's result. You can then use this probed data for
whatever it is you want.  This helps you write stuff like monitoring services,
amongst other things.

Juno is flexible, introspective and composable but still very straight-forward.
To use Juno, you simply need to create a new object, give it all the
information needed (such as the test you want to run) and the optional
(and possibly required) additional check-specific arguments, and then just let
it run in the background, working for you.

Each check Juno runs can have multiple events launched for it. The events will
only be called if you ask them to be called. This means that if you do not
want a certain event to run for a specific check, just don't provide it.

=head1 EVENTS

Let's go over the events you can run. Each check should provide all of these
events unless specified otherwise in the check's documentation.

Also, note that each check tried to decide if a result has been successful or
not. This could be decided using return codes, response headers, failed
results, etc. You have callbacks for successful results or not, but they do
not prevent you from using the other callbacks provided. They will still work
seamlessly if you provide all of them.

=over 4

=item * on_before

This event gets called before the check is actually called.

One thing you can do with it is to check how long a request takes. You can
timestamp before a check is done, and once a check has a result, you can
timestamp that again. The diff between those timestamps is how long it took
to run the check.

=item * on_result

This event gets called as soon as a check result has come in. It might have
failed, it might have been successful. It doesn't matter.

One usage for it is to timestamp the result to correspond to the C<before>
callback explained above.

Another usage for it is in case you want to check for yourself if the result
has been successful or not. Perhaps you have your own API you're testing
against and you (and only I<you>) can decide if it was successful.

You will receive the entire result and can make any decision you want.

=item * on_success

This callback is called when the check decides the result has succeeded.

=item * on_fail

This callback is called when the check decides the result has failed.

=back

Hopefully by now you understand the basic concepts of Juno. The following
documentation will help you get started on how to use Juno exactly, creating
a new object and providing it with all the information required.

=head1 ATTRIBUTES

=head2 checks

The checks you want to run.

This is a hashref of the checks. The key is the check itself (correlates to the
class in C<Juno::Check::>) and the values are the attributes to that check.

    my $juno = Juno->new(
        hosts  => [ '10.0.0.2', '10.0.0.3' ],
        checks => {
            HTTP => {
                path => '/test',
            },
        },
    );

The C<checks> argument is the most important one, and it is mandatory. This
defines what will be checked, and adds additional parameters. Some might be
optional, some might be mandatory. You should read each check's documentation
to know what options are available and which are required.

If you need to run multiple checks of the same type, such as two different
HTTP tests, you will need to run two Juno instances. It's perfectly fine,
because Juno has no global variables and works seamlessly with multiple
instances.

Hopefully this will change in the future, providing more advanced options to
have multiple checks of the same type.

=head2 hosts

An arrayref of hosts you want all checks to monitor.

    my $juno = Juno->new(
        hosts => [ '10.0.1.100', 'sub.domain.com' ],
        ...
    );

=head2 interval

The interval for every check.

    my $juno = Juno->new(
        interval => 5.6,
        ...
    );

This sets every check to be run every 5.6 seconds.

Default: 10 seconds.

=head2 after

Delay seconds for first check.

    my $juno = Juno->new(
        after => 10,
        ...
    );

This will force all checks to only begin after 10 seconds. It will basically
rest for 10 seconds and then start the checks. We can't really think of many
reasons why you would need this (perhaps waiting for a database connection?),
but nonetheless it is an optional feature and you should have control over it
if you want to change it.

If this is set to zero (the default), it will not delay the execution of the
checks.

Default: 0 seconds

=head2 prop_attributes

The C<prop_attributes> are an arrayref of attributes that are propagated from
the main Juno object to each check object. This could be a hard-coded list, but
it's cleaner to put it in an attribute. This means it's available for you to
change. There really is no need for you to do that.

    my $juno = Juno->new(
        prop_attributes => [ 'hosts', 'interval' ],
        ...
    );

Default: hosts, interval, after.

=head1 METHODS

=head2 run

Run Juno.

    use Juno;
    use AnyEvent;

    my $cv   = AnyEvent->condvar;
    my $juno = Juno->new(...);

    $juno->run;
    $cv->recv;

When you call Juno's C<run> method, it will begin running the checks.
Separating the running to a method allows you to set up a Juno object (or
several Juno objects) in advance and calling them later on when you're ready
for them to start working.

However, note that running Juno will not keep the program running by itself.
You will need some condition to keep the program running, as demonstrated
above.

=head1 AUTHORS

=over 4

=item *

Sawyer X <xsawyerx@cpan.org>

=item *

Adam Balali <adamba@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
