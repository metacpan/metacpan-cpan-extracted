package Gapp::Table;
{
  $Gapp::Table::VERSION = '0.60';
}


use Moose;
use MooseX::LazyRequire;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;
extends 'Gapp::Container';

use Gapp::TableMap;
use Gapp::Types qw( GappTableMap );

has '+gclass' => (
    default => 'Gtk2::Table',
);

has 'map' => (
    is => 'rw',
    isa => GappTableMap,
	coerce => 1,
	lazy_required => 1,
);

has '_active_cell' => (
	is => 'rw',
	isa => 'Maybe[Int]',
);

sub current_cell {
	my ( $self ) = @_;
	$self->_active_cell ? $self->map->cells->[ $self->_active_cell ] : undef;
}

sub next_cell {
	my ( $self ) = @_;
	
	my $x = defined $self->_active_cell ? $self->_active_cell + 1 : 0;
	my $cell = $self->map->cells->[$x];
	$self->_set_active_cell( $cell ? $x : undef );
	return $cell;
}


before _construct_gobject => sub {
	my $self = shift;
	return $self->set_args( [ $self->map->row_count, $self->map->col_count, 0 ] );
};



1;


__END__

=pod

=head1 NAME

Gapp::Table - Table Widget

=head1 SYNOPSIS

    Gapp::Table->new(
		map => "
        +-------%------+>>>>>>>>>>>>>>>+
        |     Name     |               |
        +--------------~ Image         |
        | Keywords     |               |
        +-------+------+[--------------+
        ^       ' More | Something     |
        ^       |      +-----+--------]+
        _ Notes |      |     |     Foo |
        +-------+------+-----+---------+
        ^ Bar          | Baz           |
        +--------------+---------------+",
		content => [
			...
		]
	);

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::Table>

=back

=head1 DESCRIPTION

L<Gapp::Table> will allow you to create complex table layouts with ease. Just
draw your table and define your content and Gapp will handle packing the widgets
and applying formatting.

See L<Gapp::TableMap> for more information on drawing tables.

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<map>

=over 4

=item isa: L<Gapp::TableMap>

=item coercions: Str

=back

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut


