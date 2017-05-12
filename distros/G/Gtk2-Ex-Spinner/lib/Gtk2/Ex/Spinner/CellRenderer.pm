package Gtk2::Ex::Spinner::CellRenderer;
use 5.008;
use strict;
use warnings;
use Gtk2;

our $VERSION = 5.1;

use constant DEBUG => 0;

use Glib::Object::Subclass
  'Gtk2::CellRendererText';

# gtk_cell_renderer_start_editing()
#
# SUPER::START_EDITING of Gtk2::CellRendererText is no good for the
# Gtk2::Entry creation because it sets that widget to stop editing on losing
# keyboard focus, which includes the switch away to the
# Spinner::PopupEntry window, the effect being to immediately stop
# editing when that window pops up.
#
sub START_EDITING {
  my ($self, $event, $view, $pathstr, $back_rect, $cell_rect, $flags) = @_;
  if (DEBUG) { print "Renderer START_EDITING '$pathstr'\n";
               print "  back ",$back_rect->x,",",$back_rect->y,
                 " ",$back_rect->width,"x",$back_rect->width,
                   "  cell ",$cell_rect->x,",",$cell_rect->y,
                     " ",$cell_rect->width,"x",$cell_rect->width,"\n";
             }
  $self->{'pathstr'} = $pathstr;

  # no frame and copy 'xalign' across, the same as CellRendererText does
  require Gtk2::Ex::Spinner::EntryWithCancel;
  my $entry = Gtk2::Ex::Spinner::EntryWithCancel->new
    (has_frame => 0,
     xalign => $self->get('xalign'));
  if (DEBUG) { print "  edit with $entry\n"; }

  {
    # This is a hack for Gtk2-Perl 1.210 and earlier ensuring
    # gtk2perl_cell_renderer_start_editing() doesn't see $entry with a
    # refcount of 1, since it would increment that as a protection against
    # premature destruction -- but then never decrement.  If the refcount is
    # 2 it leaves it alone.
    Glib::Idle->add (sub { 0 }, # Glib::SOURCE_REMOVE
                     $entry);
  }

  require Gtk2::Ex::Spinner::PopupForEntry;
  Gtk2::Ex::Spinner::PopupForEntry->new (entry => $entry);

  my $value = $self->get('text');
  $entry->set_text (defined $value ? $value : '');
  $entry->select_region (0, -1);

  my $ref_weak_self = \$self;
  require Scalar::Util;
  Scalar::Util::weaken ($ref_weak_self);
  $entry->signal_connect (editing_done => \&_do_entry_editing_done,
                          $ref_weak_self);

  if (DEBUG) {
    $entry->signal_connect (destroy => sub {
                              print "editable: destroy\n";
                            });
    $entry->signal_connect (focus_out_event => sub {
                              print "editable: focus_out_event\n";
                              return 0; # Gtk2::EVENT_PROPAGATE
                            });
  }
  $entry->show;
  return $entry;
}

# 'editing-done' handler on the Gtk2::Ex::Spinner::EntryWithCancel
#
sub _do_entry_editing_done {
  my ($entry, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "Spinner::CellRenderer _do_entry_editing_done,",
                 " cancelled ",($entry->get('editing_cancelled')?"yes":"no"),
                   "\n"; }

  my $cancelled = $entry->get('editing_cancelled');
  $self->stop_editing ($cancelled);
  if (! $cancelled) {
    $self->signal_emit ('edited', $self->{'pathstr'}, $entry->get_text);
  }
}

1;
__END__

=head1 NAME

Gtk2::Ex::Spinner::CellRenderer -- integer cell renderer with Spinner for editing

=head1 SYNOPSIS

 use Gtk2::Ex::Spinner::CellRenderer;
 my $renderer = Gtk2::Ex::Spinner::CellRenderer->new;

 $treeviewcolumn->pack_start ($renderer, 0);
 $treeviewcolumn->add_attribute ($renderer, text => 0);
 $renderer->signal_connect (edited => sub { ... });

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::Spinner::CellRenderer> is a subclass of
C<Gtk2::CellRendererText>.

    Gtk2::Object
      Gtk2::CellRenderer
        Gtk2::CellRendererText
          Gtk2::Ex::Spinner::CellRenderer

=head1 DESCRIPTION

C<Gtk2::Ex::Spinner::CellRenderer> is based on a great L<Gtk2::Ex::DateSpinner::CellRenderer>, so
in most cases documentation is the same. License is (of course) the same too :-).

C<Spinner::CellRenderer> displays an integer as a
text field.  Editing the field presents both a C<Gtk2::Entry> and a popup
C<Gtk2::Ex::Spinner>.

    +------------+
    |         99 |
    +------------+
    +------------------------------+
    | +-----+     +----+ +------+  |
    | |  99 |^    | Ok | |Cancel|  |
    | +-----+v    +----+ +------+  |
    +------------------------------+

The popup allows mouse clicks or arrow keys to increment or decrement the
value.  This is good if you often just want to bump a value up or
down a bit.  

=head2 Details

The value to display, and edit, is taken from the renderer C<text> property
and must an integer.  A new edited value is passed to the
C<edited> signal emitted on the renderer in the usual way (see
L<Gtk2::CellRenderer>).  Text renderer properties affect the display.
C<xalign> is copied to the Entry widget to have it left, right or centred
while editing the same as displayed (like CellRendererText does).

Pressing Return in the fields accepts the values.  Pressing Escape cancels
the edit.  Likewise the Ok and Cancel button widgets.  The stock
accelerators activate the buttons too, Alt-O and Alt-C in an English locale,
though Return and Escape are much easier to remember.

Note you must set the C<editable> property (per the base
C<Gtk2::CellRendererText>) to make the DateSpinner::CellRenderer editable,
otherwise nothing happens when you click.  That property can be controlled
by the usual model column or data function mechanisms to have some rows
editable and others not.

=head1 FUNCTIONS

=over 4

=item C<< $renderer = Gtk2::Ex::Spinner::CellRenderer->new (key=>value,...) >>

Create and return a new Spinner::CellRenderer object.  Optional key/value
pairs set initial properties as per C<< Glib::Object->new >>.  Eg.

    my $renderer = Gtk2::Ex::Spinner::CellRenderer->new
                     (editable => 1);

=back

=head1 OTHER NOTES

As with the plain CellRendererText, Spinner::CellRenderer creates a new
editable widget for every edit, including a new popup window every time.
Both are destroyed when accepted or cancelled.  That's a little wasteful,
but it's usually fast enough for casual editing and it might save some
memory in between.

The code for the popup and entry is in the
C<Gtk2::Ex::Spinner::PopupForEntry> and
C<Gtk2::Ex::Spinner::EntryWithCancel> components.  They're not loaded
until the first edit.  They're only meant for internal use as yet.

=head1 SEE ALSO

L<Gtk2::Ex::DateSpinner>, L<Gtk2::CellRendererText>

Gtk2-Perl F<examples/cellrenderer_date.pl> does a similar display/edit
popping up a C<Gtk2::Calendar>.  See
L<Gtk2::Ex::Datasheet::DBI|Gtk2::Ex::Datasheet::DBI> for a version of it in
use.

=head1 LICENSE

Gtk2-Ex-Spinner is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-Spinner is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-Spinner.  If not, see L<http://www.gnu.org/licenses/>.

=cut
