package Eve::Item::Entry;

use parent qw(Eve::Item);

use strict;
use warnings;

=head1 NAME

B<Eve::Item::Entry> - a base class for workflow items.

=head1 SYNOPSIS

    package Eve::Item::Entry::Foo;

    use parent qw(Eve::Item::Entry);

    sub init {
        my ($self, %arg_hash) = @_;
        my $rest_hash = Eve::Support::arguments(
            \%arg_hash, my $some_attribute);
        $self->SUPER::init(%{$rest_hash});

        $self->{'some_attribute'} = $some_attribute;
    }

    1;

    my $foo = Eve::Item::Entry::Foo->new(
        some_attribute => 'some value',
        some_super_attribute => 'super value');

    print $foo->some_attribute, $foo->some_super_attribute

=head1 DESCRIPTION

B<Eve::Item::Entry> is a base class for timed and stateful data
items. It is primarily assumed to be used as a base for database row
representations.

=head3 Constants

=over 4

=item STATUS_ACTIVE

=back

=cut

use constant {
    STATUS_ACTIVE => 1
};

=head3 Attributes

=over 4

=item C<id>

=item C<created>

=item C<modified>

=item C<status>

=back

=head3 Constructor arguments

The same as the attributes described above.

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    my $arg_hash = Eve::Support::arguments(
        \%arg_hash, my ($id, $created, $modified, $status));

    $self->{'id'} = $id;
    $self->{'created'} = $created;
    $self->{'modified'} = $modified;
    $self->{'status'} = $status;

    return;
}

=head1 SEE ALSO

=over 4

=item L<Eve::Item>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHOR

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=back

=cut

1;
