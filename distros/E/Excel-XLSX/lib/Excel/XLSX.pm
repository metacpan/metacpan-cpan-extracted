package Excel::XLSX;
# ABSTRACT: Read and write Excel XLSX data

use 5.014;
use strict;
use warnings;

use base 'Exporter';

use Excel::Writer::XLSX;
use PerlX::Maybe;
use Spreadsheet::ParseXLSX;
use YAML::XS 'Dump';

our $VERSION = '1.03'; # VERSION

our @EXPORT_OK = qw( from_xlsx to_xlsx );

sub from_xlsx {
    my ($raw_xlsx_data_in) = @_;

    my $workbook_in = Spreadsheet::ParseXLSX->new->parse(\$raw_xlsx_data_in);

    my $align_h = [ undef, qw( left center right fill justify center_across ) ];
    my $align_v = [ qw( top vcenter bottom vjustify ) ];

    my ( $workbook_data, $format_defs );
    for my $worksheet_in ( $workbook_in->worksheets ) {
        my ( $row_min, $row_max ) = $worksheet_in->row_range;
        my ( $col_min, $col_max ) = $worksheet_in->col_range;

        my $worksheet = {
            name          => $worksheet_in->get_name,
            row_heights   => [ ( $worksheet_in->get_row_heights )[ 0 .. $row_max ] ],
            col_widths    => [ ( $worksheet_in->get_col_widths  )[ 0 .. $col_max ] ],
            merged_areas  => scalar $worksheet_in->get_merged_areas,
            is_portrait   => ( $worksheet_in->is_portrait ) ? 1 : 0,
            paper         => $worksheet_in->get_paper,
            margin_left   => $worksheet_in->get_margin_left,
            margin_right  => $worksheet_in->get_margin_right,
            margin_top    => $worksheet_in->get_margin_top,
            margin_bottom => $worksheet_in->get_margin_bottom,
            margin_header => $worksheet_in->get_margin_header,
            margin_footer => $worksheet_in->get_margin_footer,
            print_scale   => $worksheet_in->get_print_scale,
            fit_to_pages  => [ $worksheet_in->get_fit_to_pages ],
        };

        for my $row ( $row_min .. $row_max ) {
            for my $col ( $col_min .. $col_max ) {
                if ( my $cell = $worksheet_in->get_cell( $row, $col ) ) {
                    my $format_id;
                    if ( my $format = $cell->get_format ) {
                        my $font         = $format->{Font};
                        my $fill         = $format->{Fill};
                        my $border_style = $format->{BdrStyle};
                        my $border_color = [ map {
                            s/^#//;
                            ( /^[0-9a-fA-F]+$/ ) ? hex($_) : undef;
                        } $format->{BdrColor} ];

                        my $format_data = {
                            (
                                ($font) ? (
                                    maybe font  => $font->{Name} || undef,
                                    maybe size  => $font->{Height} || undef,
                                    maybe color => ( $font->{Color} and $font->{Color} ne '#000000' )
                                        ? $font->{Color}
                                        : undef,
                                    maybe bold      => ( $font->{Bold} ) ? 1 : undef,
                                    maybe italic    => ( $font->{Italic} ) ? 1 : undef,
                                    maybe underline => ( $font->{UnderlineStyle} )
                                        ? $font->{UnderlineStyle}
                                        : undef,
                                    maybe font_strikeout => ( $font->{Strikeout} ) ? 1 : undef,
                                    maybe font_script    => ( $font->{Super} ) ? $font->{Super} : undef,
                                ) : (),
                            ),
                            maybe num_format => $format->{FmtIdx},
                            maybe locked     => ( $format->{Lock} ) ? 1 : undef,
                            maybe hidden     => ( $format->{Hidden} ) ? 1 : undef,
                            maybe align      => ( $format->{AlignH} )
                                ? $align_h->[ $format->{AlignH} ]
                                : undef,
                            maybe valign => ( defined $format->{AlignV} )
                                ? $align_v->[ $format->{AlignV} ]
                                : undef,
                            maybe text_wrap     => ( $format->{Wrap} ) ? 1 : undef,
                            maybe rotation      => $format->{Rotate} || undef,
                            maybe indent        => $format->{Indent} || undef,
                            maybe shrink        => $format->{Shrink} || undef,
                            maybe text_justlast => ( $format->{JustLast} ) ? 1 : undef,
                            (
                                ($fill) ? (
                                    maybe pattern  => $fill->[0] || undef,
                                    maybe bg_color => $fill->[1],
                                    maybe fg_color => ( $fill->[2] and uc $fill->[2] ne '#FFFFFF' )
                                        ? $fill->[2]
                                        : undef,
                                ) : (),
                            ),
                            (
                                ($border_style) ? (
                                    maybe left   => $border_style->[0],
                                    maybe right  => $border_style->[1],
                                    maybe top    => $border_style->[2],
                                    maybe bottom => $border_style->[3],
                                ) : (),
                            ),
                            (
                                ($border_color) ? (
                                    maybe left_color   => $border_color->[0],
                                    maybe right_color  => $border_color->[1],
                                    maybe top_color    => $border_color->[2],
                                    maybe bottom_color => $border_color->[3],
                                ) : (),
                            ),
                        };

                        if ( $format_data and %$format_data ) {
                            my $format_yaml = Dump($format_data);
                            unless ( exists $format_defs->{$format_yaml} ) {
                                push( @{ $workbook_data->{formats} }, $format_data );
                                $format_defs->{$format_yaml} = @{ $workbook_data->{formats} } - 1;
                            }
                            $format_id = $format_defs->{$format_yaml};
                        }
                    }

                    my $value = $cell->unformatted;
                    $worksheet->{cells}{$row}{$col} = {
                        value           => $value,
                        formatted       => $cell->value,
                        maybe format_id => $format_id,
                    } if ( defined $format_id or defined $value and $value =~ /\S/ );
                }
            }
        }

        push( @{ $workbook_data->{worksheets} }, $worksheet );
    }

    return $workbook_data;
}

sub to_xlsx {
    my ($workbook_data) = @_;

    open( my $fh, '>:raw', \my $raw_xlsx_data_out );
    my $workbook_out = Excel::Writer::XLSX->new($fh);

    my $formats = [
        map {
            my $valign = delete $_->{valign};
            my $format = $workbook_out->add_format(%$_);
            $format->set_align($valign) if ( defined $valign );
            $format;
        } @{ $workbook_data->{formats} }
    ];

    for my $worksheet ( @{ $workbook_data->{worksheets} } ) {
        my $worksheet_out = $workbook_out->add_worksheet( $worksheet->{name} );

        unless ( $worksheet->{is_portrait} ) {
            $worksheet_out->set_landscape;
        }
        else {
            $worksheet_out->set_portrait;
        }
        $worksheet_out->set_paper        ( $worksheet->{paper}         ) if ( exists $worksheet->{paper}         );
        $worksheet_out->set_margin_left  ( $worksheet->{margin_left}   ) if ( exists $worksheet->{margin_left}   );
        $worksheet_out->set_margin_right ( $worksheet->{margin_right}  ) if ( exists $worksheet->{margin_right}  );
        $worksheet_out->set_margin_top   ( $worksheet->{margin_top}    ) if ( exists $worksheet->{margin_top}    );
        $worksheet_out->set_margin_bottom( $worksheet->{margin_bottom} ) if ( exists $worksheet->{margin_bottom} );
        $worksheet_out->set_header( undef, $worksheet->{margin_header} ) if ( exists $worksheet->{margin_header} );
        $worksheet_out->set_footer( undef, $worksheet->{margin_footer} ) if ( exists $worksheet->{margin_header} );
        $worksheet_out->set_print_scale(   $worksheet->{print_scale}   ) if ( exists $worksheet->{print_scale}   );
        $worksheet_out->fit_to_pages( @{ $worksheet->{fit_to_pages} }  ) if ( exists $worksheet->{fit_to_pages}  );

        for my $row ( keys %{ $worksheet->{cells} } ) {
            for my $col ( keys %{ $worksheet->{cells}{$row} } ) {
                $worksheet_out->write(
                    $row,
                    $col,
                    $worksheet->{cells}{$row}{$col}{value},
                    ( exists $worksheet->{cells}{$row}{$col}{format_id} )
                        ? $formats->[ $worksheet->{cells}{$row}{$col}{format_id} ]
                        : undef,
                );
            }
        }

        for my $area ( @{ $worksheet->{merged_areas} } ) {
            my ( $first_row, $first_col, $last_row, $last_col ) = @$area;

            my $first_format = ( exists $worksheet->{cells}{$first_row}{$first_col}{format_id} )
                ? $formats->[ $worksheet->{cells}{$first_row}{$first_col}{format_id} ]
                : undef;

            my $last_format = ( exists $worksheet->{cells}{$last_row}{$last_col}{format_id} )
                ? $formats->[ $worksheet->{cells}{$last_row}{$last_col}{format_id} ]
                : undef;

            my $format = $workbook_out->add_format;
            $format->copy( $first_format // $last_format );

            if ($last_format) {
                my (
                    $bottom, $bottom_color,
                    $diag_border, $diag_color, $diag_type,
                    $left, $left_color,
                    $right, $right_color,
                    $top, $top_color
                ) = split( ':', $last_format->get_border_key );

                $format->set_right(        $right        );
                $format->set_bottom(       $bottom       );
                $format->set_right_color(  $right_color  );
                $format->set_bottom_color( $bottom_color );
            }

            $worksheet_out->merge_range(
                @$area,
                $worksheet->{cells}{$first_row}{$first_col}{value},
                $format,
            );
        }

        my ( $row, $col ) = ( 0, 0 );
        $worksheet_out->set_row   ( $row++,       $_ ) for ( @{ $worksheet->{row_heights} } );
        $worksheet_out->set_column( $col, $col++, $_ ) for ( @{ $worksheet->{col_widths } } );
        $worksheet_out->set_column( 0, 0, $worksheet->{col_widths }[0] );
    }
    $workbook_out->close;

    return $raw_xlsx_data_out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Excel::XLSX - Read and write Excel XLSX data

=head1 VERSION

version 1.03

=for markdown [![test](https://github.com/gryphonshafer/Excel-XLSX/workflows/test/badge.svg)](https://github.com/gryphonshafer/Excel-XLSX/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Excel-XLSX/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Excel-XLSX)

=head1 SYNOPSIS

    use Excel::XLSX qw( from_xlsx to_xlsx );

    open( my $in, '<:raw', 'in.xlsx' ) or die $!;
    local $/ = undef;
    my $xlsx_in = <$in>;

    my $workbook_data = from_xlsx($xlsx_in);

    $workbook_data->{worksheets}[0]{cells}{12}{7}{value} = 'Hello world!';

    my $xlsx = to_xlsx($workbook_data);

    open( my $out, '>:raw', 'out.xlsx' ) or die $!;
    print $out $xlsx;

=head1 DESCRIPTION

This module offers for export 2 functions, C<from_xlsx> and C<to_xlsx>, that
will read from raw binary Excel XLSX data into a data structure
and write from a data structure to raw binary Excel XLSX data.

=head1 FUNCTIONS

=head2 from_xlsx

Reads from raw binary Excel XLSX data and returns a data structure.

    my $workbook_data = from_xlsx($xlsx_in);

=head2 to_xlsx

Requires a data structure like what might be returned from C<from_xlsx> and
returns raw binary Excel XLSX data.

    my $xlsx = to_xlsx($workbook_data);

=head1 DATA STRUCTURE

The data structure is expected to generally look like:

    formats:
      - font: Arial
        size: 12
      - font: Arial
        size: 10
        color: #00FF00
    worksheets:
      - name: Example Worksheet
        cells:
            12:
                7:
                  - format_id: 0
                    value: Hello world!

=head1 SEE ALSO

L<Spreadsheet::ParseXLSX>, L<Excel::Writer::XLSX>, L<Excel::ValueReader::XLSX>,
L<Excel::ValueWriter::XLSX>.

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Excel-XLSX>

=item *

L<MetaCPAN|https://metacpan.org/pod/Excel::XLSX>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Excel-XLSX/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Excel-XLSX>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Excel-XLSX>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/S/Excel-XLSX.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
