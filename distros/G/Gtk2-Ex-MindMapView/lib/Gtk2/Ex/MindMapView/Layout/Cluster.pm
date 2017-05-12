package Gtk2::Ex::MindMapView::Layout::Cluster;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use List::Util;

use Gtk2::Ex::MindMapView::Layout::Group;

use base 'Gtk2::Ex::MindMapView::Layout::Group';


# $cluster = Gtk2::Ex::MindMapView::Layout::Cluster->new();

sub new
{
    my $class = shift(@_);

    my $self = $class->SUPER::new(@_);

    if (!defined $self->{cluster_no})
    {
	croak "Gtk2::Ex::MindMapView::Layout::Cluster requires a 'cluster_no'\n";
    }

    $self->{items} = [];  # Array of view items.

    return $self;
}


# $cluster->add($item)

sub add
{
    my ($self, $item) = @_;

    push @{$self->{items}}, $item;

    my $column = $self->get('column');

    my @items = @{$self->{items}};

    $self->set(height=>_cluster_height($self, \@items));

    $self->set(width=>_cluster_width($self, \@items));
}


# $cluster->layout();

sub layout
{
    my $self = shift(@_);

    my $column = $self->get('column');

    my ($x, $y) = $self->get(qw(x y));

    my $column_no = $column->get('column_no');

    my $column_width = $column->get('width');

    my @visible_items = grep { $_->is_visible(); } @{$self->{items}};

    return if (scalar @visible_items == 0);

    foreach my $item (@visible_items)
    {
	my ($item_height, $item_width) = $item->get(qw(height width));
	
	my $justification = _justification($column_no, $column_width, $item_width);

	$item->set(x=>($x + $justification));

	$item->set(y=>$y);

	$y += ($item_height + $self->get_vertical_padding());
    }
}


sub seq_no
{
    my $self = shift(@_);

    my $predecessor_item = $self->{predecessor};

    return (defined $predecessor_item) ? $predecessor_item->get('y') : $self->{cluster_no};
}


sub _cluster_height
{
    my ($self, $items_ref) = @_;

    my @visible_items = grep { $_->is_visible(); } @$items_ref;

    return 0 if (scalar @visible_items == 0);

    my $total_height = List::Util::sum (map { $_->get('height'); } @visible_items);

    my $total_pad = ($#visible_items * $self->get_vertical_padding());

#    print "Cluster, height: $total_height  pad: $total_pad  visible_items: @visible_items\n"; 

    return ($total_height + $total_pad);
}


sub _cluster_width
{
    my ($self, $items_ref) = @_;

    my @visible_items = grep { $_->is_visible(); } @$items_ref;

    return 0 if (scalar @visible_items == 0);

    my $max_width = List::Util::max (map { $_->get('width'); } @$items_ref);
    
    my $width = List::Util::min($max_width, $self->get_max_width());

#    print "Cluster, max_width: $max_width  width: $width  visible_items: @visible_items\n"; 

    return $width;
}


sub _justification
{
    my ($column_no, $column_width, $item_width) = @_;

    return 0 if ($column_no > 0);

    return ($column_width - $item_width) if ($column_no < 0);

    return (($column_width - $item_width) / 2);
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::Layout::Cluster - Vertical layout of view items.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::Layout::Cluster version 0.0.1


=head1 HEIRARCHY

  Gtk2::Ex::MindMapView::Layout::Group
  +----Gtk2::Ex::MindMapView::Layout::Cluster

=head1 SYNOPSIS

use Gtk2::Ex::MindMapView::Layout::Cluster;


=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=over

=item C<new(cluster_no=E<gt>$cluster_no)>

Instantiates an array of Gtk2::Ex::MindMapView::Items. All items in a
cluster have a common predecessor item.

=item C<add($item)>

Adds a item to the cluster, and adjusts the height and width of the
cluster.

=item C<layout()>

Places the cluster items on the canvas, and right or left justifies
them.

=item C<seq_no()>

Returns a number which is used to order the clusters in a column.

=back


=head1 DIAGNOSTICS

=over

=item C<Gtk2::Ex::MindMapView::Layout::Cluster requires a 'cluster_no'>

You must pass in a cluster_no argument when creating a
Gtk2::Ex::MindMapView::Layout::Cluster

=back

=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


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
