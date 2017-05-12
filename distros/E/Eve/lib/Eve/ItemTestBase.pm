# -*- mode: Perl; -*-
package Eve::ItemTestBase;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;
use Test::Exception;

Eve::ItemTestBase->SKIP_CLASS(1);

=head1 NAME

B<Eve::ItemTestBase> - a base class for all item classes.

=head1 SYNOPSIS

    package SomeItemTest;

    use parent qw(Eve::ItemTestBase);

    # put your item test content here

=head1 DESCRIPTION

B<Eve::ItemTestBase> is the class that provides test case setup and some
mandatory tests required to pass for all item classes.

=head1 METHODS

=head2 B<get_argument_list()>

Returns test arguments for items, can be overridden to add inheritable
properties.

=cut

sub get_argument_list {
    return {};
}

=head2 B<test_init()>

Performs initialization tests.

=cut

sub test_init {}

=head2 B<test_constants>

Performs class constant tests.

=cut

sub test_constants {}

=head2 B<test_eq>

Performs equality method implementation tests.

=cut

sub test_eq : Test(1) {
    my $self = shift;

    throws_ok(sub { $self->{'item'}->eq() }, 'Eve::Error::NotImplemented');
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
