package Gtk2::Ex::FormFactory::Table;

use strict;

use base qw( Gtk2::Ex::FormFactory::Container );

sub get_type { "table" }

sub get_layout			{ shift->{layout}			}
sub get_widget_table_attach	{ shift->{widget_table_attach}		}
sub get_widget_table_align	{ shift->{widget_table_align}		}
sub get_rows			{ shift->{rows}				}
sub get_columns			{ shift->{columns}			}

sub set_layout			{ shift->{layout}		= $_[1]	}
sub set_widget_table_attach	{ shift->{widget_table_attach}	= $_[1]	}
sub set_widget_table_align	{ shift->{widget_table_align}	= $_[1]	}
sub set_rows			{ shift->{rows}			= $_[1]	}
sub set_columns			{ shift->{columns}		= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my ($layout) = $par{'layout'};

	my $self = $class->SUPER::new(@_);
	
	$layout =~ s/^\s+//m;
	$layout =~ s/\s+$//m;
	$layout .= "\n";

	warn "Layout of table ".$self->get_name." contains tab characters"
		if $layout =~ /\t/;

	$self->set_layout($layout);

	$self->calculate_layout;
	
	return $self;
}

=cut

Table example (helps understanding the code beyond):

                This Column
                expands

+--------------+>>>>>>>>>>>>+
| 1            | 2          |
+--------------+            |
| 3            |            |
+-------+------+------------+      -
> 4     | 5    | 6          |      |
>       |      +------------+      |
>       |      | 7          |      |
+-------+------+------------+      |  All rows in this span
> 8     |      | 9          |      |  expand as well
>       |      +------------+      |
>       |      | 10         |      |
>       +------+------------+      |
>       | 11                |      |
+-------+-------------------+      -

* empty fields get no Widget (what's
  inside the field, doesn't matter)

* non-empty fields get the Widgets in
  the order showed above, counting
  from left-top to right-bottom

=cut

sub calculate_layout {
	my $self = shift;
	
	#-- Get layout of this table
	my $layout      = $self->get_layout;
	my @layout_rows = map { s/^\s*//; $_ } split (/\n/, $layout);

	#-- First we calculate the raster which forms the
	#-- basis of this table. %raster_x and %raster_y
	#-- will contain all indicies, where a column
	#-- border was detected.
	my (%raster_x, %raster_y);
	my $y = 0;
	foreach my $row ( @layout_rows ) {
		#-- Detect X coordinates
		if ( $row =~ /[|^_'~]/ ) {
			my $x = 0;
			foreach my $field ( split(/[|^_']/, $row) ) {
				$x+=length($field);
				$raster_x{$x} = 1;
				++$x;
			}
		}
		#-- Detect Y coordinates
		if ( $y == 0 || $row =~ /[-=]/ ) {
			$raster_y{$y} = 1;
		}
		#-- Count next row
		++$y;
	}

	#-- Store the number of rows the layout string has
	my $layout_rows = $y;
	
	#-- Sorted list of row/column indices
	my @raster_x = sort { $a <=> $b } keys %raster_x;
	my @raster_y = sort { $a <=> $b } keys %raster_y;

	if ( $Gtk2::Ex::FormFactory::DEBUG ) {
		require Data::Dumper;
		print "raster_x: ", Data::Dumper::Dumper(\@raster_x);
		print "raster_y: ", Data::Dumper::Dumper(\@raster_y);
	}

	#-- Now walk through all lines and build the table
	#-- attach information for each non-empty field
	my @widget_table_attach;
	my @widgets_table_align;
	$y = 0;

	foreach my $row_i ( @layout_rows ) {
		#-- $row is modified beyond
		my $row = $row_i;

		#-- Skip lines which have no | or ' or ^ or _
		#-- (such lines just separate rows from each other
		#--  and are of no interest here)
		if ( $row !~ /[|^_']/ ) {
			++$y;
			next;
		}

		$Gtk2::Ex::FormFactory::DEBUG &&
			print "=============================\n";
		$Gtk2::Ex::FormFactory::DEBUG &&
			print "[$y] analyze row: '$row'\n";

		#-- Track left/right indices and attach
		#-- column numbers
		my $right_x      = 0;
		my $right_attach = 0;
		my $left_x       = 0;
		my $left_attach  = 0;

		#-- Remove the first | character, because we
		#-- split at | borders (otherwise we would
		#-- get an empty field at the first position)
		$row =~ s/^(.)//;

		#-- And remember it, since it may be a special
		#-- character (^ _ ') defining a vertical property.
		my $row_first_char = $1;

		#-- split row into fields. All vertical special
		#-- characters mark borders, plus + and |.
		foreach my $field ( split(/[|+'_^~]/, $row) ) {
			$Gtk2::Ex::FormFactory::DEBUG &&
				print "[$y,$left_x] field='$field'\n";

			#-- Calculate right index of this field
			$right_x = $left_x + length($field)+1;

			#-- Calculate the cell span of this field using
			#-- the @raster_x array calculated above.
			my $span_x = 0;
			foreach my $x ( @raster_x ) {
				++$span_x if $x >= $left_x &&
				             $x < $right_x;
				last if $x > $right_x;
			}

			#-- With the cell span we know the right attach
			$right_attach = $left_attach + $span_x;

			#-- Now we know all X values, more work needs to
			#-- be done for the Y part

			#-- Process this field only if it doesn't
			#-- span over several rows, because then
			#-- it was processed already in a previous
			#-- iteration)
			if ( $y > 0 && substr($layout_rows[$y-1], $left_x+1, 1 ) =~ /[-=>%\[\]]/ ) {
				#-- Seek for the bottom of that field and calculate
				#-- top and bottom attachment
				my $top_attach = 0;
				my $bot_attach = 0;

				#-- Skip first line, which defines no columns
				my $y_seek;
				for ( $y_seek = 1; $y_seek < $layout_rows; ++$y_seek ) {
					$Gtk2::Ex::FormFactory::DEBUG &&
						print "top_attach: y=$y y_seek=$y_seek ".
						      "raster_y=$raster_y{$y_seek}\n";
					if ( $y_seek < $y and $raster_y{$y_seek} ) {
						#-- If we are above the current y position and
						#-- hit a y raster point, increment top_
						#-- and bot_attach
						++$top_attach;
						++$bot_attach;

					} elsif ( $raster_y{$y_seek} ) {
						#-- If we're beyond the current y position,
						#-- increase bot_attach if we hit a raster point
						++$bot_attach;
					}

					$Gtk2::Ex::FormFactory::DEBUG &&
						print "=> top_attach=$top_attach ".
						      "bot_attach=$bot_attach\n".
						      "   '".
						      substr($layout_rows[$y_seek],
						              $left_x+1, 1)."'\n";

					#-- Out here if we hit the end of the field
					last if  $y_seek >= $y and
					         substr($layout_rows[$y_seek],
							$left_x+1, 1) =~ /[-+=\[\]\%]/;

					$field .= "\n".substr($layout_rows[$y_seek], 
							      $left_x+1, $right_x-$left_x-1)
						  if $y_seek > $y;
				}

				#-- Push all attach values into the list,
				#-- but only if the field is not empty
				if ( $field =~ /\S/ ) {
					my $hexpand = $self->get_xexpansion(\@layout_rows, $left_x+1, $y, $right_x);
					my $vexpand = $self->get_yexpansion(\@layout_rows, $left_x, $y, $y_seek-1),
					my $xalign = $self->get_xalign(\@layout_rows, $left_x+1, $y, $right_x);
					my $yalign = $self->get_yalign(\@layout_rows, $left_x, $y, $y_seek-1);

					push @widget_table_attach, [
					    #-- Attachments
					    $left_attach,
					    $right_attach,
					    $top_attach,
					    $bot_attach,
					    $hexpand,
					    $vexpand,
					];

					push @widgets_table_align, {
					    xalign => $xalign,
					    yalign => $yalign,
					};

					if ( $Gtk2::Ex::FormFactory::DEBUG && $field =~ /\S/ ) {
						$hexpand = join("|",@{$hexpand});
						$vexpand = join("|",@{$vexpand});
						print "--------------------------\n";
						print "y:            $y\n";
						print "x:            ".($left_x+1),"\n";
						print "left_attach:  $left_attach\n";
						print "right_attach: $right_attach\n";
						print "top_attach:   $top_attach\n";
						print "bot_attach:   $bot_attach\n";
						print "field:        '$field'\n";
						print "hexpand:      $hexpand\n";
						print "vexpand:      $vexpand\n";
						print "xalign:       $xalign\n";
						print "yalign:       $yalign\n";
					}
				}
			}

			#-- Initialize left index/attach values
			#-- for the next field
			$left_x      = $right_x;
			$left_attach = $right_attach;
		}

		#-- Count Y coordinate
		++$y;
	}
	
	#-- Store results in the object
	$self->set_rows(scalar(@raster_y)-1);
	$self->set_columns(scalar(@raster_x-1));
	$self->set_widget_table_attach(\@widget_table_attach);
	$self->set_widget_table_align(\@widgets_table_align);

	$Gtk2::Ex::FormFactory::DEBUG &&
		print Data::Dumper::Dumper(\@widget_table_attach);

	1;
}

sub get_xexpansion {
	my $self = shift;
	my ($layout_rows, $x, $y, $max_x) = @_;

	my $row = $layout_rows->[$y-1];
	my $c;
	while ( $x <= $max_x ) {
		$c = substr($row, $x, 1);
		return ["fill","expand"] if $c =~ /[>^]/;
		++$x;
	}

	return ["fill"];
}

sub get_yexpansion {
	my $self = shift;
	my ($layout_rows, $x, $y, $max_y) = @_;

	my $c;
	while ( $y <= $max_y ) {
		$c = substr($layout_rows->[$y], $x, 1);
		return ["fill","expand"] if $c =~ /[>^]/;
		++$y;
	}

	return ["fill"];
}

sub get_xalign {
	my $self = shift;
	my ($layout_rows, $x, $y, $max_x) = @_;
	
	my $row = $layout_rows->[$y-1];
	my $c;
	while ( $x <= $max_x ) {
		$c = substr($row, $x, 1);
		return 0   if $c eq '[';
		return 1   if $c eq ']';
		return 0.5 if $c eq '%';
		++$x;
	}

	return -1;
}

sub get_yalign {
	my $self = shift;
	my ($layout_rows, $x, $y, $max_y) = @_;

	my $c;
	while ( $y <= $max_y ) {
		$c = substr($layout_rows->[$y], $x, 1);
		return 0   if $c eq "'";
		return 1   if $c eq '_';
		return 0.5 if $c eq '~';
		++$y;
	}

	return -1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::Table - Complex table layouts made easy

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::Table->new (
    layout => "+-------%------+>>>>>>>>>>>>>>>+
	       |     Name     |	    	      |
	       +--------------~ Image 	      |
	       | Keywords     | 	      |
	       +-------+------+[--------------+
	       ^       ' More | Something     |
	       ^       |      +-----+--------]+
	       _ Notes |      |     |     Foo |
	       +-------+------+-----+---------+
	       ^ Bar	      | Baz	      |
	       +--------------+---------------+",
    content => [
      Gtk2::Ex::FormFactory::Entry->new ( ... ),
      Gtk2::Ex::FormFactory::Image->new ( ... ),
      Gtk2::Ex::FormFactory::Entry->new ( ... ),
      ...
    ],
    ...
    Gtk2::Ex::FormFactory::Container attributes
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This module implements a simple way of defining complex table layouts
inside a Gtk2::Ex::FormFactory environment.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::Container
       +--- Gtk2::Ex::FormFactory::Table

  Gtk2::Ex::FormFactory::Layout
  Gtk2::Ex::FormFactory::Rules
  Gtk2::Ex::FormFactory::Context
  Gtk2::Ex::FormFactory::Proxy

=head1 LAYOUT DEFINITION

Take a look at the example in the SYNPOSIS. You see, you simply draw
the layout of your table. But how does this work exactly?

Each table is based on a straight two dimensional grid, no matter how
complicated the cells span over one or more rows or columns. You see
the grid when you extend all lines (horizontal and vertical) up to
the borders of the table. The following graphic shows the grid by
marking the imaginary lines with · characters:

  +-------+------+>>>>>+>>>>>+
  | Name  ·	 | Img ·     |
  +-------+------+·····+·····|
  | Keyw  ·	 |     ·     |
  +-------+------+-----+-----+
  ^ Notes | More | Som ·     |
  ^·······|····· +-----+-----+
  ^	  |	 |     | Foo |
  +-------+------+-----+-----+
  ^ Bar   ·	 | Baz ·     |
  +-------+------+-----+-----+

All cells of the table are attached to this grid.

Gtk2::Ex::FormFactory::Table distinguishes empty and non empty cells.
If only whitespace is inside the cell, it's empty, otherwise it has a
widget inside. Since Gtk2::Ex::FormFactory::Table is a 
L<Gtk2::Ex::FormFactory::Container> it has a simple list of widgets
as children.

So how are these widgets assigned to the cells of the table?

Short answer: from left/top to the right/bottom.
Gtk2::Ex::FormFactory::Table scans your layout drawing in this
direction and once it sees a new cell, it's counted as the next child
of the table.

Our example has this child order:

  +--------------+>>>>>>>>>>>+
  | 1		 | 2	     |
  +--------------+	     |
  | 3		 |	     |
  +-------+------+-----------+
  ^ 4	  | 5	 | 6	     |
  ^	  |	 +-----+>>>>>+
  ^	  |	 |     | 7   |
  +-------+------+-----+-----+
  ^ 8		 | 9	     |
  +--------------+-----------+

So the B<content> attribute of this table must list exactly nine
widgets, otherwise you would get a runtime exception, when it comes
to building the table.

Ok, now it's clear how the table cells are attached to the grid of
the table. But what about the size of the cells resp. their widgets
and the alignment of widgets inside their cells?

This answer is about funny characters ;)

=head2 Cell / Widget expansion

By default all cells and their widgets doesn't expand if the table
expands. But you recognized the E<gt> and ^ characters? They say, that
the cell and its widget should both resize with the table, by allocating
all space available (> for horizontal expansion and ^ for vertical).
If you want to resize just the cell, but not its widget, refer to
the next chapter about widget alignments.

In our example cell 2, 7 and 9 resize horizontal with the table,
cell 4, 5, 6, 7, 8 and 9 vertical. Cell 1 and 3 don't resize at all,
they fill the cell but stay at the cell's size, no matter how the table
resizes.

=head2 Widget alignment

By default widgets fill their cell completely. If the cell expands the
widgets expands as well. But you may want to align the widget on the
left or right side, or in the middle, resp. at the top and the bottom.
Once you define an alignment, the widget doesn't fill the cell anymore.
Again there are some funny characters defining the alignment.

For horizontal alignments the characters must be used in the B<top>
border of the cell. For vertical alignment it needs to be the B<left>
border of the cell.

Horinzontal alignment is controlled with these
characters: [ left, ] right and % middle. 

Vertical alignment is controlled with these
characters: ' top, _ bottom and ~ middle. 

In the SYNPOSIS example "Image" is attached in the middle (vertical),
"Notes" at the bottom and "More" at the top. "Something" is attached
left, "Foo" right and "Name" centered (horizontal).

=head2 Complete list of special characters

This is the complete list of recognized characters and their meaning:

=over 10

=item - | + =

The widget fills the cell, but the cell doesn't resize with the
table. That's the default, because these characters belong to the set
of ASCII graphic characters used to draw the layout.

=item >

The cell expands horizontal. Recognized only in the top
border of a cell.

=item ^

The cell expands vertical. Recognized only in the left
border of a cell.

=item [

Widget is attached on the left and doesn't expand anymore
with the cell. Recognized only in the top border of a cell.

=item ]

Widget is attached on the right and doesn't expand anymore
with the cell.  Recognized only in the top border of a cell.

=item %

Widget is attached in the middle (horizontal) and doesn't
expand anymore with the cell. Recognized only in the top border of a cell.

=item '

Widget is attached on the top and doesn't expand anymore
with the cell. Recognized only in the left border of a cell.

=item _

Widget is attached on the bottom and doesn't expand anymore
with the cell. Recognized only in the left border of a cell.

=item ~

Widget is attached in the middle (vertical) and doesn't expand
anymore with the cell. Recognized only in the left border
of a cell.

=back

=head2 Notes

Some additional notes about the layout definition string.

=over 4

=item B<Drawing characters>

Although this should be obvious ;)

In your drawing | characters (pipe symbol) mark column borders,
and - or = (dash or equal sign) characters mark row borders. The +
(plus) characters have no special meaning. They're just for candy.

For completeness: additionally the ^ _ and ' characters mark horizontal
cell borders, since these are special characters controling the
vertical alignment of a cell and are placed on the vertical borders
of cells.

You need at least one - or = character in the top vertical border
of each row, otherwise the vertical raster of your table can't be
recognized correctly. This should be no problem in practice at all.

=item B<TAB characters>

Don't use TAB characters but true SPACE characters inside the table.
You get a warning on TAB characters.

=item B<Whitespace around the table>

You may have arbitrary whitespace around your table, inlcuding TAB
characters. It's cut off before the layout string is parsed.

=back

=head1 ATTRIBUTES

Attributes are handled through the common get_ATTR(), set_ATTR()
style accessors, but they are mostly passed once to the object
constructor and must not be altered after the associated FormFactory
was built.

=over 4

=item B<layout> = SCALAR

This is a string which defines the layout of this table using some
sort of line art ASCII graphics. Refer to the LAYOUT DEFINITION chapter for
details about the format.

=back

For more attributes refer to Gtk2::Ex::FormFactory::Container.

=head1 AUTHORS

 Jörn Reder <joern at zyn dot de>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2006 by Jörn Reder.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Library General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307
USA.

=cut
