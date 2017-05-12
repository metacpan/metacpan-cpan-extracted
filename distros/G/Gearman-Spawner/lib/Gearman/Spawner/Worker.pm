package Gearman::Spawner::Worker;

use strict;
use warnings;

use Carp qw( croak );
use Gearman::Spawner::Util;
use Storable qw( nfreeze thaw );

use base 'Gearman::Worker';

use fields qw(
    data
    slot
);

=head1 SYNOPSIS

    package IncrementWorker;
    use base 'Gearman::Spawner::Worker';

    sub new {
        # copy these three lines of boilerplate into your subclass's new:
        my $self = shift;
        $self = fields::new($self) unless ref $self;
        $self->SUPER::new(@_);

        print "I am worker number $self->{slot}\n";
        print "My configuration is $self->{data}\n";

        # ... and these two, with your own methods:
        $self->register_method('increment');
        return $self;
    }

    sub increment {
        my MethodWorker $self = shift; # slot and data available here too
        my $arg = shift;
        return $arg + 1;
    }

=head1 DESCRIPTION

This is the base class for workers meant to be supervised by
L<Gearman::Spawner>.  For correct operation, the C<< ->new >> method of
descendant classes must call the C<< ->new >> method of this class with their
@_.

Since this class is itself descended from the L<fields>-derived L<Gearman::Worker>, subclasses may declare additional object members using L<fields>, e.g.,

    use fields qw( foo bar ); # $self->{foo} = 1;

Two object members are already available: C<< $self->{slot} >> and C<<
$self->{data} >>. The I<data> member is whatever was passed in the
configuration for the worker in Gearman::Spawner->new. The I<slot> is a
sequential number (1-based) which identifies the worker within the set of those
it was spawned with in its class.

=head1 METHODS

=over 4

=item Gearman::Spawner::Worker->new($method_name, [$timeout])

Registers a method to be called via a Gearman::Spawner::Worker class. A Gearman
function will be registered with the server with a name based on the method
name. When the client module's run_method function is called, the argument will
be passed to the registered method as its first non-C<$self> argument.

If $timeout is provided, the Gearman server may attempt to retry the function
if the job is not finished withint $timeout seconds.

The parameters to $method and its return value are marshalled by Storable.

=cut

sub new {
    my $self = shift;
    $self = fields::new($self) unless ref $self;

    my ($servers, $slot, $data) = @_;

    $self->SUPER::new(job_servers => $servers);

    $self->{data} = $data;
    $self->{slot} = $slot;

    return $self;
}

=item $self->register_method($method_name, [$timeout])

Registers a method to be called via Gearman::Spawner::Worker. A
Gearman function named $function_name will be registered with the server. When
a client calls that function, the method named $method (may alternatively be a
coderef) will be called with the Gearman::Spawner::Worker object as
the first argument. $method defaults to be the same as $function_name if not
provided.

If $timeout is provided, the Gearman server may attempt to retry the function
if the job is not finished withint $timeout seconds.

The parameters to $method and return value (which should be a scalar) from it
are marshalled by Storable.

=cut

sub register_method {
    my Gearman::Spawner::Worker $self = shift;
    my $method  = shift;
    my $timeout = shift;

    croak "$self cannot execute $method" unless $self->can($method);

    my $do_work = sub {
        my $job = shift;
        my $arg = $job->arg;

        # deserialize argument
        my $params = thaw($job->arg);

        # call the method
        my @retvals = $self->$method(@$params);

        # serialize return value(s)
        return \nfreeze(\@retvals);
    };

    my $func_name = $self->function_name($method);
    if ($timeout) {
        $self->register_function($func_name, $timeout, $do_work);
    }
    else {
        $self->register_function($func_name, $do_work);
    }

    return $func_name;

}

=item $self->function_name($method)

Returns the name of the function with which the given method was registered
with the gearmand. Generally the Gearman::Spawner::Client modules handle
figuring this out from the class and method names on your behalf. If for some
reason you require the name, use e.g.:

    My::Gearman::Worker->function_name('mymethod')

=back

=cut

sub function_name {
    my $self = shift;
    my $method = shift;
    return Gearman::Spawner::Util::method2function(ref $self, $method);
}

1;
