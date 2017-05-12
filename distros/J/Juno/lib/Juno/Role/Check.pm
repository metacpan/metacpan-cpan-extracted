use strict;
use warnings;
package Juno::Role::Check;
# ABSTRACT: Check role for Juno
$Juno::Role::Check::VERSION = '0.010';
use AnyEvent;
use Moo::Role;
use MooX::Types::MooseLike::Base qw<Str Num CodeRef ArrayRef>;
use PerlX::Maybe;
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

has on_before => (
    is        => 'ro',
    isa       => CodeRef,
    predicate => 1,
);

has on_result => (
    is        => 'ro',
    isa       => CodeRef,
    predicate => 1,
);

has on_success => (
    is        => 'ro',
    isa       => CodeRef,
    predicate => 1,
);

has on_fail => (
    is        => 'ro',
    isa       => CodeRef,
    predicate => 1,
);

has watcher => (
    is      => 'ro',
    writer  => 'set_watcher',
    clearer => 1,
);

requires 'check';

sub run {
    my $self = shift;

    # keep a watcher per check
    $self->set_watcher( AnyEvent->timer(
        maybe after    => $self->after,
              interval => $self->interval,
              cb       => sub { $self->check },
    ) );

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Juno::Role::Check - Check role for Juno

=head1 VERSION

version 0.010

=head1 DESCRIPTION

This role provides Juno checks with basic functionality they all share. This
document is intended for anyone writing (or planning on writing) a check for
L<Juno>.

The purpose of this role is to both enforce behavior of Juno checks and
provide various helpful attributes and methods for any check.

=head1 CONSTRAINTS

The role requires the consumer object implements a B<check> method.

=head1 ATTRIBUTES

=head2 hosts

An arrayref consisting a list of hosts (with no enforcement other than a
string) that can then be checked. Each check has multiple hosts so they are
check more than a single target in each object instance. This can be an IP
address or a hostname of any type. Different types can be mixed freely.

This attribute is being propagated from the main L<Juno> object.

Default: B<empty array>.

=head2 interval

A number (including fractions) indicating the interval of your check. This role
runs your check (using the C<check> method you provide) in this interval, so
you shouldn't worry or care about it. You can, however, specify a different
default interval, if you want.

Default: B<10> seconds.

=head2 after

A number (including fractions) indicating the delay before the checking cycle
begins. This only applies for the first check. From that point on, the cycles
will be scheduled every interval indicated by the C<interval> attribute.

Default: B<0> seconds. This means it should start right away.

=head2 on_before

A callback to run before an action occurs. Your check needs to call it before
you actually call whatever check you're running. This gives the user an
opportunity to time the check itself or to log it, for instance.

You can check whether you got such a callback using the predicate
C<has_on_before> described below.

=head2 on_result

A callback to run as soon as an action returns some response. You need to
provide the user with this to let them control it all if that's what they want.
Perhaps they don't want to count on your decision of what is good or not, or
perhaps they have different values for good or bad.

You can check whether you got such a callback using the predicate
C<has_on_result> described below.

=head2 on_success

A callback to run when you decide a check has been successful. For example,
L<Juno::Check::HTTP> calls this callback if the response code has C<2xx>.

You can check whether you got such a callback using the predicate
C<has_on_success> described below.

=head2 on_fail

A callback to run when you decide a check has failed. This is the opposite
of the above. For example, L<Juno::Check::HTTP> calls this callback if the
response code is anything but C<2xx>.

You can check whether you got such a callback using the predicate
C<has_on_fail> described below.

=head2 watcher

A watcher attribute that holds the timer that runs your check. You can change
this watcher using the C<set_watcher> method below or reset the watcher (thus
ending your check, even if Juno is still running) using the C<reset_watcher>
method below.

=head1 METHODS

=head2 has_on_before

This is a predicate method to check whether the user has give you an
C<on_before> callback.

=head2 has_on_result

This is a predicate method to check whether the user has give you an
C<on_result> callback.

=head2 has_on_success

This is a predicate method to check whether the user has give you an
C<on_success> callback.

=head2 has_on_fail

This is a predicate method to check whether the user has give you an
C<on_fail> callback.

=head2 run

This method is called by L<Juno> (but can be called separately if that's what
you want to do) in order to schedule and run your check.

This sets the timer (under the C<watcher> attribute described above) for your
check.

=head2 set_watcher

This method can override the existing watcher. It's hard to think of a usage
for it, but there it is anyway.

=head2 clear_watcher

This method clears the watcher completely, thus stopping your check. It will
not stop any existing code, but will make sure no more cycles of your check
will run. It also doesn't stop Juno from running, or other checks from
running for that matter. It will only stop yours, while lettings everything
continue running.

This can mostly be useful for the user.

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
