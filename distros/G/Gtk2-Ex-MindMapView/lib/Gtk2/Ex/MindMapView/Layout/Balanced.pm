package Gtk2::Ex::MindMapView::Layout::Balanced;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use List::Util;

use Glib ':constants';

use constant SLACK_MANY_ITEMS=>1.0;
use constant SLACK_FEW_ITEMS=>1.25;

use Gtk2::Ex::MindMapView::Layout::Group;
use Gtk2::Ex::MindMapView::Layout::Column;

use base 'Gtk2::Ex::MindMapView::Layout::Group';

sub new
{
    my $class = shift(@_);

    my $self = $class->SUPER::new(@_);

    if (!defined $self->{graph})
    {
	croak "You must pass a Gtk2::Ex::MindMapView::Graph as argument.\n";
    }

    $self->{lhs_weight} = 0;  # Weight of left hand side of tree.

    $self->{rhs_weight} = 0;  # Weight of right hand side of tree.

    $self->{columns}    = {}; # Hash of columns.

    $self->{item_count} = 0;  # A count of the number of items in the graph.

    $self->{allocated}  = {}; # List of items that have been allocated.

    my $root = $self->{graph}->get_root();

    $self->{graph}->traverse_BFS($root, sub { _allocate($self, $_[0]); });

    return $self;
}


# $layout->layout()

sub layout
{
    my $self = shift(@_);

    my $lhs_offset = 0;  # Offset of columns on left hand side of tree.

    my $rhs_offset = 0;  # Offset of columns on right hand side of tree.

    my @columns = values (%{$self->{columns}});

    my @sorted_columns = sort { abs($a->get('column_no')) <=> abs($b->get('column_no')) } @columns;

    foreach my $column (@sorted_columns)
    {
	my $column_no = $column->get('column_no');

	my $width = $column->get('width') + $self->get_horizontal_padding();

	$column->set(y=>(-0.5 * $column->get('height')));

	if ($column_no > 0)
	{
	    $column->set(x=>$rhs_offset);

	    $rhs_offset += $width;
	}

	if ($column_no < 0)
	{
	    $lhs_offset -= $width;

	    $column->set(x=>$lhs_offset);
	}

	if ($column_no == 0)
	{
	    $rhs_offset = $width / 2;

	    $lhs_offset = -($width - $rhs_offset);

	    $column->set(x=>$lhs_offset);
	}

	$column->layout();
    }
}


sub _allocate
{
    my ($self, $item) = @_;

    my @predecessors = $self->{graph}->predecessors($item);

    my $num_predecessors = scalar (@predecessors);

#    print "Balanced, _allocate, item: $item  num_predecessors: $num_predecessors\n";

    if ($num_predecessors == 0) # we're the root item.
    {
	_add($self, undef, $item, 0);

	return;
    }

    if ($num_predecessors == 1) # single predecessor.
    {
	my $column_no = _next_column_no($self, $predecessors[0], $item);

	_add($self, $predecessors[0], $item, $column_no);

	return;
    }

    # Multiple predecessors.

    my @visible_predecessors = grep { $_->is_visible(); } @predecessors;

    if (scalar @visible_predecessors == 0) # FIXME: dubious.
    {
	_add($self, $predecessors[0], $item, 0);

	return;
    }

    if (scalar @visible_predecessors == 1)
    {
	my $column_no = _next_column_no($self, $visible_predecessors[0], $item);

	_add($self, $visible_predecessors[0], $item, $column_no);

	return;
    }

    # Multiple visible predecessors.

    my @column_nos = map { $_->get_column_no(); } @visible_predecessors;

    if (_all_same(@column_nos))
    {
	my $column_no = _next_column_no($self, $visible_predecessors[0], $item);

	_add($self, $visible_predecessors[0], $item, $column_no);

	return;
    }

    # "Average" column number.

    my $total = List::Util::sum(@column_nos);

    my $column_no = int($total / (scalar @visible_predecessors));

    _add($self, $visible_predecessors[0], $item, $column_no);
}


sub _all_same
{
    my $first = shift(@_);

    foreach my $next (@_)
    {
	return FALSE if ($next != $first);
    }

    return TRUE;
}


sub _add
{
    my ($self, $predecessor_item, $item, $column_no) = @_;

    return if (exists $self->{allocated}{$item});

    my $column = $self->{columns}{$column_no};

    if (!defined $column)
    {
	$column = Gtk2::Ex::MindMapView::Layout::Column->new(column_no=>$column_no);

	$self->{columns}{$column_no} = $column;
    }

    $item->set(column=>$column);

    $column->add($predecessor_item, $item);

    $self->{allocated}{$item} = 1;

    my @columns = values (%{$self->{columns}});

    $self->set(height=>_balanced_height($self, \@columns));

    $self->set(width=>_balanced_width($self, \@columns));

    $self->{item_count}++;
}


sub _balanced_height
{
    my ($self, $columns_ref) = @_;

    my @columns = @$columns_ref;

    return 0 if (scalar @columns == 0);

    return List::Util::max( map { $_->get('height'); } @columns );
}


sub _balanced_width
{
    my ($self, $columns_ref) = @_;

    my @columns = @$columns_ref;

    return 0 if (scalar @columns == 0);

    return List::Util::sum( map { $_->get('width'); } @columns );
}


sub _next_column_no
{   
    my ($self, $predecessor_item, $item) = @_;

    my $column_no = $predecessor_item->get_column_no();

    return ($column_no + 1) if ($column_no > 0);

    return ($column_no - 1) if ($column_no < 0);

    if ($self->{rhs_weight} > ($self->{lhs_weight} * _slack($self)))
    {
	$self->{graph}->traverse_DFS($item, sub { $self->{lhs_weight} += $_[0]->get_weight(); });

	return -1;
    }

    $self->{graph}->traverse_DFS($item, sub { $self->{rhs_weight} += $_[0]->get_weight(); });

    return 1;
}


# _slack: Make rebalancing less "touchy" when the number of items is
# small.

sub _slack
{
    my $self = shift(@_);

    if ($self->{item_count} < 10)
    {
	return SLACK_FEW_ITEMS; # > 1
    }

    return SLACK_MANY_ITEMS; # 1
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::Layout::Balanced - Balanced layout for view items.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::Layout::Balanced version 0.0.1

=head1 HEIRARCHY

  Gtk2::Ex::MindMapView::Layout::Group
  +----Gtk2::Ex::MindMapView::Layout::Balanced

=head1 SYNOPSIS

use Gtk2::Ex::MindMapView::Layout::Balanced;

=head1 DESCRIPTION

A balanced layout for the mindmap. This module considers the "weight"
of each Gtk2::Ex::MindMapView::Item when laying them out. The weight
is a measure of the amount of screen real estate taken up by the item.


=head1 INTERFACE 

=over

=item C<new (graph=E<gt>$graph)>

Instantiates a new balanced layout. This code assigns
Gtk2::Ex::MindMapView::Item objects to columns based on their
relationships to each other as determined by the
Gtk2::Ex::MindMapView::Graph argument.


=item C<layout()>

Places the items in the balanced layout on the canvas. This code
determines the width of the columns in which the
Gtk2:Ex::MindMapView::Items are placed, and positions the items
appropriately on the canvas.

=back

=head1 DIAGNOSTICS

=over

=item C<You must pass a Gtk2::Ex::MindMapView::Graph as argument.>

You must pass in a Gtk2::Ex::MindMapView::Graph when instantiating a
Gtk2::Ex::MindMapView::Layout::Balanced layout.

=back

=head1 DEPENDENCIES

None.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-gtk2-ex-mindmapview@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

James Muir  C<< <hemlock@vtlink.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, James Muir C<< <hemlock@vtlink.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
