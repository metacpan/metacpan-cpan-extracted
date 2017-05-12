package Excel::Template::Element::Cell::AutoSize;
$VERSION = '0.04';
use strict;

BEGIN {
    use Excel::Template::Element::Cell;
    use Font::TTFMetrics;
    use vars qw(@ISA);

    @ISA = qw(Excel::Template::Element::Cell);

    Excel::Template::Factory::register(name => 'CELLAUTOSIZE', class => 'Excel::Template::Element::Cell::AutoSize', isa => 'CELL');
}

sub render
{
    my $self = shift;
    my ($context) = @_;

	my $font_path = $ENV{'FONT_PATH'} || die "Environment variable FONT_PATH not set\n";
	my $font_name = lc($context->active_format->{'_font'});
	$font_name .= 'bd' if $context->active_format->{'_bold'} == 700;
	my $font_size = $context->active_format->{'_size'};

	my $font_found = 0;
	foreach my $path (split(':', $font_path)){
		$font_found = 1 if -e "$path/$font_name.ttf";
		$font_path = $path if $font_found;
		last if $font_found;
	}
		
	my $font = Font::TTFMetrics->new("$font_path/$font_name.ttf") || die "Font $font_name not found\n";

	my $dpi          = 96;
	my $units_per_em = $font->get_units_per_em();
	my $text = $self->get_text($context) || ' ';
	my $font_width   = $font->string_width($text);

    	#The following expression is from the TTFMetrics docs.
	my $pixel_width  = $font_width *$font_size *$dpi /(72 *$units_per_em);

    	#The following expression is from the Spreadsheet::WriteExcel internals.
	my $cell_width   = (($pixel_width -5) /7) + 1; # For cell widths > 1

	#Set larger column width if $cell_text_length is greater than current max for column
	my $max_width_key = '_COL_WIDTH_' . $context->get($self, 'COL');
	#Initialize current max column width if this is our first access of this column
	$context->active_worksheet->{$max_width_key} = $context->active_worksheet->{$max_width_key} || 0;
	
	#print $font_name . "," . $context->active_format->{'_bold'} . "\n";
	if ($cell_width > $context->active_worksheet->{$max_width_key}){
		$context->active_worksheet->{$max_width_key} = $cell_width;
		$context->active_worksheet->set_column($context->get($self, 'COL'), $context->get($self, 'COL'), $cell_width);
   	}
	$context->active_worksheet->write(
        (map { $context->get($self, $_) } qw(ROW COL)),
        $self->get_text($context),
        $context->active_format,
    );

    return 1;
}

1;
__END__

=head1 NAME

Excel::Template::Element::Cell::AutoSize

=head1 PURPOSE

To provide a cell that is correctly sized for inserted text

=head1 NODE NAME

CELLAUTOSIZE

=head1 INHERITANCE

Excel::Template::Element::Cell

=head1 CHILDREN

Excel::Template::Element::Formula

=head1 EFFECTS

This will consume one column on the current row. 

=head1 DEPENDENCIES

Font::TTFMetrics

=head1 USAGE

  <cellautosize text="Some Text Here"/>
  <cellautosize>Some other text here</cellautosize>

  <cellautosize text="$Param2"/>
  <cellautosize>Some <var name="Param"> text here</cellautosize>

In the above example, four cells are written out. The first two have text hard-
coded. The second two have variables. The third and fourth items have another
thing that should be noted. If you have text where you want a variable in the
middle, you have to use the latter form. Variables within parameters are the
entire parameter's value.

Please see Spreadsheet::WriteExcel for what constitutes a legal formula.

=head1 AUTHOR

Tim Howell (tim@fefcful.org)
Based on Excel::Template::Element::Cell by Rob Kinyon

=head1 SEE ALSO

CELL, ROW, VAR, FORMULA

=cut
