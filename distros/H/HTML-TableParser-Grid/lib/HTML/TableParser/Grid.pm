package HTML::TableParser::Grid;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.5');

use HTML::TableParser;

sub new {
    my($class, $table_html, $offset) = @_;
    $offset ||= 0;

    my $udata = {
        row => 0,
        data => [],
    };

    my @request = ({
        id => 1,           # parse the first table
        row => \&_row,
        udata => $udata,
    });

    HTML::TableParser->new(\@request, { Decode => 1, Trim => 1, Chomp => 1 })
            ->parse($table_html) or croak $@;

    bless {
        data => $udata->{data},
        offset => $offset,
    }, $class;
}

sub cell {
    my($self, $row, $column) = @_;
    $column -= $self->{offset};
    $row -= $self->{offset};
    $self->{data}[$row][$column];
}

sub row {
    my($self, $row) = @_;
    $row -= $self->{offset};
    @{ $self->{data}[$row] };
}

sub column {
    my($self, $column) = @_;
    my @results;
    for my $row (@{ $self->{data} }) {
        push @results, $row->[$column];
    }
    @results;
}

sub num_columns {
    my($self, $row) = @_;
    $row ||= $self->{offset};
    scalar @{ $self->{data}[$row - $self->{offset}] };
}

sub num_rows {
    my($self) = @_;
    scalar @{ $self->{data} };
}

sub _row {
    my($id, $line, $cols, $udata) = @_;
    my $column = 0;
    $udata->{data}[$udata->{row}][$column++] = $_ for @{ $cols };
    $udata->{row}++;
}

1;
__END__

=head1 NAME

HTML::TableParser::Grid - Provide access methods to HTML tables by indicating row and column


=head1 SYNOPSIS

    use HTML::TableParser::Grid;

    # Assuming that $html represents an HTML table like this:
    # +----+----+-------+
    # | 00 | 01 | 02-12 |
    # +----+----+       |
    # |  10-11  |       |
    # +---------+-------+

    my $parser = HTML::TableParser::Grid->new($html);

    $parser->cell(0,0); # 00
    $parser->cell(0,2); # 02-12
    $parser->cell(1,1); # 10-11

    $parser->row(1);    # qw(10-11 10-11 02-12)

    $parser->column(1); # qw(01 10-11)

    ## Indicates 1 offset
    my $parser = HTML::TableParser::Grid->new($html, 1);

    $parser->cell(1,1); # 00


=head1 DESCRIPTION

B<HTML::TableParser::Grid> provides simple methods to access to HTML tables
by indicating row and column. This module takes advantage when many C<rowspan>s
and/or C<colspan>s make the table structure complicated.


=head1 METHODS

=head2 HTML::TableParser::Grid->new($html, [ $offset ])

Creates a new parser object.
It is passed a HTML document I<$html> which contains a table, like <table><tr><td> ... </table>. 
When I<$html> contains more than one table, just the first table is parsed.

If I<$offset> is supplied, the offset of row/column index is specified.
Default is zero.

=head2 cell($row, $column)

Returns a content of the specified cell.

=head2 row($row)

Returns a list of contents in the specified row.

=head2 column($column)

Returns a list of contents in the specified column.

=head2 num_rows

Returns the number of rows in the table.

=head2 num_columns

Returns the number of columns in the table.

=head2 _row


=head1 SEE ALSO

L<HTML::TableParser>


=head1 AUTHOR

Takeru INOUE  C<< <takeru.inoue _ gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Takeru INOUE C<< <takeru.inoue _ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
