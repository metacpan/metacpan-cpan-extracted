# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-CellLayout-Base.
#
# Gtk2-Ex-CellLayout-Base is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-CellLayout-Base is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-CellLayout-Base.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::CellLayout::Base;
use 5.008;
use strict;
use warnings;
use Carp;
use List::Util;
use Gtk2;
use Glib::Ex::FreezeNotify;

our $VERSION = 5;


#------------------------------------------------------------------------------
# Gtk2::CellLayout interface functions

# gtk_cell_layout_pack_start
#
# Because calls here have been spun through GInterface, $expand will be a
# the usual Gtk2-Perl representation of a boolean, ie. either '' or 1.
#
sub PACK_START {
  my ($self, $cell, $expand) = @_;
  my $cellinfo_list = ($self->{'cellinfo_list'} ||= []);
  if (List::Util::first {$_->{'cell'} == $cell} @$cellinfo_list) {
    croak "this cell renderer already packed into this widget";
  }
  push @$cellinfo_list, { cell => $cell,
                          pack => 'start',
                          expand => $expand };
  $self->_cellinfo_list_changed;
}

# gtk_cell_layout_pack_end
sub PACK_END {
  my ($self, $cell, $expand) = @_;
  my $cellinfo_list = ($self->{'cellinfo_list'} ||= []);
  if (List::Util::first {$_->{'cell'} == $cell} @$cellinfo_list) {
    croak "this cell renderer already packed into this widget";
  }
  push @$cellinfo_list, { cell => $cell,
                          pack => 'end',
                          expand => $expand };
  $self->_cellinfo_list_changed;
}

# gtk_cell_layout_clear
sub CLEAR {
  my ($self) = @_;
  $self->{'cellinfo_list'} = [];
  $self->_cellinfo_list_changed;
}

# gtk_cell_layout_add_attribute
#
# The core widgets like Gtk2::TreeViewColumn seem a bit slack in their
# add_attributes() when the property name is the same as previously added.
# They do a list "prepend" and so end up with the oldest setting applied
# last and thus having priority.  It's hard to believe that's right, either
# an error or the latest setting would surely have to be right.  For now we
# plonk into the hash so a new setting overwrites any previous.
#
sub ADD_ATTRIBUTE {
  my ($self, $cell, $attribute, $column) = @_;
  my $cellinfo =  $self->_get_cellinfo_for_cell ($cell);
  $cellinfo->{'attributes'}->{$attribute} = $column;
  $self->_cellinfo_attributes_changed;
}

# gtk_cell_layout_set_cell_data_func
sub SET_CELL_DATA_FUNC {
  my ($self, $cell, $func, $userdata) = @_;
  my $cellinfo =  $self->_get_cellinfo_for_cell ($cell);
  $cellinfo->{'datafunc'} = $func;
  $cellinfo->{'datafunc_userdata'} = $userdata;
  $self->_cellinfo_attributes_changed;
}

# gtk_cell_layout_clear_attributes
sub CLEAR_ATTRIBUTES {
  my ($self, $cell) = @_;
  my $cellinfo =  $self->_get_cellinfo_for_cell ($cell);
  %{$cellinfo->{'attributes'}} = ();
  $self->_cellinfo_attributes_changed;
}

# gtk_cell_layout_reorder
sub REORDER {
  my ($self, $cell, $position) = @_;
  my $cellinfo_list = $self->{'cellinfo_list'};
  foreach my $i (0 .. $#$cellinfo_list) {
    if ($cellinfo_list->[$i]->{'cell'} == $cell) {
      if ($i == $position) {
        return; # already in the right position
      }
      my $cellinfo = splice @$cellinfo_list, $i, 1;
      splice @$cellinfo_list, $position,0, $cellinfo;
      $self->_cellinfo_list_changed;
      return;
    }
  }
  croak "cell renderer not in this widget";
}

# gtk_cell_layout_get_cells (new in Gtk 2.12)
sub GET_CELLS {
  my ($self) = @_;
  return map {$_->{'cell'}} @{$self->{'cellinfo_list'}};
}

# return the cellinfo record containing the renderer $cell
sub _get_cellinfo_for_cell {
  my ($self, $cell) = @_;
  return ((List::Util::first {$_->{'cell'} == $cell}
           @{$self->{'cellinfo_list'}})
          || croak "cell renderer not in this widget");
}


#------------------------------------------------------------------------------
# extra functions

# When setting cell data, GtkCellView, GtkIconView and GtkTreeViewColumn all
# apply attributes first then run the function, so do the same here.
#
# The freeze_notify across the attributes and func is the same as the core
# viewers.  Don't know what it's for, maybe just the general principle of
# holding back notifying a group of property changes until all are done.
#
# The plain hash used for $cellinfo->{'attributes'} gives the property name
# keys in no particular order.  That should be fine, nobody should expect a
# particular order.
#
# The FreezeNotify mechanism protects against an error throw leaving the
# renderer permanently frozen.  Errors could arise from dodgy value types to
# the $cell->set(), and can arise easily from application code in $func.
#
# Freezing is not done if there's no attributes to set and no func to call.
# This will be unusual, but it saves a couple of cycles on a purely fixed
# renderer like for instance a pixbuf icon.
#
sub _set_cell_data {
  my ($self, $iter, @extra_settings) = @_;
  my $model = $self->{'model'} or return;

  foreach my $cellinfo (@{$self->{'cellinfo_list'}}) {
    my $cell = $cellinfo->{'cell'};
    my $freezer;

    if (my $ahash = $cellinfo->{'attributes'}) {
      if (my @settings = %$ahash) {
        $freezer = Glib::Ex::FreezeNotify->new ($cell);
        for (my $i = 1; $i < @settings; $i += 2) {
          $settings[$i] = $model->get_value ($iter, $settings[$i]);
        }
        $cell->set (@settings);
      }
    }
    if (@extra_settings) {
      $freezer ||= Glib::Ex::FreezeNotify->new ($cell);
      $cell->set (@extra_settings);
    }
    if (my $func = $cellinfo->{'datafunc'}) {
      $freezer ||= Glib::Ex::FreezeNotify->new ($cell);
      $func->($self, $cell, $model, $iter, $cellinfo->{'datafunc_userdata'});
    }
  }
}

sub _cellinfo_starts {
  my ($self) = @_;
  return grep {$_->{'pack'} eq 'start'} @{$self->{'cellinfo_list'}};
}
sub _cellinfo_ends {
  my ($self) = @_;
  return grep {$_->{'pack'} ne 'start'} @{$self->{'cellinfo_list'}};
}

#------------------------------------------------------------------------------
# overridable class callouts

# Not yet 100% certain about these "changed" methods.
# It's maybe, perhaps, possibly, kinda, sorta going to be like the following
# ...

sub _cellinfo_list_changed {
  my ($self) = @_;
  $self->queue_resize;
  $self->queue_draw;
}

sub _cellinfo_attributes_changed {
  my ($self) = @_;
  $self->queue_resize;
  $self->queue_draw;
}

# =head1 METHOD OVERRIDES
#
# The recommended C<use base> shown in the synopsis above brings
# C<Gtk2::Ex::CellLayout::Base> into your C<@ISA> in the usual way, and also
# in the usual way you can override the functions in C<CellLayout::Base> with
# your own implementations, probably chaining up to the base ones, perhaps
# not.  The following methods in particular can be intercepted,
#
# =over 4
#
# =item C<< $self->_cellinfo_list_changed () >>
#
# This method is called by C<PACK_START>, C<PACK_END>, C<CLEAR> and C<REORDER>
# to indicate that the list of renderers has changed.  The default
# implementation does a C<queue_resize> and C<queue_draw>, expecting a new
# size for new renderers and of course new drawing.
#
# Viewer widget code might add to this if it for instance maintains additional
# data relating to the renderers.
#
# =item C<< $self->_cellinfo_attributes_changed () >>
#
# This method is called by C<ADD_ATTRIBUTE>, C<CLEAR_ATTRIBUTES> and
# C<SET_CELL_DATA_FUNC> to indicate that renderer attributes have changed.
# The default implementation does a C<queue_resize> and C<queue_draw>,
# expecting a possible new size or new drawing from different attributes.
#
# Viewer widget code might add to this, for instance to invalidate renderer
# display size data if maybe it tries to cache that for on-screen or nearby
# rows.
#
# =back


#------------------------------------------------------------------------------
# Gtk2::Buildable interface functions

# This is the same as _gtk_cell_layout_buildable_add_child(), in particular
# as per that function it always does "pack_start" and false for the expand
# parameter.
#
sub ADD_CHILD {
  my ($self, $builder, $child, $type) = @_;
  $self->pack_start ($child, 0);
}

# In a <child>...</child> block under one of our new viewer widget, we
# handle <attributes>...</attributes> to make add_attributes calls.
#
# $self is a viewer widget, ie. someone using us, and $child is the
# Gtk2::CellRenderer child being added to the viewer.
#
sub CUSTOM_TAG_START {
  my ($self, $builder, $child, $tagname) = @_;
  if ($child && $tagname eq 'attributes') {
    require Gtk2::Ex::CellLayout::BuildAttributes;
    return Gtk2::Ex::CellLayout::BuildAttributes->new (cell_layout => $self,
                                                       cell_renderer=> $child);
  } else {
    return undef;
  }
}


1;
__END__

=for stopwords CellLayout Gtk2-Ex-CellLayout-Base Gtk2-Perl Gtk superclass Buildable renderers arrayref hashref renderer enum BUILDABLE conditionalize eg buildable superclasses natively Ryde

=head1 NAME

Gtk2::Ex::CellLayout::Base -- basic Gtk2::CellLayout implementation functions

=for test_synopsis my ($cell, @render_args)

=head1 SYNOPSIS

 package MyNewViewer;
 use Gtk2 1.180;     # to have CellLayout as an interface
 use base 'Gtk2::Ex::CellLayout::Base';

 use Glib::Object::Subclass
   'Gtk2::Widget',
   interfaces => [ 'Gtk2::CellLayout', 'Gtk2::Buildable' ];

 sub my_expose {
   my ($self, $event) = @_;
   $self->_set_cell_data;
   foreach my $cellinfo ($self->_cellinfo_starts) {
     $cellinfo->{'cell'}->render (@render_args);
   }
   foreach my $cellinfo ($self->_cellinfo_ends) {
     $cellinfo->{'cell'}->render (@render_args);
   }
   return Gtk2::EVENT_PROPAGATE;
 }

=head1 DESCRIPTION

C<Gtk2::Ex::CellLayout::Base> provides the following functions for use by a
new data viewer widget written in Perl and wanting to implement the
CellLayout interface (see L<Gtk2::CellLayout>).

    PACK_START ($self, $cell, $expand)
    PACK_END ($self, $cell, $expand)
    CLEAR ($self)
    ADD_ATTRIBUTE ($self, $cell, $attribute, $column)
    CLEAR_ATTRIBUTES ($self, $cell)
    SET_CELL_DATA_FUNC ($self, $cell, $func, $userdata)
    REORDER ($self, $cell, $position)
    @list = GET_CELLS ($self)

The functions maintain a list of C<Gtk2::CellRenderer> objects in the viewer
widget, together with associated attribute settings and/or data setup
function.

C<CellLayout::Base> is designed as a multiple-inheritance mix-in to add to
your C<@ISA>.  C<use base> per the synopsis above (see L<base>) is one way
to do that.  (If you set C<@ISA> yourself be careful not to lose what
C<Glib::Object::Subclass> sets up.)

You can enhance or override some of C<CellLayout::Base> by writing your own
versions of the functions, and then chain up (or not) to the originals with
C<SUPER> in the usual way.

Gtk2-Perl 1.180 or higher is required for C<Gtk2::CellLayout> as an
interface.  (You also need that version for C<Gtk2::Buildable> to override
the widget superclass Buildable, per L</BUILDABLE INTERFACE> below.)

=head1 CELL INFO LIST

C<Gtk2::Ex::CellLayout::Base> keeps information on the added cell renderers
in C<< $self->{'cellinfo_list'} >> on the viewer widget.  This field is an
arrayref, created when first needed, and each element in the array is a
hashref.

    [ { cell       => $renderer1,
        pack       => 'start',
        expand     => 1,
        attributes => { text => 3 },
        datafunc   => \&somefunc,
        datafunc_userdata => 'xyz'
      },
      { cell => $renderer2,
        ...
      },
      ...
    ]

The element fields are

    cell               Gtk2::CellRenderer object
    pack               string 'start' or 'end'
    expand             boolean
    attributes         hash ref { propname => colnum }
    datafunc           code ref or undef
    datafunc_userdata  any scalar

C<cell> is the renderer object added in by C<pack_start> or C<pack_end>, and
C<expand> is the flag passed in those calls.  The C<pack> field is
C<"start"> or C<"end"> according to which function was used.  C<"start"> and
C<"end"> values are per the C<Gtk2::PackType> enumeration, but that enum
doesn't normally arise in the context of a viewer widget.

C<attributes> is a hash table of property name to column number established
by C<add_attribute> and C<set_attributes>.  C<datafunc> and
C<datafunc_userdata> come from C<set_cell_data_func>.  These are all used
when preparing the renderers to draw a particular row of the
C<Gtk2::TreeModel>.

The widget C<size_request> and C<expose> operations are the two most obvious
places the cell information is needed.  Both will prepare the renderers with
data from the model, then ask their sizes or do some drawing.  The following
function is designed to prepare the renderers.

=over 4

=item C<< $self->_set_cell_data ($iter) >>

=item C<< $self->_set_cell_data ($iter, $propname,$value, ...) >>

Set the property values in all the cell renderers packed into C<$self>,
ready to draw the model row given by C<$iter>.  The model object is expected
to be in C<< $self->{'model'} >> and the C<< $self->{'cellinfo_list'} >>
attributes described above are used.

Extra C<< propname=>value >> parameters can be given, to be applied to all
the renderers.  For example the C<is_expander> and C<is_expanded> properties
could be set according to the viewer's state, and whether the model row has
children, and can be expanded.

=back

Here's a minimal C<size_request> handler for a viewer like the core
C<Gtk2::CellView> which displays a single row of a model, with each renderer
one after the other horizontally.  The width is the total of all renderers,
and the height is the maximum among them.  It could look like

    sub do_size_request {
      my ($self, $requisition) = @_;
      my $model = $self->{'model'};
      my $iter = $model->iter_nth_child (undef, $self->{'rownum'});
      $self->_set_cell_data ($iter);

      my $total_width = 0;
      my $max_height = 0;
      foreach my $cellinfo (@{$self->{'cellinfo_list'}}) {
        my $cell = $cellinfo->{'cell'};
        my (undef,undef, $width,$height)
             = $cell->get_size ($self, undef);
        $total_width += $width;
        $max_height = max ($max_height, $height);
      }
      $requisition->width ($total_width);
      $requisition->height ($max_height);
    }

An C<expose> handler is a little more complicated, firstly the cells
shouldn't drawn in C<cellinfo_list> order, but instead the C<start> ones on
the left, then the C<end> ones from the right (see C<_cellinfo_starts> and
C<_cellinfo_ends> below).  And the C<expand> flag is meant to indicate which
cells (if any) should grow to fill available space when there's more than
needed.

=head1 OTHER FUNCTIONS

=over 4

=item C<< $self->_cellinfo_starts >>

=item C<< $self->_cellinfo_ends >>

Return the C<cellinfo_list> elements which are from either C<pack_start> or
C<pack_end> respectively.  These are simply greps of C<cellinfo_list>
looking for the C<pack> field set to C<start> or C<end>.  In an expose or
similar you work across the starts from the left then the ends from the
right, towards the centre (or usually reversed to "start"s on the right in
C<rtl> mode).

    my $x = 0;
    foreach my $cellinfo ($self->_cellinfo_starts) {
      ...
      $x += $cell_width;
    }
    $x = $window_width;
    foreach my $cellinfo ($self->_cellinfo_ends) {
      $x -= $cell_width;
      ...
    }

=back

=head1 BUILDABLE INTERFACE

C<Gtk2::Ex::CellLayout::Base> also provides the following functions for use
by a viewer widget implementing the C<Gtk2::Buildable> interface.  As with
the CellLayout functions above you can override with your own versions and
chain (or not) with C<SUPER> in the usual way.

    ADD_CHILD ($self, $builder, $child, $type)
    $buildattrs = CUSTOM_TAG_START ($self, $builder, $child, $tagname)

To use these functions put C<"Gtk2::Buildable"> in your C<interfaces> list
along with C<Gtk2::CellLayout>, as shown in the L</SYNOPSIS> above.
Buildable is new in Gtk 2.12, so you must depend on that, or conditionalize
to omit it in past versions, eg.

    interfaces =>
    [ 'Gtk2::CellLayout',
      # Gtk2::Buildable is new in Gtk 2.12, omit if not available
      Gtk2::Widget->isa('Gtk2::Buildable') ? ('Gtk2::Buildable') : () ],

If you don't put C<Gtk2::Buildable> in the C<interfaces> at all you can
still create a viewer object with the buildable features inherited from
C<Gtk2::Widget>, but you can't add renderers as children within the XML.

The C<ADD_CHILD> and C<CUSTOM_TAG_START> functions provided here implement
the same syntax as the core widgets like C<Gtk2::TreeViewColumn>, which
means renderers added to layout objects with C<< <child> >>, and then
C<< <attributes> >> for C<add_attribute()> style setups on those renderers.
The C<GtkTreeView> documentation has an example for C<GtkTreeViewColumn>.
Here's another with a hypothetical C<MyNewViewer> class,

    <object class="MyNewViewer" id="myviewer">
      <property name="model">myliststore</property>
      <child>
        <object class="GtkCellRendererText" id="myrenderer">
          <property name="underline">single</property>
        </object>
        <attributes>
          <attribute name="text">0</attribute>
        </attributes>
      </child>
    </object>

A renderer "child" added this way calls C<pack_start> with "expand" false.
This is the same as the core widgets, and like in the core there's currently
no way to instead use C<pack_end> or set expand.  (C<child> has a C<type>
option which might be pressed into service, or C<GtkBox> has C<expand> etc
as settable properties, but best let Gtk take the lead on that.)

As of Gtk2-Perl 1.221 there's no chaining up to tag handlers in widget
superclasses, which means a buildable interface like this loses anything
those superclasses add to C<GtkBuilder>'s standard tags.  In particular for
example you loose C<< <accelerator> >> and C<< <accessibility> >> from
C<GtkWidget>.  Not sure how bad that is in practice.  Hopefully a future
Gtk2-Perl will allow chaining, or do it automatically.

=head1 OTHER NOTES

The C<cellinfo_list> idea is based on the similar cell info lists maintained
inside the core C<Gtk2::TreeViewColumn>, C<Gtk2::CellView> and
C<Gtk2::IconView>.  Elements are hashes so there's room for widget code to
hang extra information, like the "editing" flag of C<IconView>, or the focus
flag and calculated renderer width of C<TreeViewColumn>.

The C<_set_cell_data> function provided above is also similar to what the
core widgets do.  C<Gtk2::TreeViewColumn> even makes its version of that
public as C<< $column->cell_set_cell_data >>.  It probably works equally
well to setup one renderer at a time as it's used, rather than all at once.
Perhaps in the future C<Gtk2::Ex::CellLayout::Base> could offer something
for that, maybe even as a method on the C<cellinfo_list> elements if they
became objects as such.

The display order intended by C<pack_start> and C<pack_end> isn't described
very well in the C<GtkCellLayout> interface documentation, but it's the same
as C<GtkBox> so see there for details.  You might wonder why
C<cellinfo_list> isn't maintained with starts and ends separated in the
first place, since that's wanted for drawing.  The reason is the C<reorder>
method works on the renderers in the order added, counting from 0, with
C<pack_start> and C<pack_end> together.  This makes sense in C<GtkBox> where
the pack type can be changed later, though for C<CellLayout> the pack type
doesn't change (or not natively at least).

The C<GET_CELLS> method is always provided, though it's only used if
Gtk2-Perl is compiled against Gtk version 2.12 or higher which introduces
C<gtk_cell_layout_get_cells>.  If you want all the renderers within your
widget code (which means simply the C<cell> fields picked out of
C<cellinfo_list>) then you can call capital C<GET_CELLS> rather than worry
whether lowercase C<get_cells> is available or not.

=head1 SEE ALSO

C<Gtk2::CellLayout>, C<Gtk2::CellRenderer>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-celllayout-base/>

=head1 LICENSE

Copyright 2007, 2008, 2009, 2010 Kevin Ryde

Gtk2-Ex-CellLayout-Base is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Gtk2-Ex-CellLayout-Base is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-CellLayout-Base.  If not, see L<http://www.gnu.org/licenses/>.

=cut
