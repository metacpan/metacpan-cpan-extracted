package LIMS::MT_Plate;

use 5.006;
use strict;
use warnings;
use Exporter;
our @ISA = qw( Exporter );
our $VERSION = '1.17';


{ package plate;

	use overload '<' => \&lt_format_comparison,
	             '>' => \&gt_format_comparison,
	             '^' => \&eq_format_comparison,
	             '""' => \&plate_contents;

	# The constructor
	sub new {
		my $class = shift;
		my $self = { };
		bless $self, $class;
		if (@_) {
			$self->barcode(shift);
		}
		
		# Without any wells, this plate is just a slab of plastic....
		$self->make_wells;
		return $self;
	}
	sub DESTROY {
		my $self = shift;
	}
	# getter and setter for the plate barcode
	sub barcode {
		my $self = shift;
		if (@_)	{
			$self->{ _barcode } = shift;
		} elsif ($self->{ _barcode }) {
			$self->{ _barcode };
		} else {
			'not set';
		}
	}
	# the number of wells that have a sample in them
	# getter for _wells_filled
	# no setter - automated by count_filled_wells()
	sub wells_filled {
		my $self = shift; 
		unless (defined $self->{ _wells_filled }){
			$self->count_filled_wells;
		}
		$self->{ _wells_filled };
	}
	sub samples_in_rowcol {
		my $self = shift;
		my $rowcol = shift;
		my $hRowCols_Filled = $self->rowcols_filled;
		$hRowCols_Filled->{ $rowcol };
	}
	sub rowcol_autoincr {
		my $self = shift;
		my $hRowCols_Filled = $self->rowcols_filled;
		while (my $rowcol = shift){
			$hRowCols_Filled->{ $rowcol }++;
		}
	}
	sub add_to_rowcol {
		my $self = shift;
		my $rowcol = shift;
		my $hRowCols_Filled = $self->rowcols_filled;
		$hRowCols_Filled->{ $rowcol } += shift;
	}
	sub set_rowcol_count {
		my $self = shift;
		my $rowcol = shift;
		my $hRowCols_Filled = $self->rowcols_filled;
		$hRowCols_Filled->{ $rowcol } = shift;
	}
	# count of number of samples in each row or col
	sub rowcols_filled {
		my $self = shift;
		unless (defined $self->{ _rowcols_filled }){
			$self->count_filled_wells;
		}
		return $self->{ _rowcols_filled };
	}
	# returns undef if there are samples in the rowcol, 1 if its empty
	sub rowcol_is_empty {
		my $self = shift;
		if ($self->samples_in_rowcol(shift)){
			return;
		} else {
			return 1;
		}
	}
	sub rowcol_well_counts {
		my $self = shift;
		my $rowcol = shift;
		my $wells_filled = $self->samples_in_rowcol($rowcol);
		my $wells;
		if ($self->row_or_col($rowcol) eq 'row'){
			$wells = $self->cols;		# number of cols
		} elsif ($self->row_or_col($rowcol) eq 'col'){
			$wells = $self->rows;	# number of rows
		} else {
			die "LIMS::MT_Plate ERROR: $rowcol is not a row or column name\n";
		}
		return ($wells,$wells_filled);		
	}
	# returns the number of empty wells
	# can use as defined if not full, undef if full
	sub rowcol_not_full {
		my $self = shift;
		my ($wells,$wells_filled) = $self->rowcol_well_counts(shift);	
		return $wells - $wells_filled;
	}
	# returns 1 if full, undef otherwise
	sub rowcol_is_full {
		my $self = shift;
		my ($wells,$wells_filled) = $self->rowcol_well_counts(shift);	
		if ($wells == $wells_filled){
			return 1;
		} else {
			return;
		}
	}
	sub reset_rowcols_filled {
		my $self = shift;
		$self->{ _rowcols_filled } = { };
	}
	# this sub counts the number of wells containing a sample
	# and sets the _wells_filled value
	sub count_filled_wells {
		my $self = shift;
		$self->reset_rowcols_filled;
		my $aCols = $self->col_names;	# array_ref of column names
		my $aRows = $self->row_names;	# array_ref of row names
		my $wells_filled = 0;
		for my $row (@$aRows) {
			for my $col (@$aCols) {
				if ($self->well_referenced("$row$col") || ($self->get_sample_name("$row$col") ne 'empty')){
					$wells_filled++;
					$self->rowcol_autoincr($row,$col);
				}
			}
		}
		$self->set_filled_wells($wells_filled);	# set _wells_filled
	}
	sub incr_filled_wells {
		my $self = shift;
		$self->{ _wells_filled }++;
	}
	sub set_filled_wells {
		my $self = shift;
		$self->{ _wells_filled } = shift;
	}
	sub add_filled_wells {
		my $self = shift;
		$self->{ _wells_filled } += shift;
	}
	# wells are 'referenced' if marked as an 'offset' in the array_pipeline plate table
	# if referenced wells are 'blocked' it means it can't be used as an offset for that 
	# plate again, and hence can't be 'filled' in a plate merge, even if its actually empty
	sub well_is_referenced {
		my $self = shift;
		my $well = shift;
		$self->{ "_$well"."_referenced" }++
	}
	sub well_referenced {
		my $self = shift;
		my $well = shift;
		$self->{ "_$well"."_referenced" };
	}
	# use this method to fill a single well only
	sub fill_well {
		my $self = shift;
		my $well = shift;
		my $sample = shift;
		return if ($sample eq 'empty');
		die "LIMS::MT_Plate ERROR: Incorrect usage of method 'fill_well()'\n"
			if (ref $sample);	# sample must be a scalar

		$well = $self->check_wells($well);	#Êmake sure the user defined well is valid
		if ($self->get_sample_name($well) eq 'empty'){
			$self->{ "_$well" } = $sample;		# fill the well
			$self->incr_filled_wells;			# add to _wells_filled 
		} else {
			if ($self->wells_are_replaced){
				if ($self->wells_are_replaced == 2){
					my $contents = $self->get_sample_name($well);
					warn "Not allowed to replace sample '$contents' of plate '".$self->barcode."'in well '$well' with sample '$sample'\n";
					return;
				} else {
					$self->{ "_$well" } = $sample;		# replace the contents of the well
				}
			} else {
				my $contents = $self->get_sample_name($well);
				die "LIMS::MT_Plate ERROR: Not allowed to replace sample '$contents' of plate '".$self->barcode."' in well '$well' with sample '$sample'\n";
			}
		}
		if (@_) { $self->sample_type($well,shift) }
	}
	sub empty_well {
		my $self = shift;
		my $well = shift;
		$well = $self->check_wells($well);	#Êmake sure the user defined well is valid
		my $sample = $self->get_sample_name($well);
		$self->{ "_$well" } = 'empty';
		return $sample;
	}
	## following three methods are second attempt at importing sample file
	# using the MT_Plate_File object
	# and a spreadsheet format describing well contents
	sub mt_plate_file {
		require LIMS::MT_Plate_File;
		my $self = shift;
		if(@_) {
			my $file_type = shift;
			$self->{ _sample_file } = $file_type->new(shift,shift);	# file name, filehandle
		} 
		$self->{ _sample_file };
	}
	sub import_mt_plate_file {
		my $self = shift;
		$self->mt_plate_file(shift,shift,shift);	# shifting file type, file name/path, filehandle
		$self->import_mt_file_data;
	}
	sub import_mt_file_data {
		my $self = shift;
		my $oSample_File = $self->mt_plate_file;
		die "LIMS::MT_Plate ERROR: The plate type described in the sample file does not match that of the MT_Plate object\n" 
			unless ($oSample_File->plate_type eq ref $self);
		$self->fill_wells($oSample_File->get_all_wells,$oSample_File->get_all_samples,$oSample_File->get_all_sample_types);
	}
	# use this method to fill a range of wells with a number of samples
	# will either accept a range of wells, specified as a start and end well, or an array ref of well names
	sub fill_wells {
		my $self = shift;
		my ($aWells,$aSamples,$aSample_Types);
		if (@_ == 1) {
			$aWells = $self->well_names;
			$aSamples = shift;
		} elsif (@_ == 2) {
			$aWells = shift;
			die "LIMS::MT_Plate ERROR: Incorrect usage (A) of method 'fill_wells()'\n"
				unless (ref $aWells);	# list of well names must be an array reference
			$aSamples = shift;
		} elsif (@_ == 3) {
			my $shifted = shift;
			if (ref $shifted){
				$aWells = $shifted;
				$aSamples = shift;
				$aSample_Types = shift;
			} else {
				my $start_well = $shifted;
				my $end_well = shift;
				die "LIMS::MT_Plate ERROR: Incorrect usage (B) of method 'fill_wells()'\n"
					if ( (ref $start_well)||(ref $end_well) );	# defined wells must be scalars
				$aWells = $self->get_range_wells($start_well,$end_well);	# array_ref of well names in the specified range
				$aSamples = shift;
			}	
		} else {
			die "LIMS::MT_Plate ERROR: Incorrect usage (C) of method 'fill_wells()'\n";
		}
		$aWells = $self->check_wells($aWells);
		
		die "LIMS::MT_Plate ERROR: Incorrect usage (D) of method 'fill_wells()'\n"
			unless (ref $aSamples);	# samples must be an array reference
		die "LIMS::MT_Plate ERROR: Well number must be greater or equal to the sample number, in method 'fill_wells()'\n"
			unless (@$aWells >= @$aSamples);	# must have >= wells than samples

		for (my $i=0; $i<@$aSamples; $i++) {	# scroll through the samples....
			if ($aSample_Types){
				$self->fill_well($$aWells[$i],$$aSamples[$i],$$aSample_Types[$i]);	# ...and fill a well with a sample
			} else {
				$self->fill_well($$aWells[$i],$$aSamples[$i]);	# ...and fill a well with a sample
			}
		}
	}
	
	#Êsplits the column number and the row letter
	sub get_well_coords {
		my $well = shift;
		
		my ($row,$col) = (uc $well, uc $well);
		$row =~ s/\d//g; # remove numbers
		$col =~ s/\D//g; # remove letters
		$col =~ s/^0//; # remove leading zero
		return ($row,$col);	
	}
	
	# method that returns an array_ref containing the well names
	# in the same order as the well_format
	sub well_names {
		my $self = shift;
	
		if ($self->well_format eq 'row') {		# scroll through rows, then columns
			return $self->well_names_xrow;
		} else {	# scroll through columns, then rows
			return $self->well_names_xcol;
		} 
	}
		
	# returns an array_ref containing all well names specified by a start/end range
	sub get_range_wells {
		my $self = shift;
		my $start_well = shift;
		my $end_well = shift;

		# determine the output format i.e. row-by-row, or col-by-col
		#my $format = sample_order_format($start_well,$end_well);
		my $format = $self->well_format;
		my ($start_row,$start_col) = get_well_coords($start_well);	
		my ($end_row,$end_col) = get_well_coords($end_well);
		
		# check the wells are valid	
		$start_well = $self->check_wells($start_well);
		$end_well = $self->check_wells($end_well);
		
		my $aCols = $self->col_names;	# array_ref of column names
		my $aRows = $self->row_names;	# array_ref of row names

		my @aWells = ();
		my $start = 0;
		
		if ($format eq 'row') {	#Êscroll through rows, then columns
			ROW:for my $row (@$aRows) {
				$start++ if ($row eq $start_row);	# we're in the start row
				next ROW if ($start == 0);			# we haven't yet reached the start row
				COL:for my $col (@$aCols) {	
					$start++ if ($col == $start_col);	# we're in the start column
					next COL if ($start < 2);		# not at the start column yet
					push(@aWells,"$row$col");		#Êif we get this far, its in the well range
					last ROW if (($col == $end_col)&&($row eq $end_row));	# reached the last well, so finish 
				}
			}
		} else {	# scroll through columns, then rows
			COL:for my $col (@$aCols) {	
				$start++ if ($col == $start_col);	# we're in the start column
				next COL if ($start == 0);			#Êwe haven't yet reached the start column
				ROW:for my $row (@$aRows) {
					$start++ if ($row eq $start_row);	# we're in the start row
					next ROW if ($start < 2);		# not at the start row yet
					push(@aWells,"$row$col");		#Êif we get this far, its in the well range
					last COL if (($row eq $end_row)&&($col == $end_col));	# reached the last well, so finish 
				}
			}
		}
		return \@aWells;
	}
	
	# checks that a well or well-range is compatible with the specified plate format
	sub check_wells {
		my $self = shift;
		my $well = shift;
		
		if (ref $well) {	#Êuser has passed a ref, so must be an array_ref of well names
			my @aWells;
			for my $a_well (@$well) {	# scroll through the wells
				my ($row,$col) = get_well_coords($a_well);	# split the well name
				if ($self->{ "_$row$col" }){	# the well exists
					push (@aWells, "$row$col");	# so add it to the return array
				} else {	#Êdie if the well doesn't exist
					die "LIMS::MT_Plate ERROR: Invalid well '$a_well'\n";
				}		
			}
			return \@aWells;
		}
		
		my ($row,$col) = get_well_coords($well);	# got this far, so $well is a scalar, single well
		die "LIMS::MT_Plate ERROR: Invalid well '$well' in  check wells()\n"
			unless ($self->{ "_$row$col" });	#Êdie if the well doesn't exist
		
		return "$row$col";	# return the correctly formatted well
	}
	
	# creates the hash keys for the plate wells and set their value to 'empty'
	# finishes by setting _wells_filled to 0 
	sub make_wells {
		my $self = shift;
		
		my $aCols = $self->col_names;	# array_ref of column names
		my $aRows = $self->row_names;	# array_ref of row names
		
		for my $row (@$aRows) {
			for my $col (@$aCols) {
				$self->{ "_$row$col" } = 'empty';
			}
		}
		$self->{ _wells_filled } = 0;
	}
	#Êspecifies how the well order is defined - by row or by col
	sub well_format {
		my $self = shift;
		if (@_) {
			my $format = shift;
			die "LIMS::MT_Plate ERROR: Invalid well format specified\n"
				unless (($format eq 'row') ||
						($format eq 'col'));
			$self->{ _well_format } = $format;
		} else {
			if (defined $self->{ _well_format }){
				return $self->{ _well_format };
			} else {
				return 'row';
			}
		}
	}
	sub row_by_row {
		my $self = shift;
		$self->well_format('row');
	}
	sub col_by_col {
		my $self = shift;
		$self->well_format('col');
	}
	# returns the sample name for a given well
	sub get_sample_name {
		my $self = shift;
		my $well = uc shift;		
		die "LIMS::MT_Plate ERROR: Invalid well ($well), in method get_sample_name()\n"
			unless ($self->{ "_$well" });
		return $self->{ "_$well" };
	}
	sub get_sample_names {
		my $self = shift;
		my $aWells = shift;
		my @aSamples = ();
		for my $well (@$aWells){
			push (@aSamples,$self->get_sample_name($well));
		}
		return \@aSamples;
	}
	# returns an array ref containing all sample names
	# will accept an argument specifying whether the order of wells
	# is row-by-row, or col-by-col. 
	# If no argument, then row-by-row defaults
	sub all_samples {
		my $self = shift;
		
		my $return_format;
		my @aSamples;
		
		if (@_) {
			$return_format = lc shift;
		} else {
			$return_format = 'row';
		}
		die "LIMS::MT_Plate ERROR: Invalid sample format specified\n"
			unless (($return_format eq 'row') ||
					($return_format eq 'col'));
		
		my $aCols = $self->col_names;	# array_ref of column names
		my $aRows = $self->row_names;	# array_ref of row names
		
		if ($return_format eq 'row') {	# scroll through rows, then columns
			for my $row (@$aRows) {
				for my $col (@$aCols) {
					push (@aSamples, $self->get_sample_name("$row$col"));		# add it to the return array
				}
			}
		} else {	# scroll through columns, then rows
			for my $col (@$aCols) {
				for my $row (@$aRows) {
					push (@aSamples, $self->get_sample_name("$row$col"));		# add it to the return array
				}
			}
		}
		return \@aSamples;
	}
	# returns an array ref containing all empty wells
	# will accept an argument specifying whether the order of wells
	# is row-by-row, or col-by-col. 
	# If no argument, then row-by-row defaults
	sub wells_empty {
		my $self = shift;
		
		my $return_format;
		my @aEmpty_Wells;
		
		if (@_) {
			$return_format = lc shift;
		} else {
			$return_format = 'row';
		}
		die "LIMS::MT_Plate ERROR: Invalid sample format specified\n"
			unless (($return_format eq 'row') ||
					($return_format eq 'col'));
		
		my $aCols = $self->col_names;	# array_ref of column names
		my $aRows = $self->row_names;	# array_ref of row names
		
		if ($return_format eq 'row') {	# scroll through rows, then columns
			for my $row (@$aRows) {
				for my $col (@$aCols) {
					push (@aEmpty_Wells, "$row$col") if ($self->get_sample_name("$row$col") eq 'empty');		# add it to the return array
				}
			}
		} else {	# scroll through columns, then rows
			for my $col (@$aCols) {
				for my $row (@$aRows) {
					push (@aEmpty_Wells, "$row$col") if ($self->get_sample_name("$row$col") eq 'empty');		# add it to the return array
				}
			}
		}
		return \@aEmpty_Wells;
	}
	# late in the day - getting very lazy
	# should re-write the previous method and this next one
	# but copy, paste, and change one line is quicker!
	sub filled_wells {
		my $self = shift;
		
		my $return_format;
		my @aFilled_Wells;
		
		if (@_) {
			$return_format = lc shift;
		} else {
			$return_format = 'row';
		}
		die "LIMS::MT_Plate ERROR: Invalid sample format specified\n"
			unless (($return_format eq 'row') ||
					($return_format eq 'col'));
		
		my $aCols = $self->col_names;	# array_ref of column names
		my $aRows = $self->row_names;	# array_ref of row names
		
		if ($return_format eq 'row') {	# scroll through rows, then columns
			for my $row (@$aRows) {
				for my $col (@$aCols) {
					push (@aFilled_Wells, "$row$col") unless ($self->get_sample_name("$row$col") eq 'empty');		# add it to the return array
				}
			}
		} else {	# scroll through columns, then rows
			for my $col (@$aCols) {
				for my $row (@$aRows) {
					push (@aFilled_Wells, "$row$col") unless ($self->get_sample_name("$row$col") eq 'empty');		# add it to the return array
				}
			}
		}
		return \@aFilled_Wells;
	}
	sub sample_type {
		my $self = shift;
		my $well = uc shift;
		@_	?	$self->{ "_type_$well" } = shift
			:	$self->{ "_type_$well" };
	}
	#Êget_set for sample types
	#Êif no arg passed, will return arrayref of all sample types
	# if scalar passed, sets all sample types to that type
	#Êif array passed, sets types to array item values, row by row
	sub all_sample_types {
		my $self = shift;
		my $samples_type;
		my @aSample_Types;
		if (@_) {
			$samples_type = shift;
		}
		my $aCols = $self->col_names;	# array_ref of column names
		my $aRows = $self->row_names;	# array_ref of row names
		for my $row (@$aRows) {
			for my $col (@$aCols) {
				if ($samples_type){
					if (ref $samples_type){
						my $type = shift @$samples_type;
						$self->sample_type("$row$col",$type) if ($type);
					} else {
						$self->sample_type("$row$col",$samples_type);
					}
				} else {
					push (@aSample_Types, $self->sample_type("$row$col"));		# add it to the return array
				}
			}
		}
		return \@aSample_Types unless ($samples_type);
	}
	sub get_sample_types {
		my $self = shift;
		my $aWells = shift;
		my @aSample_Types = ();
		for my $well (@$aWells){
			my $sample_type = $self->sample_type($well);
			push (@aSample_Types,$sample_type);
		}
		return \@aSample_Types;
	}
	#Êjoins a number of plates of one format into a plate of a larger format
	#Êwill currently only join by quadrants
	sub join_plates {
		my $self = shift;
		my @aSamples 		= ();
		my $plate_num 		= @_; 					# how many plates we're joining together
		my $source_format 	= $_[0]->wells;			# format of the first plate in the list
		
		die "LIMS::MT_Plate ERROR: Must join plates into a larger format!\n"
			unless ($source_format < $self->wells);
		die "LIMS::MT_Plate ERROR: Can't join plates - too many wells for the end format\n" 
			if (($plate_num * $source_format) > $self->wells);

		my $aOffsets = $self->get_well_offsets($source_format);	# correctly ordered well names, taking account of the offset between the plate formats
		while (@_) {
			my $plate = shift;
			die "LIMS::MT_Plate ERROR: The source plates for a plate join must all be the same format\n"
				unless ($source_format == $plate->wells);
			my $aSource_Wells = $plate->well_names;
			for my $well (@$aSource_Wells) {
				my $destination_well = shift @$aOffsets;
				my $sample = $plate->get_sample_name($well);
				next if ($sample eq 'empty');
				$self->fill_well($destination_well,$sample,$plate->sample_type($well));
			}
		}
	}
	
	sub add_plate {
		my $self = shift;
		my $plate = shift;
		my $offset = uc shift;
	
		if ($plate->wells == 1) {
			$self->fill_well($offset,$plate->get_sample_name('A1'),$plate->sample_type('A1'));
			return;
		} elsif ( ($self->wells == 384) && ($plate->wells == 96) ) {		
			my $aOffsets = $self->get_well_offsets($plate->wells);	# correctly ordered well names, taking account of the offset between the plate formats
			my @aSpliced_Offset;
			
			if ($offset eq 'A1') {
				@aSpliced_Offset = splice @$aOffsets,0,96;
			} elsif ($offset eq 'A2') {
				@aSpliced_Offset = splice @$aOffsets,96,96;
			} elsif ($offset eq 'B1') {
				@aSpliced_Offset = splice @$aOffsets,192,96;
			} elsif ($offset eq 'B2') {
				@aSpliced_Offset = splice @$aOffsets,288,96;
			} else {
				die "LIMS::MT_Plate ERROR: Invalid offset ($offset) passed to method 'add_plate()'\n";
			}
			my $aSource_Wells = $plate->well_names;
			for my $well (@$aSource_Wells) {
				my $destination_well = shift @aSpliced_Offset;
					my $sample = $plate->get_sample_name($well);
					next if ($sample eq 'empty');
					$self->fill_well($destination_well,$sample,$plate->sample_type($well));
			}
		} else {
			die "LIMS::MT_Plate ERROR: MT_Plate currently only supports adding 96-well plates to 384-well plates\n";
		}
	}
	# no check of plate formats here - like for like wells are combined
	# can specify wells in 'self' that are to be combined with wells in second plate
	sub combine_plates {
		my $self = shift;
		my $plate = shift;
		my $aWells;
		if (@_){	# specifying wells to be combined
			$aWells = shift;
		} else {	# assume all wells to be combined
			$aWells = $plate->well_names;
		}
		for my $well (@$aWells){
			next if ($plate->get_sample_name($well) eq 'empty');
			$self->fill_well($well,$plate->get_sample_name($well));
			$self->sample_type($well,$plate->sample_type($well));
		}
	}
	# are we allowed to over-write the contents of a plate? 
	sub can_replace {
		my $self = shift;
		$self->wells_are_replaced(1);
	}
	sub dont_replace {
		my $self = shift;
		$self->wells_are_replaced(0);
	}
	sub warn_dont_replace {
		my $self = shift;
		$self->wells_are_replaced(2);
	}
	sub wells_are_replaced {
		my $self = shift;
		@_	?	$self->{ _can_combine } = shift
			:	$self->{ _can_combine };
	}
	sub skip_filled_wells {
		my $self = shift;
		@_	?	$self->{ _skip_filled_wells } = shift
			:	$self->{ _skip_filled_wells };
	}
	sub dont_skip_wells {
		my $self = shift;
		$self->skip_filled_wells(0);
	}
	sub can_skip_wells {
		my $self = shift;
		$self->skip_filled_wells(1);
	}
	# similar to combine_plates, but one row at a time
	sub fill_row {
		my $self = shift;
		my $row = shift;		# row in self to be filled
		my $aSamples = shift;		# samples
		my $aCols = $self->col_names;	# array_ref of column names
		for my $col (@$aCols){
			if (my $sample = shift @$aSamples){
				next if ($sample eq 'empty');
				$self->fill_well("$row$col",$sample);		# add sample to this plate
			} else {
				return;
			}
		}
	}
	# similar to combine_plates, but one col at a time
	sub fill_col {
		my $self = shift;
		my $col = shift;		# col in self to be filled
		my $aSamples = shift;		# samples
		my $aRows = $self->row_names;	# array_ref of column names
		for my $row (@$aRows){
			if (my $sample = shift @$aSamples){
				next if ($sample eq 'empty');
				$self->fill_well("$row$col",$sample);		# add sample to this plate
			} else {
				return;
			}
		}
	}
	sub fill_rows {
		my $self = shift;
		my $aRows = shift;		# rows in self to be filled
		my $aSamples = shift;		# samples
		for my $row (@$aRows){
			$self->fill_row($row,$aSamples);
		}
	}
	sub fill_cols {
		my $self = shift;
		my $aCols = shift;		# cols in self to be filled
		my $aSamples = shift;		# samples
		for my $col (@$aCols) {
			$self->fill_col($col,$aSamples); 
		}
	}
	# returns array ref of a row's contents
	sub row_contents {
		my $self = shift;
		my $row = shift;
		my $aCols = $self->col_names;	# array_ref of column names
		my @aSamples;
		for my $col (@$aCols){
			push (@aSamples, $self->get_sample_name("$row$col"));		# add it to the return array
		}
		return \@aSamples;
	}
	# returns an array ref of a col's contents
	sub col_contents {
		my $self = shift;
		my $col = shift;
		my $aRows = $self->row_names;	# array_ref of column names
		my @aSamples;
		for my $row (@$aRows){
			push (@aSamples, $self->get_sample_name("$row$col"));		# add it to the return array
		}
		return \@aSamples;
	}
	sub rows_contents {
		my $self = shift;
		my $aRows = shift;
		my @aSamples;
		for my $row (@$aRows){
			my $aRow_Samples = $self->row_contents($row);
			push (@aSamples,@$aRow_Samples);
		}
		return \@aSamples;
	}
	sub cols_contents {
		my $self = shift;
		my $aCols = shift;
		my @aSamples;
		for my $col (@$aCols){
			my $aCol_Samples = $self->col_contents($col);
			push (@aSamples,@$aCol_Samples);
		}
		return \@aSamples;
	}
	sub is_row {
		my $self = shift;
		my $row = shift;
		my $hRow_Names = $self->row_names_hash;
		return $hRow_Names->{ $row };
	}
	sub is_col {
		my $self = shift;
		my $col = shift;
		my $hCol_Names = $self->col_names_hash;
		return $hCol_Names->{ $col };
	}
	sub row_or_col {
		my $self = shift;
		my $rowcol = shift;
		if ($self->is_row($rowcol)){
			return 'row';
		} elsif ($self->is_col($rowcol)){
			return 'col';
		} else {
			return;
		}
	}
	# produce the well name list for plates in a quadrant offset
	sub get_well_offsets {
		my $self = shift;
		my $source_format = shift;
		
		if ($source_format == 1) {	# samples from tubes will be transferred in linear order
			return $self->well_names_xrow;
		} elsif ( $source_format == 96 ) {
			my $self_format = $self->wells;
			my $aRows = $self->row_names;
			my $aCols = $self->col_names;
			my $offset;		
			my @aOffsets = ();
			if ( ($self->wells)/$source_format == 4 ) {	# 96->384, or 384->1536
				$offset = 2;
			} elsif ( ($self->wells)/$source_format == 16 ) { # 96->1536
				die "LIMS::MT_Plate ERROR: MT_Plate currently does not support 1536-well offsets\n";
			} 	
			ROW_OFFSET:for (my $i=0; $i<=1; $i++) {
				COL_OFFSET:for (my $k=0; $k<=1; $k++) {
					ROW:for ( my $row=0+$i; $row<@$aRows; $row+=$offset ) {
						COL:for ( my $col=0+$k; $col<@$aCols; $col+=$offset ) {
							my $well = $$aRows[$row].$$aCols[$col];
							push (@aOffsets,$well);
						}
					}
				}
			}
			return \@aOffsets;		
		} else {	# in case we add different format plates without adapting this method
			die "LIMS::MT_Plate ERROR: Can't make offsets for the specified plate formats\n";
		}
	}
	
	# returns ref to an array containing well names
	# ordered row-by-row
	sub well_names_xrow {
		my $self = shift;
		
		my $aRows = $self->row_names;
		my $aCols = $self->col_names;
		my @aWell_Names = ();
		for my $row (@$aRows) {
			for my $col (@$aCols) {
				push (@aWell_Names, "$row$col");
			}
		}	
		return \@aWell_Names;
	}
	
	# returns ref to an array containing well names
	# ordered col-by-col
	sub well_names_xcol {
		my $self = shift;
		
		my $aRows = $self->row_names;
		my $aCols = $self->col_names;
		my @aWell_Names = ();
		for my $col (@$aCols) {
			for my $row (@$aRows) {
				push (@aWell_Names, "$row$col");
			}
		}	
		return \@aWell_Names;
	}
	sub sort_plate_wells {
		my $a_row = $a;
		$a_row =~ s/\d//;
		my $a_col = $a;
		$a_col =~ s/\D//;
		
		my $b_row = $b;
		$b_row =~ s/\d//;
		my $b_col = $b;
		$b_col =~ s/\D//;
		
		if ($a_row eq $b_row){
			return ($a_col <=> $b_col);
		} else {
			return ($a_row cmp $b_row);
		}
	}	
	# clone an object
	sub clone_plate {
		my $self = shift;
		bless {%$self}, ref $self;
	}


	#### overload operators ####
	
	# < operator compares plate formats
	sub lt_format_comparison {
		my $self = shift;
		my $plate = shift;
		
		($self->wells) < ($plate->wells);
	}
	# > operator compares plate formats
	sub gt_format_comparison {
		my $self = shift;
		my $plate = shift;
		
		($self->wells) > ($plate->wells);
	}
	# == operator compares plate formats
	sub eq_format_comparison {
		my $self = shift;
		my $plate = shift;
		
		($self->wells) == ($plate->wells);
	}
	sub plate_contents {
		my $self = shift;
		my $aWells = $self->well_names;
		for my $well (@$aWells) {
			print "$well; ",$self->get_sample_name($well),"\n";
		}
	}

}

# Class describing a single well tube
{ package tube;

	our @ISA = qw( plate );

	sub wells {
		1
	}
	sub rows {
		1
	}
	sub cols {
		1
	}
	sub row_names {
		['A']
	}
	sub col_names {
		[1]
	}
	sub row_names_hash {
		{A=>1}
	}
	sub col_names_hash {
		{1=>1}
	}
}

# Class describing a 96-well plate
{ package mt_96;

	our @ISA = qw( plate );

	sub wells {
		96
	}
	sub rows {
		8
	}
	sub cols {
		12
	}
	sub row_names {
		['A' .. 'H']
	}
	sub col_names {
		[1 .. 12]
	}
	sub row_names_hash {
		{A=>1,B=>1,C=>1,D=>1,E=>1,F=>1,G=>1,H=>1}
	}
	sub col_names_hash {
		{1=>1,2=>1,3=>1,4=>1,5=>1,6=>1,
		7=>1,8=>1,9=>1,10=>1,11=>1,12=>1}
	}
}

# Class describing a 384-well plate
{ package mt_384;

	our @ISA = qw( plate );

	sub wells {
		384
	}
	sub rows {
		16
	}
	sub cols {
		24
	}
	sub row_names {
		['A' .. 'P']
	}
	sub col_names {
		[1 .. 24]
	}
	sub row_names_hash {
		{A=>1,B=>1,C=>1,D=>1,E=>1,F=>1,G=>1,H=>1,
		I=>1,J=>1,K=>1,L=>1,M=>1,N=>1,O=>1,P=>1}
	}
	sub col_names_hash {
		{1=>1,2=>1,3=>1,4=>1,5=>1,6=>1,7=>1,8=>1,
		9=>1,10=>1,11=>1,12=>1,13=>1,14=>1,15=>1,16=>1,
		17=>1,18=>1,19=>1,20=>1,21=>1,22=>1,23=>1,24=>1}
	}
}

# Class describing a 1536-well plate
{ package mt_1536;

	our @ISA = qw( plate );

	sub wells {
		1536
	}
	sub rows {
		32
	}
	sub cols {
		48
	}
	sub row_names {
		['A' .. 'Z','AA','AB','AC','AD','AE','AF']
	}
	sub col_names {
		[1 .. 48]
	}
	sub row_names_hash {
		{A=>1,B=>1,C=>1,D=>1,E=>1,F=>1,G=>1,H=>1,
		I=>1,J=>1,K=>1,L=>1,M=>1,N=>1,O=>1,P=>1,
		Q=>1,R=>1,S=>1,T=>1,U=>1,V=>1,W=>1,X=>1,
		Y=>1,Z=>1,AA=>1,AB=>1,AC=>1,AD=>1,AE=>1,AF=>1}
	}
	sub col_names_hash {
		{1=>1,2=>1,3=>1,4=>1,5=>1,6=>1,7=>1,8=>1,
		9=>1,10=>1,11=>1,12=>1,13=>1,14=>1,15=>1,16=>1,
		17=>1,18=>1,19=>1,20=>1,21=>1,22=>1,23=>1,24=>1,
		25=>1,26=>1,27=>1,28=>1,29=>1,30=>1,31=>1,32=>1,
		33=>1,34=>1,35=>1,36=>1,37=>1,38=>1,39=>1,40=>1,
		41=>1,42=>1,43=>1,44=>1,45=>1,46=>1,47=>1,48=>1}
	}
}

{ package mt_plate;

	our @ISA = qw ( plate );
	
	sub new {
		my $class = shift;
		
		my ($barcode,$wells);
		if (@_ == 2) {
			$barcode = shift;
		}
		$wells = shift;
		die "LIMS::MT_Plate ERROR: No plate type defined for plate '$barcode'\nin method 'mt_plate->new()'\n" unless $wells;
		if ($wells == 1){
			$class = 'tube';
		} else {
			$class = "mt_$wells";
		}
		$class->new($barcode);
	}
}

1;
__END__

=head1 NAME

LIMS::MT_Plate - A Perl module for creating and manipulating micro-titre plate objects

=head1 SYNOPSIS

	use LIMS::MT_Plate;

	$oPlate = mt_plate->new('a plate with 96 wells',96);
	$oPlate->fill_wells(\@wells,\@samples);
	$sample_well_A1 = $oPlate->get_sample_name('A1');
	$aSamples_Ref = $oPlate->all_samples;

=head1 DESCRIPTION

LIMS::MT_Plate is a Perl module for creating and manipulating microtitre plate objects. It defines a Class of MT_Plate for each microtitre format, which include variables specific to the format and methods that are common to all. 

The most common use of MT_Plate is to enable the consistent assignment of multiple samples to wells of a microtitre plate while ensuring the plate layout is valid for the specified format, and also to more easily manage the transfer of samples from plate to plate. 

MT_Plate currently supports 96, 384 and 1536 well plate formats, as well as an individual tube, and provides methods for filling individual wells, and multiple wells. The filling of multiple wells supports either row-by-row (i.e. A1=sample1, A2=sample2, etc) or column-by-column ordering (i.e. A1=sample1, B1=sample2, etc), depending on the name format of the wells passed to the method C<fill_wells()> as described in the examples above. 

The identity of a sample in a single well can be returned, or alternatively all of the samples in the plate can be exported as a reference to an array. Similar to the filling of wells, the order of the samples returned in the array can be either row-by-row, or col-by-col, as described in the examples above. 

What the module won't do is re-order samples in a plate. The reasons for this might not be obvious to someone who doesn't work in a laboratory - but if you don't want to contaminate your samples that's basically a no-no. What you would do instead is transfer the samples from one plate to another, re-ordering them as you do so - and that's what you should do if you use MT_Plate. 

=head1 METHODS

=head2 Creating Plate Objects

There are two ways you can create an MT_Plate object

	$oPlate = mt_plate->new('a 96-well plate',96);
	$oPlate = mt_96->new('a 96-well plate');

In either case, the name (barcode) is optional, and can be set later

	$oPlate->barcode('another mt_plate');

Several different formats are currently supported, including a single-well plate (otherwise known as a tube).

	$oTube = tube->new('a microfuge tube');
	$oPlate = mt_384->new('a 384-well plate');
	$oPlate = mt_1536->new('a 1536-well plate');

=head2 Filling Wells

=head3 From a file

Most likely, you have a flat file naming all the samples in your plate, and you'd like to import that into an MT_Plate object. To do this you will need to install the L<Microarray|Microarray> modules, and use the module L<LIMS::MT_Plate_File|LIMS::MT_Plate_File>. First, create an MT_Plate object of the correct class and then use the C<import_mt_plate_file()> method to import the file;

	$oPlate->import_mt_plate_file('mt_plate_file',$file,$fh);	# shifting file type, file name/path, filehandle
	
The filehandle is an optional parameter to the C<import_mt_plate_file()> method, since a filehandle will be created so long as the correct path to the file is provided. However, for instances where the file path is not available but a filehandle is (for instance, following upload of a file on a web page) you can pass the file name and filehandle separately.  

=head3 Manually - single well

	$oPlate->fill_well('A1','sample1');

=head3 Manually - multiple wells

Samples are added to a plate by passing an array reference to the C<fill_wells()> function. In the simplest case, the wells are filled row-by-row (i.e. well A1 gets $samples[0], A2 gets $samples[1], etc). This is the default order for all functions. 

	$oPlate->fill_wells(\@samples);

You can also specify other well orders, or numbers of samples other than a full plate. A range of wells can be specified as shown in the first example below, and this format can be used to change the filling order to column-by-column, simply by turning round the well names (i.e. A1 gets $samples[0], B1 gets $samples[1], etc). Aternatively, you can set the order using the C<well_format()> method.

	$oPlate->fill_wells('A1','P24',\@samples);	# row-by-row filling
 	$oPlate->fill_wells('1A','24P',\@samples);	# col-by-col filling

If you have an array of appropriate well names, then this can be passed along with the samples such that the order of wells in the array will determine the filling order. 

	$oPlate->fill_wells(\@wells,\@samples);

Or you can fill by row or column name. Unlike C<fill_wells()> described above, each of these following methods actually removes samples from the C<'$aSamples'> list as they are added to a well.

	$oPlate->fill_row('A',$aSamples);
	$oPlate->fill_rows(['A'..'D'],$aSamples);
	$oPlate->fill_col(1,$aSamples);
	$oPlate->fill_cols([1..6],$aSamples);

By default, you can't replace the contents of a well that already has a sample in it, but you can override this, or reset as follows;

	$oPlate->can_replace;	# will replace a sample
	$oPlate->dont_replace;	# will die if asked to replace a sample
	$oPlate->warn_dont_replace;	# will warn if asked to replace a sample

If you use any of the well filling methods on a plate that already has samples in, while C<warn_dont_replace()> is set, then any sample asked to fill an already filled well will be missed out of the process to avoid filling the un-fillable well. 

=head3 Specifying sample type

You also can specify a C<'sample_type()'>, either for each individual well, or one type for the whole plate.

	$oPlate->fill_well('A1','sample','sample_type');		# by passing after the sample name in 'fill_well()'
	$oPlate->sample_type('A1','sample_type');		# or using 'sample_type()' after a well has been filled
	$oPlate->all_sample_types('sample_type');		# all samples are set the same
	$oPlate->all_sample_types(\@aSample_Types);		# different types set at once
	my $sample_type = $oPlate->sample_type('A1');
	my $aSample_Types = $oPlate->all_sample_types;

=head2 Identifying Plate Contents

=head3 Single well

	$sample = $oTube->get_sample_name;
	$sample = $oPlate->get_sample_name('A1');

=head3 Row or Column

	$aSamples = $oPlate->row_contents('A');
	$aSamples = $oPlate->rows_contents(['A'..'D']);
	$aSamples = $oPlate->col_contents(1);
	$aSamples = $oPlate->cols_contents([1..6]);

=head3 Whole plate

The entire contents of a plate can be returned as a reference to an array, either ordered row-by-row (ie A1, A2 etc) or column-by-column (ie A1, B1, etc). If no order is specified, row-by-row defaults. Can also set the return order using the C<well_format()> method.

	$aSamples_Ref = $oPlate->all_samples('row');	
	$aSamples_Ref = $oPlate->all_samples('col');	

Well names can be returned as an array ref

	$aWell_Names = $oPlate->well_names('row');
	$aWell_Names = $oPlate->well_names('col');

...allowing you to easily loop through all of the wells

	for my $well (@$aWell_Names) {
		print "well $well; ".$oPlate->get_sample_name($well)."\n";
	}

Finally, you can retrieve an array ref containing the sample names in a specified list of well names

	$aSamples = $oPlate->get_sample_names(\@aWells);

=head2 Joining Plates

Two or more plates can be combined into a larger format plate. Joining 4x 96, 4x 384, or 16x 96 places samples in quadrant offsets. When joining tubes into a plate format, the samples are ordered linearly, row-by-row.

	$oPlate->join_plates($oPlate1,$oPlate2,$oPlate3,$oPlate4);

Alternatively, two plates can be combined using the C<combine_plates()> method. This will simply replace the target object's well contents with those from a source plate passed to C<combine_plates()>. Empty wells in the source plate will not cause wells in the object plate being 'emptied' - only if there is a sample in the source will any change occur. You can also specify wells to be combined, rather than combining the whole plate. 

	$oPlate->combine_plates($oPlate2);			# whole plates are combined
	
	$aWells = ['A1,'A2','A3'];
	$oPlate->combine_plates($oPlate2,$aWells);	# only specific wells are combined

Finally, a 96-well plate can be added to a 384-well plate in a given quadrant. This is similar to executing the C<join_plates()> method, but only specifying one of the source plates.

	$oPlate->add_plate($oPlate2,'B1');

=head2 Comparisons

	if ($oPlate1 < $oPlate2) {
		print $oPlate1->barcode," is a smaller format than ",$oPlate2->barcode,"\n";
	} elsif ($oPlate1 > $oPlate2) {
		print $oPlate1->barcode," is a bigger format than ",$oPlate2->barcode,"\n";
	} elsif ($oPlate1 ^ $oPlate2) {
		print $oPlate1->barcode," and ",$oPlate2->barcode," are the same format\n";
	}

=head2 Other Methods 

Several other methods return variables associated with the object

=over

=item B<barcode>

Returns the plate barcode if no argument is passed

=item B<wells>

Returns the number of wells in the plate i.e. the plate format

=item B<cols>

Returns the number of columns in the plate

=item B<rows>

Returns the number of rows in the plate

=item B<wells_filled>

Returns the number of wells in the plate that have a sample in them

=item B<row_names>

Returns an array ref containing the row names

=item B<col_names>

Returns an array ref containing the column numbers

=back

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, UCL EGA Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/AcademicResearch/Cancer/trl>

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
