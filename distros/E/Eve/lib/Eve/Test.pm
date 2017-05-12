package Eve::Test;

use strict;
use warnings;

use parent qw(Test::Class);

use Test::More;

=head1 NAME

B<Eve::Test> - a base class for all test cases.

=head1 SYNOPSIS

    use parent qw(Eve::Test);

    sub startup : Test(startup) {
        my $self = shift;

        $self->{'testcase_property'} = 'Testcase';
    }

    sub setup : Test(setup) {
        my $self = shift;

        $self->{'test_property'} = 'Test';
    }

    sub test_match : Test(2) {
        my $self = shift;

        is($something, $self->{'testcase_property'},
            'Does something equal a testcase property?');
        is($something, $self->{'test_property'},
            'Does something equal a test property?');

        Eve::Test::is_lazy(
            code => sub {
                return $self->{'some_registry'}->get_some_lazy_service();
            },
            class_name => 'Some::Lazy::Service',
            description =>
                'Does the subroutine return the same instance of '
                . 'Some::Lazy::Service?');

        Eve::Test::is_prototype(
            code => sub {
                return $self->{'some_registry'}->get_some_prototype_service();
            },
            class_name => 'Some::Prototype::Service',
            description =>
                'Does the subroutine return a different instance of '
                . 'Some::Prototype::Service?');
    }

    sub setup : Test(teardown) {
        my $self = shift;

        undef $self->{'test_property'};
    }

    sub shutdown : Test(shutdown) {
        my $self = shift;

        undef $self->{'testcase_property'};
    }

=head1 DESCRIPTION

B<Eve::Test> class uses the L<Test::Class> module as a base. Each
test case that wants to use its functionality should inherit from it.
After this it is easy to define setup/teardown, startup/shutdown and
test methods.

=head2 Test methods

A test method is specified as such by using special method attributes
like so:

    sub test_something : Test {
        # Your test here
    }

If there is more than one test in the method, their count should be
specified:

    sub test_something : Test(4) {
        # Your four tests here
    }

If there is no way to tell how many tests are going to be run in the
method, the 'no_plan' parameter can be used:

    sub test_something : Test(no_plan) {
        # Your test here
    }

=head2 Abstract test classes

To avoid running tests on abstract test classes call the SKIP_CLASS
method in the package.

    Eve::SomeAbstractClassTest->SKIP_CLASS(1);

=cut

INIT { Test::Class->runtests() }

=head1 METHODS

=head2 B<is_lazy()>

Asserts that a code block returns the same object on two sequential
calls and that this object is an instance of a certain class. When
using this assertion method add two tests to the plan for each call.

    use Eve::Test;

    sub test_lazy_service : Test(2) {
        Eve::Test::is_lazy(
            code => sub {
                return $some_registry->some_lazy_service();
            },
            class_name => 'Some::Class::Name',
            description => 'I need this service to be lazy!');
    }

=head3 Arguments

=over 4

=item C<code>

=item C<class_name>

=item C<description>

(optional) defaults to undef.

=back

=cut

sub is_lazy {
    my (%arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash,
        my ($code, $class_name), my $description = \undef);

    isa_ok($code->(), $class_name, $description);
    is($code->(), $code->(), $description);

    return;
}

=head2 B<is_prototype()>

Asserts that a code block returns a different object on two sequential
calls and that this object is an instance of a certain class. When
using this assertion method add two tests to the plan for each call.

    use Eve::Test;

    sub test_prototype_service : Test(2) {
        Eve::Test::is_prototype(
            code => sub {
                return $some_registry->some_prototype_service();
            },
            class_name => 'Some::Class::Name',
            description => 'I need this service to be a prototype!');
    }

=head3 Arguments

=over 4

=item C<code>

=item C<class_name>

=item C<description>

(optional) defaults to undef.

=back

=cut

sub is_prototype {
    my (%arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash,
        my ($code, $class_name), my $description = \undef);

    isa_ok($code->(), $class_name, $description);
    isnt($code->(), $code->(), $description);

    return;
}

=head1 SEE ALSO

=over 4

=item L<Test::Class>

=item L<Test::Simple>

=item L<Test::More>

=item L<Test::Exception>

=item L<Test::MockObject>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHORS

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=cut

1;
