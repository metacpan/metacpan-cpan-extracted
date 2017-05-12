package Gapp::TableCell;
{
  $Gapp::TableCell::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

has [qw( left right top bottom )] => (
    is => 'rw',
    isa => 'Int',
);

has [qw( hexpand vexpand )] => (
    is => 'rw',
    isa => 'ArrayRef',
);

has [qw( xalign yalign )] => (
    is => 'rw',
    isa => 'Num',
);

sub table_attach {
    my ( $self ) = @_;
    return $self->left, $self->right, $self->top, $self->bottom, $self->hexpand, $self->vexpand;
}

1;



__END__

=pod

=head1 NAME

Gapp::TableCell - TableCell Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::TableCell>

=back

=head1 DESCRIPTION

Table cells are used to layout widgets in a table. Generally you won't need
to worry about the details of table cells.

If you want to change how widgets are added to a table (which you probably
don't), then you this documentation will be useful. To change how widgets are
added to a table, you need to create a layout. You do this using
L<Gapp::Layout>.

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<left, right, top , bottom>

=over 4

=item isa: Int

=back

=item B<hexpand, vexpand>

=over 4

=item isa: ArrayRef

=back

=item B<xalign, yalign>

=over 4

=item isa: Num

=back

=back

=head1 PROVIDED METHODS

=over 4

=item B<table_attach>

Returns the values to pass to C<Gtk2::Table::attach>. This is used

=item B<hexpand, vexpand>

=over 4

=item isa: Bool

=back

=item B<xalign, yalign>

=over 4

=item isa: Num

=back

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut