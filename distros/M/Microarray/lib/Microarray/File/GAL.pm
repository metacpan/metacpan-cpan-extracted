package Microarray::File::GAL;

use 5.006;
use strict;
use warnings;
our $VERSION = '2.16';

require Microarray::File;

{ package gal_file;

	our @ISA = qw( delimited_file );

	sub import_data {
		my $self = shift;
		die "Microarray:GAL ERROR: This file does not have a '.gal' suffix\n" unless
			($self->file_name =~ /\.gal$/i); 
		my $aaData = $self->load_file_data;
		$self->set_file_type(shift @$aaData);	# File format (ATF) and version (1.0). 
		$self->set_head_count(shift @$aaData);	# no. header records & data columns
		$self->sort_data($aaData);
	}
	sub DESTROY {
		my $self = shift;
	}
	#Êno need to set header row, but left this in to check its there!
	sub set_file_type {
		my $self = shift;
		my $aRow = shift;
		die "Microarray::File::GAL ERROR: Gal file does not have an ATF header\n" unless ($aRow->[0] eq 'ATF');
	}
	sub file_format {
		'ATF'
	}
	sub file_version {
		'1.0';
	}
	sub set_head_count {
		my $self = shift;
		my $aRow = shift;
		$self->header_rows($aRow->[0]);
		$self->data_cols($aRow->[1]);
	}
	sub header_rows {	# second row of file, first value - number of rows before spot data 
		my $self = shift;
		@_	?	$self->{ _header_rows } = shift
			:	$self->{ _header_rows };
	}	
	sub data_cols {		# second row of file, second value - number of spot data columns
		my $self = shift;
		@_	?	$self->{ _data_cols } = shift
			:	$self->{ _data_cols };
	}
	sub sort_data {
		my $self = shift;
		my $aaData = shift;
		$self->set_header_info($aaData);
		$self->set_spot_info($aaData);
	}
	sub set_header_info {
		my $self = shift;
		my $aaData = shift;
		my $hhBlock_Info = { };
		my $block_count = 0;
		while (my $aLine = shift @$aaData) {
			if ($aLine->[0] =~ /^Block\d+=/){
				$block_count++;
				$aLine->[0] =~ s/\"//g;
				$aLine->[0] =~ s/\s//g;
				my ($block,$block_coords) = split(/=/,$aLine->[0]);
				$block =~ s/Block//;
				warn "Microarray::File::GAL ERROR: Discrepency in header info\n".
					"\treading block $block, expecting block $block_count\n"
					unless ($block_count == $block);
				my @aCoordinates = split(/,/, $block_coords);
				$self->set_block_layout($aCoordinates[0],$aCoordinates[1]);
				$hhBlock_Info->{ $block } = { coordinates => \@aCoordinates, spots => [] };
			} elsif ($aLine->[0] =~ /=/){
				my ($key,$value) = split(/=/,$aLine->[0]);
				$self->{ "_$key" } = $value;
				$self->add_header_key($key);
			} else {
				$self->set_spot_indexes($aLine);
				last;
			}
		} 
		$self->block_count($block_count);
		$self->{ _block_info } = $hhBlock_Info;		
	}
	sub block_layout {
		my $self = shift;
		unless (defined $self->{ _block_layout }){
			$self->{ _block_layout } = { row => {}, col => {} };
		}
		if (@_){
			my $row_col = shift;
			return unless ($row_col =~ /row|col/i);
			my $hLayout = $self->{ _block_layout };
			return $hLayout->{ $row_col };
		} else {
			return $self->{ _block_layout };
		}
	}
	sub block_rows {
		my $self = shift;
		my $hRows = $self->block_layout('row');
		return scalar(keys %$hRows);
	}
	sub block_cols {
		my $self = shift;
		my $hCols = $self->block_layout('col');
		return scalar(keys %$hCols);
	}
	sub set_block_layout {
		my $self = shift;
		my $block_row = shift;
		my $block_col = shift;
		my $hLayout = $self->block_layout;
		$$hLayout{ row }{ $block_row }++; 
		$$hLayout{ col }{ $block_col }++; 
	}
	sub set_spot_indexes {
		my $self = shift;
		my $aLine = shift;
		my $hIndexes = {};
		for (my $i=0; $i<@$aLine; $i++){
			my $key = $aLine->[$i];
			$hIndexes->{ $key } = $i;
			$hIndexes->{ $i } = $key;
		}
		$self->gal_type('v4.1') if (defined $hIndexes->{ Annotation });
		$self->{ _spot_indexes } = $hIndexes;
	}
	sub get_spot_indexes {
		my $self = shift;
		my $hIndexes = $self->{ _spot_indexes };
		if (@_){
			my $key = shift;
			return $hIndexes->{ $key };
		} else {
			return $hIndexes;
		}
	}
	sub gal_type {
		my $self = shift;
		if (@_){
			$self->{ _gal_type } = shift;
		} else {
			if (defined $self->{ _gal_type }){
				$self->{ _gal_type };
			} else {
				$self->default_gal_type;
			}
		}
	}
	sub default_gal_type {
		'v1.0';
	}
	sub add_header_key {
		my $self = shift;
		my $aHeader_Keys = $self->header_keys;
		push (@$aHeader_Keys,shift);
	}
	# array ref containing the keys (names) of corresponding header values
	sub header_keys {
		my $self = shift;
		unless (defined $self->{ _header_keys }){
			$self->{ _header_keys } = [];
		}
		$self->{ _header_keys };
	}
	sub get_header_value {
		my $self = shift;
		my $key = shift;
		return $self->{ "_$key" };
	}
	sub get_block_info {
		my $self = shift;
		my $hhBlock_Info = $self->{ _block_info };
		if (@_){
			my $block = shift;
			die "Microarray::File::GAL ERROR: Block number out of range\ntried to get block $block\n" 
				unless (defined $hhBlock_Info->{ $block });
			$hhBlock_Info->{ $block };
		} else {
			$hhBlock_Info;
		}
	}
	sub get_block_coords {
		my $self = shift;
		my $hBlock_Info = $self->get_block_info(shift);
		return $hBlock_Info->{ coordinates };
	}
	sub get_block_spots {
		my $self = shift;
		my $hBlock_Info = $self->get_block_info(shift);
		return $hBlock_Info->{ spots };
	}
	sub block_x_origin {
		my $self = shift;
		my $aCoordinates = $self->get_block_coords(shift);
		return $aCoordinates->[0];
	}
	sub block_y_origin {
		my $self = shift;
		my $aCoordinates = $self->get_block_coords(shift);
		return $aCoordinates->[1];
	}
	# should the feature diameter ever change between blocks? 
	sub block_feature_diameter {	# in um
		my $self = shift;
		my $aCoordinates = $self->get_block_coords(shift);
		return $aCoordinates->[2];
	}
	# number of columns in the block
	# from the header block info
	# for actual counted cols, use counted_cols($block)
	sub block_x_features {	
		my $self = shift;
		my $block = shift;
		my $aCoordinates = $self->get_block_coords($block);
		warn "Microarray::File::GAL ERROR: Discrepency in column count for block $block.\n".
			$aCoordinates->[3]." columns set in header information, ".$self->counted_cols($block)." columns counted\n"
			unless ($aCoordinates->[3] == $self->counted_cols($block));
		return $aCoordinates->[3];
	}
	sub block_x_spacing {	# column spacing in um
		my $self = shift;
		my $aCoordinates = $self->get_block_coords(shift);
		return $aCoordinates->[4];
	}
	# number of rows in the block
	# from the header block info
	# for actual counted rows, use counted_rows($block)
	sub block_y_features {	
		my $self = shift;
		my $block = shift;
		my $aCoordinates = $self->get_block_coords($block);
		warn "Microarray::File::GAL ERROR: Discrepency in row count for block $block.\n".
			$aCoordinates->[5]." rows set in header information, ".$self->counted_rows($block)." rows counted\n"
			unless ($aCoordinates->[5] == $self->counted_rows($block));
		return $aCoordinates->[5];
	}
	sub block_y_spacing {	# row spacing in um
		my $self = shift;
		my $aCoordinates = $self->get_block_coords(shift);
		return $aCoordinates->[6];
	}
	sub block_count {
		my $self = shift;
		if (@_){
			$self->{ _blocks } = shift;
		} else {
			if (defined $self->{ _BlockCount }){
				warn "Microarray::File::GAL ERROR: Discrepency in block count.\n".
					$self->{ _BlockCount }." blocks set in the header information, ".$self->{ _blocks }." blocks counted\n" 
					unless ($self->{ _BlockCount } == $self->{ _blocks });
			}
			$self->{ _blocks };
		}
	}
	sub set_spot_info {
		my $self = shift;
		my $aaData = shift;
		my $block = 0;
		my $spot_count = 0;
		my $hIndexes = $self->get_spot_indexes;
		while (my $aLine = shift @$aaData){		# spot header row has already been shifted off
			unless ($block == $$aLine[$hIndexes->{Block}]){	# BLOCK MIGHT NOT BE INDEX[0] !!!
				$block = $$aLine[$hIndexes->{Block}];
			}
			if (($$aLine[$hIndexes->{Name}])&&($$aLine[$hIndexes->{Name}] ne '')){
				$self->set_spot($aLine,$block);
				$spot_count++;
			} 
		}
		$self->set_spot_count($spot_count);
	}
	sub set_spot {
		my $self = shift;
		my $aLine = shift;
		my $block = shift;
		my $hIndexes = $self->get_spot_indexes;
		my $hInfo = { Name => $$aLine[$hIndexes->{Name}], ID => $$aLine[$hIndexes->{ID}] };
		if ($self->gal_type eq 'v4.1'){	
			$hInfo->{Annotation} = $$aLine[$hIndexes->{Annotation}];
		}
		my $ahSpots = $self->get_block_spots($block);
		$$ahSpots[ $$aLine[$hIndexes->{Column}] ][ $$aLine[$hIndexes->{Row}] ] = $hInfo;
		$self->count_block_rowcols($block,$$aLine[$hIndexes->{Column}],$$aLine[$hIndexes->{Row}]);
	}
	sub count_block_rowcols {
		my $self = shift;
		my $block = shift;
		my $col = shift;
		my $row = shift;

		if ($col > $self->counted_cols($block)){
			$self->set_counted_cols($block,$col);
		}
		if ($row > $self->counted_rows($block)){
			$self->set_counted_rows($block,$row);
		}
	}
	# returns number of cols in a specific block, counted from set_spot()
	# different to col_count(), which compares col count in all blocks
	sub counted_cols {
		my $self = shift;
		my $block = shift;
		unless (defined $self->{ "_Col_Count_block_$block" }){
			$self->{ "_Col_Count_block_$block" } = 0;
		}
		$self->{ "_Col_Count_block_$block" };
	}
	sub set_counted_cols {
		my $self = shift;
		my $block = shift;
		$self->{ "_Col_Count_block_$block" } = shift;
	}
	# returns number of rows in a specific block, counted from set_spot()
	# different to row_count(), which compares row count in all blocks
	sub counted_rows {
		my $self = shift;
		my $block = shift;
		unless (defined $self->{ "_Row_Count_block_$block" }){
			$self->{ "_Row_Count_block_$block" } = 0;
		}
		$self->{ "_Row_Count_block_$block" };
	}
	sub set_counted_rows {
		my $self = shift;
		my $block = shift;
		$self->{ "_Row_Count_block_$block" } = shift;
	}
	# accepts (block,col,row)
	sub get_spot_info {
		my $self = shift;
		my $ahSpots = $self->get_block_spots(shift);
		return $$ahSpots[ shift ][ shift ];
	}
	# accepts (block,col,row)
	sub get_spot_name {
		my $self = shift;
		my $hInfo = $self->get_spot_info(shift,shift,shift);
		return $hInfo->{ Name };
	}
	# accepts (block,col,row,name)
	sub set_spot_name {
		my $self = shift;
		my $hInfo = $self->get_spot_info(shift,shift,shift);
		$hInfo->{ Name } = shift;
	}
	# accepts (block,col,row)
	sub get_spot_id {
		my $self = shift;
		my $hInfo = $self->get_spot_info(shift,shift,shift);
		return $hInfo->{ ID };
	}
	# accepts (block,col,row,id)
	sub set_spot_id {
		my $self = shift;
		my $hInfo = $self->get_spot_info(shift,shift,shift);
		$hInfo->{ ID } = shift;
	}
	# accepts (block,col,row)
	sub get_spot_annotation {
		my $self = shift;
		my $hInfo = $self->get_spot_info(shift,shift,shift);
		return $hInfo->{ Annotation };
	}
	# accepts (block,col,row,annotation)
	sub set_spot_annotation {
		my $self = shift;
		my $hInfo = $self->get_spot_info(shift,shift,shift);
		$hInfo->{ Annotation } = shift;
	}
	sub set_spot_count {
		my $self = shift;
		$self->{ '_SpotCount' } = shift;
	}
	sub spot_count {
		my $self = shift;
		$self->{ '_SpotCount' };
	}
	# return number of rows in each block if they are all the same
	# otherwise returns -1
	# if you need actual row count for a specific block, use counted_rows($block)
	sub row_count {
		my $self = shift;
		unless (defined $self->{ _row_count }){
			$self->set_row_count;
		}
		$self->{ _row_count };
	}
	sub set_row_count {
		my $self = shift;
		my $blocks = $self->block_count;
		my %hRows = ();
		for (my $i=1; $i<=$blocks; $i++){
			my $rows = $self->counted_rows($i);
			$hRows{$rows}++;
		}
		my @aRows = keys %hRows;
		if (@aRows == 1){
			$self->{ _row_count } = $aRows[0]; 
		} elsif (@aRows > 1){
			$self->{ _row_count } = -1;
		} else {
			return;
		}
	}
	# return number of columns in each block if they are all the same
	# otherwise returns -1
	# if you need actual column count for a specific block, use counted_cols($block)
	sub col_count {
		my $self = shift;
		unless (defined $self->{ _col_count }){
			$self->set_col_count;
		}
		$self->{ _col_count };
	}
	sub set_col_count {
		my $self = shift;
		my $blocks = $self->block_count;
		my %hCols = ();
		for (my $i=1; $i<=$blocks; $i++){
			my $cols = $self->counted_cols($i);
			$hCols{$cols}++;
		}
		my @aCols = keys %hCols;
		if (@aCols == 1){
			$self->{ _col_count } = $aCols[0]; 
		} elsif (@aCols > 1){
			$self->{ _col_count } = -1;
		} else {
			return;
		}
	}
	# return feature_diameter of each block if all the same
	# otherwise returns -1
	sub feature_diameter {
		my $self = shift;
		unless (defined $self->{ _feature_diameter }){
			$self->set_feature_diameter;
		}
		$self->{ _feature_diameter };
	}
	sub set_feature_diameter {
		my $self = shift;
		my $blocks = $self->block_count;
		my %hDiam = ();
		for (my $i=1; $i<=$blocks; $i++){
			my $diam = $self->block_feature_diameter($i);
			$hDiam{$diam}++;
		}
		my @aDiam = keys %hDiam;
		if (@aDiam == 1){
			$self->{ _feature_diameter } = $aDiam[0]; 
		} elsif (@aDiam > 1){
			$self->{ _feature_diameter } = -1;
		} else {
			return;
		}
	}
	# return x_spacing of each block if all the same
	# otherwise returns -1
	sub x_spacing {
		my $self = shift;
		unless (defined $self->{ _x_spacing }){
			$self->set_x_spacing;
		}
		$self->{ _x_spacing };
	}
	sub set_x_spacing {
		my $self = shift;
		my $blocks = $self->block_count;
		my %hX_Spacing = ();
		for (my $i=1; $i<=$blocks; $i++){
			my $x_spacing = $self->block_x_spacing($i);
			$hX_Spacing{$x_spacing}++;
		}
		my @aX_Spacing = keys %hX_Spacing;
		if (@aX_Spacing == 1){
			$self->{ _x_spacing } = $aX_Spacing[0]; 
		} elsif (@aX_Spacing > 1){
			$self->{ _x_spacing } = -1;
		} else {
			return;
		}
	}
	# return y_spacing of each block if all the same
	# otherwise returns -1
	sub y_spacing {
		my $self = shift;
		unless (defined $self->{ _y_spacing }){
			$self->set_y_spacing;
		}
		$self->{ _y_spacing };
	}
	sub set_y_spacing {
		my $self = shift;
		my $blocks = $self->block_count;
		my %hY_Spacing = ();
		for (my $i=1; $i<=$blocks; $i++){
			my $y_spacing = $self->block_y_spacing($i);
			$hY_Spacing{$y_spacing}++;
		}
		my @aY_Spacing = keys %hY_Spacing;
		if (@aY_Spacing == 1){
			$self->{ _y_spacing } = $aY_Spacing[0]; 
		} elsif (@aY_Spacing > 1){
			$self->{ _y_spacing } = -1;
		} else {
			return;
		}
	}
	sub file_string {
		my $self = shift;
		my $string = "ATF\t1.0\n".$self->header_rows."\t".$self->data_cols."\n";
		$string .= $self->header_string;
		$string .= $self->blocks_string;
		if ($self->gal_type eq 'v4.1'){
			$string .= "Block\tRow\tColumn\tID\tName\tAnnotation\n";
		} else {
			$string .= "Block\tRow\tColumn\tID\tName\n";
		}
		$string .= $self->rows_string;
		return $string;
	}
	sub header_string {
		my $self = shift;
		my $string = "";
		my $aHeaders = $self->header_keys;
		for (my $i=1; $i<=@$aHeaders; $i++){
			my $value = $self->get_header_value($aHeaders->[$i-1]);
			$string .= "\"".$aHeaders->[$i-1]."=$value\"\n";
		}
		return $string;
	}
	# formats the header block info for gal file output
	# counted_cols() and counted_rows() used instead of block_x_features() and block_y_features()
	# so that printing spacers can be removed from the GAL file 
	# only relevant when going from file->file, since block_x_features() and block_y_features()
	# aren't saved to db (since all block row/col counts are assumed the same) - see gal_file_table()
	sub blocks_string {
		my $self = shift;
		my $string = "";
		if (my $blocks = $self->block_count){
			for (my $i=1; $i<=$blocks; $i++){
				$string .= 	"\"Block$i= ".
							$self->block_x_origin($i).", ".
							$self->block_y_origin($i).", ".
							$self->feature_diameter.", ".
							$self->counted_cols($i).", ".		# actual cols, not original set value
							$self->block_x_spacing($i).", ".
							$self->counted_rows($i).", ".		# actual rows, not original set value
							$self->block_y_spacing($i)."\"\n";
			}
		} 
		return $string;
	}
	sub rows_string {
		my $self = shift;
		my $string = "";
		my @aValues = ();
		BLOCK:for (my $block=1; $block<=$self->block_count; $block++){
			ROW:for (my $row=1; $row<=$self->counted_rows($block); $row++){
				COL:for (my $col=1; $col<=$self->counted_cols($block); $col++){
				
					my $name = $self->get_spot_name($block,$col,$row);
					my $id = $self->get_spot_id($block,$col,$row);
				
					next COL unless ($name && ($name ne ''));
				
					if ($self->gal_type eq 'v4.1'){
						my $comment = $self->get_spot_annotation($block,$col,$row);
						$string .= "$block\t$row\t$col\t$id\t$name\t$comment\n";
					} else {
						$string .= "$block\t$row\t$col\t$id\t$name\n";
					}
				}
			}
		}
		return $string;
	}	
}

1;

__END__

=head1 NAME

Microarray::File::GAL - A Perl module for managing microarray GAL file objects

=head1 SYNOPSIS

	use Microarray::File::GAL;

	my $gal_file 	= gal_file->new("/gal_file.gal");	# if no filehandle, assumes name is full path to file
	# or
	my $gal_file 	= gal_file->new("gal_file.gal",$filehandle);	# pass name and FileHandle to original file
	
	my $spot_name 	= $gal_file->get_spot_name($block,$col,$row);
	my $spot_id 	= $gal_file->get_spot_id($block,$col,$row);

	# print the GAL back to file
	my $string = $gal_file->file_string;

=head1 DESCRIPTION

Microarray::File::GAL is an object-oriented Perl module for managing microarray GAL files. It doesn't create GAL files for you, but instead is used to check the contents of a GAL file, and display the microarray layout described by it. 

=head2 Block padding

For whatever reason, many microarrays are printed with gaps (padding) between pin-blocks. This padding is generated by creating empty rows/columns in the printing software, and (at least on our system) these empty rows/columns are carried through to the GAL file. When the GAL module parses a GAL file, it skips any spot that has a blank 'Name' field, hence automatically removing any padding rows/columns. 

It is also important to note that the method C<file_string()> is not a simple regurgitation of a GAL file opened by the object - padding spots won't be output by this method either. This provides a very quick and easy way to remove padding from a GAL file;

	#!/usr/bin/perl -w
	use strict;
	use Microarray::File::GAL;
	my $oGal_File = gal_file->new('gal_file.gal');
	open GALFILE, ">gal_file_unpadded.gal";
	print GALFILE $oGal_File->file_string;
	close GALFILE;

If whole rows/columns of padding are found and removed, and the original GAL file has block coordinate information in the header, the GAL module will throw an error during output, warning that the number of rows/columns it has found differs from what is recorded in the header. Don't worry, this is acceptable behaviour. 

=head1 METHODS

=over

=item B<get_spot_name>, B<get_spot_id>

Returns the Name/ID of a spot feature. Spot coordinates defined by passing (in order) a block, column and row value. 

=item B<set_spot_name>, B<set_spot_id>

Set the Name/ID of a spot feature.  

=item B<file_format>, B<file_version>

The first two values at the top of your GAL file (typically C<'ATF 1'>)

=item B<header_rows>, B<data_cols>

The next two values at the top of your GAL file - the number of rows in the header, and the number of columns of data

=item B<block_count>, B<spot_count>

Returns the number of blocks/spots on the array

=item B<block_x_origin>, B<block_y_origin>

The x,y coordinates of the start of a specified block passed to the method

=item B<block_feature_diameter>

The diameter in microns of features (spots) in a specified block

=item B<feature_diameter>

As above, but across the whole array. Returns spot diameter (in microns) if the same in all blocks, otherwise returns -1

=item B<block_x_features>, B<block_y_features>

The number of features (spots) in each column (x) or row (y) of a specified block, as described in the header block info (if present)

=item B<counted_rows>, B<counted_cols>

As above, but the actual counted values of a specified block, rather than those described in the header block info

=item B<row_count>, B<column_count>

As above, but across the whole array. Returns the number if all blocks are the same, otherwise returns -1

=item B<block_x_spacing>, B<block_y_spacing>

The spacing in microns between features (spots) in a specified block passed to the method

=item B<x_spacing>, B<y_spacing>

As above, but across the whole array. Returns the value (in microns) if all blocks are the same, otherwise returns -1

=item B<file_string>

Output the object's GAL file data as a text string.  

=back

=head1 TESTING

This distribution does not include a GAL file for testing purposes, since the one used for the test is very large. If you would like to run the full test you can download the file at L<http://www.instituteforwomenshealth.ucl.ac.uk/trl/pipeline/download.html>.  

=head1 SEE ALSO

L<Microarray|Microarray>, L<Microarray::File|Microarray::File>

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/AcademicResearch/Cancer/trl>

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

