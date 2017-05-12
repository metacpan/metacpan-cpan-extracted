package HTML::FormatNroff::Table::Cell;

use 5.004;
use strict;
use warnings;
use Carp;

sub new {
    my ( $class, %attr ) = @_;

    my $self = bless {
        header   => $attr{'header'}   || '',
        nowrap   => $attr{'nowrap'}   || 'nowrap',
        rowspan  => $attr{'rowspan'}  || 1,
        colspan  => $attr{'colspan'}  || 1,
        align    => $attr{'align'}    || 'left',
        valign   => $attr{'valign'}   || 'middle',
        contents => $attr{'contents'} || '',

        text => "",
    }, $class;

    return $self;
}

sub add_text {
    my ( $self, $text ) = @_;

    $self->{'text'} .= $text;
}

sub alignment {
    my ($self) = @_;

    return $self->{'align'};
}

sub colspan {
    my ($self) = @_;

    return $self->{'colspan'};
}

sub text {
    my ($self) = @_;

    return $self->{'text'};
}

sub width {
    my ($self) = @_;

    length( $self->{'text'} );
}

1;

__END__

=pod

=head1 NAME

HTML::FormatNroff::Table::Cell - Format HTML Table

=head1 SYNOPSIS

    use HTML::FormatNroff::Table::Cell;
    use parent 'HTML::FormatNroff::Table::Cell';

=head1 DESCRIPTION

The HTML::FormatNroff::Table::Cell is a base class used to record information
about a table entry as part of FormatTable processing. It is necessary to
record information for formatting into languages such as nroff tbl which
require formatting information ahead of the table data.

=head1 METHODS

=head2 new

    my $cell = HTML::FormatNroff::Table::Cell->new(%attr);

Since this is a base class, a derived class constructor such as
L<HTML::FormatNroff::Table::CellNroff> should be called.

The following attributes are supported:

=over

=item header

is a header (default is '')

=item nowrap

do not wrap if defined

=item rowspan

number of rows cell spans (default is 1)

=item colspan

number of columns cell spans (default is 1)

=item align

alignment of cell contents (default is 'left')

=item valign

vertical alignment of cell (default is 'middle')

=item contents

contents of cell (default is '')

=back

=head2 add_text($text);

Add additional contents to cell.

=head2 alignment();

Return cell alignment.

=head2 colspan();

Return cell colspan.

=head2 text();

Return cell text.

=head2 width();

Return cell width in characters.

=head1 SEE ALSO

L<HTML::FormatNroff>,

=head1 COPYRIGHT

Copyright (c) 1997 Frederick Hirsch. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Frederick Hirsch <f.hirsch@opengroup.org>

=cut
