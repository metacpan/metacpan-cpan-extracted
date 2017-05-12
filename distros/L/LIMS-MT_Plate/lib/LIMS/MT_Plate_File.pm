package LIMS::MT_Plate_File;

use 5.006;
use strict;
use warnings;
our $VERSION = '1.12';

use Microarray::File;

{ package mt_plate_file;

	our @ISA = qw( simple_delimited_file );

	# standard format
	# required fields; well name, sample name, sample type

	sub sort_data {
		my $self = shift;
		my $aaData = shift;
		my $aCol_Headers = shift @$aaData;
		my $col_num = @$aCol_Headers;
		$self->column_num($col_num);
		$self->set_data_fields($aCol_Headers);
		$self->import_samples($aaData);		
	}
	sub import_samples {
		my $self = shift;
		my $aaData = shift;
		
		my $hhData_Rows = $self->get_data_rows;
		for my $aData_Row (@$aaData){		
			$self->set_well($aData_Row->[$self->well_index],
							$aData_Row->[$self->sample_index],
							$aData_Row->[$self->sample_type_index]);
			$self->count_well;
		}
	}
	sub set_well {
		my $self = shift;
		my $well = shift;
		$self->{ "_$well" } = shift;
		$self->{ "_$well"."_type" } = shift;
		$self->record_well($well);		
	}
	sub record_well {
		my $self = shift;
		my $aWells = $self->get_all_wells;
		push (@$aWells,shift);
	}
	sub get_all_wells {
		my $self = shift;
		unless (defined $self->{ _all_wells }){
			$self->{ _all_wells } = [ ];
		}
		$self->{ _all_wells };
	}
	sub get_sample {
		my $self = shift;
		my $well = shift;
		$self->{ "_$well" };
	}
	sub get_sample_type {
		my $self = shift;
		my $well = shift;
		$self->{ "_$well"."_type" };		
	}
	sub get_all_samples {
		my $self = shift;
		my $aWells = $self->get_all_wells;
		my $aSamples = [];
		for my $well (@$aWells){
			push (@$aSamples,$self->get_sample($well));
		}
		return $aSamples;
	}
	sub get_all_sample_types {
		my $self = shift;
		my $aWells = $self->get_all_wells;
		my $aSample_Types = [];
		for my $well (@$aWells){
			push (@$aSample_Types,$self->get_sample_type($well));
		}
		return $aSample_Types;
	}
	sub plate_barcode {
		my $self = shift;
		if (@_){
			$self->{ _plate_name } = shift;
		} else {
			if (defined $self->{ _plate_name }){
				return $self->{ _plate_name };
			} else {
				return $self->file_name;
			}
		}
	}
	sub plate_type {
		my $self = shift;
		if (@_){
			$self->{ _plate_type } = shift;
		} else {
			if (defined $self->{ _plate_type }){
				return $self->{ _plate_type };
			} else {
				return $self->guessed_plate_type;
			}
		}
	}
	sub guessed_plate_type {
		my $self = shift;
		unless (defined $self->{ _guessed_plate_type }){
			$self->guess_plate_type;
		}
		$self->{ _guessed_plate_type };
	}
	sub guess_plate_type {
		my $self = shift;
		my $aWells = $self->get_all_wells;
		my ($aRows,$aCols) = get_well_coords($aWells);
		my $last_row = uc $aRows->[-1];
		my $last_col = $aCols->[-1];
		my $plate_type;
		if (($last_row eq "A")&&($last_col == 1)){
			$plate_type = "tube";
		} elsif (($last_row le "H")&&($last_col <= 12)) {
			$plate_type = "mt_96";
		} elsif (($last_row le "P")&&($last_col <= 24)) {
			$plate_type = "mt_384";
		} elsif (($last_row le "AF")&&($last_col <= 48)) {
			$plate_type = "mt_1536";
		} else {
			die "LIMS::MT_Plate_File ERROR: Well name '$last_row$last_col' doesn't match supported plate formats";
		}
		$self->{ _guessed_plate_type } = $plate_type;
	}
	#Êsplits the column number and the row letter
	sub get_well_coords {
		my $aWells = shift;
		my @aRows = ();
		my @aCols = ();
		for my $well (@$aWells){
			my ($row,$col) = (uc $well, uc $well);
			$row =~ s/\d//g;
			$col =~ s/\D//g;
			push (@aRows,$row);
			push (@aCols,$col);
		}
		my @aSorted_Rows = sort @aRows;
		my @aSorted_Cols = sort @aCols;
		return (\@aSorted_Rows,\@aSorted_Cols);
	}	
	sub wells_imported {
		my $self = shift;
		$self->{ _wells_imported };
	}
	sub count_well {
		my $self = shift;
		$self->{ _wells_imported }++;
	}
	sub well_index {
		my $self = shift;
		$self->get_column_id('well');
	}
	sub sample_index {
		my $self = shift;
		$self->get_column_id('name');
	}
	sub sample_type_index {
		my $self = shift;
		$self->get_column_id('type');
	}
}

{ package simple_plate_file;

	our @ISA = qw( mt_plate_file );


}

{ package rowcol_plate_file;

	our @ISA = qw( mt_plate_file );

	sub import_samples {
		my $self = shift;
		my $aaData = shift;
		
		my $hhData_Rows = $self->get_data_rows;
		for my $aData_Row (@$aaData){
			my $well = $aData_Row->[$self->row_index].$aData_Row->[$self->col_index];
			$self->set_well($well,
							$aData_Row->[$self->sample_index],
							$aData_Row->[$self->sample_type_index]);
			$self->count_well;
		}
	}
	sub row_index {
		my $self = shift;
		if ($self->get_column_id('v1.1 96-well plate row')){
			return $self->get_column_id('v1.1 96-well plate row');
		} elsif ($self->get_column_id('Row')){
			return $self->get_column_id('Row');
		} elsif ($self->get_column_id('row')){
			return $self->get_column_id('row');
		} else {
			die "Can't find a column in the file that contains a 'Row' field\n";
		}
	}
	sub col_index {
		my $self = shift;
		if ($self->get_column_id('v1.1 96-well plate column')){
			return $self->get_column_id('v1.1 96-well plate column');
		} elsif ($self->get_column_id('Column')){
			return $self->get_column_id('Column');
		} elsif ($self->get_column_id('Col')){
			return $self->get_column_id('Col');
		} elsif ($self->get_column_id('column')){
			return $self->get_column_id('column');
		} elsif ($self->get_column_id('col')){
			return $self->get_column_id('col');
		} else {
			die "Can't find a column in the file that contains a 'Column' field\n";
		}
	}
	sub sample_index {
		my $self = shift;
		$self->get_column_id('International clone ID');
	}
	sub sample_type_index {
		my $self = shift;
		$self->get_column_id('Library');
	}
}

1;

__END__

=head1 NAME

LIMS::MT_Plate_File - A Perl module for managing microtitre plate file objects

=head1 SYNOPSIS

	use LIMS::MT_Plate_File;

	my $sample_file = mt_plate_file->new("/file.txt");


=head1 DESCRIPTION

LIMS::MT_Plate_File is an object-oriented Perl module for managing files describing the contents of a microtitre plate for import to the L<LIMS::MT_Plate|LIMS::MT_Plate> module. There are two classes of MT_Plate_File object - the C<mt_plate_file> class uses a single 'well' column to name the wells (e.g. 'A1') whereas the C<rowcol_plate_file> class uses two separate columns 'row' and 'col'.

=head1 METHODS

=over

=item B<get_sample, get_sample_type>

Pass these methods a well name to retrieve the sample name/type. 

=item B<get_all_samples, get_all_sample_types>

Returns an array ref of all sample names/types

=item B<plate_barcode, plate_type>

Returns the plate barcode/type, the latter assumed from well/row numbers

=item B<wells_imported>

The number of wells imported

=back

=head1 SEE ALSO

L<Microarray::File|Microarray::File>, L<LIMS::MT_Plate|LIMS::MT_Plate>

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, UCL EGA Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/AcademicResearch/Cancer/trl>

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
