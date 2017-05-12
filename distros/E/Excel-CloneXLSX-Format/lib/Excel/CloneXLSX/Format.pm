package Excel::CloneXLSX::Format;

use 5.008001;
use strict;
use warnings;

our $VERSION = "0.03";

use Exporter 'import';
our @EXPORT_OK = qw(translate_xlsx_format);

sub translate_xlsx_format {
    my ($old_fmt) = @_;
    return {} unless (defined $old_fmt);

    # font
    my $old_font = $old_fmt->{Font};
    my %new_fmt  = (
        font           => $old_font->{Name},
        size           => $old_font->{Height},
        color          => $old_font->{Color},
        bold           => $old_font->{Bold},
        italic         => $old_font->{Italic},
        underline      => $old_font->{UnderlineStyle},
        font_strikeout => $old_font->{Strikeout},
        font_script    => $old_font->{Super},
    );

    # shading
    my $old_shading = $old_fmt->{Fill};
    my @shading_fields = qw(pattern fg_color bg_color);
    for my $idx (0..$#shading_fields) {
        $new_fmt{ $shading_fields[$idx] } = $old_shading->[$idx]
            if (defined $old_shading->[$idx]);
    }

    # if pattern is 'solid', Excel swaps fgColor and bgColor. This unswaps.
    if ($new_fmt{pattern} == 1) {
        @new_fmt{qw(bg_color fg_color)} = @new_fmt{qw(fg_color bg_color)};
    }

    # alignment
    # halign numbers match up, valign numbers are off by one
    my ($old_halign, $old_valign) = @{$old_fmt}{qw(AlignH AlignV)};
    $new_fmt{text_h_align} = $old_halign;
    $new_fmt{text_v_align} = defined($old_valign) ? $old_valign+1 : 0;

    # borders
    my $old_border_style = $old_fmt->{BdrStyle};
    my $old_border_color = $old_fmt->{BdrColor};
    my @sides = qw(left right top bottom);
    for my $idx (0..$#sides) {
        my $side = $sides[$idx];
        $new_fmt{$side} = $old_border_style->[$idx] if ($old_border_style->[$idx]);
        $new_fmt{"${side}_color"} = $old_border_color->[$idx] if ($old_border_color->[$idx]);
    }

    return \%new_fmt;
}



1;
__END__

=encoding utf-8

=head1 NAME

Excel::CloneXLSX::Format - Convert Spreadsheet::ParseXLSX formats to Excel::Writer::XLSX

=head1 SYNOPSIS

 use Excel::CloneXLSX::Format qw(translate_xlsx_format);
 use Excel::Writer::XLSX;
 use Safe::Isa;
 use Spreadsheet::ParseXLSX;

 my $old_workbook  = Spreadsheet::ParseXLSX->new->parse('t/data/sample.xlsx');
 my $old_worksheet = $old_workbook->worksheet('Sheet1');

 open my $fh, '>', 't/data/converted.xlsx'
     or die "Can't open output: $!";
 my $new_workbook  = Excel::Writer::XLSX->new( $fh );
 my $new_worksheet = $new_workbook->add_worksheet();

 my ($row_min, $row_max) = $old_worksheet->row_range();
 my ($col_min, $col_max) = $old_worksheet->col_range();
 for my $row ($row_min..$row_max) {
     for my $col ($col_min..$col_max) {

         my $old_cell   = $old_worksheet->get_cell($row, $col);
         my $old_format = $old_cell->$_call_if_object('get_format');
         my $fmt_props  = translate_xlsx_format( $old_format );
         my $new_format = $new_workbook->add_format(%$fmt_props);
         $new_worksheet->write(
             $row, $col, ($old_cell->$_call_if_object('unformatted') || ''),
             $new_format
         );
     }
 }

 $new_workbook->close;


=head1 DESCRIPTION

CPAN has great modules for reading XLS/XLSX files
(L<Spreadsheet::ParseExcel> / L<Spreadsheet::ParseXLSX>), and a great
module for writing XLSX files (L<Excel::Writer::XLSX>), but no module
for editing XLSX files.  I<This> module... won't do that either.  It
B<will> convert L<Spreadsheet::ParseExcel>-style cell formats to a
structure that L<Excel::Writer::XLSX> will understand.

My hope is to eventually release an Excel::CloneXLSX module that will
create a copy of a C<< ::Parse* >> object, with hooks to modify the
content.


=head1 USAGE

=head2 translate_xlsx_format( $cell->get_format() )

Takes the hashref returned from L<Spreadsheet::ParseExcel::Cell>'s
C<get_format()> method and returns a hashref that can be fed to
L<Excel::Writer::XLSX>'s C<new_format()> method.

=head3 What's Supported

=over

=item * Font (Family, Style, Size, {Super,Sub}script)

=item * Background Color

=item * Alignment

=item * Border Style and Color

=back

=head3 What isn't

=over

=item * Foreground Color

Trying to set the foreground color produces weird results.  I think it
might be a bug in C<Excel::Writer::XLSX>, but I haven't yet
investigated.

=item * Everything else

=back

=head1 LICENSE

Copyright (C) Fitz Elliott.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Fitz Elliott E<lt>felliott@fiskur.orgE<gt>

=cut

