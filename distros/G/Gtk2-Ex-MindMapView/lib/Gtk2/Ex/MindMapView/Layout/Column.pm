package Gtk2::Ex::MindMapView::Layout::Column;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use List::Util;

use Gtk2::Ex::MindMapView::Layout::Group;
use Gtk2::Ex::MindMapView::Layout::Cluster;

use base 'Gtk2::Ex::MindMapView::Layout::Group';

sub new
{
    my $class = shift(@_);

    my $self = $class->SUPER::new(@_);

    if (!defined $self->{column_no})
    {
	croak "Gtk2::Ex::MindMapView::Layout::Column requires a 'column_no'\n";
    }

    $self->{clusters} = {}; # Hash of clusters.

    return $self;
}


# $column->add($predecessor_item, $item)

sub add
{
    my ($self, $predecessor_item, $item) = @_;

    my $cluster_item = (defined $predecessor_item) ? $predecessor_item : $item;

    my $cluster = $self->{clusters}{$cluster_item};

    if (!defined $cluster)
    {
	$cluster = Gtk2::Ex::MindMapView::Layout::Cluster->new(column=>$self,
				       predecessor=>$predecessor_item,
				       cluster_no=>(scalar keys(%{$self->{clusters}})));

	$self->{clusters}{$cluster_item} = $cluster;
    }

    $cluster->add($item);

    my @clusters = values (%{$self->{clusters}});

    $self->set(height=>_column_height($self, \@clusters));

    $self->set(width=>_column_width($self, \@clusters));
}


# $column->layout();

sub layout
{
    my $self = shift(@_);

    my ($x, $y) = $self->get(qw(x y));

    my @clusters = values (%{$self->{clusters}});

    my @sorted_clusters = sort { $a->seq_no() <=> $b->seq_no() } @clusters;

#    my @sorted_clusters = sort { $a->get('cluster_no') <=> $b->get('cluster_no') } @clusters;

    my @visible_clusters = grep  { $_->get('height') > 0 } @sorted_clusters;

    foreach my $cluster (@visible_clusters)
    {
	$cluster->set(x=>$x);

	$cluster->set(y=>$y);

	$cluster->layout();

	$y += ($cluster->get('height') + $self->get_vertical_padding());
    }
}


sub _column_height
{
    my ($self, $clusters_ref) = @_;

    my @clusters = @$clusters_ref;

    my @visible_clusters = grep { $_->get('height') > 0 } @clusters;

    return 0 if (scalar @visible_clusters == 0);

    my $total_height = List::Util::sum (map { $_->get('height'); } @visible_clusters);

    my $total_pad = ($#visible_clusters * $self->get_vertical_padding());

#    print "Column, height: $total_height  pad: $total_pad\n";

    return ($total_height + $total_pad);
}

sub _column_width
{
    my ($self, $clusters_ref) = @_;

    my @clusters = @$clusters_ref;

    my $max_width = List::Util::max (map { $_->get('width'); } @clusters);

    my $width = List::Util::min($max_width, $self->get_max_width());

#    print "Column, max_width: $max_width  width: $width\n";

    return $width;
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::Layout::Column - Display vertical layout of clusters.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::Layout::Column version 0.0.1

=head1 HEIRARCHY

  Gtk2::Ex::MindMapView::Layout::Group
  +----Gtk2::Ex::MindMapView::Layout::Column

=head1 SYNOPSIS

use Gtk2::Ex::MindMapView::Layout::Column;


=head1 DESCRIPTION

The Gtk2::Ex::MindMapView::Layout::Column is used to layout
Gtk2::Ex::MindMapView::Items in columns on a Gnome2::Canvas.

=head1 INTERFACE 

=over

=item C<new(column_no=E<gt>$column_no)>

Instantiates the column and saves the column number for future
reference.

Each column is assigned a column number, which is used to determine
which side of the root column it is on. The root column is always
column zero. Columns to the right of the root have positive column
numbers, columns to the left of the root column have negative column
numbers.

=item C<add($predecessor_item, $item)>

Each Gtk2::Ex::MindMapView::Item is added to a cluster in a
column. The cluster groups items according to their predecessor.

=item C<layout()>

Places Gtk2::Ex::MindMapView::Items on the canvas according to the
cluster they belong to.

=back

=head1 DIAGNOSTICS

=over

=item C<Gtk2::Ex::MindMapView::Layout::Column requires a 'column_no'>

You must pass in a column_no argument when creating a
Gtk2::Ex::MindMapView::Layout::Column.

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
