package Launcher::Cascade::Base;

=head1 NAME

Launcher::Cascade::Base - a base class for a Launcher. Provides everything but the launch() and test()

=head1 SYNOPSIS

    use base qw( Launch::Cascade::Base );

    sub launch {
        my $self = shift;
        # implement the launcher
    }

    sub test {
        my $self = shift;
        # implement the test
        ...
        return 1 if $success;
        return 0 if $error;
        return undef; # don't know
    }

=head1 DESCRIPTION

This is a base class for a process launcher. It implements a mechanism to
handle dependencies between process (i.e., processes that require other
processes to be successfully finished before they can start).

Subclasses must overload the launch() and test() methods to define what to
launch, and how to test whether is succeeded or failed.

The run() method will invoke the launch() method, but only if:

=over 4

=item *

The launcher has not run yet.

=item *

All its dependencies, if any, have been run successfully.

=item *

It has already run and failed, but hasn't reached its maximum number of
retries.

=back

=cut

use strict;
use warnings;

use base qw( Launcher::Cascade );
use overload '""' => \&as_string;

use Log::Log4perl qw( get_logger );
use Launcher::Cascade::ListOfStrings::Errors;

=head2 Attributes

Attributes are accessed through accessor methods. These methods, when called
without an argument, will return the attribute's value. With an argument, they
will set the attribute's value to that argument, and return the former value.

=over 4

=item B<name>

A simple string used only for printing hopefully useful messages. This should
be set to something meaningfully.

=item B<status>

The status of the the launcher. Its value should not be accessed directly but
through set_success(), set_failure(), is_ready(), has_run(), is_success(),
is_failure() methods.

The possible values are:

=over 5

=item B<0>

Not run yet

=item B<1>

Running, but it is still unknown whether it has succeeded or failed.

=item B<2>

Success

=item B<3>

Failure

=back

=cut

=item B<retries>

Number of retries so far (0 at the first attempt).

=item B<max_retries>

Number of failed attempts after which to consider the process as failed. 0 will
try only once. -1 will B<not> try forever (you don't want your launcher to last
forever do you?).

=item B<time_between_retries>

How long to wait between retries, in seconds. The program will not block during
this time.

=item B<errors>

A C<Launcher::Cascade::ListOfStrings::Errors> object, containing a series of
error messages, as pushed by the add_error() method.

=cut

Launcher::Cascade::make_accessors qw( name errors );
Launcher::Cascade::make_accessors_with_defaults
    status               => 0,
    retries              => 0,
    max_retries          => 0,
    time_between_retries => 0,
    _last_retry_at       => 0,
;

=back

=head2 Methods

=over 4

=item B<dependencies>

=item B<dependencies> I<LIST>

=item B<dependencies> I<ARRAYREF>

Returns the list of C<Launcher::Cascade::Base> objects that this one depends
upon (i.e., they must have successfully been run before this one runs).

When called with a I<LIST> of arguments, this methods also sets the list of
dependencies to I<LIST>. The argument can also be an I<ARRAYREF>, in which case
it will automatically be dereferenced.

All elements in I<LIST> or I<ARRAYREF> should be instances of
C<Launcher::Cascade::Base> or one of its subclasses.

=cut

sub dependencies {

    my $self = shift;
    $self->{_dependencies} ||= [];
    if ( @_ ) {
        if ( UNIVERSAL::isa($_[0], 'ARRAY') ) {
            # Dereference the first arg if it is an arrayref (so that the
            # method can be called with an arrayref from the constructor).
            $self->{_dependencies} = $_[0];
        }
        else {
            $self->{_dependencies} = [ @_ ];
        }
    }
    @{$self->{_dependencies}};
}

=item B<add_dependencies> I<LIST>

Pushes a dependency to the list of dependencies.  All elements in I<LIST>
should be instances of C<Launcher::Cascade::Base> or one of its subclasses.

=cut

sub add_dependencies {

    my $self = shift;
    push @{$self->{_dependencies} ||= []}, @_;
}

=item B<set_success>

=item B<set_failure>

Sets the status() attribute to the value corresponding to a success, resp. failure.

=cut

sub set_success {
    my $self = shift;
    $self->status(2);
}

sub set_failure {
    my $self = shift;
    $self->status(3);
}

=item B<is_ready>

Checks whether the object is ready to run. Several conditions must be met for
this to happen:

=over 5

=item *

status() must be 0, otherwise is_ready() yields C<undef>.

=item *

all dependencies must be successful, otherwise is_ready() yields 0.

=back

Returns 1 in all other cases.

=cut

sub is_ready {

    my $self = shift;
    return unless $self->status() == 0;

    foreach ( $self->dependencies() ) {
        return 0 unless $_->is_success();
    }
    return 1;
}

=item B<launch>

Performs the real action. This method should be overridden in subclasses of
C<Launcher::Cascade::Base>.

=cut

sub launch {}

=item B<test>

Performs the test to decide whether the process succeeded or failed. This
method should be overridden in subclasses of C<Launcher::Cascade::Base>. It
must return:

=over 5

=item *

C<undef> if it cannot be determined whether the process has succeeded or failed
(e.g., the process is still in its starting phase)

=item *

a B<true> status if the process has succeeded.

=item *

a B<false> status if the process has failed.

=back

=cut

sub test {}

=item B<run>

Invokes method launch() if the object is_ready(), and sets its status
accordingly.

=cut

sub run {

    my $self = shift;
    return unless $self->is_ready();
    $self->launch();
    $self->status(1); # Running
}

=item B<check_status>

Performs the test() and sets the status according to its result. Will not run
test() until the number of seconds specified by time_between_retries() has
elapsed since the last test.

=cut

sub check_status {

    my $self = shift;
    my $logger = get_logger;

    return unless $self->status() == 1;

    # Checking whether it is too early for another attempt
    my $time = time;
    return if $self->time_between_retries()
           && $time - $self->_last_retry_at() < $self->time_between_retries();
    $self->_last_retry_at($time);

    $logger->debug("Performing the test() for $self");
    my $result = eval {
        $self->test();
    };
    if ( $@ ) {
        my $msg = "Test for $self died unexpectedly: $@";
        $logger->error($msg);
        $self->add_error($msg);
        $self->set_failure();
        return;
    }

    if ( !defined($result) ) {
        $logger->debug("Still not sure whether $self succeeded");
        if ( $self->retries() < $self->max_retries() ) {
            $self->retries($self->retries() + 1);
            return;
        }
        else {
            my $msg = "Maximum number of retries reached";
            $logger->error($msg);
            $self->add_error($msg);
            $self->set_failure();
        }
    }
    elsif ( $result > 0) {
        $logger->info("$self ran successfully");
        $self->set_success();
    }
    else {
        $logger->info("$self failed to run successfully");
        $self->set_failure();
    }
}

=item B<is_success>

=item B<is_failure>

=item B<has_run>

This methods query the object's current status, and return a true status if,
respectively, the object has run successfully, or the object has run and
failed, or if the object has run (whether it succeeded or failed).

=cut

sub is_success {
    my $self = shift;
    $self->status() == 2;
}

sub is_failure {
    my $self = shift;
    $self->status() == 3;
}

sub has_run {

    my $self = shift;
    $self->is_success() || $self->is_failure();
}

=item B<reset>

Reset the object's status so that it can be run again.

=cut

sub reset {

    my $self = shift;
    $self->retries(0);
    $self->status(0);
    $self->_last_retry_at(0);
}

=item B<as_string>

Returns a string representing the object (its name()). This method is invoked
when the object is interpolated in a double quoted string.

=cut

sub as_string {

    my $self = shift;

    return $self->name();
}

=item B<add_error> I<MESSAGE>

Pushes I<MESSAGE> to the list of messages hold by the the
C<Launcher::Cascade::ListOfStrings::Errors> object in the errors() attribute.
I<MESSAGE> should be either a string or a C<Launcher::Cascade::Printable>
object, or any object that can be stringified.

=cut

sub add_error {

    my $self = shift;
    push @{$self->{_errors} ||= new Launcher::Cascade::ListOfStrings::Errors }, @_;
}

=back

=head2 Constants

=over 4

=item B<SUCCESS>

=item B<FAILURE>

=item B<UNDEFINED>

Subclasses can use theses "constant" methods within their test() methods, to
report either success, failure or the undetermined state of a test.

    sub test {

        my $self = shift;

        if ( ... ) {
            return $self->SUCCESS;
        }
        elsif ( ... ) {
            return $self->FAILURE;
        }
        else {
            return $self->UNDEFINED;
        }
    }

=back

=cut

sub SUCCESS   { 1     } 

sub FAILURE   { -1    } 

sub UNDEFINED { undef } 

=head1 SEE ALSO

L<Launcher::Cascade>, L<Launcher::Cascade::Printable>,
L<Launcher::Cascade::ListOfStrings::Errors>.

=head1 AUTHOR

Cédric Bouvier C<< <cbouvi@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2006 Cédric Bouvier, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1; # end of Launcher::Cascade::Base
