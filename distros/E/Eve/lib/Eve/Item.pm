package Eve::Item;

use parent qw(Eve::Class);

use strict;
use warnings;

use Eve::Exception;

=head1 NAME

B<Eve::Item> - a base class for item classes.

=head1 SYNOPSIS

    package Eve::Item::Foo;

    use parent qw(Eve::Item);

    sub init {
        my ($self, %arg_hash) = @_;
        my $rest_hash = Eve::Support::arguments(
            \%arg_hash, my $some_attribute);
        $self->SUPER::init(%{$rest_hash});

        $self->{'some_attribute'} = $some_attribute;
    }

    1;

    my $foo = Eve::Item::Foo->new(
        some_attribute => 'some value',
        some_super_attribute => 'super value');

    print $foo->some_attribute, $foo->some_super_attribute

=head1 DESCRIPTION

B<Eve::Item> is a base class for item classes. It is assumed to
represent the data part of an object.

=head1 METHODS

=head2 B<eq()>

=head3 Arguments

=over 4

=item C<item>

a C<Eve::Item> derivative object that needs to be compared with the
current one.

=back

=cut

sub eq {
    Eve::Error::NotImplemented->throw();
}

=head1 SEE ALSO

=over 4

=item L<Eve::Class>

=item L<Eve::Exception>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHOR

=over 4

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;
