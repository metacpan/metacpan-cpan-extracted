package Excel::Template::Element::Cell;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(Excel::Template::Element);

    use Excel::Template::Element;
}

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{TXTOBJ} = Excel::Template::Factory->_create('TEXTOBJECT');

    return $self;
}

sub _get_text
{
    my $self = shift;
    my ($context) = @_;

    my $txt = $context->get($self, 'TEXT');
    if (defined $txt)
    {
        my $txt_obj = Excel::Template::Factory->_create('TEXTOBJECT');
        push @{$txt_obj->{STACK}}, $txt;
        $txt = $txt_obj->resolve($context);
    }
    else
    {
        $txt = $self->{TXTOBJ}->resolve($context)
    }

    return $txt;
}

my %legal_types = (
    'blank'     => 'write_blank',
    'formula'   => 'write_formula',
    'number'    => 'write_number',
    'string'    => 'write_string',
    'url'       => 'write_url',
    'date_time' => 'write_date_time',
);

sub render
{
    my $self = shift;
    my ($context, $method) = @_;

    unless ( $method )
    {
        my $type = $context->get( $self, 'TYPE' );
        if ( defined $type )
        {
            my $type = lc $type;

            if ( exists $legal_types{ $type } )
            {
                $method = $legal_types{ $type };
            }
            else
            {
                warn "'$type' is not a legal cell type.\n"
                    if $^W;
            }
        }
    }

    $method ||= 'write';

    my ($row, $col) = map { $context->get($self, $_) } qw(ROW COL);

    my $ref = $context->get( $self, 'REF' );
    if (defined $ref && length $ref)
    {
        $context->add_reference( uc( $ref ), $row, $col );
    }

    # Apply the cell width to the current column
    if (my $width = $context->get($self, 'WIDTH'))
    {
        $width =~ s/[^\d.]//g;
        $width *= 1;
        if ($width > 0)
        {
            $context->active_worksheet->set_column($col, $col, $width);
        }
    }

    $context->active_worksheet->$method(
        $row, $col,
        $self->_get_text($context),
        $context->active_format,
    );

    my $comment = $context->get($self, 'COMMENT');
    if (defined $comment && length $comment){
         $context->active_worksheet->write_comment($row, $col,$comment);
    }

    return 1;
}

sub deltas
{
    return {
        COL => +1,
    };
}

1;
__END__

=head1 NAME

Excel::Template::Element::Cell - Excel::Template::Element::Cell

=head1 PURPOSE

To actually write stuff to the worksheet

=head1 NODE NAME

CELL

=head1 INHERITANCE

L<ELEMENT|Excel::Template::Element>

=head1 ATTRIBUTES

=over 4

=item * TEXT

This is the text to write to the cell. This can either be text or a parameter with a dollar-sign in front of the parameter name.

=item * COL

Optionally, you can specify which column you want this cell to be in. It can be either a number (zero-based) or an offset. See L<Excel::Template> for more info on offset-based numbering.

=item * REF

Adds the current cell to the a list of cells that can be backreferenced.  This is useful when the current cell needs to be referenced by a formula. See L<BACKREF|Excel::Tepmlate::Element::Backref> and L<RANGE|Excel::Tepmlate::Container::Range>.

=item * WIDTH

Sets the width of the column the cell is in. The last setting for a given column
will win out.

=item * TYPE

This allows you to specify what write_*() method will be used. The default is to call write() and let L<Spreadsheet::WriteExcel> make the right call. However, you may wish to override it. L<Excel::Template> will not do any form of validation on what you provide. You are assumed to know what you're doing.

The legal types (taken from L<Spreadsheet::WriteExcel>) are:

=item * COMMENT

Add a comment to the cell

=over 4

=item * blank

=item * formula

=item * number

=item * string

=item * url

=item * date_time

=back

other write_* methods as defined defined L<Spreadsheet::WriteExcel> would be integrated by request

=back

=head1 CHILDREN

L<FORMULA|Excel::Template::Element::Formula>

=head1 EFFECTS

This will consume one column in the current row.

=head1 DEPENDENCIES

None

=head1 USAGE

  <cell text="Some Text Here"/>
  <cell>Some other text here</cell>

  <cell text="$Param2"/>
  <cell>Some <var name="Param"> text here</cell>

In the above example, four cells are written out. The first two have text hard-coded. The second two have variables. The third and fourth items have another thing that should be noted. If you have text where you want a variable in the middle, you have to use the latter form. Variables within parameters are the entire parameter's value.

Please see L<Spreadsheet::WriteExcel> for what constitutes a legal formula.

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

L<ROW|Excel::Template::Container::Row>, L<VAR|Excel::Template::Element::Var>, L<FORMULA|Excel::Template::Element::Formula>

=cut
