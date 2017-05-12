package HTML::FormatNroff::Table::Row;

use strict;
use warnings;
use Carp;

sub new {
    my ( $class, %attr ) = @_;

    my $self = bless {
        align  => $attr{'align'}  || 'left',
        valign => $attr{'valign'} || 'middle',
        current_cell => undef,
        ended        => 1,
        cells        => [],
    }, $class;

    return $self;
}

sub add_element {
    my ( $self, %attr ) = @_;

    croak "Should be subclassed.\n";
}

sub end_element {
    my ($self) = @_;

    croak "Should be subclassed.\n";
}

sub add_text {
    my ( $self, $text ) = @_;

    if ( $self->{'ended'} != 0 ) {
        return;
    }

    my $cell = $self->{'current_cell'};
    if ( defined($cell) ) {
        $cell->add_text($text);
    }
    else {
        return 0;
    }
}

sub text {
    my ($self) = @_;

    my $cell = $self->{'current_cell'};
    if ( defined($cell) ) {
        return $cell->text();
    }
    else {
        return 0;
    }
}

sub widths {
    my ( $self, $final, $array_ref ) = @_;

    my @widths;
    my $cell;
    foreach $cell ( @{ $self->{'cells'} } ) {
        push( @widths, $cell->width() );
    }

    $cell = $self->{'current_cell'};
    if ( defined($cell) ) {
        push( @widths, $cell->width() );
    }

    push( @$array_ref, [@widths] );
}

sub output {
    my ( $self, $final, $formatter, $tab ) = @_;

    my $cell;
    foreach $cell ( @{ $self->{'cells'} } ) {
        $cell->output($formatter);
        $formatter->out("$tab");
    }

    if ( defined( $self->{'current_cell'} ) ) {
        $self->{'current_cell'}->output($formatter);
    }
    $formatter->out("\n.sp\n");
}

1;

__END__

=pod

=head1 NAME

HTML::FormatNRoff::Table::Row - Format HTML Table row

=head1 SYNOPSIS

    use HTML::FormatNRoff::Table::Row;
    use parent 'HTML::FormatNRoff::Table::Row';

=head1 DESCRIPTION

The HTML::FormatNRoff::Table::Row is used to record information and process a
table row. This is a base class.

=head1 METHODS

=head2 new

    my $table_row = new HTML::FormatNRoff::Table::Row(%attr);

The following attributes are supported:

=over

=item align

'left','center', or 'right' alignment of table row entries

=item valign

vertical alignment, 'top' or 'middle'

=back

=head2 add_element(%attr);

Add table element - should be subclassed.

=head2 end_element();

End table element - should be subclassed.

=head2 add_text($text);

Add text to cell.

=head2 text();

Return text associated with current table cell.

=head2 widths($final, $array_ref);

push the array of cell widths (in characters)
onto the array specified using the array reference $array_ref.

=head2 output($final, $formatter, $tab);

Output the row data using the $formatter to do the output,
and separating each cell using the $tab character. $final is not used.

=head1 SEE ALSO

L<HTML::FormatNroff::Table>

=head1 COPYRIGHT

Copyright (c) 1997 Frederick Hirsch. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Frederick Hirsch <f.hirsch@opengroup.org>

=cut



