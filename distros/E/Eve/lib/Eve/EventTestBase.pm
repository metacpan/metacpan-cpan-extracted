package Eve::EventTestBase;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::MockObject;
use Test::More;

use Eve::RegistryStub;

use Eve::Registry;

Eve::EventTestBase->SKIP_CLASS(1);

=head1 NAME

B<Eve::EventTestBase> - a base class for event test case classes.

=head1 SYNOPSIS

    package BogusEventTest;

    use parent qw(Eve::EventTestBase);

    # Place the event test case class here

=head1 DESCRIPTION

B<Eve::EventTestBase> is the class that provides tests that are
required to pass for all event classes.

=head1 METHODS

=head2 B<setup()>

=cut

sub setup {
    my $self = shift;

    $self->{'registry'} = Eve::Registry->new();
    $self->{'event_map'} = $self->{'registry'}->get_event_map();
}

=head2 B<test_trigger()>

A mandatory test case for the C<trigger()> method.

=cut

sub test_trigger : Test(6) {
    my $self = shift;

    my $handler_list = [];
    for my $i (0..2) {
        $self->{'event'}->trigger();

        for my $handler (@{$handler_list}) {
            is($handler->call_pos(1), 'handle');
            is_deeply(
                [$handler->call_args(1)],
                [$handler, event => $self->{'event'}]);
        }

        my $handler_mock = Test::MockObject->new()->set_always('handle', 1);
        push(@{$handler_list}, $handler_mock);
        $self->{'event_map'}->bind(
            event_class => ref $self->{'event'},
            handler => $handler_mock);
    }
}

=head1 SEE ALSO

=over 4

=item L<Eve::Test>

=item L<Test::Class>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Sergey Konoplev, Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;
