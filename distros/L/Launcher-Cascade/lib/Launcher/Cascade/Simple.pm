package Launcher::Cascade::Simple;

=head1 NAME

Launcher::Cascade::Simple - a simple implementation for a Launcher, based on
callbacks.

=head1 SYNOPSIS

    use Launcher::Cascade::Simple;

    sub test_method {
        my $self = shift;
        if    ( ... ) { return SUCCESS   }
        elsif ( ... ) { return FAILURE   }
        else          { return UNDEFINED }
    }
    sub launch_method {
        my $self = shift;
        ...
    }
    my $launcher = new Launcher::Cascade::Simple
        -name        => 'simple',
        -test_hook   => \&test_method,
        -launch_hook => \&launch_method,
    ;

=head1 DESCRIPTION

A Launcher::Cascade class only has to provide methods to launch() a process,
and to test() whether it succeeded. One way is to create a subclass of
C<Launcher::Cascade::Base> and to overload the methods there.

For simple cases, however, it might be easier to instantiate a
C<Launcher::Cascade::Simple> and provide it with two callbacks, one for
launching and one for testing.

=cut

use strict;
use warnings;

use base qw( Launcher::Cascade::Base Exporter );

=head2 Exports

=over 4

=item B<SUCCESS>

=item B<FAILURE>

=item B<UNDEFINED>

=back

Launcher::Cascade::Simple exports the constant methods C<SUCCESS>, C<FAILURE>
and C<UNDEFINED> as defined in Launcher::Cascade::Base. These can be used as
constants in the fonction given to test_hook().

=cut

our @EXPORT = qw( SUCCESS FAILURE UNDEFINED );

sub SUCCESS   { __PACKAGE__->SUPER::SUCCESS   ()  } 
sub FAILURE   { __PACKAGE__->SUPER::FAILURE   ()  } 
sub UNDEFINED { __PACKAGE__->SUPER::UNDEFINED ()  } 

=head2 Attributes

Attributes are accessed through accessor methods. These methods, when called
without an argument, will return the attribute's value. With an argument, they
will set the attribute's value to that argument, and return the former value.

=over 4

=item B<launch_hook>

=item B<test_hook>

Callbacks that will be invoked when calling the launch() and test() methods,
respectively. The callbacks will receive whatever arguments were given to
launch() or test(), including the reference to the object itself (the callbacks
can thus be considered as methods).

In addition, test_hook() can be given a arrayref of callbacks, in order to
implement several tests that depend on each other, as in:

    $launcher->test_hook([sub { ... }, sub { ... }, sub { ... }]);

In that case, test() will invoke each callback in turn. If it fails, test()
will immediately return failure. If it succeeds, test() will proceed with the
next callback. If it is undefined, test() will retry the same callback at its
next attempt, if max_retries() is not null.

=back

=cut

Launcher::Cascade::make_accessors qw( launch_hook test_hook _current_test_stack );

=head2 Methods

=over 4

=item B<launch>

This method overrides that from C<Launcher::Cascade::Base> and invokes the
callback given in the launch_hook() attribute.

=cut

sub launch {

    $_[0]->launch_hook()->(@_);
}

=item B<test>

This method overrides that from C<Launcher::Cascade::Base> and either,

=over 5

=item *

invokes the one callback given in the test_hook() attribute,

=item *

or invokes, one after another, the callbacks given in the test_hook()
attribute, until one of them fails or all of them succeed. If the result of the
test is undefined, the same callback will be invoked at next attempt, provided
that max_retries() is not null.

=back

=cut

sub test {

    my $self = shift;
    if ( UNIVERSAL::isa($self->test_hook(), 'ARRAY') ) {
        my @test = @{$self->_current_test_stack() || $self->test_hook()};
        my $result;
        while ( @test ) {
            $result = $test[0]->($self, @_);
            if ( defined($result) && $result > 0 ) {
                shift @test;
            }
            else {
                last;
            }
        }
        $self->_current_test_stack(\@test);
        return $result;
    }
    else {
        $self->test_hook()->($self, @_);
    }
}

=item B<reset>

Reset the object's status so that it can be run again.

=cut

sub reset {

    my $self = shift;
    $self->SUPER::reset(@_);
    $self->_current_test_stack(undef);
}

=back

=head1 SEE ALSO

L<Launcher::Cascade::Base>

=head1 AUTHOR

Cédric Bouvier C<< <cbouvi@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2006 Cédric Bouvier, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1; # end of Launcher::Cascade::Simple
