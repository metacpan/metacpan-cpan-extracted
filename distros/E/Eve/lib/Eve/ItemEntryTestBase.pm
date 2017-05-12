# -*- mode: Perl; -*-
package Eve::ItemEntryTestBase;

use parent qw(Eve::ItemTestBase);

use strict;
use warnings;

use Test::More;

Eve::ItemEntryTestBase->SKIP_CLASS(1);

=head1 NAME

B<Eve::ItemEntryTestBase> - a base class for all entry item classes.

=head1 SYNOPSIS

    package SomeEntryItemTest;

    use parent qw(Eve::ItemEntryTestBase);

    # put your item test content here

=head1 DESCRIPTION

B<Eve::ItemEntryTestBase> is the class that provides test case setup
and some mandatory tests required to pass for all item entry
classes. Is derived from the B<Eve::ItemTestBase> and uses its methods
via C<SUPER> call notation. All classes that derive from it should
implement the tests in the same manner.

=head1 METHODS

=head2 B<get_argument_list()>

Returns test arguments for items, can be overridden to add inheritable
properties.

=cut

sub get_argument_list {
    my $self = shift;

    return {
        %{$self->SUPER::get_argument_list()},
        'id' => 123,
        'created' => '2011-03-16 17:03:45',
        'modified' => '2011-03-16 17:04:33',
        'status' => 1};
}

=head2 B<test_init()>

Performs initialization tests.

=cut

sub test_init {
    my $self = shift;

    $self->SUPER::test_init();

    is($self->{'item'}->id, 123);
    is($self->{'item'}->created, '2011-03-16 17:03:45');
    is($self->{'item'}->modified, '2011-03-16 17:04:33');
    is($self->{'item'}->status, 1);
}

=head2 B<test_constants>

Performs class constant tests.

=cut

sub test_constants {
    my $self = shift;

    $self->SUPER::test_constants();

    is($self->{'item'}->STATUS_ACTIVE, 1);
}

=head1 SEE ALSO

=over 4

=item L<Eve::Test>

=item L<Eve::ItemTestBase>

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
