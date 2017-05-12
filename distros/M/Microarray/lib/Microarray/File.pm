package Microarray::File;

use 5.006;
use strict;
use warnings;
our $VERSION = '1.24';

{ package microarray_file;

	sub new {
		my $class = shift;
		my $self = { };
		if (@_){
			$self->{ _file_name } = shift;		# shift in file name
			bless $self, $class;
			$self->set_filehandle(shift) if (@_);	# Fh is passed from CGI
			$self->import_data;
		} else {
			bless $self, $class;
		}
		return $self;
	}
	sub DESTROY {
		my $self = shift;
		if (defined $self->{ _filehandle }){
			my $filehandle = $self->{ _filehandle };
			close $filehandle;
		}
	}
	sub filehandle {
		my $self = shift;
		unless (defined $self->{ _filehandle }){
			$self->set_filehandle;
		}
		$self->{ _filehandle };
	}
	sub set_filehandle {	
		my $self = shift;
		if (@_){
			$self->{ _filehandle } = shift;
		} else {
			$self->{ _filehandle } = $self->create_filehandle;
		}
		$self->filehandle_is_set(1);
	}
	sub filehandle_is_set {
		my $self = shift;
		@_	?	$self->{ _filehandle_is_set } = shift
			:	$self->{ _filehandle_is_set };
	}
	sub create_filehandle {
		use FileHandle;
		my $self = shift;
		my $file_name = $self->file_name;
		my $filehandle = new FileHandle "< $file_name" or die 
			"Microarray::File ERROR: Could not create filehandle for '$file_name'\n$!\n";
		return $filehandle;
	}
	sub close_filehandle {
		my $self = shift;
    	my $filehandle = $self->filehandle;
		close $filehandle or die 
			"Microarray::File ERROR: Could not close filehandle\n$!\n";
	}
	sub reset_filehandle {
		my $self = shift;
		my $file_handle = $self->filehandle;
		close $file_handle or die "Microarray::File ERROR: Can't close filehandle\n";
		delete $self->{ _filehandle };
		delete $self->{ _filehandle_is_set };
	}		
	sub file_name {
		my $self = shift;
		@_	?	$self->{ _file_name } = shift
			:	$self->{ _file_name };
	}
	sub import_data {
		return;		# no default method in class microarray_file
	}
	sub get_header_info {
		my $self = shift;
		unless ( defined $self->{ _header_info } ){
			$self->set_header_info;
		}
		if (@_) {
			my $key = shift;
			my $hHeader_Info = $self->{ _header_info };
			return $hHeader_Info->{ $key };
		} else {
			$self->{ _header_info };
		}
	}
	sub get_header_keys {
		my $self = shift;
		my $hHeader_Info = $self->get_header_info;
		return keys %$hHeader_Info;
	}
}

{ package microarray_text_file;

	our @ISA = qw( microarray_file ); 

	sub set_source {
		my $self = shift;
		$self->{ _source } = $self->import_clean_source;
	}
	sub get_source {
		my $self = shift;
		unless (defined $self->{ _source }){
			$self->set_source;
		}
		$self->{ _source };
	}
	sub import_clean_source {
		my $self = shift;
		my $source;
		if ($self->filehandle_is_set){
			$source = $self->source_from_filehandle;
		} elsif ($self->file_name) {
			$source = $self->source_from_filename;
		} else {
			my $class = ref $self;
			die "Microarray::File::$class ERROR: No filehandle, file name or database BLOB was provided. Could not import\n";
		}
		$source =~ s/(?:\015{1,2}\012|\015|\012)/\n/gs;	# clean line ends
		$self->have_cleaned_ends(1);
		return $source;
	}
	sub source_from_filehandle {
		my $self = shift;
		my $file_handle = $self->filehandle;
		my $source = do { local($/); <$file_handle> };	# slurp in the file
		return $source;
	}
	sub source_from_filename {
		use File::Slurp;
		my $self = shift;
		File::Slurp::read_file( $self->file_name );
	}
	# import_data defaults to set_source
	sub import_data {
		my $self = shift;
		$self->set_source;
	}
	sub line_num {
		my $self = shift;
		@_	?	$self->{ _line_num } = shift
			:	$self->{ _line_num };
	}	
	# cleans line ends from different systems to standard /n
	sub clean_line_ends {
		my $self = shift;
		return if ($self->have_cleaned_ends);
		my $file_handle = $self->filehandle;
		my $file_name = $self->file_name;
		open (TEMPFILE, '>', "$file_name.temp") or die "Microarray::File ERROR: Can't open temp file for writing";
		while (<$file_handle>){
			my $input_line = $_;
			$input_line =~ s/(?:\015{1,2}\012|\015|\012)/\n/gs;		# clean line ends
			print TEMPFILE $input_line;
		}
		$self->reset_filehandle;
		close TEMPFILE or die "Microarray::File ERROR: Can't close the temp file";
		rename ("$file_name.temp",$file_name);
		$self->have_cleaned_ends(1);
	}
	sub have_cleaned_ends {
		my $self = shift;
		@_	?	$self->{ _have_cleaned_ends } = shift
			:	$self->{ _have_cleaned_ends };
	}

}

{ package delimited_file;

	# delimited file, but not a simple columnar format

	our @ISA = qw( microarray_text_file );

	# default load incorporates split on a delimiter, and line end cleaning
	sub load_file_data {
		my $self = shift;
		my $source = $self->get_source;
		my @aLines = split(/\n/,$source);
		my @aaArray_From_File;
		my $delimiter = $self->delimiter;
		foreach (@aLines){
			s/\"//g;
			my @aCells = split(/$delimiter/,$_);
			push (@aaArray_From_File, \@aCells);
		}
		return \@aaArray_From_File;
	}
	# parse_line extracted from Text::ParseWords and adapted
	# to return an array reference instead of an array
	sub parse_line {
		our $PERL_SINGLE_QUOTE;	
		no warnings;	# We will be testing undef strings
	    my($delimiter, $line) = @_;
	    my($word, @pieces);

	    while (length($line)) {
			$line =~ s/^(["'])			# a $quote
		        	    ((?:\\.|(?!\1)[^\\])*)	# and $quoted text
				    \1				# followed by the same quote
				   |				# --OR--
				   ^((?:\\.|[^\\"'])*?)		# an $unquoted text
				    (\Z(?!\n)|(?-x:$delimiter)|(?!^)(?=["']))  
				    				# plus EOL, delimiter, or quote
				  //xs or return;		# extended layout
			my($quote, $quoted, $unquoted, $delim) = ($1, $2, $3, $4);
			return() unless( defined($quote) || length($unquoted) || length($delim));

		    $unquoted =~ s/\\(.)/$1/sg;
		    if (defined $quote) {
				$quoted =~ s/\\(.)/$1/sg if ($quote eq '"');
				$quoted =~ s/\\([\\'])/$1/g if ( $PERL_SINGLE_QUOTE && $quote eq "'");
		    }
	        $word .= defined $quote ? $quoted : $unquoted;
	 
	        if (length($delim)) {
	            push(@pieces, $word);
	            undef $word;
	        }
	        if (!length($line)) {
	            push(@pieces, $word);
			}
	    }
	    return(\@pieces);
	}
	sub delimiter {
		my $self = shift;
		unless (defined $self->{ _delimiter }){
			$self->set_delimiter;
		}
		$self->{ _delimiter };
	}	
	sub set_delimiter { 
		my $self = shift;
		if ($self->file_name =~ /.csv$/i) {
			$self->{ _delimiter } = ",";
		} else {
			$self->{ _delimiter } = "\t";
		}
	}	
	
	### the following methods provide a key to store/retrieve
	### column headers from the file data
	
	# column headers of the data
	sub set_data_fields {
		my $self = shift;
		my $aData_Fields = shift;
		die "Data Fields were not loaded correctly. Maybe you chose the wrong data file type?\n" unless $aData_Fields;
		my $hData_Fields = { };
		for (my $i=0; $i < @$aData_Fields; $i++) {
			my $field = $$aData_Fields[$i];
			$$hData_Fields{ $field } = $i;
			$$hData_Fields{ $i } = $field;
		}
		$self->{ _data_fields } = $hData_Fields;	# column headers of the data
	}
	sub get_data_fields {
		my $self = shift;
		unless (defined $self->{ _data_fields }){
			my $aaData = $self->get_source;
			$self->set_data_fields(shift @$aaData);
		}
		$self->{ _data_fields };
	}
	# return column name from index, or vice versa
	sub get_column_id {
		my $self = shift;
		my $column_id = shift;
		my $hColumn_Id = $self->get_data_fields;
		$hColumn_Id->{ $column_id };
	}
	## copied from simple delimited file for quantarray_data package
  sub set_imported_data {
		my $self = shift;
		my $aaData = shift;
		$self->{ _imported_data } = $aaData;
	}
	sub get_imported_data {
		my $self = shift;
		$self->{ _imported_data };
	}
}

{ package simple_delimited_file;

	# simple delimited spreadsheet format, with a column header row
	 
	our @ISA = qw( delimited_file );

	sub import_data {
		my $self = shift;
		my $aaData = $self->load_file_data;	# from package delimited_file
		my $line_num = @$aaData;
		$self->line_num($line_num-1);	# ignore column header
		$self->sort_data($aaData);
	}
	sub sort_data {
		my $self = shift;
		my $aaData = shift;
		my $aCol_Headers = shift @$aaData;
		$self->set_imported_data($aaData);
		$self->column_num(scalar @$aCol_Headers);
		$self->set_data_fields($aCol_Headers);
	}
	sub set_imported_data {
		my $self = shift;
		my $aaData = shift;
		$self->{ _imported_data } = $aaData;
	}
	sub get_imported_data {
		my $self = shift;
		$self->{ _imported_data };
	}
	# count of the number of columns in the original data set
	sub column_num {
		my $self = shift;
		@_	?	$self->{ _column_num } = shift
			:	$self->{ _column_num };
	}
	# compares the number of fields returned by get_data_fields
	# with the number of columns in the original file
	# returns true if they are the same, false otherwise 
	sub check_col_numbers {
		my $self = shift;
		my $col_num = $self->column_num;
		my $hData_Fields = $self->get_data_fields;
		my $keys = keys %$hData_Fields;
		if ($col_num = $keys){
			return 1;
		} else {
			return;
		}
	}
	# hash ref to be filled with hash refs of row data
	sub get_data_rows {
		my $self = shift;
		unless (defined $self->{ _data_rows }){
			$self->{ _data_rows } = { };
		}
		$self->{ _data_rows };
	}
	sub get_data_row {
		my $self = shift;
		my $row = shift;
		my $hhData_Rows = $self->get_data_rows;
		return $hhData_Rows->{ $row };
	}
	sub import_cells {
		my $self = shift;
		
		my $aaData = $self->get_imported_data;
		my $key_col = $self->key_column;
		my $hhData_Rows = $self->get_data_rows;
		my $row = 1;
		for my $aData_Row (@$aaData){		
			my %hData_Row = ();
			for (my $i=0; $i<@$aData_Row; $i++){
				my $value = $aData_Row->[$i];
				$hData_Row{  $self->get_column_id($i) } = $value;
			}
			if ($key_col == -1){
				$hhData_Rows->{ $row } = \%hData_Row;
			} else {
				$hhData_Rows->{ $aData_Row->[$key_col] } = \%hData_Row;
			}
			$row++;
		}
	}
	#Êthe name column header providing the 'primary key'
	# returns the index number of that header
	# -1 indicates to use row number
	sub key_column {
		my $self = shift;
		if (@_){
			$self->{ _key_column } = $self->get_column_id(shift);
		} else {
			unless (defined $self->{ _key_column }){
				$self->{ _key_column } = -1;
			}	
			$self->{ _key_column };
		}
	}
}

{ package log_file;

	our @ISA = qw( microarray_text_file );
    
    sub create_filehandle {
		use FileHandle;
		my $self = shift;
		my $file_name = $self->file_name;
		my $filehandle = new FileHandle ">> $file_name" or die 
			"Microarray::File ERROR: Could not create filehandle for '$file_name'\n$!\n";
		return $filehandle;
	}
	sub load_file_data {
		my $self = shift;
		my $source = $self->get_source;
		my @aLines = split(/\n/,$source);
		return \@aLines;
	}
	sub add_text {
		my $self = shift;
		my $file_handle = $self->filehandle;
		while (@_){
			my $text = shift;
			return unless $text;
			if (ref $text){
				for my $line (@$text){
					print $file_handle $line."\n";
				}
			} else {
				print $file_handle $text."\n";
			}
		}
	}
}



1;

__END__

=head1 NAME

Microarray::File - Perl objects for handling microarray file formats

=head1 SYNOPSIS

	use Microarray::File;

	my $array_file = microarray_text_file->new('/file');  		# can pass just a filename...
	my $filehandle = $array_file->filehandle;					# ...and retrieve the filehandle

	my $array_file = microarray_text_file->new('/file',$Fh); 	# or create the filehandle yourself

=head1 DESCRIPTION

Microarray::File provides functions for creating microarray file objects. The module includes functions for importing and sorting data for text files. 

=head1 METHODS

=head2 Generic methods

=over

=item B<file_name>

Get or set the file name. If the filehandle is being set by Microarray::File, this needs to be the full path, otherwise can be any name.

=item B<get_header_keys>, B<get_header_info>

If the file type has a header of some kind, the method C<get_header_keys()> will return a list of the keys parsed from the header. The method C<get_header_info()> will return a hash of the header information, or if a key is passed it will return the relevant value. 

=item B<get_source>

Returns the file contents, as are. 

=back

=head2 microarray_text_file

The sub class C<microarray_text_file> handles any standard text file. As with all text files, line endings are 'normalised'. 

=over

=item B<line_num>

Returns the number of lines read

=back

=head2 delimited_file

This is a text file with delimited cells, but not necessarily a straightforward 'spreadsheet' type format. 

=over

=item B<delimiter>

Guesses and returns the delimiter type based on file name suffix. If '.csv', assumes a comma separated format, otherwise assumes a tab-delimited format. 

=item B<get_data_fields>

Returns the column headers as a hash. Both the column names and column numbers have keys, returning the corresponding value. i.e. if column 2 is called 'Name', then the C<data_fields> hash has the following keys;

	2=>'Name'
	'Name'=>2

Clearly this falls down if any of the columns have a numerical name in the same range as the number of columns, but different values (i.e. column 2 is named '3'). Oh well.     

=item B<get_column_id>

Returns the column name from its column number, and I<vice versa>

=back

=head2 simple_delimited_file

This is a delimited file with a simple columnar 'spreadsheet' format and no header.

=over

=item B<column_num>

The number of columns

=item B<key_column>

Get/set the column index of a column to use as a 'primary key'. If a column is not set, returns -1. 

=back

=head2 log_file methods

=over

=item B<add_text>

Add text to the log file

=back

=head1 SEE ALSO

L<Microarray|Microarray>

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/AcademicResearch/Cancer/trl>

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

