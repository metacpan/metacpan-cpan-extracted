package Gnom2::Print::Config::Constants;

use strict;
require Exporter;

our @ISA = qw/Exporter/;

our @EXPORT = qw(
GNOME_PRINT_KEY_PAPER_SIZE
GNOME_PRINT_KEY_PAPER_WIDTH
GNOME_PRINT_KEY_PAPER_HEIGHT
GNOME_PRINT_KEY_PAPER_ORIENTATION
GNOME_PRINT_KEY_PAPER_ORIENTATION_MATRIX
GNOME_PRINT_KEY_PAGE_ORIENTATION
GNOME_PRINT_KEY_PAGE_ORIENTATION_MATRIX
GNOME_PRINT_KEY_ORIENTATION
GNOME_PRINT_KEY_LAYOUT
GNOME_PRINT_KEY_LAYOUT_WIDTH
GNOME_PRINT_KEY_LAYOUT_HEIGHT
GNOME_PRINT_KEY_RESOLUTION
GNOME_PRINT_KEY_RESOLUTION_DPI
GNOME_PRINT_KEY_RESOLUTION_DPI_X
GNOME_PRINT_KEY_RESOLUTION_DPI_Y
GNOME_PRINT_KEY_NUM_COPIES
GNOME_PRINT_KEY_COLLATE
GNOME_PRINT_KEY_PAGE_MARGIN_LEFT
GNOME_PRINT_KEY_PAGE_MARGIN_RIGHT
GNOME_PRINT_KEY_PAGE_MARGIN_TOP
GNOME_PRINT_KEY_PAGE_MARGIN_BOTTOM
GNOME_PRINT_KEY_PAPER_MARGIN_LEFT
GNOME_PRINT_KEY_PAPER_MARGIN_RIGHT
GNOME_PRINT_KEY_PAPER_MARGIN_TOP
GNOME_PRINT_KEY_PAPER_MARGIN_BOTTOM
GNOME_PRINT_KEY_OUTPUT_FILENAME
GNOME_PRINT_KEY_DOCUMENT_NAME
GNOME_PRINT_KEY_PREFERED_UNIT
);

use constant GNOME_PRINT_KEY_PAPER_SIZE => "Settings.Output.Media.PhysicalSize"
use constant GNOME_PRINT_KEY_PAPER_WIDTH => "Settings.Output.Media.PhysicalSize.Width"
use constant GNOME_PRINT_KEY_PAPER_HEIGHT => "Settings.Output.Media.PhysicalSize.Height"
use constant GNOME_PRINT_KEY_PAPER_ORIENTATION => "Settings.Output.Media.PhysicalOrientation"
use constant GNOME_PRINT_KEY_PAPER_ORIENTATION_MATRIX => "Settings.Output.Media.PhysicalOrientation.Paper2PrinterTransform"
use constant GNOME_PRINT_KEY_PAGE_ORIENTATION => "Settings.Document.Page.LogicalOrientation"
use constant GNOME_PRINT_KEY_PAGE_ORIENTATION_MATRIX => "Settings.Document.Page.LogicalOrientation.Page2LayoutTransform"
use constant GNOME_PRINT_KEY_ORIENTATION => "Settings.Document.Page.LogicalOrientation"
use constant GNOME_PRINT_KEY_LAYOUT => "Settings.Document.Page.Layout"
use constant GNOME_PRINT_KEY_LAYOUT_WIDTH => "Settings.Document.Page.Layout.Width"
use constant GNOME_PRINT_KEY_LAYOUT_HEIGHT => "Settings.Document.Page.Layout.Height"
use constant GNOME_PRINT_KEY_RESOLUTION => "Settings.Output.Resolution"
use constant GNOME_PRINT_KEY_RESOLUTION_DPI => "Settings.Output.Resolution.DPI"
use constant GNOME_PRINT_KEY_RESOLUTION_DPI_X => "Settings.Output.Resolution.DPI.X"
use constant GNOME_PRINT_KEY_RESOLUTION_DPI_Y => "Settings.Output.Resolution.DPI.Y"
use constant GNOME_PRINT_KEY_NUM_COPIES => "Settings.Output.Job.NumCopies"
use constant GNOME_PRINT_KEY_COLLATE => "Settings.Output.Job.Collate"
use constant GNOME_PRINT_KEY_PAGE_MARGIN_LEFT => "Settings.Document.Page.Margins.Left"
use constant GNOME_PRINT_KEY_PAGE_MARGIN_RIGHT => "Settings.Document.Page.Margins.Right"
use constant GNOME_PRINT_KEY_PAGE_MARGIN_TOP => "Settings.Document.Page.Margins.Top"
use constant GNOME_PRINT_KEY_PAGE_MARGIN_BOTTOM => "Settings.Document.Page.Margins.Bottom"
use constant GNOME_PRINT_KEY_PAPER_MARGIN_LEFT => "Settings.Output.Media.Margins.Left"
use constant GNOME_PRINT_KEY_PAPER_MARGIN_RIGHT => "Settings.Output.Media.Margins.Right"
use constant GNOME_PRINT_KEY_PAPER_MARGIN_TOP => "Settings.Output.Media.Margins.Top"
use constant GNOME_PRINT_KEY_PAPER_MARGIN_BOTTOM => "Settings.Output.Media.Margins.Bottom2"
use constant GNOME_PRINT_KEY_OUTPUT_FILENAME => "Settings.Transport.Backend.FileName"
use constant GNOME_PRINT_KEY_DOCUMENT_NAME => "Settings.Document.Name"
use constant GNOME_PRINT_KEY_PREFERED_UNIT => "Settings.Document.PreferedUnit"

1;

=head1 NAME

Gnome2::Print::Config::Constants - constants for use with Gnom2::Print::Config

=head1 SYNOPSIS

  use Gnome2::Print; # gets the actual Gnome2::Print::Config objects and methods

  use Gnome2::Print::Config::Constants; # load extra constants

=head1 DESCRIPTION

Similarily to Pango, in order to effectively use Gnome2::Print::Config you need
a few constants that are not supplied by the type system or by other means.

This module exports all of those extra constants when you load it.
They use the fully-prefixed names from the C documentation.

=head1 EXPORT

These are some default keys to be used with Gnome2::Print::Config set/get
methods:

  GNOME_PRINT_KEY_PAPER_SIZE
  GNOME_PRINT_KEY_PAPER_WIDTH
  GNOME_PRINT_KEY_PAPER_HEIGHT
  GNOME_PRINT_KEY_PAPER_ORIENTATION
  GNOME_PRINT_KEY_PAPER_ORIENTATION_MATRIX
  GNOME_PRINT_KEY_PAGE_ORIENTATION
  GNOME_PRINT_KEY_PAGE_ORIENTATION_MATRIX
  GNOME_PRINT_KEY_ORIENTATION
  GNOME_PRINT_KEY_LAYOUT
  GNOME_PRINT_KEY_LAYOUT_WIDTH
  GNOME_PRINT_KEY_LAYOUT_HEIGHT
  GNOME_PRINT_KEY_RESOLUTION
  GNOME_PRINT_KEY_RESOLUTION_DPI
  GNOME_PRINT_KEY_RESOLUTION_DPI_X
  GNOME_PRINT_KEY_RESOLUTION_DPI_Y
  GNOME_PRINT_KEY_NUM_COPIES
  GNOME_PRINT_KEY_COLLATE
  GNOME_PRINT_KEY_PAGE_MARGIN_LEFT
  GNOME_PRINT_KEY_PAGE_MARGIN_RIGHT
  GNOME_PRINT_KEY_PAGE_MARGIN_TOP
  GNOME_PRINT_KEY_PAGE_MARGIN_BOTTOM
  GNOME_PRINT_KEY_PAPER_MARGIN_LEFT
  GNOME_PRINT_KEY_PAPER_MARGIN_RIGHT
  GNOME_PRINT_KEY_PAPER_MARGIN_TOP
  GNOME_PRINT_KEY_PAPER_MARGIN_BOTTOM
  GNOME_PRINT_KEY_OUTPUT_FILENAME
  GNOME_PRINT_KEY_DOCUMENT_NAME
  GNOME_PRINT_KEY_PREFERED_UNIT
 
These keys are also available without importing this module, using
Gnome2::Print::Print-E<gt>I<key>, e.g.:

  Gnome2::Print::Config->key_output_filename;

=head1 BUGS

This module shouldn't exist, but some parts of the API just aren't clean.

This stuff is hardcoded directly from the headers of libgnomeprint 2.2.3

=head1 SEE ALSO

perl(1), Gtk2(3pm), Gnome2(3pm), Gnome2::Print(3pm).

=head1 AUTHOR

Emmanuele Bassi E<lt>emmanuele.bassi@iol.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Emmanuele Bassi

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the 
Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
Boston, MA  02111-1307  USA.

=cut
