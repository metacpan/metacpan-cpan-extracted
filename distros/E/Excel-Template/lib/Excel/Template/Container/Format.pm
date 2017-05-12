package Excel::Template::Container::Format;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw( Excel::Template::Container );

    use Excel::Template::Container;
}

use Excel::Template::Format;

sub render
{
    my $self = shift;
    my ($context) = @_;

    my $old_format = $context->active_format;

    my %values;
    while ( my ($k, $v) = each %$self ) {
        $values{$k} = $context->resolve( $self, $k );
    }

    my $format = $context->format_object->copy(
        $context, $old_format, %values,
    );
    $context->active_format($format);

    my $child_success = $self->iterate_over_children($context);

    $context->active_format($old_format);

    return $child_success;
}

1;
__END__

=head1 NAME

Excel::Template::Container::Format - Excel::Template::Container::Format

=head1 PURPOSE

To format all children according to the parameters

=head1 NODE NAME

FORMAT

=head1 INHERITANCE

Excel::Template::Container

=head1 ATTRIBUTES

Boolean attributes should be set to 1, 0, true, or false.

Color values can be the color name or the color index. See L<Spreadsheet::WriteExcel/"COLOURS IN EXCEL">

=over 4

=item * align

Set to either left, center, right, fill, or justify. Default is left.  See also valign.

=item * bg_color

Set to a color value. Default is none.

=item * bold

This will set bold to on or off, depending on the boolean value.

=item * border

Set the border for all for edges of a cell. Also see bottom, top, left, and right.
Valid values are 0 - 7. 

See L<Spreadsheet::WriteExcel/"set_border()">

=item * border_color

Sets the color value for the border. See also border, top_color, bottom_color, left_color
and right_color.

=item * bottom

See border.

=item * bottom_color

See border_color

=item * color

This will set the color of the text, depending on color value. Default is black.

=item * fg_color

Set to a color value. This color will be used in foreground of some patterns. See color
to change the color of text. Also see bg_color and pattern.

=item * font

This will sent the font face. Default is Arial.

=item * font_outline

This will set font_outline to on or off, depending on the boolean value. (q.v.
OUTLINE tag)

=item * font_shadow

This will set font_shadow to on or off, depending on the boolean value. (q.v.
SHADOW tag). This only applies to Excel for Macintosh.

=item * font_strikeout

This will set font_strikeout to on or off, depending on the boolean value. (q.v.
STRIKEOUT tag)

=item * hidden

This will set whether the cell is hidden to on or off, depending on the boolean
value.

=item * indent

Set the indentation level for a cell. Positive integers are allowed.

=item * italic

This will set italic to on or off, depending on the boolean value. (q.v. ITALIC
tag)

=item * left

See border.

=item * left_color

See border_color.

=item * num_format

Set to the index of one of Excel's built-in number formats. See L<Spreadsheet::WriteExcel/"set_num_format()"> 

=item * pattern

Set to an integer, 0 - 18. Sets the background fill pattern of a ell. Default is 1, solid.

=item * right

See border.

=item * right_color

See border color.

=item * rotation

Set the rotation of the text in a cell. The rotation can be any angle in the range -90 to 90 degrees. 
The angle 270 is also supported. This indicates text where the letters run from top to bottom.

=item * shrink

A boolean value. If true, text will shrink to fit a cell.

=item * size

This will set the size of the font. Default is 10. Unless a row height is 
specifically set, the row will grow taller as necessary.

=item * text_justlast

A boolean value to justify the last line. Only applies to Far Eastern versions of Excel.

=item * text_wrap

A boolean value. When set to true, text will wrap in a cell instead of crossing over
into empty cells. If the row height is not set, the row will grow taller to accommodate
the wrapping text.

=item * top

See border.

=item * top_color

See border_color

=item * valign

Set to top, vcenter, bottom, or vjustify. Default is vcenter. See also align.

=back

=head1 CHILDREN

None

=head1 EFFECTS

None

=head1 DEPENDENCIES

None

=head1 USAGE

  <format bold="1">
    ... Children here
  </format>

In the above example, the children will be displayed (if they are displaying
elements) in a bold format. All other formatting will remain the same and the
"bold"-ness will end at the end tag.

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

BOLD, HIDDEN, ITALIC, OUTLINE, SHADOW, STRIKEOUT

=cut
