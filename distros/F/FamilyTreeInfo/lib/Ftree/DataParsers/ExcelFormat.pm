package Ftree::DataParsers::ExcelFormat;
use strict;
use warnings;
use version; our $VERSION = qv('2.3.41');

use Spreadsheet::ParseExcel;
use Ftree::DataParsers::ExtendedSimonWardFormat
  ;    # for getting pictures. Temporal solution
use Ftree::FamilyTreeData;
# use CGI::Carp qw(fatalsToBrowser);
use Encode qw(decode);

sub createFamilyTreeDataFromFile {
    my ($config_) = @_;
    my $file_name = $config_->{file_name}
      or die "No file_name is given in config";

    my $family_tree_data = Ftree::FamilyTreeData->new();
    my $excel            = Spreadsheet::ParseExcel::Workbook->Parse($file_name)
      or die "Unable to parse file " . $file_name;
    foreach my $sheet ( @{ $excel->{Worksheet} } ) {
        $sheet->{MaxRow} ||= $sheet->{MinRow};
        foreach my $row ( $sheet->{MinRow} + 1 .. $sheet->{MaxRow} ) {
            my $tempperson = {
                id             => convertCell( $sheet->{Cells}[$row][0] ),
                first_name     => convertCell( $sheet->{Cells}[$row][3] ),
                mid_name       => convertCell( $sheet->{Cells}[$row][4] ),
                last_name      => convertCell( $sheet->{Cells}[$row][5] ),
                title          => convertCell( $sheet->{Cells}[$row][1] ),
                prefix         => convertCell( $sheet->{Cells}[$row][2] ),
                suffix         => convertCell( $sheet->{Cells}[$row][6] ),
                nickname       => convertCell( $sheet->{Cells}[$row][7] ),
                father_id      => convertCell( $sheet->{Cells}[$row][8] ),
                mother_id      => convertCell( $sheet->{Cells}[$row][9] ),
                email          => convertCell( $sheet->{Cells}[$row][10] ),
                homepage       => convertCell( $sheet->{Cells}[$row][11] ),
                date_of_birth  => convertCell( $sheet->{Cells}[$row][12] ),
                date_of_death  => convertCell( $sheet->{Cells}[$row][13] ),
                gender         => convertCell( $sheet->{Cells}[$row][14] ),
                is_living      => convertCell( $sheet->{Cells}[$row][15] ),
                place_of_birth => convertCell( $sheet->{Cells}[$row][16] ),
                place_of_death => convertCell( $sheet->{Cells}[$row][17] ),
                cemetery       => convertCell( $sheet->{Cells}[$row][18] ),
                schools        => ( defined $sheet->{Cells}[$row][19] )
                ? [ split( /,/, convertCell( $sheet->{Cells}[$row][19] ) ) ]
                : undef,
                jobs => ( defined $sheet->{Cells}[$row][20] )
                ? [ split( /,/, convertCell( $sheet->{Cells}[$row][20] ) ) ]
                : undef,
                work_places => ( defined $sheet->{Cells}[$row][21] )
                ? [ split( /,/, convertCell( $sheet->{Cells}[$row][21] ) ) ]
                : undef,
                places_of_living => convertCell( $sheet->{Cells}[$row][22] ),
                general          => convertCell( $sheet->{Cells}[$row][23] )
            };
            $family_tree_data->add_person($tempperson);
        }
    }
    if ( defined $config_->{photo_dir} ) {
        Ftree::DataParsers::ExtendedSimonWardFormat::setPictureDirectory( $config_->{photo_dir} );
        Ftree::DataParsers::ExtendedSimonWardFormat::fill_up_pictures($family_tree_data);
    }

    return $family_tree_data;
}

sub convertCell {
    my ($cell) = @_;
    return undef unless defined $cell;
    my $rowtxt = '';
    if ( !$cell ) {
        $rowtxt = "\t";

        # next;
    }
    my $val = $cell->{Val};
    if ( !defined($val) or $val eq '' ) {
        $rowtxt = "\t";

        # next;
    }
    if (defined $val){
    if ( defined $cell->{Code} && $cell->{Code} eq 'ucs2' ){
    $val = decode( "UTF-16BE", $val );
  }
    $val =~ s/^\s+//;
    $val =~ s/\s+$//;
  }
    if ( $val eq '' ) {
        $rowtxt = "\t";
        next;
    }
    $rowtxt = "$val";

    return $rowtxt;

# return $cell->{Val} if( $cell->{Type} eq "Numeric" );
# return $cell->{Val} unless( defined $cell->{Code} );
# use Encode qw(decode encode);
# $characters = decode('UTF-8', $octets,     Encode::FB_CROAK);
# return  decode('UTF-8',$cell->{Val},Encode::FB_CROAK);#decode('UTF-16LE', $cell->{Val});
# Encode::from_to( $cell->{Val}, "utf8", "utf16le" );
}

1;
