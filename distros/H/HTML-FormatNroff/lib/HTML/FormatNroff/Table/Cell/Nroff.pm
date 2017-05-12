package HTML::FormatNroff::Table::Cell::Nroff;

use 5.004;
use strict;
use warnings;
use parent 'HTML::FormatNroff::Table::Cell';
use Carp;

my $_max_tbl_cell = 300;

my %_formats = (
    left   => "l",
    center => "c",
    right  => "r",
);

sub format_str {
    my ( $self, $width ) = @_;

    my $result = $_formats{ $self->{'align'} };
    if ($width) { $result .= "w(" . $width . "i)"; }
    my $cnt = $self->{'colspan'};
    while ( $cnt > 1 ) {
        $result .= " s";
        $cnt--;
    }
    return $result;
}

sub output {
    my ( $self, $formatter ) = @_;

    $formatter->out("T{\n.ad l\n.fi\n");
    if ( $self->{'header'} eq 'header' ) {
        $formatter->font_start('B');
    }
    my $text = $self->{'text'};
    $text =~ s/ +/ /;

    # need to split to avoid buffer overrun in tbl,
    # using $_max_tbl_cell as magic number
    my $len = length($text);
    while ( $len > 0 ) {
        if ( $len < $_max_tbl_cell ) {
            $formatter->out($text);
            $len = 0;
        }
        else {
            my $place = index( $text, " ", $_max_tbl_cell / 2 );
            $formatter->out( substr( $text, 0, $place ) );
            $formatter->out("\n");
            $text = substr( $text, $place + 1 );
            $len = length($text);
        }
    }

    if ( $self->{'header'} eq 'header' ) {
        $formatter->font_end();
    }
    $formatter->out("\n.nf\nT}");
}

1;

__END__

=pod

=head1 NAME

HTML::FormatNroff::Table::Cell::Nroff - Format HTML Table entry

=head1 SYNOPSIS

    use HTML::FormatNroff::Table::Cell::Nroff;
    my $cell = new HTML::FormatNroff::Table::Cell::Nroff(%attr);

=head1 DESCRIPTION

The HTML::FormatNroff::Table::Cell::Nroff is used to record information about a
table entry and produce format information about the entry.  It is used by
FormatTableNroff to process HTML tables.

=head1 METHODS

=head2 format_str($width);

Produce a tbl format specification for the current cell, consisting of an
alignment character, width (in inches), and any subsequent colspan
specifications. An example is "cw(2i)".

=head2 output($formatter);

Output a table cell entry using the formatter defined by $formatter.

    The nroff
    T{
    .ad 1
    .fi
     contents
    .nf
    }T

Construct is used to format text inside a cell. Bold is used for a table
header.

=head1 SEE ALSO

L<HTML::FormatNroff>

=head1 COPYRIGHT

Copyright (c) 1997 Frederick Hirsch. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Frederick Hirsch <f.hirsch@opengroup.org>

=cut

