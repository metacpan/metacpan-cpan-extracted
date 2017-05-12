package Gtk2::Ex::MindMapView::Connection;

our $VERSION = '0.000001';

use warnings;
use strict;

use List::Util;

use Gnome2::Canvas;

use POSIX qw(DBL_MAX);

use Glib ':constants';
use Glib::Object::Subclass
    Gnome2::Canvas::Bpath::,
    properties => [
		   Glib::ParamSpec->string ('arrows', 'arrow-type',
					    'Type of arrow to display', 'none', G_PARAM_READWRITE),

		   Glib::ParamSpec->scalar ('predecessor_item', 'predecessor_item',
					    'Predecessor view item', G_PARAM_READWRITE),

		   Glib::ParamSpec->scalar ('item', 'item_item',
					    'Item view_item', G_PARAM_READWRITE),
		   ]
    ; 


sub INIT_INSTANCE
{
    my $self = shift(@_);

    $self->{x1} = 0;

    $self->{y1} = 0;

    $self->{x2} = 0;

    $self->{y2} = 0;

    $self->{predecessor_item} = undef;

    $self->{predecessor_signal_id}  = 0;

    $self->{item}              = undef;

    $self->{item_signal_id}    = 0;
}


sub SET_PROPERTY
{
    my ($self, $pspec, $newval) = @_;

    my $param_name = $pspec->get_name();

    if ($param_name eq 'predecessor_item')
    {
	if ((defined $self->{predecessor_item}) && ($self->{predecessor_item} != $newval))
	{
	    $self->{predecessor_item}->signal_handler_disconnect($self->{predecessor_signal_id});
	}

	$self->{predecessor_item} = $newval;

	$self->{predecessor_signal_id} =
	    $newval->signal_connect('connection_adjust'=>
				    sub { _predecessor_connection($self, @_); });
    }

    if ($param_name eq 'item')
    {
	if ((defined $self->{item}) && ($self->{item} != $newval))
	{
	    $self->{item}->signal_handler_disconnect($self->{item_signal_id});
	}

	$self->{item} = $newval;

	$self->{item_signal_id} = 
	    $newval->signal_connect('connection_adjust'=>
				    sub { _item_connection($self, @_); });
    }

    $self->{$param_name} = $newval;

#    print "Connection, SET_PROPERTY, name: $param_name  value: $newval\n";

    if ((defined $self->{predecessor_item}) && (defined $self->{item}))
    {
	_set_connection_path($self);
    }
}


sub connect
{
    my $self = shift(@_);

    $self->{predecessor_signal_id} = 
	$self->{predecessor_item}->signal_connect('connection_adjust'=>
 				     sub { _predecessor_connection($self, @_); });
    $self->{item_signal_id} = 
	$self->{item}->signal_connect('connection_adjust'=>
				      sub { _item_connection($self, @_); });
}


sub disconnect
{
    my $self = shift(@_);

    $self->{predecessor_item}->signal_handler_disconnect($self->{predecessor_signal_id});

    $self->{item}->signal_handler_disconnect($self->{item_signal_id});
}


sub _direction
{
    my ($predecessor_item, $item) = @_;

    my $predecessor_column = $predecessor_item->get('column');

    my $predecessor_column_no =
	(defined $predecessor_column) ? $predecessor_column->get('column_no') : 0;

    my $column = $item->get('column');

    my $item_column_no   = (defined $column) ? $column->get('column_no') : 0;

    if ($predecessor_column_no > $item_column_no)
    {
	return ('left', 'left');
    }

    if ($predecessor_column_no < $item_column_no)
    {
	return ('right', 'right');
    }

    if ($predecessor_column_no >= 0)
    {
	return ('right', 'left');
    }

    return ('left', 'right');
}


sub _item_connection
{
    my $self = shift(@_);

    my $direction = (_direction($self->get('predecessor_item'), $self->get('item')))[1];

    my $side = ($direction eq 'right') ? 'left' : 'right';

    my ($x2, $y2) = $self->get('item')->get_connection_point($side);

    my @successors = $self->get('item')->successors($side);

    my $offset = ($side eq 'left') ? -3 : 3; # FIXME: UGH should be radius of toggle.

    $self->{x2} = (scalar @successors > 0) ? $x2 + $offset : $x2;

    $self->{y2} = $y2;

    _set_connection_path($self);
}


sub _predecessor_connection
{
    my $self = shift(@_);

    my $direction = (_direction($self->get('predecessor_item'), $self->get('item')))[0];

    my ($x1, $y1) = $self->get('predecessor_item')->get_connection_point($direction);

    my @successors = $self->get('predecessor_item')->successors($direction);

    my $offset = ($direction eq 'left') ? -3 : 3; # FIXME: UGH should be radius of toggle.

    $self->{x1} = (scalar @successors > 0) ? $x1 + $offset : $x1;

    $self->{y1} = $y1;

    _set_connection_path($self);
}


sub _bpath
{
    my $self = shift(@_);

    my $x1 = $self->{x1};

    my $y1 = $self->{y1};

    my $x2 = $self->{x2};

    my $y2 = $self->{y2};

    my ($predecessor_direction, $item_direction) =
	_direction($self->get('predecessor_item'), $self->get('item'));

    my $c = List::Util::max(25, abs((($x2 - $x1) / 2)));

    my $a = ($predecessor_direction eq 'right') ? $x1 + $c : $x1 - $c;

    my $b = ($item_direction eq 'right') ? $x2 - $c : $x2 + $c;

    my @p = ($x1, $y1, $a, $y1, $b, $y2, $x2, $y2);

    my $pathdef = Gnome2::Canvas::PathDef->new();

    $pathdef->moveto  ($p[0],  $p[1]);

    $pathdef->curveto ($p[2],  $p[3],  $p[4],  $p[5],  $p[6],  $p[7]);


    return $pathdef if ($self->get('arrows') eq 'none');


    my $h = 4 * $self->get('width-pixels'); # Height of arrow head.

    my $v = $h / 2; 

    if ($item_direction eq 'right')
    {
	@p = ($x2-$h,$y2+$v, $x2-$h,$y2-$v, $x2,$y2);
    }
    else
    {
	@p = ($x2+$h,$y2+$v, $x2+$h,$y2-$v, $x2,$y2);
    }

    $pathdef->lineto ($p[0], $p[1]);

    $pathdef->lineto ($p[2], $p[3]);

    $pathdef->lineto ($p[4], $p[5]);

    return $pathdef if ($self->get('arrows') eq 'one-way');


    my $o = 3; # offset.

    $h = $h + $o;

    $pathdef->moveto  ($x1, $y1);

    if ($item_direction eq 'left')
    {
	@p = ($x1-$h,$y1+$v, $x1-$h,$y1-$v, $x1,$y1);
    }
    else
    {
	@p = ($x1+$h,$y1+$v, $x1+$h,$y1-$v, $x1,$y1);
    }

    $pathdef->lineto ($p[0], $p[1]);

    $pathdef->lineto ($p[2], $p[3]);

    $pathdef->lineto ($p[4], $p[5]);

    return $pathdef;
}


sub _set_connection_path
{
    my $self = shift(@_);

    $self->set_path_def(_bpath($self));

    if ($self->get('item')->is_visible() && $self->get('predecessor_item')->is_visible())
    {
	$self->show();

	$self->lower_to_bottom();
    }
    else
    {
	$self->hide();
    }
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::Connection - Draw connections between view items.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::Connection version 0.0.1

=head1 HEIRARCHY

 Glib::Object
 +----Gtk2::Object
      +----Gnome2::Canvas::Item
           +----Gnome2::Canvas::Shape
                +----Gnome2::Canvas::Bpath
                     +----Gtk2::Ex::MindMapView::Connection

=head1 SYNOPSIS

use Gtk2::Ex::MindMapView::Connection;

=head1 DESCRIPTION

This module is internal to Gtk2::Ex::MindMapView. Connections are
instantiated by Gtk2::Ex::MindMapView.  This module is responsible for
drawing the connecting lines between Gtk2::Ex::MindMapView::Items onto
the canvas.

The Gtk2::Ex::MindMapView::Connection is an observer. It registers
with the view items so that it may be notified when a view item's
state changes.

=head1 INTERFACE 

=head2 Properties

=over

=item 'arrows' (string : readable / writable)

Indicates whether arrows should be drawn. Possible values are:
C<none>, C<one-way>, and C<two-way>.

=item 'predecessor_item' (Gtk2::Ex::MindMapView::Item : readable / writable)

The item at which this connection starts.

=item 'item' (Gtk2::Ex::MindMapView::Item : readable / writable)

The item at which this connection ends.

=back

=head2 Methods

=over

=item INIT_INSTANCE

This subroutine is called by Glib::Object::Subclass as the object is
being instantiated. You should not call this subroutine directly.
Leave it alone.

=item SET_PROPERTY

This subroutine is called by Glib::Object::Subclass when a property is
being set. You should not call this subroutine directly. Leave it
alone. Instead call the C<set> method to assign values to properties.

=item connect

Connect the Gtk2::Ex::MindMapView::Connection to the items it
observes.


=item disconnect

Disconnect the Gtk2::Ex::MindMapView::Connection from the items it
observes.

=back

=head1 DIAGNOSTICS

=over

None.

=back

=head1 DEPENDENCIES

None.

=head1 BUGS and LIMITATIONS

=over

Error message from libart "*** attempt to put segment in horiz list
twice" occurs when drawing 'two-way' arrows.

With 'two-way' arrows the arrow pointing back to the predecessor item
is partially covered by the toggle.

=back

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
