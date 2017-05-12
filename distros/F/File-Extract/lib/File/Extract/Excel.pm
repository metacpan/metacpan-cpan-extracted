# $Id: /mirror/perl/File-Extract/trunk/lib/File/Extract/Excel.pm 4210 2007-10-27T13:43:07.499967Z daisuke  $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package File::Extract::Excel;
use strict;
use base qw(File::Extract::Base);
use Spreadsheet::ParseExcel;

sub mime_type { 'application/excel' }
sub extract
{
    my $self = shift;
    my $file = shift;

    my $book  = Spreadsheet::ParseExcel::Workbook->Parse($file);
    return unless $book;

    my $text = '';
    foreach my $sheet (@{$book->{Worksheet}}) {
        last if !defined $sheet->{MaxRow};
        foreach my $row ($sheet->{MinRow} .. $sheet->{MaxRow}) {
            foreach my $col ($sheet->{MinCol} .. $sheet->{MaxCol}) {
                my $cell = $sheet->{Cells}[$row][$col];
                if ($cell) {
                    $text .= $cell->Value;
                }
                $text .= " ";
            }
            $text .= "\n";
        }
        $text .= "\n\n";
    }

    return File::Extract::Result->new(
        text => eval { $self->recode($text) } || $text,
        filename => $file,
        mime_type => $self->mime_type
    );
}

1;

__END__

=head1 NAME

File::Extract::Excel - Extract Text From Excel Files

=cut