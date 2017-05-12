package Excel::Template::Element::MergeRange;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(Excel::Template::Element::Cell);

    use Excel::Template::Element::Cell;
    use Excel::Template::Element::Range;
}

sub render {
    my $self = shift;
    my ($context) = @_;

    my $ref_name = $context->resolve($self, 'REF');

    my @refs = $context->get_all_references( $ref_name );
    (@refs)
        || die "You must specify a ref for MERGE_RANGE";

    my $range = Excel::Template::Element::Range->_join_refs(@refs);

    # NOTE:
    # we need to copy the current format
    # because Spreadsheet::WriteExcel will 
    # mark any format used in a merged cell
    # as being specifically for a merged cell
    # and therefore not usable elsewhere.

    my $old_format = $context->active_format;

    my %values;
    while ( my ($k, $v) = each %$self ) {
        $values{$k} = $context->resolve( $self, $k );
    }

    # force is_merged on here to differentiate the formats
    $values{is_merged} = 1;

    my $format = $context->format_object->copy(
        $context, $old_format, %values,
    );
    $context->active_format($format);

    $context->active_worksheet->merge_range(
        $range,
        $self->_get_text($context),
        $format,
    );

    $context->active_format($old_format);

    return 1;
}

1;
__END__

=head1 NAME

Excel::Template::Element::MergeRange - Excel::Template::Element::MergeRange

=head1 PURPOSE

To merge a range of cells in a spreadsheet

=head1 NODE NAME

MERGE_RANGE

=head1 INHERITANCE

L<ELEMENT|Excel::Template::Element>

=head1 EFFECTS

This will merge a range of cells.

=head1 DEPENDENCIES

None

=head1 USAGE

  <cell ref="foo"/>
  <cell ref="foo"/>
  <cell ref="foo"/>
  <merge_range ref="foo">Text to insert into merged range</merge_range>

Or a cross rows:

  <row>
    <cell ref="foo"/>
    <cell ref="foo"/>
    <cell ref="foo"/>
  </row>
  <row>
    <cell ref="foo"/>
    <cell ref="foo"/>
    <cell ref="foo"/>
    <format>
      <merge_range ref="foo">Text to insert into merged range</merge_range>
    </format>
  </row>


=head1 AUTHOR

Stevan Little (stevan.little@iinteractive.com)

=head1 SEE ALSO

Nothing

=cut
