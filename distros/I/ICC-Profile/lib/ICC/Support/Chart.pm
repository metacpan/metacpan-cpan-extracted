package ICC::Support::Chart;

use strict;
use Carp;

our $VERSION = 1.71;

# revised 2018-03-29
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# support modules
use Config;
use Data::Dumper;
use Encode;
use File::Glob;
use POSIX ();
use Time::Piece;
use XML::LibXML;

# enable static variables
use feature 'state';

# create new chart object
# parameters: ([hash])
# parameters: (ref_to_data_array, [hash])
# parameters: (path_to_file, [hash])
# parameters: (path_to_folder, [hash])
# returns: (ref_to_chart_object) -or- (ref_to_chart_object, error_string)
sub new {

	# get object class
	my $class = shift();

	# local variables
	my ($self, $hash, $array, $format, $offset, $path, $files, $result, $error);

	# create empty chart object
	$self = [
		{},   # object header
		[[]], # chart data
		[[]], # colorimetry data
		[],   # header lines
		{},   # SAMPLE_ID hash
	];

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# if there are additional parameters
	if (@_) {
		
		# if first parameter is an array or a Math::Matrix object
		if (ref($_[0]) eq 'ARRAY' || UNIVERSAL::isa($_[0], 'Math::Matrix')) {
			
			# get array reference
			$array = shift();
			
			# get format header from hash
			$format = $hash->{'format'};
			
			# copy format header to object, if defined
			$self->[1][0] = [@{$format}] if defined($format);
			
			# set array offset
			$offset = defined($format) ? 1 : 0;
			
			# for each row
			for my $i (0 .. $#{$array}) {
				
				# copy array
				$self->[1][$i + $offset] = [@{$array->[$i]}];
				
			}
			
		# if first parameter is a scalar
		} elsif (! ref($_[0])) {
			
			# get path
			$path = shift();
			
			# save path in object header
			$self->[0]{'file_path'} = $path;
			
			# get file list
			$files = _files($path);
			
			# no files
			if (@{$files} == 0) {
				
				# invalid path
				carp($error = "no files in path: $path\n");
				
			# one file
			} elsif (@{$files} == 1) {
				
				# read chart
				($result = _readChart($self, $files->[0], $hash)) && carp($error = "chart $files->[0] $result\n");
				
				# add colorimetric metadata
				_addColorMeta($self);
				
			# multiple files
			} else {
				
				# if folder handling undefined or 'AVG'
				if (! defined($hash->{'folder'}) || $hash->{'folder'} eq 'AVG') {
					
					# read average chart
					_readChartAvg($self, $files, $hash) || carp($error = "no valid charts in path: $path\n");
					
				# if folder handling 'APPEND'
				} elsif ($hash->{'folder'} eq 'APPEND') {
					
					# read appended chart
					_readChartAppend($self, $files, $hash) || carp($error = "no valid charts in path: $path\n");
					
				} else {
					
					# invalid folder handling
					carp($error = "invalid folder handling: $hash->{'folder'}\n");
					
				}
				
			}
			
		} else {
			
			# invalid parameter(s)
			carp($error = "invalid parameter(s)");
			
		}
		
		# make SAMPLE_ID hash
		_makeSampleID($self);
		
	# if hash defined
	} elsif (defined($hash)) {
		
		# make patch set
		($result = _makePatchSet($self, $hash)) && carp($error = "failed making patch set - $result\n");
		
	}

	# bless object
	bless($self, $class);

	# return
	return(wantarray() ? ($self, $error) : $self);

}

# get/set reference to header hash
# parameters: ([ref_to_new_hash])
# returns: (ref_to_hash)
sub header {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
	
		# if one parameter, a hash reference
		if (@_ == 1 && ref($_[0]) eq 'HASH') {
		
			# set header to copy of hash
			$self->[0] = {%{shift()}};
		
		} else {
		
			# error
			croak('parameter must be a hash reference');
		
		}
	
	}

	# return reference
	return($self->[0]);

}

# get/set reference to data array
# note: row 0 contains the DATA_FORMAT field names
# note: set updates the SAMPLE_ID hash and colorimetry array
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub array {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, an array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY') {
			
			# get array reference
			my $array = shift();
			
			# initialize data array
			$self->[1] = [];
			
			# if array is not empty
			if (@{$array}) {
				
				# for each row
				for my $i (0 .. $#{$array}) {
					
					# copy to object
					$self->[1][$i] = [@{$array->[$i]}];
					
				}
				
				# make SAMPLE_ID hash
				_makeSampleID($self);
				
				# add colorimetric metadata
				_addColorMeta($self);
				
			}
		
		} else {
			
			# error
			croak('parameter must be an array reference');
			
		}
	
	}

	# return reference
	return($self->[1]);

}

# get data array size
# returns: (number_rows)
# returns: (number_rows, number_columns)
sub size {

	# get object reference
	my $self = shift();

	# return array or scalar
	return(wantarray ? ($#{$self->[1]}, $#{$self->[1][0]} + 1) : $#{$self->[1]});

}

# get data matrix size
# returns: (number_rows)
# returns: (number_rows, number_columns)
sub matrix_size {

	# get object reference
	my $self = shift();

	# get row length from data
	my $rows = _getRowLength($self);

	# compute columns
	my $cols = $rows ? POSIX::ceil($#{$self->[1]}/$rows) : 0;

	# return array or scalar
	wantarray ? return($rows, $cols) : return($rows);

}

# get row slice from SAMPLE_ID values
# id_keys is a list of scalars and/or array references
# row_slice is reference to an array of row indices
# note: returns undef if any key is missing
# parameters: (id_keys)
# returns: (row_slice)
sub rows {

	# get object reference
	my $self = shift();

	# local variable
	my (@keys, @rows);

	# flatten id key list
	@keys = @{ICC::Shared::flatten(@_)};

	# get row list using SAMPLE_ID hash
	@rows = @{$self->[4]}{@keys};

	# return row slice or undef if any rows are missing
	return((grep {! defined()} @rows) ? undef : \@rows);

}

# get column slice from DATA_FORMAT keys
# format_keys is a list of scalars and/or array references
# column_slice is reference to an array of column indices
# note: tries to match ignoring context if exact match fails
# note: returns 'undef' if any column is missing
# parameters: (format_keys)
# returns: (column_slice)
sub cols {

	# get object reference
	my $self = shift();

	# local variables
	my (@keys, %fmt, @cols);

	# flatten format key list
	@keys = @{ICC::Shared::flatten(@_)};

	# make lookup hash
	%fmt = map {defined($self->[1][0][$_]) ? ($self->[1][0][$_], $_) : ()} (0 .. $#{$self->[1][0]});

	# lookup format keys in hash
	@cols = @fmt{@keys};

	# if any columns undefined
	if (grep {! defined()} @cols) {
		
		# make lookup hash without context prefixes
		%fmt = map {(defined($self->[1][0][$_]) && $self->[1][0][$_] =~ m/^(.*?)\|?([^\|\n]*)$/) ? ($2, $_) : ()} (0 .. $#{$self->[1][0]});
		
		# lookup format keys in hash
		@cols = @fmt{@keys};
		
	}

	# return column slice or undef if any columns undefined
	return((grep {! defined()} @cols) ? undef : \@cols);

}

# get DATA_FORMAT keys from column slice
# column_slice is a list of scalars and/or array references
# format_keys is an array reference
# note: returns 'undef' if any key is missing
# parameters: (column_slice)
# returns: (format_keys)
sub fmt_keys {

	# get object reference
	my $self = shift();

	# local variable
	my (@keys);

	# if column slice an empty array reference ([])
	if (@_ == 1 && ref($_[0]) eq 'ARRAY' && @{$_[0]} == 0) {
		
		# get all format keys
		@keys = @{$self->[1][0]};
		
	} else {
		
		# get format keys per flattened slice
		@keys = map {$self->[1][0][$_]} @{ICC::Shared::flatten(@_)};
		
	}

	# return format keys or undef if any keys are missing
	return((grep {! defined()} @keys) ? undef : \@keys);

}

# get/set context
# 'undef' indicates no context (get or set)
# returned context may be a scalar or an array
# parameter: (column_slice) => returns: (context)
# parameters: (column_slice, context) => returns: (modified_keys)
sub context {

	# get object reference
	my $self = shift();

	# local variables
	my ($cols, $context, @cx);

	# return if no parameters supplied
	return(undef) if (@_ == 0);

	# get column slice
	$cols = ICC::Shared::flatten(shift());

	# use all columns if slice is empty
	$cols = [0 .. $#{$self->[1][0]}] if (@{$cols} == 0);

	# if no context parameter
	if (@_ == 0) {
		
		# match contexts
		@cx = map {$self->[1][0][$_] =~ m/^(.*)\|/ ? $1 : undef} @{$cols};
		
		# return array if wanted
		return(@cx) if (wantarray);
		
		# warn if columns have different contexts
		(@cx == grep {(! defined($cx[0]) && ! defined($_)) || ($cx[0] eq $_)} @cx) || warn('columns have different contexts');
		
		# return context of first column
		return($cx[0]);
		
	} else {
		
		# get context
		$context = shift();
		
		# for each column
		for my $i (0 .. $#{$cols}) {
			
			# if context is defined
			if (defined($context)) {
				
				# replace current context
				$self->[1][0][$cols->[$i]] =~ s/^(?:.*\|)?(.*)$/$context\|$1/;
				
			# if context is 'undef'
			} else {
				
				# remove current context
				$self->[1][0][$cols->[$i]] =~ s/^.*\|//;
				
			}
			
		}
		
		# return modified keys
		return([@{$self->[1][0]}[@{$cols}]]);
		
	}
	
}

# test for a specified data class
# returns list of matched indices or count
# context parameter of '|' matches fields with no context
# parameters: (class, [context])
# returns: (list -or- count)
sub test {

	# get parameters
	my ($self, $class, $context) = @_;

	# local variables
	my (%regex, @fields);

	# hash of compiled regex
	%regex = (
		'RGB' => qr/^(?:(.*)\|)?RGB_[RGB]$/,
		'CMYK' => qr/^(?:(.*)\|)?CMYK_[CMYK]$/,
		'XYZ' => qr/^(?:(.*)\|)?XYZ_[XYZ]$/,
		'XYY' => qr/^(?:(.*)\|)?XYY_(?:X|Y|CAPY)$/,
		'LAB' => qr/^(?:(.*)\|)?LAB_[LAB]$/,
		'LCH' => qr/^(?:(.*)\|)?LAB_[LCH]$/,
		'NCLR' => qr/^(?:(.*)\|)?[2-9A-F]CLR_[1-9A-F]$/,
		'SPECTRAL' => qr/^(?:(.*)\|)?(?:nm|SPECTRAL_NM_|SPECTRAL_NM|SPECTRAL_|NM_|R_)\d{3}$/,
		'SPOT' => qr/^(?:(.*)\|)?SPOT_\d+$/,
		'DENSITY' => qr/^(?:(.*)\|)?D_(?:RED|GREEN|BLUE|VIS)$/,
		'STDEVXYZ' => qr/^(?:(.*)\|)?STDEV_[XYZ]$/,
		'STDEVLAB' => qr/^(?:(.*)\|)?STDEV_[LAB]$/,
		'MEAN_DE' => qr/^(?:(.*)\|)?MEAN_DE$/,
		'ID' => qr/^(?:(.*)\|)?(?:SAMPLE_ID|SampleID)$/,
		'NAME' => qr/^(?:(.*)\|)?SAMPLE_NAME$/,
		'DEVICE' => qr/^(?:(.*)\|)?(?:RGB_[RGB]|CMYK_[CMYK]|[2-9A-F]CLR_[1-9A-F])$/,
	);

	# verify class
	(! ref($class) && exists($regex{$class})) || croak('invalid data class');

	# if context is undefined
	if (! defined($context)) {
		
		# match format fields (ignoring context)
		@fields = grep {$self->[1][0][$_] =~ /$regex{$class}/} (0 .. $#{$self->[1][0]});
		
	# if context is '|'
	} elsif ($context eq '|') {
		
		# match format fields (no context)
		@fields = grep {$self->[1][0][$_] =~ /$regex{$class}/ && ! defined($1)} (0 .. $#{$self->[1][0]});
		
	} else {
		
		# match format fields (matching context)
		@fields = grep {$self->[1][0][$_] =~ /$regex{$class}/ && defined($1) && ($1 eq $context)} (0 .. $#{$self->[1][0]});
		
	}

	# return (list -or- count)
	return(wantarray() ? @fields : scalar(@fields));

}

# get/set keyword value(s)
# CGATS ASCII file header lines are stored as an array in the object header
# most lines contain a keyword followed by a value, which this methods gets/sets
# a keyword may be used more than once, so the value parameter is an array
# if the keyword doesn't exist, a new line is added when setting its value
# if the keyword is enclosed by angle brackets, existing lines are removed
# parameters: () => returns: (file_header_array_reference)
# parameters: (keyword) => returns: (value_array)
# parameters: (keyword, value_array) => returns: (original_value_array)
sub keyword {

	# get parameters
	my ($self, $key, @values) = @_;

	# local variables
	my ($del, @ix, @current);

	# if no keyword, return file header array reference
	(defined($key)) || return($self->[3]);

	# set delete flag, stripping angle brackets (if any)
	$del = ($key =~ s/^<(.*)>$/$1/);

	# get indices of existing keyword (if any)
	@ix = grep {$self->[3][$_][0] eq $key} (0 .. $#{$self->[3]});

	# get current values array (if any)
	@current = map {$self->[3][$_][1]} @ix;

	# if delete flag set
	if ($del) {
		
		# while indices
		while (@ix) {
			
			# delete array element
			splice(@{$self->[3]}, pop(@ix), 1);
			
		}
		
	}

	# if there are supplied values
	if (@values) {
		
		# for each value
		for (@values) {
			
			# if not a number or already quoted
			if (! m/^([\d.-]+|".*")$/) {
				
				# remove any quotes
				s/"//g;
				
				# enclose in quotes
				$_ = "\"$_\"";
				
			}
			
		}
		
		# while indices and values
		while (@ix && @values) {
			
			# set keyword/value entry
			$self->[3][shift(@ix)] = [$key, shift(@values)];
			
		}
		
		# for each remaining value (if any)
		for (@values) {
			
			# add keyword/value entry
			push(@{$self->[3]}, [$key, $_]);
			
		}
		
	}

	# return current values array, or scalar
	return(wantarray ? @current : $current[0]);

}

# get/set CREATED value
# adds CREATED keyword when setting, if none
# parameters: () # gets date/time from CREATED value
# parameters: (string) # sets/adds CREATED keyword/value
# parameters: (Time::Piece_object) # sets/adds CREATED keyword/value
# returns: (Time::Piece_object) # default is localtime
sub created {

	# get parameters
	my ($self, $t) = @_;

	# local variables
	my (@ix, $datetime);

	# get indices of existing CREATED lines (if any)
	@ix = grep {$self->[3][$_][0] eq 'CREATED'} (0 .. $#{$self->[3]});

	# print warning if more than one CREATED line
	print "warning: more than one CREATED keyword\n" if (@ix > 1);

	# if date/time parameter given
	if (defined($t)) {
		
		# make Time::Piece object if reference is a scalar
		$t = _makeTimePiece($t) if (! ref($t));
		
		# if not a Time::Piece object
		if (ref($t) ne 'Time::Piece') {
			
			# print warning
			print "warning: invalid date/time parameter, using localtime instead\n";
			
			# use local time
			$t = localtime();
			
		}
		
		# make ISO 8601 datetime string from Time::Piece object
		$datetime = $t->strftime('%Y-%m-%dT%T%z');
		substr($datetime, -2, 0, ':');
		
		# if CREATED lines
		if (@ix) {
			
			# replace value in first CREATED line
			$self->[3][$ix[0]][1] = "\"$datetime\"";
			
		} else {
			
			# if keyword lines exist
			if (@{$self->[3]}) {
				
				# insert CREATED line (as second line)
				splice(@{$self->[3]}, 1, 0, ['CREATED', "\"$datetime\""]);
				
			} else {
				
				# add CREATED line
				$self->[3][0] = ['CREATED', "\"$datetime\""];
				
			}
			
		}
		
	# no parameter
	} else {
		
		# if CREATED lines
		if (@ix) {
			
			# make Time::Piece object from first CREATED value
			$t = _makeTimePiece($self->[3][$ix[0]][1]);
			
		} else {
			
			# print warning
			print "warning: no CREATED keyword, returning localtime instead\n";
			
			# use local time
			$t = localtime();
			
		}
		
	}

	# return Time::Piece object
	return($t);

}

# get/set data array slice
# row_slice and column_slice may be either a scalar or array reference
# replacement_data is reference to a 2-D array of replacement values
# replacement data dimensions must match size of row_slice and column_slice
# data_slice is reference to a 2-D array, selected by row_slice and column_slice
# parameters: ([row_slice, [column_slice, [replacement_data]]])
# return: (data_slice)
sub slice {

	# get parameters
	my ($self, $rows, $cols, $data) = @_;

	# select all rows if row slice undefined
	$rows = [] if (! defined($rows));

	# select all fields if column slice undefined
	$cols = [] if (! defined($cols));

	# call get/set subroutine
	_getset($self, 1, $rows, $cols, $data);

}

# get/set colorimetry array slice
# row_slice and column_slice may be either a scalar or array reference
# replacement_data is reference to a 2-D array of replacement values
# replacement data dimensions must match size of row_slice and column_slice
# data_slice is reference to a 2-D array, selected by row_slice and column_slice
# parameters: ([row_slice, [column_slice, [replacement_data]]])
# return: (data_slice)
sub colorimetry {

	# get parameters
	my ($self, $rows, $cols, $data) = @_;

	# flatten row slice
	$rows = defined($rows) ? ICC::Shared::flatten($rows) : [];

	# select all rows if row slice empty
	$rows = [0 .. $#{$self->[2]}] if (@{$rows} == 0);

	# flatten column slice
	$cols = defined($cols) ? ICC::Shared::flatten($cols) : [];

	# select all fields if column slice empty
	$cols = [0 .. $#{$self->[1][0]}] if (@{$cols} == 0);

	# call get/set subroutine
	_getset($self, 2, $rows, $cols, $data);

}

# get/set SAMPLE_ID data
# optional hash contains supplementary parameters
# row_slice and column_slice are 1-D array references
# data_slice is a Math::Matrix object (2-D array)
# replacement_data is a Math::Matrix object or 2-D array
# parameters: ([hash]) => returns: (column_slice)
# parameters: (row_slice, [hash]) => returns: (data_slice)
# parameters: (row_slice, replacement_data, [hash]) => returns: (column_slice)
sub id {

	# local variables
	my ($hash, %fmt, $cols);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $rows, $data) = @_;

	# make lookup hash (context| -or- '||' => column)
	%fmt = map {($self->[1][0][$_] =~ m/^(.*\|)?(?:SAMPLE_ID|SampleID|ID)$/) ? (defined($1) ? $1 : '||', $_) : ()} (0 .. $#{$self->[1][0]});

	# if context defined
	if (defined($hash->{'context'})) {
		
		# get id column with context
		$cols = $fmt{"$hash->{'context'}|"};
		
	} else {
		
		# get id column without context
		$cols = $fmt{'||'};
		
		# if id column undefined
		if (! defined($cols)) {
			
			# make lookup hash ignoring context ('||' => column)
			%fmt = map {($self->[1][0][$_] =~ m/^(?:.*\|)?(?:SAMPLE_ID|SampleID|ID)$/) ? ('||', $_) : ()} (0 .. $#{$self->[1][0]});
			
			# get id column
			$cols = $fmt{'||'};
			
		}
		
	}

	# call get/set subroutine
	_getset($self, 1, $rows, $cols, $data);

}

# get/set SAMPLE_NAME data
# optional hash contains supplementary parameters
# row_slice and column_slice are 1-D array references
# data_slice is a Math::Matrix object (2-D array)
# replacement_data is a Math::Matrix object or 2-D array
# parameters: ([hash]) => returns: (column_slice)
# parameters: (row_slice, [hash]) => returns: (data_slice)
# parameters: (row_slice, replacement_data, [hash]) => returns: (column_slice)
sub name {

	# local variables
	my ($hash, $cols);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $rows, $data) = @_;

	# get column slice, adding optional context prefix
	$cols = cols($self, defined($hash->{'context'}) ? "$hash->{'context'}|SAMPLE_NAME" : 'SAMPLE_NAME');

	# call get/set subroutine
	_getset($self, 1, $rows, $cols, $data);

}

# get/set RGB data
# optional hash contains supplementary parameters
# row_slice and column_slice are 1-D array references
# data_slice is a Math::Matrix object (2-D array)
# replacement_data is a Math::Matrix object or 2-D array
# parameters: ([hash]) => returns: (column_slice)
# parameters: (row_slice, [hash]) => returns: (data_slice)
# parameters: (row_slice, replacement_data, [hash]) => returns: (column_slice)
sub rgb {

	# local variables
	my ($hash, $cols);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $rows, $data) = @_;

	# get column slice, adding optional context prefix
	$cols = cols($self, map {defined($hash->{'context'}) ? "$hash->{'context'}|$_" : $_} qw(RGB_R RGB_G RGB_B));

	# call get/set subroutine
	_getset($self, 1, $rows, $cols, $data);

}

# get/set CMYK data
# optional hash contains supplementary parameters
# row_slice and column_slice are 1-D array references
# data_slice is a Math::Matrix object (2-D array)
# replacement_data is a Math::Matrix object or 2-D array
# parameters: ([hash]) => returns: (column_slice)
# parameters: (row_slice, [hash]) => returns: (data_slice)
# parameters: (row_slice, replacement_data, [hash]) => returns: (column_slice)
sub cmyk {

	# local variables
	my ($hash, $cols);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $rows, $data) = @_;

	# get column slice, adding optional context prefix
	$cols = cols($self, map {defined($hash->{'context'}) ? "$hash->{'context'}|$_" : $_} qw(CMYK_C CMYK_M CMYK_Y CMYK_K));

	# call get/set subroutine
	_getset($self, 1, $rows, $cols, $data);

}

# get/set 6CLR data
# optional hash contains supplementary parameters
# row_slice and column_slice are 1-D array references
# data_slice is a Math::Matrix object (2-D array)
# replacement_data is a Math::Matrix object or 2-D array
# parameters: ([hash]) => returns: (column_slice)
# parameters: (row_slice, [hash]) => returns: (data_slice)
# parameters: (row_slice, replacement_data, [hash]) => returns: (column_slice)
sub hex {

	# local variables
	my ($hash, $cols);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $rows, $data) = @_;

	# get column slice, adding optional context prefix
	$cols = cols($self, map {defined($hash->{'context'}) ? "$hash->{'context'}|$_" : $_} qw(6CLR_1 6CLR_2 6CLR_3 6CLR_4 6CLR_5 6CLR_6));

	# call get/set subroutine
	_getset($self, 1, $rows, $cols, $data);

}

# get/set nCLR data
# optional hash contains supplementary parameters
# row_slice and column_slice are 1-D array references
# data_slice and replacement_data are 2-D array references
# parameters: ([hash]) => returns: (column_slice)
# parameters: (row_slice, [hash]) => returns: (data_slice)
# parameters: (row_slice, replacement_data, [hash]) => returns: (column_slice)
sub nCLR {

	# local variables
	my ($hash, $context, %fmt, %fmt2, $chan, @cols);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $rows, $data) = @_;

	# get the context
	$context = $hash->{'context'};

	# make lookup hash (key => column)
	%fmt = map {($self->[1][0][$_] =~ m/^(?:.*\|)?[2-9A-F]CLR_[1-9A-F]$/) ? ($self->[1][0][$_], $_) : ()} (0 .. $#{$self->[1][0]});

	# make lookup hash (prefix -or- '||' => channels)
	%fmt2 = map {($self->[1][0][$_] =~ m/^(.*\|)?([2-9A-F])CLR_[1-9A-F]$/) ? (defined($1) ? ($1, $2) : ('||', $2)) : ()} (0 .. $#{$self->[1][0]});

	# if context defined
	if (defined($context)) {
		
		# get the number of channels
		($chan = $fmt2{"$context|"}) || return();
		
		# append format
		$chan .= 'CLR_';
		
		# get column slice (selected from %fmt columns)
		@cols = grep {$self->[1][0][$_] =~ m/^$context\|$chan[1-9A-F]$/} values(%fmt);
		
	} else {
		
		# if number of channels undefined
		if (! defined($chan = $fmt2{'||'})) {
			
			# make lookup hash ignoring prefix (key => column)
			%fmt = map {($self->[1][0][$_] =~ m/^(?:.*\|)?([2-9A-F]CLR_[1-9A-F])$/) ? ($1, $_) : ()} (0 .. $#{$self->[1][0]});
			
			# make lookup hash ('||' => channels)
			%fmt2 = map {($self->[1][0][$_] =~ m/^(?:.*\|)?([2-9A-F])CLR_[1-9A-F]$/) ? ('||', $1) : ()} (0 .. $#{$self->[1][0]});
			
			# get the number of channels
			($chan = $fmt2{'||'}) || return();
			
			# append format
			$chan .= 'CLR_';
			
			# get column slice (selected from %fmt columns)
			@cols = grep {$self->[1][0][$_] =~ m/^(?:.*\|)?$chan[1-9A-F]$/} values(%fmt);
			
		} else {
			
			# append format
			$chan .= 'CLR_';
			
			# get column slice (selected from %fmt columns)
			@cols = grep {$self->[1][0][$_] =~ m/^$chan[1-9A-F]$/} values(%fmt);
			
		}
		
	}

	# sort by color channel (1-9, A-F)
	@cols = sort {substr($self->[1][0][$a], -1) cmp substr($self->[1][0][$b], -1)} @cols;

	# match last format key
	$self->[1][0][$cols[-1]] =~ m/([2-9A-F])CLR_([1-9A-F])$/;

	# verify number of format keys
	(CORE::hex($1) == @cols && CORE::hex($2) == @cols) || croak('wrong number of nCLR keys');

	# call get/set subroutine
	_getset($self, 1, $rows, \@cols, $data);

}

# get/set device data
# device data is either RGB, CMYK or nCLR
# device values have range (0 - 1)
# optional hash contains supplementary parameters
# row_slice and column_slice are 1-D array references
# data_slice is a Math::Matrix object (2-D array)
# replacement_data is a Math::Matrix object or 2-D array
# parameters: ([hash]) => returns: (column_slice)
# parameters: (row_slice, [hash]) => returns: (data_slice)
# parameters: (row_slice, replacement_data, [hash]) => returns: (column_slice)
sub device {

	# local variables
	my ($hash, $cols, $mult);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $rows, $data) = @_;

	# get column slice or return empty
	$cols = rgb($self, $hash) || cmyk($self, $hash) || nCLR($self, $hash) || return();

	# set multiplier (255 if RGB, else 100)
	$mult = ($self->[1][0][$cols->[0]] =~ m/RGB_R$/) ? 255 : 100;

	# call get/set subroutine
	_getset($self, 1, $rows, $cols, $data, sub {map {defined($_) ? $_/$mult : $_} @_}, sub {map {defined($_) ? $_ * $mult : $_} @_});

}

# get/set CTV data
# optional hash contains supplementary parameters
# row_slice and column_slice are 1-D array references
# data_slice is a Math::Matrix object (2-D array)
# replacement_data is a Math::Matrix object or 2-D array
# parameters: ([hash]) => returns: (column_slice)
# parameters: (row_slice, [hash]) => returns: (data_slice)
# parameters: (row_slice, replacement_data, [hash]) => returns: (column_slice)
sub ctv {

	# local variables
	my ($hash, $cols);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $rows, $data) = @_;

	# get column slice, adding optional context prefix
	$cols = cols($self, map {defined($hash->{'context'}) ? "$hash->{'context'}|$_" : $_} qw(CTV));

	# call get/set subroutine
	_getset($self, 1, $rows, $cols, $data);

}

# get/set L*a*b* data
# optional hash contains supplementary parameters
# row_slice and column_slice are 1-D array references
# data_slice is a Math::Matrix object (2-D array)
# replacement_data is a Math::Matrix object or 2-D array
# parameters: ([hash]) => returns: (column_slice)
# parameters: (row_slice, [hash]) => returns: (data_slice)
# parameters: (row_slice, replacement_data, [hash]) => returns: (column_slice)
sub lab {

	# local variables
	my ($hash, $cols);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $rows, $data) = @_;

	# get column slice, adding optional context prefix
	$cols = cols($self, map {defined($hash->{'context'}) ? "$hash->{'context'}|$_" : $_} qw(LAB_L LAB_A LAB_B));

	# call get/set subroutine
	_getset($self, 1, $rows, $cols, $data, _lab_encoding($self, $hash));

}

# get/set XYZ data
# optional hash contains supplementary parameters
# row_slice and column_slice are 1-D array references
# data_slice is a Math::Matrix object (2-D array)
# replacement_data is a Math::Matrix object or 2-D array
# parameters: ([hash]) => returns: (column_slice)
# parameters: (row_slice, [hash]) => returns: (data_slice)
# parameters: (row_slice, replacement_data, [hash]) => returns: (column_slice)
sub xyz {

	# local variables
	my ($hash, $cols);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $rows, $data) = @_;

	# get column slice, adding optional context prefix
	$cols = cols($self, map {defined($hash->{'context'}) ? "$hash->{'context'}|$_" : $_} qw(XYZ_X XYZ_Y XYZ_Z));

	# call get/set subroutine
	_getset($self, 1, $rows, $cols, $data, _xyz_encoding($self, $cols, $hash));

}

# get/set density data
# optional hash contains supplementary parameters
# row_slice and column_slice are 1-D array references
# data_slice is a Math::Matrix object (2-D array)
# replacement_data is a Math::Matrix object or 2-D array
# parameters: ([hash]) => returns: (column_slice)
# parameters: (row_slice, [hash]) => returns: (data_slice)
# parameters: (row_slice, replacement_data, [hash]) => returns: (column_slice)
sub density {

	# local variables
	my ($hash, $cols);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $rows, $data) = @_;

	# get column slice
	$cols = cols($self, map {defined($hash->{'context'}) ? "$hash->{'context'}|$_" : $_} qw(D_RED D_GREEN D_BLUE D_VIS));

	# call get/set subroutine
	_getset($self, 1, $rows, $cols, $data, _density_encoding($self, $hash));

}

# get/set reflectance/transmittance data
# optional hash contains supplementary parameters
# row_slice and column_slice are 1-D array references
# data_slice is a Math::Matrix object (2-D array)
# replacement_data is a Math::Matrix object or 2-D array
# parameters: ([hash]) => returns: (column_slice)
# parameters: (row_slice, [hash]) => returns: (data_slice)
# parameters: (row_slice, replacement_data, [hash]) => returns: (column_slice)
sub rgbv {

	# local variables
	my ($hash, $cols);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $rows, $data) = @_;

	# get column slice
	$cols = cols($self, map {defined($hash->{'context'}) ? "$hash->{'context'}|$_" : $_} qw(R_RED R_GREEN R_BLUE R_VIS));

	# call get/set subroutine
	_getset($self, 1, $rows, $cols, $data, _rgbv_encoding($self, $hash));

}

# get/set spectral data
# optional hash contains supplementary parameters
# row_slice and column_slice are 1-D array references
# data_slice is a Math::Matrix object (2-D array)
# replacement_data is a Math::Matrix object or 2-D array
# parameters: ([hash]) => returns: (column_slice)
# parameters: (row_slice, [hash]) => returns: (data_slice)
# parameters: (row_slice, replacement_data, [hash]) => returns: (column_slice)
sub spectral {

	# local variables
	my ($hash, $fields, $cols);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $rows, $data) = @_;

	# get spectral fields array
	$fields = _spectral($self, $hash->{'context'});

	# get column slice from spectral fields array
	$cols = defined($fields) ? [map {$_->[0]} @{$fields}] : undef;

	# call get/set subroutine
	_getset($self, 1, $rows, $cols, $data);

}

# get spectral wavelength array
# array is sorted (low to high)
# parameters: ([hash])
# returns: (ref_to_wavelength_array)
sub wavelength {

	# get parameters
	my ($self, $hash) = @_;

	# get spectral fields array or return empty
	my $fields = _spectral($self, $hash->{'context'}) || return();

	# return
	return([map {$_->[1]} @{$fields}]);

}

# get spectral wavelength range
# structure is [start_nm, end_nm, increment]
# parameters: ([hash])
# returns: (range)
sub nm {

	# get parameters
	my ($self, $hash) = @_;
	
	# local variables
	my ($fields, $inc);

	# get spectral fields array or return empty
	$fields = _spectral($self, $hash->{'context'}) || return();

	# compute increment
	$inc = $fields->[1][1] - $fields->[0][1];

	# verify wavelength increment
	($inc > 0 && abs($#{$fields} * $inc - $fields->[-1][1] + $fields->[0][1]) < 1E-12) || warn('inconsistent wavelength values');

	# return range
	return([$fields->[0][1], $fields->[-1][1], $inc]);

}

# get illuminant white point
# parameters: ([hash])
# returns: (XYZ_vector)
sub iwtpt {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($encode, $cols, $iwtpt, $get);

	# extract encoding hash
	$encode = {'encoding' => delete($hash->{'encoding'})};

	# get XYZ or L*a*b* column slice
	$cols = xyz($self, $hash) || lab($self, $hash) || croak('illuminant white point XYZ or L*a*b* column slice undefined');

	# get illuminant white point
	$iwtpt = _illumWP($self, $cols, $hash);

	# get code reference
	($get) = _xyz_encoding($self, $cols, $encode);

	# return encoded XYZ vector
	return([&$get(@{$iwtpt})]);

}

# get media white point
# parameters: ([hash])
# returns: (XYZ_vector)
sub wtpt {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($encode, $cols, $get);

	# extract encoding hash
	$encode = {'encoding' => delete($hash->{'encoding'})};

	# get XYZ or L*a*b* column slice
	$cols = xyz($self, $hash) || lab($self, $hash) || croak('white point XYZ or L*a*b* column slice undefined');

	# if media white point undefined in colorimetry array
	if (! defined($self->[2][3][$cols->[0]])) {
		
		# compute media white point or return undefined
		(_mediaWP($self, $cols, $hash)) || return();
		
	}

	# get code reference
	($get) = _xyz_encoding($self, $cols, $encode);

	# return encoded XYZ vector
	return([&$get(@{$self->[2][3]}[@{$cols}])]);

}

# get media black point
# parameters: ([hash])
# returns: (XYZ_vector)
sub bkpt {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($encode, $cols, $get);

	# extract encoding hash
	$encode = {'encoding' => delete($hash->{'encoding'})};

	# get XYZ or L*a*b* column slice
	$cols = xyz($self, $hash) || lab($self, $hash) || croak('black point XYZ or L*a*b* column slice undefined');

	# if media black point undefined in colorimetry array
	if (! defined($self->[2][4][$cols->[0]])) {
		
		# compute media black point or return undefined
		(_mediaBP($self, $cols, $hash)) || return();
		
	}

	# get code reference
	($get) = _xyz_encoding($self, $cols, $encode);

	# return encoded XYZ vector
	return([&$get(@{$self->[2][4]}[@{$cols}])]);

}

# compute media OBA index
# requires M1 and M2 measurements
# requires device values -or- sample number
# optional hash keys are 'sample', 'device', and 'context'
# parameters: ([hash])
# returns: (oba_index)
# returns: (M1_XYZ_vector, M2_XYZ_vector)
sub oba_index {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($sample, $dev, $mwv, $wps, $wpdata, $context1, $context2, $m1, $m2, @xyz1, @xyz2, $nm, $color);

	# if 'sample' defined
	if (defined($hash->{'sample'})) {
		
		# get sample from hash
		$sample = $hash->{'sample'};
		
		# if valid sample number
		if (Scalar::Util::looks_like_number($sample) && $sample == int($sample) && $sample > 0 && $sample <= $#{$self->[1]}) {
			
			# get sample data row
			$wpdata = $self->[1][$sample];
			
		} else {
			
			# warn
			warn('invalid sample number');
			
			# return empty
			return();
			
		}
		
	} else {
		
		# if device data (using 'device' context)
		if ($dev = device($self, {'context' => $hash->{'device'}})) {
			
			# set media white device value (255 if RGB, 0 otherwise)
			$mwv = ($self->[1][0][$dev->[0]] =~ m/RGB_R$/) ? 255 : 0;
			
			# if paper white samples found
			if ($wps = find($self, sub {@_ == grep {$_ == $mwv} @_}, [], $dev)) {
				
				# add average paper white sample row
				add_avg($self, $wps);
				
				# get sample data row
				$wpdata = pop(@{$self->[1]});
				
			} else {
				
				# warn
				warn('no paper white samples');
				
				# return empty
				return();
				
			}
			
		} else {
			
			# warn
			warn('no sample value or device data');
			
			# return empty
			return();
			
		}
		
	}

	# if 'context' defined
	if (defined($hash->{'context'})) {
		
		# if context an array reference containing two scalars
		if (ref($hash->{'context'}) eq 'ARRAY' && ! ref($hash->{'context'}->[0]) && ! ref($hash->{'context'}->[1])) {
			
			# get specified 'M1' context
			$context1 = $hash->{'context'}->[0];
			
			# get specified 'M2' context
			$context2 = $hash->{'context'}->[1];
			
		} else {
			
			# warn
			warn('OBA context is an array reference containing M1 and M2 contexts');
			
			# return empty
			return();
			
		}
		
	} else {
		
		# use standard 'M1' context
		$context1 = 'M1_Measurement';
		
		# use standard 'M2' context
		$context2 = 'M2_Measurement';
		
	}

	# if M1 and M2 spectral data
	if (($m1 = spectral($self, {'context' => $context1})) && ($m2 = spectral($self, {'context' => $context2}))) {
		
		# get spectral range
		$nm = nm($self, {'context' => $context1});
		
		# if increment is 10 or 20 nm
		if ($nm->[2] == 10 || $nm->[2] == 20) {
			
			# make ASTM color object
			$color = ICC::Support::Color->new({'illuminant' => 'D50', 'increment' => $nm->[2]});
			
		} else {
			
			# make CIE color object
			$color = ICC::Support::Color->new({'illuminant' => ['CIE', 'D50'], 'increment' => $nm->[2]});
			
		}
		
		# compute M1 and M2 XYZ values
		@xyz1 = $color->transform(@{$wpdata}[@{$m1}]);
		@xyz2 = $color->transform(@{$wpdata}[@{$m2}]);
		
	# if M1 and M2 XYZ data
	} elsif (($m1 = xyz($self, {'context' => $context1})) && ($m2 = xyz($self, {'context' => $context2}))) {
		
		# get M1 and M2 XYZ values (assumes D50 illumination)
		@xyz1 = @{$wpdata}[@{$m1}];
		@xyz2 = @{$wpdata}[@{$m2}];
		
	# if M1 and M2 L*a*b* data
	} elsif (($m1 = lab($self, {'context' => $context1})) && ($m2 = lab($self, {'context' => $context2}))) {
		
		# compute M1 and M2 XYZ values (D50 illumination)
		@xyz1 = ICC::Shared::_Lab2XYZ(@{$wpdata}[@{$m1}], ICC::Shared::D50);
		@xyz2 = ICC::Shared::_Lab2XYZ(@{$wpdata}[@{$m2}], ICC::Shared::D50);
		
	} else {
		
		# warn
		warn('M1 and M2 data required for OBA index');
		
		# return empty
		return();
		
	}

	# return array (XYZ media white points) or scalar (OBA index)
	return(wantarray ? (\@xyz1, \@xyz2) : ($xyz1[2] - $xyz2[2])/82.49);

}

# get chromatic adaptation transform (CAT) object
# a CAT is optionally created when adding XYZ data
# optional hash contains supplementary parameters
# parameters: ([hash])
# returns: (CAT_object)
sub cat {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($cols, $cat);

	# get column slice, adding optional context prefix
	$cols = cols($self, map {defined($hash->{'context'}) ? "$hash->{'context'}|$_" : $_} qw(XYZ_X XYZ_Y XYZ_Z));

	# return if slice undefined
	return() if (! defined($cols));

	# get CAT or illuminant
	$cat = $self->[2][2][$cols->[0]];

	# return CAT if defined
	return((defined($cat) && UNIVERSAL::isa($cat, 'ICC::Profile::matf')) ? $cat : ());

}

# get Color object
# a Color object is created when adding XYZ data from spectral data
# optional hash contains supplementary parameters
# parameters: ([hash])
# returns: (Color_object)
sub color {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($cols, $color);

	# get column slice, adding optional context prefix
	$cols = cols($self, map {defined($hash->{'context'}) ? "$hash->{'context'}|$_" : $_} qw(XYZ_X XYZ_Y XYZ_Z));

	# return if slice undefined
	return() if (! defined($cols));

	# get CAT or illuminant
	$color = $self->[2][1][$cols->[0]];

	# return CAT if defined
	return((defined($color) && UNIVERSAL::isa($color, 'ICC::Support::Color')) ? $color : ());

}

# append rows to data array
# data matrix is the 2-D array of data values to be appended
# column slice is a reference to an array of data matrix column indices
# parameters: (data_matrix, [column_slice])
# returns: (row_slice)
sub add_rows {

	# get parameters
	my ($self, $matrix, $cols) = @_;

	# set offset to upper index + 1, or 0 if a new object (row 0 is empty)
	my $offset = $#{$self->[1]} || @{$self->[1][0]} ? $#{$self->[1]} + 1 : 0;

	# call 'splice_rows'
	splice_rows($self, $offset, 0, $matrix, $cols);

	# return row slice
	return([$offset .. ($offset + $#{$matrix})]);

}

# append columns to data array
# data matrix is the 2-D array of data values to be appended
# header is a reference to an array of DATA_FORMAT keywords
# parameters: (data_matrix, [header])
# returns: (column_slice)
sub add_cols {

	# get parameters
	my ($self, $matrix, $header) = @_;

	# verify matrix a 2-D array or Math::Matrix object
	(ref($matrix) eq 'ARRAY' && ref($matrix->[0]) eq 'ARRAY') || (UNIVERSAL::isa($matrix, 'Math::Matrix')) || croak ('invalid matrix parameter');

	# if header supplied
	if (defined($header)) {
		
		# verify header is 1-D array of scalars
		(ref($header) eq 'ARRAY' && @{$header} == grep {! ref()} @{$header}) || croak('invalid header parameter');
		
		# verify header and matrix have same number of columns
		(@{$header} == @{$matrix->[0]}) || croak('header and matrix have different number of columns');
		
		# add header to matrix
		$matrix = [$header, @{$matrix}];
		
	}

	# warn if matrix and object have different number of rows
	(@{$matrix} == @{$self->[1]}) || carp('matrix and object have different number of rows');

	# set offset to upper index + 1
	my $offset = $#{$self->[1][0]} + 1;

	# call 'splice_cols'
	splice_cols($self, $offset, 0, $matrix);

	# return column slice
	return([$offset .. ($offset + $#{$matrix->[0]})]);

}

# add average sample
# assumes device values (if any) are same for each sample
# averages measurement values - spectral, XYZ, L*a*b* or density
# L*a*b* values are converted to xyz for averaging, then back to L*a*b*
# density values are converted to reflectance for averaging, then back to density
# returns row slice of the appended average sample
# parameters: (row_slice, [hash])
# returns: (row_slice)
sub add_avg {

	# get parameters
	my ($self, $rows, $hash) = @_;

	# local variables
	my ($c1, $c2, $c3, @id, @name);

	# flatten row slice
	$rows = ICC::Shared::flatten($rows);

	# resolve empty row slice
	$rows = [1 .. $#{$self->[1]}] if (@{$rows} == 0);

	# get averaging groups
	($c1, $c2, $c3) = _avg_groups($self, $hash);

	# for each format field
	for my $i (0 .. $#{$self->[1][0]}) {
	
		# add column if SAMPLE_ID field
		push(@id, $i) if ($self->[1][0][$i] =~ m/^(?:.*\|)?(?:SAMPLE_ID|SampleID)$/);
	
		# add column if SAMPLE_NAME field
		push(@name, $i) if ($self->[1][0][$i] =~ m/^(?:.*\|)?SAMPLE_NAME$/);
	
	}

	# return average sample
	return([_add_avg($self, $rows, $c1, $c2, $c3, \@id, \@name, $hash)]);

}

# add format keys
# keys are appended to row 0 of the data array
# note: format_keys is a list of scalars and/or array references
# note: format_keys are saved as given, with or without context
# parameters: (format_keys)
# returns: (column_slice)
sub add_fmt {

	# get parameters
	my $self = shift();

	# local variables
	my (@keys, $i, %fmt);

	# flatten format key list
	@keys = @{ICC::Shared::flatten(@_)};

	# get upper column index
	$i = $#{$self->[1][0]};

	# make format lookup hash of existing keys
	%fmt = map {$self->[1][0][$_], $_} (0 .. $#{$self->[1][0]});

	# warn if duplicate keys
	warn('adding duplicate format key(s)') if (grep {exists($fmt{$_})} @keys);

	# push format keys onto format row
	push(@{$self->[1][0]}, @keys);

	# return slice array reference
	return([$i + 1 .. $#{$self->[1][0]}]);

}

# append CTV data to data array
# computed from L*a*b* data, XYZ data, or spectral data
# if CTV data already exists, return those slices
# adds L*a*b* data, and XYZ data if missing
# parameters: ([hash])
# returns: (column_slice)
sub add_ctv {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($context, $added, $cols, $Lab, $color);
	my ($iwtpt, $WPxyz, @wtpt, $dev, $mwv, $coef, @Ls);
	my ($den, $a, $b, $c, $d, $e, $f, $mat);

	# get base context
	$context = $hash->{'context'};

	# get added context
	$added = defined($hash->{'added'}) ? $hash->{'added'} : $context;

	# return column slice if CTV data already exists
	return($cols) if ($cols = _cols($self, map {defined($added) ? "$added|$_" : $_} qw(CTV)));

	# if L*a*b* exists, or is added
	if ($Lab = (_cols($self, map {defined($context) ? "$context|$_" : $_} qw(LAB_L LAB_A LAB_B)) || add_lab($self, $hash))) {
		
		# get L*a*b* colorimetry hash
		$color = $self->[2][6][$Lab->[0]];
		
		# for each possible colorimetry key
		for my $key (qw(illuminant observer increment bandpass cat)) {
			
			# if key is specified
			if (defined($hash->{$key})) {
				
				# if YAML strings differ
				if (YAML::Tiny::Dump($hash->{$key}) ne YAML::Tiny::Dump($color->{$key})) {
					
					# print warning
					warn("$key parameter differs from source");
					
				}
				
			}
			
		}
		
		# if 'context' and 'added' keys are undefined, and L*a*b* source has context
		if (! defined($added) && $self->[1][0][$Lab->[0]] =~ m/^(.*)\|/) {
			
			# set 'added' to L*a*b* context
			$added = $1;
			
		}
		
		# add CTV columns slice
		$cols = add_fmt($self, map {defined($added) ? "$added|$_" : $_} qw(CTV));
		
		# get supplied illuminant white point
		$iwtpt = $hash->{'iwtpt'};
		
		# if supplied illuminant white point is valid
		if (defined($iwtpt) && (3 == grep {defined() && ! ref() && $_ > 0} @{$iwtpt})) {
			
			# use it
			$WPxyz = $iwtpt;
			
		# if XYZ illuminant white point is valid
		} elsif (3 == grep {defined() && ! ref() && $_ > 0} @{$self->[2][2]}[@{$Lab}]) {
			
			# use it
			$WPxyz = [@{$self->[2][2]}[@{$Lab}]];
			
		} else {
			
			# use D50
			$WPxyz = ICC::Shared::D50;
			
		}
		
		# if media white point undefined in colorimetry array
		if (! defined($self->[2][3][$Lab->[0]])) {
			
			# compute media white point or return undefined
			(_mediaWP($self, $Lab, $hash)) || return();
			
		}
		
		# get media white point (Lx, Ly, Lz)
		@wtpt = ICC::Shared::_xyz2Lxyz($self->[2][3][$Lab->[0]]/$WPxyz->[0], $self->[2][3][$Lab->[1]]/$WPxyz->[1], $self->[2][3][$Lab->[2]]/$WPxyz->[2]);
		
		# get device column slice
		$dev = device($self, {'context' => $hash->{'device'}});
		
		# set media white device value (255 if RGB, 0 otherwise)
		$mwv = ($self->[1][0][$dev->[0]] =~ m/RGB_R$/) ? 255 : 0;
		
		# set origin
		$self->[2][0][$cols->[0]] = $Lab;
		
		# save media white CTV (0)
		$self->[2][3][$cols->[0]] = 0;
		
		# save colorimetry hash
		@{$self->[2][6]}[$cols->[0]] = $color;
		
		# get coefficient array
		$coef = defined($hash->{'coef'}) ? $hash->{'coef'} : [1, 1, 1, 0, 0, 0];
		
		# compute denominator
		$den = $coef->[0]**2 + $coef->[1]**2 + $coef->[2]**2;
		
		# compute matrix elements
		$a = ($coef->[0]**2 + $coef->[4]**2 + $coef->[5]**2)/$den;
		$b = ($coef->[1]**2 + $coef->[3]**2 + $coef->[5]**2)/$den;
		$c = ($coef->[2]**2 + $coef->[3]**2 + $coef->[4]**2)/$den;
		$d = -$coef->[5]**2/$den;
		$e = -$coef->[4]**2/$den;
		$f = -$coef->[3]**2/$den;
		
		# make Mahalanobis matrix
		$mat = [
			[$a, $d, $e],
			[$d, $b, $f],
			[$e, $f, $c]
		];
		
		# bless the object
		bless($mat, 'Math::Matrix');
		
		# for each sample
		for my $i (1 .. $#{$self->[1]}) {
			
			# if all device channels are white
			if (@{$dev} == grep {$_ == $mwv} @{$self->[1][$i]}[@{$dev}]) {
				
				# save CTV (0)
				$self->[1][$i][$cols->[0]] = 0;
				
			} else {
				
				# compute sample Lx, Ly, Lz values
				@Ls = ICC::Shared::_Lab2Lxyz(@{$self->[1][$i]}[@{$Lab}]);
				
				# save CTV (computed as Mahalanobis distance)
				$self->[1][$i][$cols->[0]] = _mahal(\@wtpt, \@Ls, $mat);
				
			}
			
		}
		
	} else {
		
		# warn
		warn('spectral, XYZ or L*a*b* data is required');
		
		# return empty
		return();
		
	}

	# return column slice
	return($cols);

}

# append L*a*b* data to data array
# computed from XYZ data or spectral data
# if L*a*b* data already exists, returns that slice
# adds XYZ data, if only spectral data exists
# parameter: ([hash])
# returns: (column_slice)
sub add_lab {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($context, $added, $cols, $xyz, $color, $iwtpt, $WPxyz);

	# get base context
	$context = $hash->{'context'};

	# get added context
	$added = defined($hash->{'added'}) ? $hash->{'added'} : $context;

	# return column slice if L*a*b* data already exists
	return($cols) if ($cols = _cols($self, map {defined($added) ? "$added|$_" : $_} qw(LAB_L LAB_A LAB_B)));

	# if XYZ data exists, or is added
	if ($xyz = (_cols($self, map {defined($context) ? "$context|$_" : $_} qw(XYZ_X XYZ_Y XYZ_Z)) || add_xyz($self, $hash))) {
		
		# get XYZ colorimetry hash
		$color = $self->[2][6][$xyz->[0]];
		
		# for each possible colorimetry key
		for my $key (qw(illuminant observer increment bandpass cat)) {
			
			# if key is specified
			if (defined($hash->{$key})) {
				
				# if YAML strings differ
				if (YAML::Tiny::Dump($hash->{$key}) ne YAML::Tiny::Dump($color->{$key})) {
					
					# print warning
					warn("$key parameter differs from source");
					
				}
				
			}
			
		}
		
		# if 'context' and 'added' keys are undefined, and XYZ source has context
		if (! defined($added) && $self->[1][0][$xyz->[0]] =~ m/^(.*)\|/) {
			
			# set 'added' to XYZ context
			$added = $1;
			
		}
		
		# add L*a*b* columns slice
		$cols = add_fmt($self, map {defined($added) ? "$added|$_" : $_} qw(LAB_L LAB_A LAB_B));
		
		# get supplied illuminant white point
		$iwtpt = $hash->{'iwtpt'};
		
		# if supplied illuminant white point is valid
		if (defined($iwtpt) && (3 == grep {defined() && ! ref() && $_ > 0} @{$iwtpt})) {
			
			# use it
			$WPxyz = $iwtpt;
			
		# if XYZ illuminant white point is valid
		} elsif (3 == grep {defined() && ! ref() && $_ > 0} @{$self->[2][2]}[@{$xyz}]) {
			
			# use it
			$WPxyz = [@{$self->[2][2]}[@{$xyz}]];
			
		} else {
			
			# use D50
			$WPxyz = ICC::Shared::D50;
			
		}
		
		# set origin
		@{$self->[2][0]}[@{$cols}] = ($xyz) x 3;
		
		# save illuminant white point
		@{$self->[2][2]}[@{$cols}] = @{$WPxyz};
		
		# save colorimetry hash
		@{$self->[2][6]}[@{$cols}] = ($color) x 3;
		
		# for each sample
		for my $s (1 .. $#{$self->[1]}) {
			
			# compute L*a*b* values from XYZ values
			@{$self->[1][$s]}[@{$cols}] = ICC::Shared::_XYZ2Lab(@{$self->[1][$s]}[@{$xyz}], $WPxyz);
			
		}
		
	} else {
		
		# warn
		warn('spectral or XYZ data is required');
		
		# return empty
		return();
		
	}

	# return column slice
	return($cols);

}

# append XYZ data to data array
# computed from spectral data or L*a*b* data
# if XYZ data already exists, returns that slice
# default colorimetry is D50, 2 degree observer
# parameters: ([hash])
# returns: (column_slice)
sub add_xyz {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($oba, $spec1, $spec2, $context, $added);
	my ($spec, $color, $illum, $specv, $nm, $cols);
	my ($cat, $spectral, $xyz, $Lab, @WPlab, $WPxyz);

	# if 'oba' defined
	if (defined($hash->{'oba'})) {
		
		# get oba factor
		$oba = $hash->{'oba'};
		
		# if 'context' defined
		if (defined($hash->{'context'})) {
			
			# if context an array reference containing two scalars
			if (ref($hash->{'context'}) eq 'ARRAY' && ! ref($hash->{'context'}->[0]) && ! ref($hash->{'context'}->[1])) {
				
				# get specified 'M1' spectral slice
				$spec1 = spectral($self, {'context' => $hash->{'context'}->[0]});
				
				# get specified 'M2' spectral slice
				$spec2 = spectral($self, {'context' => $hash->{'context'}->[1]});
				
				# use specified 'M2' context
				$context = $hash->{'context'}->[1];
				
			} else {
				
				# warn
				warn('OBA context is an array reference containing M1 and M2 contexts');
				
				# return empty
				return();
				
			}
			
		} else {
			
			# get spectral slice using standard 'M1' context
			$spec1 = spectral($self, {'context' => 'M1_Measurement'});
			
			# get spectral slice using standard 'M2' context
			$spec2 = spectral($self, {'context' => 'M2_Measurement'});
			
			# use standard 'M2' context
			$context = 'M2_Measurement';
			
		}
		
		# verify spectral slices
		if (! $spec1 || ! $spec2 || $#{$spec1} != $#{$spec2}) {
			
			# warn
			warn('M1 and M2 spectral data required for OBA effect');
			
			# return empty
			return();
			
		}
		
		# get added context
		$added = defined($hash->{'added'}) ? $hash->{'added'} : 'OBA';
		
	} else {
		
		# get base context
		$context = $hash->{'context'};
		
		# get added context
		$added = defined($hash->{'added'}) ? $hash->{'added'} : $context;
		
	}

	# return column slice if XYZ data already exists
	return($cols) if ($cols = _cols($self, map {defined($added) ? "$added|$_" : $_} qw(XYZ_X XYZ_Y XYZ_Z)));

	# if spectral data exists
	if (test($self, 'SPECTRAL', $context)) {
		
		# get spectral slice
		$spec = spectral($self, {'context' => $context});
		
		# add chart wavelength range to hash
		$hash->{'range'} = nm($self, {'context' => $context});
		
		# make empty 'Color.pm' object
		$color = ICC::Support::Color->new();
		
		# if illuminant is defined, an array reference
		if (defined($hash->{'illuminant'}) && ref($hash->{'illuminant'}) eq 'ARRAY') {
			
			# if illuminant is ['DATA'] (ProfileMaker convention)
			if (defined($hash->{'illuminant'}->[0]) && $hash->{'illuminant'}->[0] eq 'DATA') {
				
				# verify chart object contains illuminant data
				(defined($self->[0]{'illuminant'}) && ref($self->[0]{'illuminant'}) eq 'ARRAY') || croak('no illuminant data');
				
				# make new chart object from illuminant data
				$illum = ICC::Support::Chart->new($self->[0]{'illuminant'});
				
				# get spectral values
				($specv = $illum->spectral([1])->[0]) || croak('illuminant chart has no spectral data');
				
				# get wavelength range
				$nm = $illum->nm();
				
				# update 'illuminant' value in hash
				$hash->{'illuminant'} = [$nm, $specv];
				
			}
			
			# initialize object for CIE method
			ICC::Support::Color::_cie($color, $hash);
			
		} else {
			
			# initialize object for ASTM method
			ICC::Support::Color::_astm($color, $hash);
			
		}
		
		# if 'context' and 'added' keys are undefined, and spectral source has context
		if (! defined($added) && $self->[1][0][$spec->[0]] =~ m/^(.*)\|/) {
			
			# set 'added' to spectral context
			$added = $1;
			
		}
		
		# add XYZ columns slice
		$cols = add_fmt($self, map {defined($added) ? "$added|$_" : $_} qw(XYZ_X XYZ_Y XYZ_Z));
		
		# set origin
		@{$self->[2][0]}[@{$cols}] = ($spec) x 3;
		
		# save reference to Color.pm object
		@{$self->[2][1]}[@{$cols}] = ($color) x 3;
		
		# if chromatic adaptation transform (cat) is specified
		if (defined($hash->{'cat'})) {
			
			# if cat is 'matf' object
			if (UNIVERSAL::isa($hash->{'cat'}, 'ICC::Profile::matf')) {
				
				# use it
				$cat = $hash->{'cat'};
				
			# if cat is 'bradford'
			} elsif ($hash->{'cat'} eq 'bradford') {
				
				# make 'bradford' object
				$cat = ICC::Profile::matf->bradford($color->iwtpt());
				
			# if cat is 'cat02'
			} elsif ($hash->{'cat'} eq 'cat02') {
				
				# make 'cat02' object
				$cat = ICC::Profile::matf->cat02($color->iwtpt());
				
			# if cat is 'quasi'
			} elsif ($hash->{'cat'} eq 'quasi') {
				
				# make 'quasi' object
				$cat = ICC::Profile::matf->quasi($color->iwtpt());
				
			} else {
				
				# warn
				warn('invalid cat type');
				
			}
			
		}
		
		# if cat defined
		if (defined($cat)) {
			
			# save cat reference
			@{$self->[2][2]}[@{$cols}] = ($cat) x 3;
			
		} else {
			
			# save white point
			@{$self->[2][2]}[@{$cols}] = @{$color->iwtpt()};
			
		}
		
		# save colorimetry hash
		@{$self->[2][6]}[@{$cols}] = ({map {defined($hash->{$_}) ? ($_, $hash->{$_}) : ()} qw(illuminant observer bandpass method ibandpass imethod oba cat increment range encoding)}) x 3;
		
		# for each sample
		for my $i (1 .. $#{$self->[1]}) {
			
			# get spectral slice
			$spectral->[$i - 1] = [@{$self->[1][$i]}[@{$spec}]];
			
		}
		
		# transform to XYZ data (hash may contain 'encoding' key)
		$xyz = ICC::Support::Color::_trans2($color, $spectral, $hash);
		
		# add OBA effect, if enabled
		_add_oba($self, $spec1, $spec2, $xyz, $oba, $hash) if $oba;
		
		# for each sample
		for my $i (1 .. $#{$self->[1]}) {
			
			# if cat defined
			if (defined($cat)) {
				
				# set XYZ slice with cat
				@{$self->[1][$i]}[@{$cols}] = ICC::Profile::matf::_trans0($cat, @{$xyz->[$i - 1]});
				
			} else {
				
				# set XYZ slice
				@{$self->[1][$i]}[@{$cols}] = @{$xyz->[$i - 1]};
				
			}
			
		}
		
	# if L*a*b* data exists
	} elsif (test($self, 'LAB', $context)) {
		
		# warn if illuminant is specified
		(! defined($hash->{'illuminant'})) || warn('illuminant specified but no spectral data!');
		
		# get L*a*b* slice
		$Lab = cols($self, map {defined($context) ? "$context|$_" : $_} qw(LAB_L LAB_A LAB_B));
		
		# if 'context' and 'added' keys are undefined, and L*a*b* source has context
		if (! defined($added) && $self->[1][0][$Lab->[0]] =~ m/^(.*)\|/) {
			
			# set 'added' to L*a*b* context
			$added = $1;
			
		}
		
		# get L*a*b* white point values
		@WPlab = @{$self->[2][2]}[@{$Lab}];
		
		# use scalar values or D50
		$WPxyz = (3 == grep {defined() && ! ref() && $_ > 0} @WPlab) ? [@WPlab] : ICC::Shared::D50;
		
		# add XYZ columns slice
		$cols = add_fmt($self, map {defined($added) ? "$added|$_" : $_} qw(XYZ_X XYZ_Y XYZ_Z));
		
		# set origin
		@{$self->[2][0]}[@{$cols}] = ($Lab) x 3;
		
		# save illuminant white point
		@{$self->[2][2]}[@{$cols}] = @{$WPxyz};
		
		# for each sample
		for my $s (1 .. $#{$self->[1]}) {
			
			# compute XYZ values from L*a*b* values
			@{$self->[1][$s]}[@{$cols}] = ICC::Shared::_Lab2XYZ(@{$self->[1][$s]}[@{$Lab}], $WPxyz);
			
		}
		
	} else {
		
		# warn
		warn('spectral or L*a*b* data is required');
		
		# return empty
		return();
		
	}

	# return column slice
	return($cols);

}

# append ISO 5-3 density data to data array
# computed from spectral data only
# if density data already exists, return that slice
# default status is 'T', encoding is 'density'
# parameters: ([hash])
# returns: (column_slice)
sub add_density {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($context, $added, $encode, $fp, $cols, $spec, $temp, $color, $spectral, $rgbv);

	# get base context
	$context = $hash->{'context'};

	# get added context
	$added = defined($hash->{'added'}) ? $hash->{'added'} : $context;

	# get encoding
	$encode = $hash->{'encoding'} // 'density';

	# if invalid encoding
	if ($encode ne 'density' && $encode ne 'linear') {
		
		# warn
		warn('invalid density encoding, using \'density\'');
		
		# set encoding
		$encode = 'density';
		
	}

	# set format prefix
	$fp = $encode eq 'density' ? 'D' : 'R';

	# return column slice if density/reflectance data already exists
	return($cols) if ($cols = cols($self, map {defined($added) ? "$added|$fp$_" : "$fp$_"} qw(_RED _GREEN _BLUE _VIS)));

	# if spectral data
	if (test($self, 'SPECTRAL', $context)) {
		
		# get spectral slice
		$spec = spectral($self, $hash);
		
		# make copy of hash
		$temp = Storable::dclone($hash);
		
		# add chart wavelength range to hash
		$temp->{'range'} = nm($self, $hash);
		
		# make empty 'Color.pm' object
		$color = ICC::Support::Color->new();
		
		# initialize object for ISO 5-3 method
		ICC::Support::Color::_iso($color, $temp);
		
		# if 'context' and 'added' keys are undefined, and spectral source has context
		if (! defined($added) && $self->[1][0][$spec->[0]] =~ m/^(.*)\|/) {
			
			# set 'added' to spectral context
			$added = $1;
			
		}
		
		# add density/reflectance columns slice
		$cols = add_fmt($self, map {defined($added) ? "$added|$fp$_" : "$fp$_"} qw(_RED _GREEN _BLUE _VIS));
		
		# set origin
		@{$self->[2][0]}[@{$cols}] = ($spec) x 4;
		
		# save reference to Color.pm object
		@{$self->[2][1]}[@{$cols}] = ($color) x 4;
		
		# save colorimetry hash
		@{$self->[2][6]}[@{$cols}] = ({map {defined($temp->{$_}) ? ($_, $temp->{$_}) : ()} qw(status increment range encoding)}) x 4;
		
		# for each sample
		for my $i (1 .. $#{$self->[1]}) {
			
			# get spectral slice
			$spectral->[$i - 1] = [@{$self->[1][$i]}[@{$spec}]];
			
		}
		
		# set encoding
		$temp->{'encoding'} = $encode;
		
		# transform to density/reflectance data (per encoding)
		$rgbv = ICC::Support::Color::_trans2($color, $spectral, $temp);
		
		# for each sample
		for my $i (1 .. $#{$self->[1]}) {
			
			# set data values
			@{$self->[1][$i]}[@{$cols}] = @{$rgbv->[$i - 1]};
			
		}
	
	} else {
		
		# warn
		warn('spectral data is required');
		
		# return empty
		return();
		
	}

	# return column slice
	return($cols);

}

# add computed values to data array
# processing is done by a user-defined function (udf)
# data groups are defined by one or more column slice(s)
# supported hash keys: 'element', 'sample', 'device', 'rows', 'start', 'added'
# either an 'element' udf or a 'sample' udf are required, but not both
# an 'element' udf computes a single value from single slice value(s)
# a 'sample' udf computes all values at once from slice value array(s)
# setting the 'device' flag converts RGB/CMYK/nCLR values to device values
# the 'rows' parameter is the row slice computed, default is all rows
# the 'start' parameter is the first column computed, default is to append
# the 'added' parameter may be a scalar or an array reference
# an 'added' scalar will be used as a context prefix
# an 'added' array must be the same size as the columns added
# parameters: (column_slice_0, column_slice_1, ... hash)
# returns: (added_column_slice)
sub add_udf {

	# local variables
	my ($self, $hash, @cs, $rows, $m, $n, @div, $udfe, $udfs);
	my (@p, @u, @s, $cx, $added);

	# get object reference
	$self = shift();

	# get parameter hash
	$hash = pop();

	# verify a hash reference
	(ref($hash) eq 'HASH') || croak('last parameter must be a hash reference');

	# verify number of slices
	(@cs = @_) || croak('one or more column slices are required');

	# get row slice, all rows by default
	$rows = defined($hash->{'rows'}) ? $hash->{'rows'} : [];

	# if row slice an empty array reference
	if (ref($rows) eq 'ARRAY' && @{$rows} == 0) {
		
		# use all rows
		$rows = [1 .. $#{$self->[1]}];
		
	} else {
		
		# flatten row slice
		$rows = ICC::Shared::flatten($rows);
		
		# verify row slice contents
		(@{$rows} == grep {Scalar::Util::looks_like_number($_) && int($_) == $_ && $_ > 0 && $_ <= $#{$self->[1]}} @{$rows}) || croak('invalid row slice');
		
	}

	# get starting column, append by default
	$n = defined($hash->{'start'}) ? $hash->{'start'} : $#{$self->[1][0]} + 1;

	# if an array reference (slice), use the first value
	$n = $n->[0] if (ref($n) eq 'ARRAY');

	# verify starting column
	(Scalar::Util::looks_like_number($n) && int($n) eq $n && $n >= 0) || croak('invalid \'start\' parameter');

	# if 'device' flag
	if ($hash->{'device'}) {
		
		# for each data format
		for my $i (0 .. $#{$self->[1][0]}) {
			
			# set divisor to 255 for RGB data
			$div[$i] = 255 if ($self->[1][0][$i] =~ m/RGB_[RGB]$/);
			
			# set divisor to 100 for CMYK data
			$div[$i] = 100 if ($self->[1][0][$i] =~ m/CMYK_[CMYK]$/);
			
			# set divisor to 100 for nCLR data
			$div[$i] = 100 if ($self->[1][0][$i] =~ m/[2-9A-F]CLR_[1-9A-F]$/);
		}
		
	}

	# get udf CODE refs
	$udfe = $hash->{'element'};
	$udfs = $hash->{'sample'};

	# if both udfs defined
	if (defined($udfe) && defined($udfs)) {
		
		# error
		croak('both \'element\' and \'sample\' udfs are defined');
		
	# if 'element' udf defined
	} elsif (defined($udfe)) {
		
		# verify udf is a code reference
		(ref($udfe) eq 'CODE') || croak('\'element\' udf is not a CODE reference');
		
		# for each parameter
		for my $i (0 .. $#cs) {
			
			# if an array reference
			if (ref($cs[$i]) eq 'ARRAY') {
				
				# if first slice
				if (! defined($m)) {
					
					# get upper index
					$m = $#{$cs[0]};
					
					# compute added slice
					@s = ($n .. $n + $m);
					
				} else {
					
					# verify slice size
					($#{$cs[$i]} == $m) || croak('column slices are different sizes');
					
				}
				
				# verify a valid column slice
				(ref($cs[$i]) eq 'ARRAY' || @{$cs[$i]} == grep {Scalar::Util::looks_like_number($_) && int($_) == $_ && $_ >= 0 && $_ <= $#{$self->[1][0]}} @{$cs[$i]}) || croak('invalid column slice');
				
			# if a scalar
			} elsif (! ref($cs[$i])) {
				
				# verify a valid column index
				(Scalar::Util::looks_like_number($cs[$i]) && int($cs[$i]) == $cs[$i] && $cs[$i] >= 0 && $cs[$i] <= $#{$self->[1][0]}) || croak('invalid column index');
				
			} else {
				
				# error
				croak('parameter must be a scalar or an array reference');
				
			}
			
		}
		
		# verify at least one column slice parameter
		(defined($m)) || croak('at least one column slice is required');
		
		# for each sample
		for my $i (@{$rows}) {
			
			# for each column index
			for my $j (0 .. $m) {
				
				# for each parameter
				for my $k (0 .. $#cs) {
					
					# get column index (slice -or- scalar)
					$cx = (ref($cs[$k]) eq 'ARRAY') ? $cs[$k][$j] : $cs[$k];
					
					# get parameter value
					$p[$k] = $self->[1][$i][$cx];
					
					# adjust device values, if divisor defined
					$p[$k] /= $div[$cx] if defined($div[$cx]);
					
				}
				
				# call 'element' udf
				$self->[1][$i][$n + $j] = &$udfe(@p, $j);
				
			}
			
		}
		
	# if 'sample' udf defined
	} elsif (defined($udfs)) {
		
		# verify udf is a code reference
		(ref($udfs) eq 'CODE') || croak('\'sample\' udf is not a CODE reference');
		
		# for each parameter
		for my $i (0 .. $#cs) {
			
			# verify a valid column slice
			(ref($cs[$i]) eq 'ARRAY' || @{$cs[$i]} == grep {Scalar::Util::looks_like_number($_) && int($_) == $_ && $_ >= 0 && $_ <= $#{$self->[1][0]}} @{$cs[$i]}) || croak('invalid column slice');
			
		}
		
		# verify at least one parameter
		(@cs) || croak('at least one column slice is required');
		
		# for each sample
		for my $i (@{$rows}) {
			
			# for each column slice
			for my $j (0 .. $#cs) {
				
				# for each slice element
				for my $k (0 .. $#{$cs[$j]}) {
					
					# get column index
					$cx = $cs[$j][$k];
					
					# get parameter value
					$p[$j][$k] = $self->[1][$i][$cx];
					
					# adjust device values, if divisor defined
					$p[$j][$k] /= $div[$cx] if defined($div[$cx]);
					
				}
				
			}
			
			# if first sample
			if (! defined($m)) {
				
				# call 'sample' udf
				@u = &$udfs(@p);
				
				# get upper index
				$m = $#u;
				
				# compute added slice
				@s = ($n .. $n + $m);
				
				# copy values to object
				@{$self->[1][$i]}[@s] = @u;
				
			} else {
				
				# call 'sample' udf
				@{$self->[1][$i]}[@s] = &$udfs(@p);
				
			}
			
		}
		
	} else {
		
		# error
		croak('no udf is defined');
		
	}

	# get 'added' parameter, default is 'udf', could be undefined
	$added = exists($hash->{'added'}) ? $hash->{'added'} : 'udf';

	# if 'added' is undefined
	if (! defined($added)) {
		
		# if 'element' udf -or- size of first column slice equals number of added columns
		if (defined($udfe) || @{$cs[0]} == @s) {
			
			# add data format stripping context from first column slice
			@{$self->[1][0]}[@s] = map {m/^(?:.*\|)?(.*)$/; $1} @{$self->[1][0]}[@{$cs[0]}];
			
		} else {
			
			# add data format as 'colxxx'
			@{$self->[1][0]}[@s] = map {"col$_"} @s;
			
		}
		
	# if 'added' a scalar
	} elsif (! ref($added)) {
		
		# if 'element' udf -or- size of first column slice equals number of added columns
		if (defined($udfe) || @{$cs[0]} == @s) {
			
			# add data format using 'added' as context with first column slice format keys
			@{$self->[1][0]}[@s] = map {m/^(?:.*\|)?(.*)$/; "$added|$1"} @{$self->[1][0]}[@{$cs[0]}];
			
		} else {
			
			# add data format using 'added' as context to 'colxxx'
			@{$self->[1][0]}[@s] = map {"$added|col$_"} @s;
			
		}
		
	# if 'added' is an array ref and size equals number of added columns
	} elsif (ref($added) eq 'ARRAY' && @{$added} == @s) {
		
		# add data format using 'added' as array
		@{$self->[1][0]}[@s] = @{$added};
		
	} else {
		
		# error
		croak('invalid \'added\' parameter');
		
	}

	# return added column slice
	return([@s]);

}

# append date column to data array
# adds same date/time to each sample
# supported hash keys: 'date', 'format', 'added'
# parameter: ([hash])
# returns: (column_slice)
sub add_date {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($cols, $added, $date, $fmt, $str);

	# get added context
	$added = $hash->{'added'};

	# return column slice if date column already exists
	return($cols) if ($cols = _cols($self, defined($added) ? "$added|CREATED" : 'CREATED'));

	# add date column slice
	$cols = add_fmt($self, defined($added) ? "$added|CREATED" : 'CREATED');

	# if date supplied
	if (defined($date = $hash->{'date'})) {
		
		# if date is a number
		if (Scalar::Util::looks_like_number($date)) {
			
			# make Time::Piece object
			$date = localtime($date);
			
		# if date not a Time::Piece object
		} elsif (ref($date) ne 'Time::Piece') {
			
			# error
			croak('invalid date parameter');
		}
		
	} else {
		
		# use 'CREATED' value from chart
		$date = created($self);
		
	}

	# compute the date/time string (same for each sample)
	$str = defined($fmt = $hash->{'format'}) ? $date->strftime($fmt) : $date->epoch();

	# for each row
	for my $i (1 .. $#{$self->[1]}) {
		
		# set the date time string
		$self->[1][$i][$cols->[0]] = $str;
		
	}

	# return column slice
	return($cols);

}

# splice rows into data array
# offset and length are as used by Perl's 'splice' function
# data matrix is the 2-D array of data values to be spliced
# column slice is a reference to an array of data matrix column indices
# parameters: ([offset, [length, [data_matrix, [column_slice]]]])
# returns: (removed_data_matrix)
sub splice_rows {

	# get parameters
	my ($self, $offset, $length, $matrix, $cols) = @_;

	# local variables
	my (@ix, @list, @s, $removed);

	# if offset supplied
	if (defined($offset)) {
		
		# verify offset a scalar
		(! ref($offset) && (int($offset) == $offset)) || croak('invalid offset parameter');
		
	}

	# if length supplied
	if (defined($length)) {
		
		# verify length an integer scalar
		(! ref($length) && int($length) == $length) || croak('invalid length parameter');
		
	}

	# if matrix supplied
	if (defined($matrix)) {
		
		# verify matrix a 2-D array or Math::Matrix object
		(ref($matrix) eq 'ARRAY' && ref($matrix->[0]) eq 'ARRAY') || (UNIVERSAL::isa($matrix, 'Math::Matrix')) || croak ('invalid matrix parameter');
		
	}

	# if column slice supplied
	if (defined($cols)) {
		
		# verify column slice an array reference
		(ref($cols) eq 'ARRAY') || croak('invalid cols parameter');
		
		# verify length, offset and matrix supplied
		(defined($length) && defined($offset) && defined($matrix)) || croak('cols requires length, offset and matrix');
		
		# flatten column slice
		@ix = @{ICC::Shared::flatten($cols)};
		
		# make splice list using column slice
		@list = map {@s[@ix] = @{$_}; [@s]} @{$matrix};
		
		# splice the data
		$removed = [splice(@{$self->[1]}, $offset, $length, @list)];
		
	} else {
		
		# if matrix supplied
		if (defined($matrix)) {
			
			# verify length, offset
			(defined($length) && defined($offset)) || croak('matrix requires length and offset');
			
			# make splice list from full matrix
			@list = map {[@{$_}]} @{$matrix};
			
			# splice the data
			$removed = [splice(@{$self->[1]}, $offset, $length, @list)];
			
		} else {
			
			# if length supplied
			if (defined($length)) {
				
				# verify offset supplied
				(defined($offset)) || croak('length requires offset');

				# splice the data
				$removed = [splice(@{$self->[1]}, $offset, $length)];
				
			} else {
				
				# if offset supplied
				if (defined($offset)) {
					
					# splice the data
					$removed = [splice(@{$self->[1]}, $offset)];
					
				} else {
					
					# get data array reference
					$removed = $self->[1];
					
					# init data array
					$self->[1] = [[]];
					
					# init colorimetry array
					$self->[2] = [[]];
					
				}
				
			}
			
		}
		
	}

	# update the SAMPLE_ID hash
	_makeSampleID($self);

	# return removed data
	return(bless($removed, 'Math::Matrix'));

}

# splice columns into data array
# offset and length are as used by Perl's 'splice' function
# data matrix is the 2-D array of data values to be spliced
# row slice is a reference to an array of data matrix row indices
# parameters: ([offset, [length, [data_matrix, [row_slice]]]])
# returns: (removed_data_matrix)
sub splice_cols {

	# get parameters
	my ($self, $offset, $length, $matrix, $rows) = @_;

	# local variables
	my (@ix, @s, @filler, $removed);

	# if offset supplied
	if (defined($offset)) {
		
		# verify offset a scalar
		(! ref($offset) && (int($offset) == $offset)) || croak('invalid offset parameter');
		
	}

	# if length supplied
	if (defined($length)) {
		
		# verify length an integer scalar
		(! ref($length) && int($length) == $length) || croak('invalid length parameter');
		
	}

	# if matrix supplied
	if (defined($matrix)) {
		
		# verify matrix a 2-D array or Math::Matrix object
		(ref($matrix) eq 'ARRAY' && ref($matrix->[0]) eq 'ARRAY') || (UNIVERSAL::isa($matrix, 'Math::Matrix')) || croak ('invalid matrix parameter');
		
	}

	# if row slice supplied
	if (defined($rows)) {
		
		# verify row slice an array reference
		(ref($rows) eq 'ARRAY') || croak('invalid cols parameter');
		
		# verify length, offset and matrix supplied
		(defined($length) && defined($offset) && defined($matrix)) || croak('rows requires length, offset and matrix');
		
		# flatten row slice
		@ix = @{ICC::Shared::flatten($rows)};
		
		# make list of matrix row refs
		@s[@ix] = @{$matrix};
		
		# make filler data
		@filler = (undef) x @{$matrix->[0]};
		
		# for each data row
		for my $i (0 .. $#{$self->[1]}) {
			
			# if matrix data defined
			if (defined($s[$i])) {
				
				# splice matrix data
				$removed->[$i] = [splice(@{$self->[1][$i]}, $offset, $length, @{$s[$i]})];
				
			} else {
				
				# splice filler data
				$removed->[$i] = [splice(@{$self->[1][$i]}, $offset, $length, @filler)];
				
			}
			
		}
		
		# for each colorimetry row
		for my $i (0 .. $#{$self->[2]}) {
			
			# splice filler data
			splice(@{$self->[2][$i]}, $offset, $length, @filler) if (defined($self->[2][$i][$offset]));
			
		}
		
	} else {
		
		# if matrix supplied
		if (defined($matrix)) {
			
			# verify length, offset
			(defined($length) && defined($offset)) || croak('matrix requires length and offset');
			
			# make filler data
			@filler = (undef) x @{$matrix->[0]};
			
			# for each data row
			for my $i (0 .. $#{$self->[1]}) {
				
				# if matrix data defined
				if (defined($matrix->[$i])) {
					
					# splice matrix data
					$removed->[$i] = [splice(@{$self->[1][$i]}, $offset, $length, @{$matrix->[$i]})];
					
				} else {
					
					# splice filler data
					$removed->[$i] = [splice(@{$self->[1][$i]}, $offset, $length, @filler)];
					
				}
				
			}
			
			# for each colorimetry row
			for my $i (0 .. $#{$self->[2]}) {
				
				# splice filler data
				splice(@{$self->[2][$i]}, $offset, $length, @filler) if (defined($self->[2][$i][$offset]));
				
			}
			
		} else {
			
			# if length supplied
			if (defined($length)) {
				
				# verify offset supplied
				(defined($offset)) || croak('length requires offset');
				
				# for each data row
				for my $i (0 .. $#{$self->[1]}) {
					
					# splice the data
					$removed->[$i] = [splice(@{$self->[1][$i]}, $offset, $length)];
					
				}
				
				# for each colorimetry row
				for my $i (0 .. $#{$self->[2]}) {
					
					# splice filler data
					splice(@{$self->[2][$i]}, $offset, $length) if (defined($self->[2][$i][$offset]));
					
				}
				
			} else {
				
				# if offset supplied
				if (defined($offset)) {
					
					# for each data row
					for my $i (0 .. $#{$self->[1]}) {
						
						# splice the data
						$removed->[$i] = [splice(@{$self->[1][$i]}, $offset)];
						
					}
					
					# for each colorimetry row
					for my $i (0 .. $#{$self->[2]}) {
						
						# splice filler data
						splice(@{$self->[2][$i]}, $offset) if (defined($self->[2][$i][$offset]));
						
					}
					
				} else {
					
					# get data array reference
					$removed = $self->[1];
					
					# init data array
					$self->[1] = [[]];
					
					# init colorimetry array
					$self->[2] = [[]];
					
				}
				
			}
			
		}
		
	}

	# initialize SAMPLE_ID hash if no SAMPLE_ID field
	$self->[4] = {} if (0 == test($self, 'ID'));

	# return removed data
	return(bless($removed, 'Math::Matrix'));

}

# remove rows from data array
# parameters: (row_slice)
# returns: (removed_data_matrix)
sub remove_rows {

	# get parameters
	my ($self, $rows) = @_;

	# local variables
	my ($f, $up, @r, @s, $removed);

	# return empty matrix if row slice undefined
	return(bless([[]], 'Math::Matrix')) if (! defined($rows));

	# flatten row slice
	$f = ICC::Shared::flatten($rows);

	# if row slice is empty
	if (! defined($f->[0])) {
		
		# remove all rows, except row 0 (DATA_FORMAT)
		$removed = [splice(@{$self->[1]}, 1)];
		
		# clear SAMPLE_ID hash
		$self->[4] = {};
		
		# return removed data
		return(bless($removed, 'Math::Matrix'));
		
	}

	# get upper row index
	$up = $#{$self->[1]};

	# verify row slice
	(grep {$_ != int($_) || $_ < 1 || $_ > $up} @{$f}) && carp('row slice contains invalid index value(s)');

	# initialize slice (always keep row 0)
	@s = (0);

	# for each row
	for my $i (1 .. $up) {
		
		# if index contained in row slice
		if (grep {$i == $_} @{$f}) {
			
			# add to slice (remove)
			push(@r, $i);
			
		} else {
			
			# add to slice (keep)
			push(@s, $i)
			
		}
		
	}

	# if rows to remove
	if (@r) {
		
		# set removed data (@r)
		$removed = [@{$self->[1]}[@r]];
		
		# set kept data (@s)
		$self->[1] = [@{$self->[1]}[@s]];
		
		# update the SAMPLE_ID hash
		_makeSampleID($self);
		
	} else {
		
		# set removed data (none)
		$removed = [[]];
		
	}

	# return removed data
	return(bless($removed, 'Math::Matrix'));

}

# remove columns from data array
# parameters: (column_slice)
# returns: (removed_data_matrix)
sub remove_cols {

	# get parameters
	my ($self, $cols) = @_;

	# local variables
	my ($f, $up, @r, @s, $removed, $kept, $color);

	# return empty matrix if column slice undefined
	return(bless([[]], 'Math::Matrix')) if (! defined($cols));

	# flatten column slice
	$f = ICC::Shared::flatten($cols);

	# if columns slice is empty
	if (! defined($f->[0])) {
		
		# copy all rows
		$removed = [@{$self->[1]}];
		
		# clear data array
		$self->[1] =[[]];
		
		# clear colorimetry array
		$self->[2] = [[]];
		
		# clear SAMPLE_ID hash
		$self->[4] = {};
		
		# return removed data
		return(bless($removed, 'Math::Matrix'));
		
	}

	# get upper column index
	$up = $#{$self->[1][0]};

	# verify column slice
	(grep {$_ != int($_) || $_ < 0 || $_ > $up} @{$f}) && carp('column slice contains invalid index value(s)');

	# for each column
	for my $i (0 .. $up) {
		
		# if index contained in column slice
		if (grep {$i == $_} @{$f}) {
			
			# add to slice (remove)
			push(@r, $i);
			
		} else {
			
			# add to slice (keep)
			push(@s, $i)
			
		}
		
	}

	# if columns to remove
	if (@r) {
		
		# for each data row
		for my $i (0 .. $#{$self->[1]}) {
			
			# set removed data (@r)
			$removed->[$i] = [@{$self->[1][$i]}[@r]];
			
			# set kept data (@s)
			$kept->[$i] = [@{$self->[1][$i]}[@s]];
			
		}
		
		# update object data
		$self->[1] = $kept;
		
		# for each colorimetry row
		for my $i (0 .. $#{$self->[2]}) {
			
			# set kept colorimetry (@s)
			$color->[$i] = [@{$self->[2][$i]}[@s]];
			
		}
		
		# update colorimetry data
		$self->[2] = $color;
		
		# initialize SAMPLE_ID hash if no SAMPLE_ID field
		$self->[4] = {} if (0 == test($self, 'ID'));
		
	} else {
		
		# set removed data (none)
		$removed = [[]];
		
	}

	# return removed data
	return(bless($removed, 'Math::Matrix'));

}

# get sample selection based on 2-D location
# indices are one-based, with origin at the upper left
# row matrix slice may contain indices of undefined rows
# entire chart is used when the row and column indices are omitted
# chart row length is provided as a parameter, or obtained from the data
# parameters: ([upper_row_index, lower_row_index, left_column_index, right_column_index], [chart_row_length])
# returns: (row_matrix_slice)
sub select_matrix {

	# get object reference
	my $self = shift();

	# local variables
	my ($sn, $cmax, @rows, @cols, $matrix);
	my ($row_length, $upper, $lower, $left, $right);

	# get number of samples
	$sn = $#{$self->[1]};

	# if 0 or 4 parameters
	if (@_ == 0 || @_ == 4) {
		
		# get row length from data
		$row_length = _getRowLength($self);
		
	# if 1 or 5 parameters
	} elsif (@_ == 1 || @_ == 5) {
		
		# get row length
		$row_length = pop();
		
		# verify row length
		(Scalar::Util::looks_like_number($row_length) && $row_length == int($row_length) && $row_length > 0) || croak('invalid chart row length');
		
	} else {
		
		# error
		croak('wrong number of parameters');
		
	}
	
	# if row and column parameters provided
	if (@_) {
		
		# get row and column parameters
		($upper, $lower, $left, $right) = @_;
		
		# verify upper and lower indices
		(! ref($upper) && $upper == int($upper) && $upper > 0 && $upper <= $row_length) || warn('invalid upper row index');
		(! ref($lower) && $lower == int($lower) && $lower > 0 && $lower <= $row_length) || warn('invalid lower row index');
		
		# get maximum column index
		$cmax = $sn % $row_length ? int($sn/$row_length) + 1 : int($sn/$row_length);
		
		# verify left and right indices
		(! ref($left) && $left == int($left) && $left > 0 && $left <= $cmax) || warn('invalid left column index');
		(! ref($right) && $right == int($right) && $right > 0 && $right <= $cmax) || warn('invalid right column index');
		
		# if upper index < lower index
		if ($upper < $lower) {
			
			# make rows array
			@rows = ($upper .. $lower);
			
		} else {
			
			# make rows array
			@rows = reverse($lower .. $upper);
			
		}
		
		# if left index < right index
		if ($left < $right) {
			
			# make columns array
			@cols = ($left .. $right);
			
		} else {
			
			# make columns array
			@cols = reverse($right .. $left);
			
		}
		
	# use entire chart
	} else {
		
		# make rows array
		@rows = (1 .. $row_length);
		
		# if chart is rectangular
		if ($sn % $row_length == 0) {
			
			# make columns array
			@cols = (1 .. $sn/$row_length);
			
		} else {
			
			# warning
			warn('chart is not rectangular');
			
			# make columns array
			@cols = (1 .. int($sn/$row_length) + 1);
			
		}
		
	}

	# for each row
	for my $i (0 .. $#rows) {
		
		# for each column
		for my $j (0 .. $#cols) {
			
			# set matrix element
			$matrix->[$j][$i] = ($cols[$j] - 1) * $row_length + $rows[$i];
			
		}
		
	}

	# return row matrix slice
	return(bless($matrix, 'Math::Matrix'));

}

# get sample selection using template
# samples are matched by their device values
# supported hash keys: 'dups', 'rows', 'context', 'template_context', 'sid_context', 'method', 'copy'
# duplicate handling: 0 - sample average (default), 1 - FIFO, 2 - LIFO, 3 - first sample, 4 - last sample
# parameters: (template_chart_object, [hash])
# returns: (row_matrix_slice, [sid_matrix_slice])
sub select_template {

	# get parameters
	my ($self, $template, $hash) = @_;

	# local variables
	my ($row_length, $dups, $copys, $copyt);
	my ($devcs, $devct, $devs, $devt);
	my ($sx, $c1, $c2, $c3, $n, @src, $cmp);
	my ($target, $low, $high, $interval, @m, $nomatch);
	my ($rows, $avg, $matrix, $devp, $sidt, $sid);

	# verify template is a chart object
	(UNIVERSAL::isa($template, 'ICC::Support::Chart')) || croak('template not an ICC::Support::Chart object');

	# get template row length
	$row_length = _getRowLength($template, $hash);

	# set duplicate handling
	$dups = defined($hash->{'dups'}) ? $hash->{'dups'} : 0;

	# if copy slice is defined
	if (defined($hash->{'copy'})) {
		
		# flatten the copy slice
		$copys = ICC::Shared::flatten($hash->{'copy'});
		
		# add copied fields to template
		$copyt = add_fmt($template, @{$self->[1][0]}[@{$copys}]);
		
	}

	# verify parameters
	(! ref($row_length) && $row_length == int($row_length) && $row_length > 0) || croak('invalid chart_row_length parameter');
	($dups == int($dups) && $dups >= 0 && $dups <= 4) || croak('invalid duplicate_handling parameter');

	# get object device column slice
	$devcs = device($self, $hash);

	# get template device column slice
	$devct = device($template, {'context' => $hash->{'template_context'}});

	# verify object and template column slices
	(defined($devcs)) || croak ('object device data missing');
	(defined($devct)) || croak ('template device data missing');
	($#{$devcs} == $#{$devct}) || croak('object and template have different number of channels');

	# get object device values
	$devs = device($self, [], $hash);

	# get template device values
	$devt = device($template, [], {'context' => $hash->{'template_context'}});

	# get index of next object sample
	$sx = $#{$self->[1]} + 1;

	# get averaging groups if duplicates are averaged
	($c1, $c2, $c3) = _avg_groups($self, $hash) if ($dups == 0);

	# get number of channels
	$n = @{$devcs};

	# initialize sample list
	@src = ();

	# for each sample
	for my $i (0 .. $#{$devs}) {
		
		# if all device values defined
		if ($n == grep {defined()} @{$devs->[$i]}) {
			
			# add sample to source list
			push(@src, [@{$devs->[$i]}, $i + 1]);
			
		}
		
	}

	# sort object device values
	@src = sort {
		
		# for each channel
		for my $i (0 .. $#{$a}) {
			
			# quit loop if device values are unequal
			last if ($cmp = $a->[$i] <=> $b->[$i])
			
		# use last comparison for sort test
		} $cmp
		
	} @src;

	# for each template sample
	for my $i (0 .. $#{$devt}) {
		
		# initialize search indices
		$low = 0;
		$high = $#src;
		
		# initialize no match flag
		$nomatch = 0;
		
		# for each channel
		for my $j (0 .. $#{$devt->[0]}) {
			
			# get the target value
			$target = $devt->[$i][$j];
			
			# locate interval containing or bounding the target value
			$interval = _bin_search(\@src, $target, $j, $low, $high);
			
			# find indices matching the target value
			@m = grep {$src[$_][$j] == $target} @{$interval};
			
			# if no object values exactly match the target value
			if (@m == 0) {
				
				# sort interval indices by distance to target value
				@m = sort {$a->[1] <=> $b->[1]} map {[$_, abs($src[$_][$j] - $target)]} @{$interval};
				
				# if distance to closest object value > 0.00201
				if (abs($target - $src[$m[0][0]][$j]) > 0.00201) {
					
					# print warning
					print "no match to template sample $i\n";
					print "device values: @{$devt->[$i]}\n";
					
					# set no match flag
					$nomatch = 1;
					
					# quit channel loop
					last;
					
				}
				
				# set target to closest object value
				$target = $src[$m[0][0]][$j];
				
				# locate interval containing the target value
				$interval = _bin_search(\@src, $target, $j, $low, $high);
				
				# find indices matching the target value
				@m = grep {$src[$_][$j] == $target} @{$interval};
				
			}
			
			# update interval
			$low = $m[0];
			$high = $m[-1];
			
		}
		
		# if no match found
		if ($nomatch) {
			
			# locate nearest object sample(s) using linear search
			($low, $high) = _lin_search(\@src, $devt->[$i]);
			
			# print message
			print "closest match is object sample $src[$low][-1]\n";
			print "device values @{$src[$low]}[0 .. $#{$devt->[0]}]\n";
			
		}
		
		# single sample
		if ($low == $high) {
			
			# set matrix element to first row matching object sample
			$matrix->[$i/$row_length][$i % $row_length] = $src[$low][-1];
			
		# duplicate samples
		} else {
			
			# duplicates are averaged
			if ($dups == 0) {
				
				# for each appended avg sample
				for my $j ($sx .. $#{$self->[1]}) {
					
					# set avg
					$avg = $j;
					
					# get device values
					$devp = $self->device([$j]);
					
					# for each channel
					for my $k (0 .. $#{$devp->[0]}) {
						
						# clear avg if device values differ
						$avg = 0 if ($devp->[0][$k] != $devt->[$i][$k]);
						
					}
					
					# quit loop if device values match
					last if ($avg);
					
				}
				
				# if existing avg sample found
				if ($avg) {
					
					# set matrix element to existing avg sample
					$matrix->[$i/$row_length][$i % $row_length] = $avg;
					
				} else {
					
					# make row slice of duplicate samples
					$rows = [map {$src[$_][-1]} ($low .. $high)];
					
					# set matrix element to new avg sample
					$matrix->[$i/$row_length][$i % $row_length] = _add_avg($self, $rows, $c1, $c2, $c3);
					
				}
				
			# use FIFO sample
			} elsif ($dups == 1) {
				
				# from low to high
				for my $j ($low .. $high) {
					
					# if index > 0
					if ($src[$j][-1] > 0) {
						
						# set matrix element to object sample index
						$matrix->[$i/$row_length][$i % $row_length] = $src[$j][-1];
						
						# invert sample index to indicate it was used
						$src[$j][-1] = - $src[$j][-1];
						
						# quit loop
						last;
						
					}
					
				}
				
				# if matrix element undefined
				if (! defined($matrix->[$i/$row_length][$i % $row_length])) {
					
					# print message
					print "FIFO stack empty for @{$devt->[$i]}\n";
					print "using last stack sample\n";
					
					# set matrix element to last row matching object sample
					$matrix->[$i/$row_length][$i % $row_length] = - $src[$high][-1];
					
				}
				
			# use LIFO sample
			} elsif ($dups == 2) {
				
				# from high to low
				for my $j (reverse($low .. $high)) {
					
					# if index > 0
					if ($src[$j][-1] > 0) {
						
						# set matrix element to object sample index
						$matrix->[$i/$row_length][$i % $row_length] = $src[$j][-1];
						
						# invert sample index to indicate it was used
						$src[$j][-1] = - $src[$j][-1];
						
						# quit loop
						last;
						
					}
					
				}
				
				# if matrix element undefined
				if (! defined($matrix->[$i/$row_length][$i % $row_length])) {
					
					# print message
					print "LIFO stack empty for @{$devt->[$i]}\n";
					print "using last stack sample\n";
					
					# set matrix element to first row matching object sample
					$matrix->[$i/$row_length][$i % $row_length] = - $src[$low][-1];
					
				}
				
			# use first duplicate sample
			} elsif ($dups == 3) {
				
				# set matrix element to first row matching object sample
				$matrix->[$i/$row_length][$i % $row_length] = $src[$low][-1];
				
			# use last duplicate sample
			} elsif ($dups == 4) {
				
				# set matrix element to last row matching object sample
				$matrix->[$i/$row_length][$i % $row_length] = $src[$high][-1];
				
			} else {
				
				# error
				croak('invalid duplicate handling');
				
			}
			
		}
		
		# if 'copy' slice defined
		if (defined($copys)) {
			
			# get the object row
			$n = $matrix->[$i/$row_length][$i % $row_length];
			
			# copy selected values from object to template
			@{$template->[1][$i + 1]}[@{$copyt}] = @{$self->[1][$n]}[@{$copys}];
			
			# if device values differ
			if ($nomatch) {
				
				# copy device values from object to template
				@{$template->[1][$i + 1]}[@{$devct}] = @{$self->[1][$n]}[@{$devcs}];
				
			}
			
		}
		
	}

	# if sid-matrix is wanted and template has sid values
	if (wantarray() && ($sidt = id($template, [], {'context' => $hash->{'sid_context'}}))) {
		
		# for each template sample
		for my $i (0 .. $#{$sidt}) {
			
			# set sid matrix element to sid slice value
			$sid->[$i/$row_length][$i % $row_length] = $sidt->[$i][0];
			
		}
		
		# return row matrix slice and sid matrix slice
		return(bless($matrix, 'Math::Matrix'), bless($sid, 'Math::Matrix'));
		
	} else {
		
		# return row matrix slice
		return(bless($matrix, 'Math::Matrix'));
		
	}

}

# get sample selection
# array of data values is supplied to code block
# sample is included if code block returns 'true' value
# default row_slice is all samples
# default column_slice is all columns
# parameters: (code_reference, row_slice, column_slice)
# returns: (row_slice)
sub find {

	# get parameters
	my ($self, $code, $rows, $cols) = @_;

	# local variables
	my (@s);

	# verify code reference
	(ref($code) eq 'CODE') || croak('selection parameter must be a code reference');

	# if row slice undefined or empty
	if (! defined($rows) || (ref($rows) eq 'ARRAY' && @{$rows} == 0)) {
		
		# use all rows
		$rows = [1 .. $#{$self->[1]}];
		
	} else {
		
		# flatten slice
		$rows = ICC::Shared::flatten($rows);
		
	}

	# if column slice undefined or empty
	if (! defined($cols) || (ref($cols) eq 'ARRAY' && @{$cols} == 0)) {
		
		# use all columns
		$cols = [0 .. $#{$self->[1][0]}];
		
	} else {
		
		# flatten slice
		$cols = ICC::Shared::flatten($cols);
		
	}

	# select samples
	@s = grep {&$code(@{$self->[1][$_]}[@{$cols}])} @{$rows};

	# return selection, or undef if none selected
	return(scalar(@s) ? \@s : undef);

}

# get sample selection based on device values
# array of device values is supplied to code block
# sample is included if code block returns 'true' value
# default row_slice is all samples
# context may be specified with parameter hash
# parameters: (code_reference, [row_slice], [hash])
# returns: (row_slice)
sub ramp {

	# local variables
	my ($hash, $cols, $mult, @s);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $code, $rows) = @_;

	# verify code reference
	(ref($code) eq 'CODE') || croak('selection parameter must be a code reference');

	# if row slice undefined or empty
	if (! defined($rows) || (ref($rows) eq 'ARRAY' && @{$rows} == 0)) {
		
		# use all rows
		$rows = [1 .. $#{$self->[1]}];
		
	} else {
		
		# flatten slice
		$rows = ICC::Shared::flatten($rows);
		
	}

	# get device column slice
	(defined($cols = device($self, $hash))) || croak('device values required');

	# set multiplier (255 if RGB, else 100)
	$mult = ($self->[1][0][$cols->[0]] =~ m/RGB_R$/) ? 255 : 100;

	# select samples
	@s = grep {&$code(map {$_/$mult} @{$self->[1][$_]}[@{$cols}])} @{$rows};

	# return selection, or undef if none selected
	return(scalar(@s) ? \@s : undef);

}

# get sample selection based on L*a*b* values
# array of L*a*b* values is supplied to code block
# sample is included if code block returns 'true' value
# default row_slice is all samples
# context may be specified with parameter hash
# parameters: (code_reference, [row_slice], [hash])
# returns: (row_slice)
sub range {

	# local variables
	my ($hash, $cols, @s);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $code, $rows) = @_;

	# verify code reference
	(ref($code) eq 'CODE') || croak('selection parameter must be a code reference');

	# if row slice undefined or empty
	if (! defined($rows) || (ref($rows) eq 'ARRAY' && @{$rows} == 0)) {
		
		# use all rows
		$rows = [1 .. $#{$self->[1]}];
		
	} else {
		
		# flatten slice
		$rows = ICC::Shared::flatten($rows);
		
	}

	# get L*a*b* column slice
	(defined($cols = lab($self, $hash))) || croak('L*a*b* values required');

	# select samples
	@s = grep {&$code(@{$self->[1][$_]}[@{$cols}])} @{$rows};

	# return selection, or undef if none selected
	return(scalar(@s) ? \@s : undef);

}

# generate randomized sample slice
# parameter: ([row_slice])
# returns: (row_slice)
sub randomize {

	# get parameters
	my ($self, $rows) = @_;

	# if row slice defined
	if (defined($rows)) {
		
		# if row slice an empty array reference
		if (ref($rows) eq 'ARRAY' && @{$rows} == 0) {
			
			# use all rows
			$rows = [1 .. $#{$self->[1]}];
			
		} else {
			
			# flatten row slice
			$rows = ICC::Shared::flatten($rows);
			
			# verify row slice contents
			(@{$rows} == grep {! ref() && $_ == int($_) && $_ >= 0} @{$rows}) || croak('invalid row slice');
			
		}
		
		# return row slice, randomized
		return([List::Util::shuffle(@{$rows})]);
		
	} else {
		
		# return all samples, randomized
		return([List::Util::shuffle(1 .. $#{$self->[1]})]);
		
	}

}

# analyze chart device values
# creates an array structure with an element for each device channel.
# each element contains a hash, a keys array, and a ramp array.
# hash keys are device values, and hash values are arrays of samples.
# if row-slice is omitted, all samples are used.
# if the dup_flag is false (default), a new sample is added
# containing average measurement values, and the new sample
# is substituted for the anonymous array of duplicates.
# if the dup_flag is true, duplicate samples are included in
# array of samples grouped within anonymous arrays.
# dup_flag and/or device context are specified with parameter hash
# parameters: ([row_slice], [hash])
# returns: (ref_to_structure)
sub analyze {

	# get object reference
	my $self = shift();

	# local variables
	my ($hash, $rows, $dup, $ramp, $dev, $c1, $c2, $c3, @id, @name, $mult);
	my (@d, %dev_hash, $key, $avg, $value, $struct);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get device column slice
	($dev = device($self, $hash)) || croak('chart has no device values');

	# get row slice
	$rows = shift() if (ref($_[0]) eq 'ARRAY');

	# flatten row slice
	$rows = $rows ? ICC::Shared::flatten($rows) : [];

	# use all samples if slice is empty
	$rows = [1 .. $#{$self->[1]}] if (@{$rows} == 0);

	# get dup flag
	$dup = defined($hash->{'dups'}) ? $hash->{'dups'} : 0;

	# get ramp value
	$ramp = defined($hash->{'ramp'}) ? $hash->{'ramp'} : 0;

	# get averaging groups
	($c1, $c2, $c3) = _avg_groups($self, $hash);

	# for each column
	for my $i (0 .. $#{$self->[1][0]}) {
		
		# add column if SAMPLE_ID field
		push(@id, $i) if ($self->[1][0][$i] =~ m/^(?:.*\|)?(?:SAMPLE_ID|SampleID)$/);
		
		# add column if SAMPLE_NAME field
		push(@name, $i) if ($self->[1][0][$i] =~ m/^(?:.*\|)?SAMPLE_NAME$/);
		
	}

	# set device multiplier (255 for RGB values, otherwise 100)
	$mult = ($self->[1][0][$dev->[0]] =~ m/^(?:.*\|)?RGB_[RGB]$/) ? 255 : 100;

	# for each sample
	for my $i (0 .. $#{$rows}) {
		
		# get device values
		@d = @{$self->[1][$rows->[$i]]}[@{$dev}];
		
		# divide by multiplier (setting -0 to 0)
		@d = map {$_ == 0 ? 0 : $_/$mult} @d;
		
		# make device value key
		$key = join(':', @d);
		
		# if key exists
		if (exists($dev_hash{$key})) {
			
			# add sample to existing hash entry
			push(@{$dev_hash{$key}}, $rows->[$i]);
			
		} else {
			
			# add device hash entry
			$dev_hash{$key} = [$rows->[$i]];
			
		}
		
	}

	# if dup flag is not set
	if (! $dup) {
		
		# for each key
		for my $key (keys(%dev_hash)) {
			
			# if duplicate samples
			if (@{$dev_hash{$key}} > 1) {
				
				# if measurement data
				if (@{$c1} || @{$c2} || @{$c3}) {
					
					# add average sample
					$avg = _add_avg($self, $dev_hash{$key}, $c1, $c2, $c3, \@id, \@name);
					
					# update hash to average sample
					$dev_hash{$key} = [$avg];
					
				} else {
					
					# update hash to first sample
					$dev_hash{$key} = [$dev_hash{$key}[0]];
					
				}
				
			}
			
		}
		
		# update the SAMPLE_ID hash
		_makeSampleID($self);
		
	}

	# make empty structure
	$struct = [map {[{}, [], []]} (0 .. $#{$dev})];

	# for each key
	for my $key (keys(%dev_hash)) {
		
		# split key to device values
		@d = split(/:/, $key);
		
		# get value
		$value = $dev_hash{$key};
		
		# resolve single value to scalar
		$value = $value->[0] if (@{$value} == 1);
		
		# for each device channel
		for my $i (0 .. $#d) {
			
			# if key exists
			if (exists($struct->[$i][0]{$d[$i]})) {
				
				# add sample to hash entry
				push(@{$struct->[$i][0]{$d[$i]}}, $value);
				
			} else {
				
				# add hash entry
				$struct->[$i][0]{$d[$i]} = [$value];
				
				# add device value to keys array
				push(@{$struct->[$i][1]}, $d[$i]);
			
			}
			
			# if all other device values equal ramp value
			if (@d == grep {$_ == $i || $d[$_] == $ramp} (0 .. $#d)) {
				
				# add sample to ramp array
				push(@{$struct->[$i][2]}, $value);
				
			}
			
		}
		
	}

	# for each device channel
	for my $i (0 .. $#{$dev}) {
		
		# sort keys array (decreasing frequency)
		$struct->[$i][1] = [sort {@{$struct->[$i][0]{$b}} <=> @{$struct->[$i][0]{$a}}} @{$struct->[$i][1]}];
		
		# sort ramp array (increasing values)
		$struct->[$i][2] = [sort {$self->[1][(! ref($a) ? $a : $a->[0])][$dev->[$i]] <=> $self->[1][(! ref($b) ? $b : $b->[0])][$dev->[$i]]} @{$struct->[$i][2]}];
		
	}

	# return
	return($struct);

}

# write chart to ISO 28178 (CGATS.17) ASCII file
# optional slice parameters are either scalars, array references or 'Math::Matrix' objects
# optional hash parameter keys: 'sid', 'append'
# parameters: (path_to_file, [row_slice, [column_slice]], [hash])
sub write {

	# local variables
	my ($hash, $row_length, $m, $n, @files, $sid, $fh, $rs, @fields);
	my (%cspec, $keyword, $value, $source, $std_key, @s, $sidx, $append);
	my ($null, $undef);

	# get optional hash parameter
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $path, $rows, $cols) = @_;

	# if row slice defined
	if (defined($rows)) {
		
		# if row slice an empty array reference
		if (ref($rows) eq 'ARRAY' && @{$rows} == 0) {
			
			# use all rows
			$rows = [1 .. $#{$self->[1]}];
			
		} else {
			
			# get row length if row slice is Math::Matrix object
			$row_length = @{$rows->[0]} if (UNIVERSAL::isa($rows, 'Math::Matrix'));
			
			# flatten row slice
			$rows = ICC::Shared::flatten($rows);
			
		}
		
	} else {
		
		# use all rows
		$rows = [1 .. $#{$self->[1]}];
		
	}

	# get number of rows
	$m = @{$rows};

	# warn if invalid samples
	(@{$rows} == grep {$_ == int($_) && $_ != 0 && defined($self->[1][$_])} @{$rows})|| warn('row slice contains invalid samples');

	# if column slice defined
	if (defined($cols)) {
		
		# if column slice an empty array reference
		if (ref($cols) eq 'ARRAY' && @{$cols} == 0) {
			
			# use all columns
			$cols = [0 .. $#{$self->[1][0]}];
			
		} else {
			
			# flatten column slice
			$cols = ICC::Shared::flatten($cols);
			
		}
		
	} else {
		
		# use all columns
		$cols = [0 .. $#{$self->[1][0]}];
		
	}

	# get number of columns
	$n = @{$cols};

	# filter column slice
	@{$cols} = grep {$_ == int($_) && defined($self->[1][0][$_])} @{$cols};

	# warn if invalid fields
	($n == @{$cols}) || warn('column slice contains invalid fields');

	# if 'sid' hash value defined
	if (defined($sid = $hash->{'sid'})) {
		
		# if array reference or Math::Matrix object
		if (ref($sid) eq 'ARRAY' || UNIVERSAL::isa($sid, 'Math::Matrix')) {
			
			# flatten 'sid' slice
			$sid = ICC::Shared::flatten($sid);
			
			# warn row slice and sid slice are different sizes
			($m == @{$sid}) || warn('row slice and sid slice are different sizes');
			
		} elsif ($sid eq 'row') {
			
			# use sequential row list
			$sid = [1 .. $m];
			
		} else {
			
			# error
			croak('invalid \'sid\' hash value');
			
		}
		
	}

	# resolve file list from path
	(defined($path) && (! ref($path)) && (@files = File::Glob::bsd_glob($path))) || croak("invalid path: $path, stopped");

	# verify file path is unique
	(@files == 1) || warn('file path not unique');

	# open the file
	open($fh, '>', $files[0]) || croak("$! when opening $files[0], stopped");

	# get the record separator
	$rs = $self->[0]{'write_rs'} || $self->[0]{'read_rs'} || "\n";

	# initialize color specification hash
	# so lines with 'FileInformation' source are printed
	%cspec = ('FileInformation' => 1);

	# add referenced sources to color specification hash
	for (@{$self->[2][5]}[@{$cols}]) {$cspec{$_}++ if defined()};

	# for each header line
	for (@{$self->[3]}) {
		
		# get keyword, value and source
		($keyword, $value, $source) = @{$_};
		
		# if keyword defined and length > 0
		if (defined($keyword) && length($keyword)) {
			
			# make uppercase
			$keyword = uc($keyword);
			
			# skip certain keywords
			next if ($keyword =~ m/KEYWORD|NUMBER_OF_FIELDS|NUMBER_OF_SETS/);
			next if (defined($row_length) && $keyword =~ m/LGOROWLENGTH/);
			
			# if no source or referenced source
			if (! defined($source) || $cspec{$source}) {
				
				# if value defined and length > 0
				if (defined($value) && length($value)) {
					
					# print keyword/value
					print $fh "$keyword\t$value$rs";
					
				} else {
					
					# print keyword only
					print $fh "$keyword$rs";
					
				}
				
			}
			
		} else {
			
			# print empty line
			print $fh "$rs";
			
		}
		
	}

	# get format fields
	@fields = @{$self->[1][0]}[@{$cols}];

	# remove any context, trim leading and trailing white space, and replace spaces with underscores
	for (@fields) {s/^.*\|//; s/^\s*(.*?)\s*$/$1/; s/ /_/g}

	# make standard format keyword regex (per ISO 28178 and common usage)
	$std_key = '^(?:' . join('|', qw(SAMPLE_ID SAMPLE_NO STRING RGB_[RGB] CMYK_[CMYK] [2-9A-F]CLR_[1-9A-F] PC\d+_\d+ SPOT_\d+
	           (?:nm|SPECTRAL_NM_|SPECTRAL_NM|SPECTRAL_|NM_|R_)\d{3} D_(?:RED|GREEN|BLUE|VIS|MAJOR_FILTER) XYZ_[XYZ] XYY_(?:X|Y|CAPY)
	           LAB_[LABCH] LAB_DE LAB_DE_94 LAB_DE_CMC LAB_DE_2000 MEAN_DE STDDEV_[XYZ] STDDEV_[LAB] CHI_SQD_PAR)) . ')$';

	# for each format field
	for (@fields) {
		
		# if not a standard keyword
		if (! /$std_key/) {
			
			# print KEYWORD
			printf $fh "KEYWORD\t%s$rs", $_;
			
		}
		
	}

	# if 'sid' slice defined
	if (defined($sid)) {
		
		# if 'SAMPLE_ID' keyword(s)
		if (@s = grep {uc($fields[$_]) eq 'SAMPLE_ID'} (0 .. $#fields)) {
			
			# save index of first match
			$sidx = $s[0];
			
		} else {
			
			# insert 'SAMPLE_ID' keyword
			unshift(@fields, 'SAMPLE_ID');
			
		}
		
	}

	# print LGOROWLENGTH (if $row_length defined)
	printf $fh "LGOROWLENGTH\t%d$rs", $row_length if (defined($row_length));

	# print NUMBER_OF_FIELDS
	printf $fh "NUMBER_OF_FIELDS\t%d$rs", scalar(@fields);

	# print BEGIN_DATA_FORMAT
	print $fh 'BEGIN_DATA_FORMAT', $rs;

	# print format string (if any)
	print $fh join("\t", @fields), $rs if (@fields);

	# print END_DATA_FORMAT
	print $fh 'END_DATA_FORMAT', $rs;

	# print NUMBER_OF_SETS
	printf $fh "NUMBER_OF_SETS\t%d$rs", scalar(@{$rows});

	# print BEGIN_DATA
	print $fh 'BEGIN_DATA', $rs;

	# get null replacement value
	$null = $hash->{'null'} // 'null';

	# get undef replacement value
	$undef = $hash->{'undef'} // 'undef';

	# for each row
	for my $i (0 .. $#{$rows}) {
		
		# get data fields, replacing null and undefined values
		@fields = map {defined() ? length() ? $_ : $null : $undef} @{$self->[1][$rows->[$i]]}[@{$cols}];
		
		# trim leading and trailing white space, and replace spaces with underscores
		for (@fields) {s/^\s*(.*?)\s*$/$1/; s/ /_/g};
		
		# if 'sid' slice defined
		if (defined($sid)) {
			
			# if 'sid' index defined
			if (defined($sidx)) {
				
				# replace 'sid' value
				$fields[$sidx] = $sid->[$i];
				
			} else {
				
				# insert 'sid' value
				unshift(@fields, $sid->[$i]);
			}
			
		}
		
		# print the data record
		print $fh join("\t", @fields), $rs;
		
	}

	# print END_DATA
	print $fh 'END_DATA', $rs;

	# if 'append' hash value defined
	if (defined($append = $hash->{'append'})) {
		
		# replace line endings, if any
		$append =~ s/\n/$rs/g;
		
		# print appended data
		print $fh $append;
		
	}

	# close the file
	close($fh);

}

# write chart to CxF3 file
# optional slice parameters are either scalars, array references or 'Math::Matrix' objects
# optional hash parameter keys: 'cc:FileInformation'
# parameters: (path_to_file, [row_slice, [column_slice]], [hash])
sub writeCxF3 {

	# local variables
	my ($hash, $row_length, $n);
	my ($dom, $root, $ns, $nsURI);
	my ($datetime, $id, $ops, $objcol);
	my ($prefix, $nid, $obj, $xpath, $node);
	my (%lookup, @data, @files, $sub, $spot);

	# get optional hash parameter
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $path, $rows, $cols) = @_;

	# if row slice defined
	if (defined($rows)) {
		
		# if row slice an empty array reference
		if (ref($rows) eq 'ARRAY' && @{$rows} == 0) {
			
			# use all rows
			$rows = [1 .. $#{$self->[1]}];
			
		} else {
			
			# get row length if row slice is Math::Matrix object
			$row_length = @{$rows->[0]} if (UNIVERSAL::isa($rows, 'Math::Matrix'));
			
			# flatten row slice
			$rows = ICC::Shared::flatten($rows);
			
		}
		
	} else {
		
		# set array reference to all rows
		$rows = [1 .. $#{$self->[1]}];
		
	}

	# get number of rows
	$n = @{$rows};

	# filter row slice
	@{$rows} = grep {$_ == int($_) && $_ != 0 && defined($self->[1][$_])} @{$rows};

	# warn if invalid samples
	($n == @{$rows}) || warn('row slice contains invalid samples');

	# open CxF3 template
	eval {$dom = XML::LibXML->load_xml('location' => ICC::Shared::getICCPath('Templates/CxF3_template.xml'))} || croak('can\'t load CxF3 template');

	# get the root element
	$root = $dom->documentElement();

	# get the namespace prefix and URI
	$ns = $root->prefix();
	$nsURI = $root->namespaceURI();

	# make 'FileInformation' nodes
	$datetime = _makeCxF3fileinfo($self, $root, $ns, $nsURI, $hash);

	# make write operations array from column slice
	# array structure: [[[class, prefix, XPath, [sub_paths], [columns], {attributes}, sort_order], ...], ...]
	$ops = _makeCxF3writeops($self, $root, $ns, $cols);

	# make 'ColorSpecification' nodes
	_makeCxF3colorspec($self, $root, $ns, $nsURI, $ops);

	# get the 'ObjectCollection' node
	($objcol) = $root->findnodes("$ns:Resources/$ns:ObjectCollection");

	# init object Id index
	$id = 1;

	# for each group of operations
	for my $i (0 .. $#{$ops}) {
		
		# get prefix (ObjectType)
		$prefix = $ops->[$i][0][1];
		
		# initialize name Id
		$nid = 0;
		
		# for each row in slice
		for my $j (@{$rows}) {
			
			# increment name Id
			$nid++;
			
			# add 'Object' node
			$obj = $objcol->appendChild(XML::LibXML::Element->new("$ns:Object"));
			$obj->setAttribute('ObjectType', $prefix);
			$obj->setAttribute('Name', "$prefix$nid");
			$obj->setAttribute('Id', "c$id");
			$obj->setNamespace($nsURI, $ns);
			
			# add 'CreationDate' node
			$node = $obj->appendChild(XML::LibXML::Element->new("$ns:CreationDate"));
			$node->appendText($datetime);
			$node->setNamespace($nsURI, $ns);
			
			# init XPath node hash
			%lookup = ();
			
			# for each operation in the group
			for my $k (0 .. $#{$ops->[$i]}) {
				
				# set current node to Object
				$node = $obj;
				
				# initialize XPath
				$xpath = undef;
				
				# for each XPath segment
				for (split(/\//, $ops->[$i][$k][2])) {
					
					# add segment to XPath
					$xpath = defined($xpath) ? "$xpath/$_" : $_;
					
					# if segment exists
					if (exists($lookup{$xpath})) {
						
						# use node
						$node = $lookup{$xpath};
						
					} else {
						
						# add node
						$node = $node->appendChild(XML::LibXML::Element->new($_));
						$node->setNamespace($nsURI, $ns);
						
						# add hash entry (except Tag elements)
						$lookup{$xpath} = $node if ($_ ne "$ns:Tag");
						
					}
					
				}
				
				# for each attribute key (if any)
				for (keys(%{$ops->[$i][$k][5]})) {
					
					# set node attribute using either data element or hash value
					$node->setAttribute($_, (ref($ops->[$i][$k][5]{$_}) eq 'ARRAY') ? $self->[1][$j][$ops->[$i][$k][5]{$_}[0]] : $ops->[$i][$k][5]{$_});
					
				}
				
				# get data
				@data = @{$self->[1][$j]}[@{$ops->[$i][$k][4]}];
				
				# warn on undefined data
				(@data == grep {defined()} @data) || warn("undefined data in sample $j when writing CxF3 file");
				
				# if subpaths
				if (@{$ops->[$i][$k][3]}) {
					
					# for each subpath
					for my $s (0 .. $#{$ops->[$i][$k][3]}) {
						
						# add node
						# CxF3 schema requires integer values for RGB data
						$sub = $node->appendChild(XML::LibXML::Element->new($ops->[$i][$k][3][$s]));
						$sub->appendText($ops->[$i][$k][0] eq 'RGB' ? int($data[$s] + 0.5) : $data[$s]);
						$sub->setNamespace($nsURI, $ns);
						
					}
					
					# if NCLR class
					if ($ops->[$i][$k][0] eq 'NCLR') {
						
						# for each spot color
						for my $s (4 .. $#data) {
							
							# add SpotColor elements
							$spot = $node->appendChild(XML::LibXML::Element->new("$ns:SpotColor"));
							$spot->setNamespace($nsURI, $ns);
							$sub = $spot->appendChild(XML::LibXML::Element->new("$ns:Name"));
							$sub->appendText('Spot' . ($s + 1));
							$sub->setNamespace($nsURI, $ns);
							$sub = $spot->appendChild(XML::LibXML::Element->new("$ns:Percentage"));
							$sub->appendText($data[$s]);
							$sub->setNamespace($nsURI, $ns);
							
						}
						
					}
					
				# no subpaths and one data value
				} elsif (@data == 1) {
					
					# add data as text content
					$node->appendText($data[0]);
					
				# no subpaths and multiple data values
				} elsif (@data > 1) {
					
					# if DENSITY class
					if ($ops->[$i][$k][0] eq 'DENSITY') {
						
						##### to be done
						
					} else {
						
						# join data and add as text content
						$node->appendText(join(' ', @data));
						
					}
					
				}
				
			}
			
			# add Name attribute to TagCollection element
			$lookup{"$ns:TagCollection"}->setAttribute('Name', 'Location') if exists($lookup{"$ns:TagCollection"});
			
			# if nothing was added to Object
			if ($node->isSameNode($obj)) {
				
				# unbind the node
				$node->unbindNode();
				
			} else {
				
				# increment Object Id
				$id++;
				
			}
			
		}
		
	}

	# validate the CxF3 document
	_validateCxF3($dom) if (defined($hash->{'validate'}) && $hash->{'validate'});

	# resolve file list from path
	(@files = File::Glob::bsd_glob($path)) || croak('invalid file path');

	# verify file path is unique
	(@files == 1) || warn('file path not unique');

	# write CxF3 file
	$dom->toFile($files[0], 1);

}

# write chart data array as delimited ASCII file (for Excel, R, MATLAB, etc.)
# optional slice parameters are either scalars, array references or 'Math::Matrix' objects
# optional hash parameter keys: 'header', 'sep', 'eol', and 'undef'
# parameters: (path_to_file, [row_slice, [column_slice]], [hash])
sub writeASCII {

	# local variables
	my ($hash, $row_length, $n, @files, $fh);
	my ($fs, $rs, $undef, $hdr, @fields);

	# get optional hash parameter
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $path, $rows, $cols) = @_;

	# if row slice defined
	if (defined($rows)) {
		
		# if row slice an empty array reference
		if (ref($rows) eq 'ARRAY' && @{$rows} == 0) {
			
			# use all rows
			$rows = [1 .. $#{$self->[1]}];
			
		} else {
			
			# get row length if row slice is Math::Matrix object
			$row_length = @{$rows->[0]} if (UNIVERSAL::isa($rows, 'Math::Matrix'));
			
			# flatten row slice
			$rows = ICC::Shared::flatten($rows);
			
		}
		
	} else {
		
		# use all rows
		$rows = [1 .. $#{$self->[1]}];
		
	}

	# get number of rows
	$n = @{$rows};

	# filter row slice
	@{$rows} = grep {$_ == int($_) && $_ != 0 && defined($self->[1][$_])} @{$rows};

	# warn if invalid samples
	($n == @{$rows}) || warn('row slice contains invalid samples');

	# if column slice defined
	if (defined($cols)) {
		
		# if column slice an empty array reference
		if (ref($cols) eq 'ARRAY' && @{$cols} == 0) {
			
			# use all columns
			$cols = [0 .. $#{$self->[1][0]}];
			
		} else {
			
			# flatten column slice
			$cols = ICC::Shared::flatten($cols);
			
		}
		
	} else {
		
		# use all columns
		$cols = [0 .. $#{$self->[1][0]}];
		
	}

	# get number of columns
	$n = @{$cols};

	# filter column slice
	@{$cols} = grep {$_ == int($_) && defined($self->[1][0][$_])} @{$cols};

	# warn if invalid fields
	($n == @{$cols}) || warn('column slice contains invalid fields');

	# resolve file list from path
	(defined($path) && (! ref($path)) && (@files = File::Glob::bsd_glob($path))) || croak("invalid path: $path, stopped");

	# verify file path is unique
	(@files == 1) || warn('file path not unique');

	# open the file
	open($fh, '>', $files[0]) || croak("$! when opening $files[0], stopped");

	# get header mode
	$hdr = $hash->{'header'} || 1;

	# get the field separator
	$fs = $hash->{'sep'} || "\t";

	# get the record separator
	$rs = $hash->{'eol'} || "\n";

	# get the undefined string
	$undef = $hash->{'undef'} || '';

	# if header enabled
	if ($hdr) {
		
		# if format fields, replacing undefined values
		if (@fields = map {defined() ? $_ : $undef} @{$self->[1][0]}[@{$cols}]) {
			
			# if header mode 2, remove contexts
			if ($hdr == 2) {for (@fields) {s/^.*\|//}};
			
			# trim leading and trailing white space, and replace spaces with underscores
			for (@fields) {s/^\s*(.*?)\s*$/$1/; s/ /_/g};
			
			# print format record
			print $fh join($fs, @fields), $rs;
			
		}
		
	}

	# for each row
	for my $i (@{$rows}) {
		
		# get data fields, replacing undefined values
		@fields = map {defined() ? $_ : $undef} @{$self->[1][$i]}[@{$cols}];
		
		# trim leading and trailing white space, and replace spaces with underscores
		for (@fields) {s/^\s*(.*?)\s*$/$1/; s/ /_/g};
		
		# print the data record
		print $fh join($fs, @fields), $rs;
		
	}

	# close the file
	close($fh);

}

# write TIFF file
# RGB, CMYK, and CIE L*a*b* color spaces supported
# 8-bit, 16-bit or 32-bit, Intel or Motorola byte order supported
# alpha and spot channels in RGB and CMYK files supported
# supported hash keys: 'width', 'height', 'gap', 'left', 'right', 'rows', 'bits', 'dither', 'endian', 'xres', 'yres', 'unit'
# parameters: (path_to_file, [row_slice, [column_slice]], [hash])
sub writeTIFF {

	# local variables
	my ($hash, $trows, $tcols, $n, @files, $fh);
	my ($base, $cs, %fields, @alpha, $pi, $rcols, $fmt, $mult, $mab, $samples);
	my ($width, $height, $gap, $left, $right, $bits, $xres, $yres, $unit);
	my ($le, $short, $long, $fp, $max, $minab, $maxab);
	my ($tags, $imagewidth, $bytecount, $stripsize);
	my ($ifd, $data, @cmyk, @spot);

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# get remaining parameters
	my ($self, $path, $rows, $cols) = @_;

	# if row slice defined
	if (defined($rows)) {
		
		# if row slice an empty array reference
		if (ref($rows) eq 'ARRAY' && @{$rows} == 0) {
			
			# use all rows
			$rows = [1 .. $#{$self->[1]}];
			
		} else {
			
			# get row length if row slice is Math::Matrix object
			$trows = @{$rows->[0]} if (UNIVERSAL::isa($rows, 'Math::Matrix'));
			
			# flatten row slice
			$rows = ICC::Shared::flatten($rows);
			
		}
		
	} else {
		
		# use all rows
		$rows = [1 .. $#{$self->[1]}];
		
	}

	# get number of rows
	$n = @{$rows};

	# filter row slice
	@{$rows} = grep {$_ == int($_) && $_ != 0 && defined($self->[1][$_])} @{$rows};

	# warn if invalid samples
	($n == @{$rows}) || warn('row slice contains invalid samples');

	# get target row length, if not defined by row matrix
	$trows = _getRowLength($self, $hash) if (! defined($trows));

	# limit to number of samples
	$trows = $trows > $n ? $n : $trows;

	# verify row length
	($trows == int($trows) && $trows > 0) || croak('invalid row length, stopped');

	# compute target columns
	$tcols = int($n/$trows) + ($n % $trows ? 1 : 0);

	# if column slice defined
	if (defined($cols)) {
		
		# if column slice an empty array reference
		if (ref($cols) eq 'ARRAY' && @{$cols} == 0) {
			
			# use all columns
			$cols = [0 .. $#{$self->[1][0]}];
			
		} else {
			
			# flatten column slice
			$cols = ICC::Shared::flatten($cols);
			
		}
		
	} else {
		
		# use all columns
		$cols = [0 .. $#{$self->[1][0]}];
		
	}

	# get number of columns
	$n = @{$cols};

	# filter column slice
	@{$cols} = grep {$_ == int($_) && defined($self->[1][0][$_])} @{$cols};

	# warn if invalid fields
	($n == @{$cols}) || warn('column slice contains invalid fields');

	# for each column in slice
	for (@{$self->[1][0]}[@{$cols}]) {
		
		# if a supported color space
		if (m/^((?:.*\|)?(RGB|CMYK|[4-9A-F]CLR|LAB)_)/) {
			
			# set base and color space
			$base = $1;
			$cs = $2;
			
			# quit loop
			last();
			
		}
		
	}

	# verify color space
	(defined($cs)) || croak('column slice does not contain a supported color space, stopped');

	# get bits per sample and verify
	$bits = defined($hash->{'bits'}) ? $hash->{'bits'} : 16;
	($bits == 8 || $bits == 16 || $bits == 32) || croak('invalid \'bits\' parameter, stopped');

	# set little-endian flag from system config
	$le = ($Config{'byteorder'} =~ m/1234/);

	# if endian parameter provided
	if (defined($hash->{'endian'})) {

		# if little-endian
		if ($hash->{'endian'} eq 'little') {
			
			# set flag
			$le = 1;
			
		# if big-endian
		} elsif ($hash->{'endian'} eq 'big') {
			
			# clear flag
			$le = 0;
			
		} else {
			
			# warn
			warn('invalid \'endian\' parameter');
			
		}
		
	}

	# if little-endian
	if ($le) {
		
		# set 'pack' formats
		$short = 'v';
		$long = 'V';
		$fp = 'f<';
		
	} else {
		
		# set 'pack' formats
		$short = 'n';
		$long = 'N';
		$fp = 'f>';
		
	}

	# make lookup hash of column slice fields
	%fields = map {defined($self->[1][0][$_]) ? ($self->[1][0][$_], $_) : ()} @{$cols};

	# if color space is RGB
	if ($cs eq 'RGB') {
		
		# set photometric interpretation
		$pi = 2;
		
		# get alpha channels (if any)
		@alpha = map {defined($fields{"$base$_"}) ? $fields{"$base$_"} : ()} ('A', 'A0' .. 'A9');
		
		# get refined column slice (including alpha channels)
		$rcols = [(map {$fields{"$base$_"}} qw(R G B)), @alpha];
		
		# set pack format (8, 16 or 32 bits)
		$fmt = ($bits == 8) ? 'C*' : ($bits == 16) ? "$short*" : "$fp*";
		
		# set multiplier (8, 16 or 32 bits)
		$mult = ($bits == 8) ? 1 : ($bits == 16) ? 257 : 1/255;
		
	# if color space is CMYK (8 or 16 bits)
	} elsif ($cs eq 'CMYK' && $bits != 32) {
		
		# set photometric interpretation
		$pi = 5;
		
		# get refined column slice
		$rcols = [map {$fields{"$base$_"}} qw(C M Y K)];
		
		# set pack format (8 or 16 bits)
		$fmt = ($bits == 8) ? 'C*' : "$short*";
		
		# set multiplier (8 or 16 bits)
		$mult = ($bits == 8) ? 2.55 : 655.35;
		
	# if color space is nCLR (8 or 16 bits)
	} elsif ($cs =~ m/^([4-9A-F])CLR$/ && $bits != 32) {
		
		# set photometric interpretation
		$pi = 5;
		
		# get refined column slice
		$rcols = [map {$fields{sprintf('%s%x', $base, $_)}} (1 .. CORE::hex($1))];
		
		# set pack format (8 or 16 bits)
		$fmt = ($bits == 8) ? 'C*' : "$short*";
		
		# set multiplier (8 or 16 bits)
		$mult = ($bits == 8) ? 2.55 : 655.35;
		
	# if color space if L*a*b* (8 or 16 bits)
	} elsif ($cs eq 'LAB' && $bits != 32) {
		
		# set photometric interpretation
		$pi = 8;
		
		# get refined column slice
		$rcols = [map {$fields{"$base$_"}} qw(L A B)];
		
		# set pack format (8 or 16 bits)
		$fmt = ($bits == 8) ? '(Ccc)*' : "$short*";
		
		# set multipliers (8 or 16 bits)
		$mult = ($bits == 8) ? 2.55 : 655.35; # L*
		$mab = ($bits == 8) ? 1 : 256; # a* and b*
		
	} else {
		
		# error
		croak('invalid TIFF format');
		
	}

	# verify all fields defined
	(@{$rcols} == grep {defined()} @{$rcols}) || croak('column slice has missing fields, stopped');

	# set number of samples
	$samples = @{$rcols};

	# get the sample patch width and verify
	$width = defined($hash->{'width'}) ? $hash->{'width'} : 1;
	($width == int($width) && $width > 0) || croak('invalid \'width\' parameter, stopped');

	# get the sample patch height and verify
	$height = defined($hash->{'height'}) ? $hash->{'height'} : 1;
	($height == int($height) && $height > 0) || croak('invalid \'height\' parameter, stopped');

	# get the sample patch gap and verify
	$gap = defined($hash->{'gap'}) ? $hash->{'gap'} : 0;
	($gap == int($gap) && $gap >= 0) || croak('invalid \'gap\' parameter, stopped');

	# get the left edge width and verify
	$left = defined($hash->{'left'}) ? $hash->{'left'} : 0;
	($left =~ m/^([0-9]+)(?:\.([0-9]+))?$/ && (! defined($2) || $1 >= $2)) || croak('invalid \'left\' parameter, stopped');
	$left = [$1, defined($2) ? $2 : 0];

	# get the right edge width and verify
	$right = defined($hash->{'right'}) ? $hash->{'right'} : 0;
	($right =~ m/^([0-9]+)(?:\.([0-9]+))?$/ && (! defined($2) || $1 >= $2)) || croak('invalid \'right\' parameter, stopped');
	$right = [$1, defined($2) ? $2 : 0];

	# get the x-resolution and verify
	$xres = defined($hash->{'xres'}) ? $hash->{'xres'} : 72;
	($xres > 0 && $xres <= 4E4) || croak('invalid \'xres\' parameter, stopped');

	# get the y-resolution and verify
	$yres = defined($hash->{'yres'}) ? $hash->{'yres'} : 72;
	($yres > 0 && $yres <= 4E4) || croak('invalid \'yres\' parameter, stopped');

	# get the resolution unit and verify
	$unit = defined($hash->{'unit'}) ? $hash->{'unit'} : 2;
	($unit == 1 || $unit == 2 || $unit == 3) || croak('invalid \'unit\' parameter, stopped');

	# compute image width
	$imagewidth = $tcols * $width + ($tcols - 1) * $gap + $left->[0] - $left->[1] + $right->[0] - $right->[1];

	# compute strip byte count
	$bytecount = $imagewidth * $height * $samples * $bits/8;

	# compute strip size (strips must begin on word boundary)
	$stripsize = $bytecount + $bytecount % 2;

	# set image tags [type, data]
	$tags->{'256'} = [3, $imagewidth]; # ImageWidth
	$tags->{'257'} = [3, $trows * $height]; # ImageLength
	$tags->{'258'} = [3, ($bits) x $samples]; # BitsPerSample
	$tags->{'259'} = [3, 1]; # Compression
	$tags->{'262'} = [3, $pi]; # PhotometricInterpretation
	$tags->{'273'} = [4, map {$_ * $stripsize + 8} (0 .. $trows - 1)]; # StripOffsets
	$tags->{'277'} = [3, $samples]; # SamplesPerPixel
	$tags->{'278'} = [3, $height]; # RowsPerStrip
	$tags->{'279'} = [4, ($bytecount) x $trows]; # StripByteCounts
	$tags->{'282'} = [5, $xres * 1E4, 1E4]; # XResolution
	$tags->{'283'} = [5, $yres * 1E4, 1E4]; # YResolution
	$tags->{'296'} = [3, $unit]; # ResolutionUnit
	$tags->{'339'} = [3, (3) x $samples] if ($bits == 32); # SampleFormat

	# resolve file list from path
	(defined($path) && (! ref($path)) && (@files = File::Glob::bsd_glob($path))) || croak("invalid path: $path, stopped");

	# verify file path is unique
	(@files == 1) || warn('file path not unique');

	# open the file
	open($fh, '>', $files[0]) || croak("$! when opening $files[0], stopped");

	# set binary mode
	binmode($fh);

	# write TIFF header
	print $fh pack("A2$short$long", $le ? 'II' : 'MM', 42, $ifd = $trows * $stripsize + 8);

	# set min/max values
	$max = ($bits == 8) ? 255 : ($bits == 16) ? 65535 : 1;
	$minab = ($bits == 8) ? -128 : -32768;
	$maxab = ($bits == 8) ? 127 : 32767;

	# for each strip
	for my $i (0 .. $trows - 1) {
		
		# for each patch in strip
		for my $j (0 .. $tcols - 1) {
			
			# if patch in row slice
			if (defined($rows->[$trows * $j + $i])) {
				
				# if L*a*b* data
				if ($pi == 8) {
					
					# get the data
					$data->[$j][0] = $mult * $self->[1][$rows->[$trows * $j + $i]][$rcols->[0]];
					$data->[$j][1] = $mab * $self->[1][$rows->[$trows * $j + $i]][$rcols->[1]];
					$data->[$j][2] = $mab * $self->[1][$rows->[$trows * $j + $i]][$rcols->[2]];
					
					# limit the data
					$data->[$j][0] = $data->[$j][0] < 0 ? 0 : ($data->[$j][0] > $max ? $max : $data->[$j][0]);
					$data->[$j][1] = $data->[$j][1] < $minab ? $minab : ($data->[$j][1] > $maxab ? $maxab : $data->[$j][1]);
					$data->[$j][2] = $data->[$j][2] < $minab ? $minab : ($data->[$j][2] > $maxab ? $maxab : $data->[$j][2]);
					
				# if CMYK + spot data
				} elsif ($pi == 5 && @{$rcols} > 4) {
					
					# get CMYK values
					@cmyk = @{$self->[1][$rows->[$trows * $j + $i]]}[@{$rcols}[0 .. 3]];
					
					# get spot values
					@spot = @{$self->[1][$rows->[$trows * $j + $i]]}[@{$rcols}[4 .. $#{$rcols}]];
					
					# get the data (spot channels are inverted)
					$data->[$j] = [(map {$_ * $mult} @cmyk), (map {(100 - $_) * $mult} @spot)];
					
					# limit the data
					@{$data->[$j]} = map {$_ < 0 ? 0 : ($_ > $max ? $max : $_)} @{$data->[$j]};
					
				# RGB data
				} else {
					
					# get the data
					$data->[$j] = [map {$_ * $mult} @{$self->[1][$rows->[$trows * $j + $i]]}[@{$rcols}]];
					
					# limit the data (8 or 16 bits)
					@{$data->[$j]} = map {$_ < 0 ? 0 : ($_ > $max ? $max : $_)} @{$data->[$j]} if ($bits != 32);
					
				}
				
			# patch undefined
			} else {
				
				# if L*a*b* data
				if ($pi == 8) {
					
					# if last patch
					if ($i == ($trows - 1) && $j == ($tcols - 1)) {
						
						# set gray value
						$data->[$j] = [$max * 0.7, 0, 0];
						
					} else {
						
						# set white value
						$data->[$j] = [$max, 0, 0];
						
					}
					
				# if CMYK + spot data
				} elsif ($pi == 5) {
					
					# if last patch
					if ($i == ($trows - 1) && $j == ($tcols - 1)) {
						
						# set gray value
						$data->[$j] = [0, 0, 0, $max * 0.4, ($max) x ($samples - 4)];
						
					} else {
						
						# set white value
						$data->[$j] = [0, 0, 0, 0, ($max) x ($samples - 4)];
						
					}
					
				# RGB data
				} else {
					
					# if last patch
					if ($i == ($trows - 1) && $j == ($tcols - 1)) {
						
						# set gray value
						$data->[$j] = [($max * 0.7) x $samples];
						
					} else {
						
						# set white value
						$data->[$j] = [($max) x $samples];
						
					}
					
				}
				
			}
			
		}
		
		# write TIFF strip
		_writeTIFFstrip($fh, $tags, $width, $gap, $left, $right, $i, $data, $fmt, $hash->{'dither'});
		
	}

	# write TIFF IFD
	_writeTIFFdir($fh, $ifd, $short, $long, $tags);

	# close file
	close($fh);

}

# write chart to Adobe Swatch Exchange (.ase) file
# column slice must be CMYK, RGB or L*a*b*
# color type: 0 - global, 1 - spot, 2 - normal (default)
# parameters: (path_to_file, row_slice, column_slice, [color_type])
sub writeASE {

	# get parameters
	my ($self, $path, $rows, $cols, $type) = @_;

	# local variables
	my ($n, @fmt, $cs, $le, $sn, @files, $fh);
	my ($name, $slen, $blen);
	my ($cmyk, $rgb, $Lab, $val);

	# verify row_slice and column_slice are supplied
	(defined($rows) && defined($cols)) || croak('missing parameters');

	# if row slice an empty array reference
	if (ref($rows) eq 'ARRAY' && @{$rows} == 0) {
		
		# use all rows
		$rows = [1 .. $#{$self->[1]}];
		
	} else {
		
		# flatten row slice
		$rows = ICC::Shared::flatten($rows);
		
	}

	# get number of rows
	$n = @{$rows};

	# filter row slice
	@{$rows} = grep {$_ == int($_) && $_ != 0 && defined($self->[1][$_])} @{$rows};

	# warn if invalid samples
	($n == @{$rows}) || warn('row slice contains invalid samples');

	# get format array
	@fmt = @{$self->[1][0]}[@{$cols}];

	# if column slice is CMYK
	if (4 == @fmt && 4 == grep {m/^(?:.*\|)?CMYK_[CMYK]$/} @fmt) {
		
		# set color space
		$cs = 'CMYK';
		
	# if column slice is RGB
	} elsif (3 == @fmt && 3 == grep {m/^(?:.*\|)?RGB_[RGB]$/} @fmt) {
		
		# set color space
		$cs = 'RGB ';
		
	# if column slice is L*a*b*
	} elsif (3 == @fmt && 3 == grep {m/^(?:.*\|)?LAB_[LAB]$/} @fmt) {
		
		# set color space
		$cs = 'LAB ';
		
	} else {
		
		# error
		croak('invalid column slice');
		
	}
	
	# if color type is undefined, set default (2 - normal)
	$type = 2 if (! defined($type));
	
	# verify color type
	($type == int($type) && $type >= 0 && $type <= 2) || croak('invalid ASE color type');
	
	# get little-endian flag
	$le = ($Config{'byteorder'} =~ m/1234/);
	
	# get sample name slice (could be undefined)
	$sn = $self->name;
	
	# resolve file list from path
	(@files = File::Glob::bsd_glob($path)) || croak('invalid file path');
	
	# verify file path is unique
	(@files == 1) || warn('file path not unique');
	
	# open file
	open($fh, '>', $files[0]);

	# set binary mode
	binmode($fh);

	# print header (file signature, version, number of blocks)
	print $fh pack('A4nnN', 'ASEF', 1, 0, scalar(@{$rows}));
	
	# for each sample
	for my $s (@{$rows}) {
		
		# if color space is CMYK
		if ($cs eq 'CMYK') {
			
			# get the CMYK values
			$cmyk = $self->slice([$s], $cols);
			
			# if SAMPLE_NAME is defined
			if (defined($sn)) {
				
				# get color name
				$name = $self->[1][$s][$sn->[0]];
				
				# replace underscores with spaces
				$name =~ s/_/ /g;
				
			} else {
				
				# build color name from CMYK values
				$name = sprintf('C=%d M=%d Y=%d K=%d', @{$cmyk->[0]});
				
			}
			
			# compute string length
			$slen = length($name) + 1;
			
			# compute block length
			$blen = 2 * $slen + 24;
			
			# print block
			print $fh pack('nNn', 1, $blen, $slen);
			print $fh encode('UTF-16BE', $name . "\x00");
			print $fh pack('A4', 'CMYK');
			
			# for each CMYK value
			for my $i (0 .. 3) {
				
				# convert to floating point
				$val = pack('f', $cmyk->[0][$i]/100);
				
				# reverse if little-endian system
				$val = reverse($val) if ($le);
				
				# print value
				print $fh $val;
				
			}
			
			# print color type
			print $fh pack('n', $type);
			
		# if color space is RGB
		} elsif ($cs eq 'RGB ') {
			
			# get the RGB values
			$rgb = $self->slice([$s], $cols);
			
			# if SAMPLE_NAME is defined
			if (defined($sn)) {
				
				# get color name
				$name = $self->[1][$s][$sn->[0]];
				
				# replace underscores with spaces
				$name =~ s/_/ /g;
				
			} else {
				
				# build color name from RGB values
				$name = sprintf('R=%d G=%d B=%d', @{$rgb->[0]});
				
			}
			
			# compute string length
			$slen = length($name) + 1;
			
			# compute block length
			$blen = 2 * $slen + 20;
			
			# print block
			print $fh pack('nNn', 1, $blen, $slen);
			print $fh encode('UTF-16BE', $name . "\x00");
			print $fh pack('A4', 'RGB ');
			
			# for each RGB value
			for my $i (0 .. 2) {
				
				# convert to floating point
				$val = pack('f', $rgb->[0][$i]/255);
				
				# reverse if little-endian system
				$val = reverse($val) if ($le);
				
				# print value
				print $fh $val;
				
			}
			
			# print color type
			print $fh pack('n', $type);
			
		# if color space is L*a*b*
		} elsif ($cs eq 'LAB ') {
			
			# get the L*a*b* values
			$Lab = $self->slice([$s], $cols);
			
			# if SAMPLE_NAME is defined
			if (defined($sn)) {
				
				# get color name
				$name = $self->[1][$s][$sn->[0]];
				
				# replace underscores with spaces
				$name =~ s/_/ /g;
				
			} else {
				
				# build color name from L*a*b* values
				$name = sprintf('L=%d a=%d b=%d', @{$Lab->[0]});
				
			}
			
			# compute string length
			$slen = length($name) + 1;
			
			# compute block length
			$blen = 2 * $slen + 20;
			
			# print block
			print $fh pack('nNn', 1, $blen, $slen);
			print $fh encode('UTF-16BE', $name . "\x00");
			print $fh pack('A4', 'LAB ');
			
			# modify L* value
			$Lab->[0][0] /= 100;
			
			# for each L*a*b* value
			for my $i (0 .. 2) {
				
				# convert to floating point
				$val = pack('f', $Lab->[0][$i]);
				
				# reverse if little-endian system
				$val = reverse($val) if ($le);
				
				# print value
				print $fh $val;
				
			}
			
			# print color type
			print $fh pack('n', $type);
			
		}
		
	}
	
	# close file
	close($fh);
	
}

# print object contents to string
# format is an array structure
# parameter: ([format])
# returns: (string)
sub sdump {

	# get parameters
	my ($self, $p) = @_;

	# local variables
	my ($s, $fmt);

	# resolve parameter to an array reference
	$p = defined($p) ? ref($p) eq 'ARRAY' ? $p : [$p] : [];

	# get format string
	$fmt = defined($p->[0]) && ! ref($p->[0]) ? $p->[0] : 'undef';

	# set string to object ID
	$s = sprintf("'%s' object, (0x%x)\n", ref($self), $self);

	# return
	return($s);

}

# get column slice from DATA_FORMAT keys
# format_keys is a list of keys with optional context
# column_slice is reference to an array of column indices
# note: returns 'undef' if any column is missing
# parameters: (format_keys)
# returns: (column_slice)
sub _cols {

	# get object reference
	my $self = shift();

	# local variables
	my (%fmt, @cols);

	# make lookup hash of DATA_FORMAT keys
	%fmt = map {defined($self->[1][0][$_]) ? ($self->[1][0][$_], $_) : ()} (0 .. $#{$self->[1][0]});

	# lookup format keys in hash
	@cols = @fmt{@_};

	# return column slice or undef if any columns undefined
	return((grep {! defined()} @cols) ? undef : \@cols);

}

# get spectral fields array
# array contains column indices and wavelength
# and is sorted by wavelength (low to high)
# parameters: (object_reference, [context])
# returns: (array_reference)
sub _spectral {

	# get parameters
	my ($self, $context) = @_;

	# local variables
	my (%fmt, @fields);

	# make lookup hash (context|wavelength -or- wavelength => column)
	%fmt = map {($self->[1][0][$_] =~ m/^(.*\|)?(?:nm|SPECTRAL_NM_|SPECTRAL_NM|SPECTRAL_|NM_|R_)(\d{3})$/) ? (defined($1) ? "$1$2" : $2, $_) : ()} (0 .. $#{$self->[1][0]});

	# if context defined
	if (defined($context)) {
		
		# make list of matching fields
		@fields = map {m/^$context\|(\d{3})$/ ? [$fmt{$_}, $1] : ()} keys(%fmt);
		
	} else {
		
		# make list of matching fields
		@fields = map {m/^(\d{3})$/ ? [$fmt{$_}, $1] : ()} keys(%fmt);
		
		# if no matching fields
		if (@fields == 0) {
			
			# make lookup hash (wavelength => column)
			%fmt = map {($self->[1][0][$_] =~ m/^(?:.*\|)?(?:nm|SPECTRAL_NM_|SPECTRAL_NM|SPECTRAL_|NM_|R_)(\d{3})$/) ? ($1, $_) : ()} (0 .. $#{$self->[1][0]});
			
			# make list of fields
			@fields = map {[$fmt{$_}, $_]} keys(%fmt);
			
		}
		
	}

	# return undef if no match
	return() if (@fields == 0);

	# sort by wavelength
	@fields = sort {$a->[1] <=> $b->[1]} @fields;

	# return array reference
	return(\@fields);

}

# binary search
# locates the interval containing or bounding the target value
# returns an array of four index values, which indicate upper and lower transitions
# parameters: (source_array, target_value, channel_index, low_index, high_index)
# returns: (interval_index_array)
sub _bin_search {
	
	# get parameters
	my ($source, $target, $channel, $low, $high) = @_;
	
	# local variables
	my ($k, $interval);
	
	# copy low and high indices
	$interval->[0] = $low;
	$interval->[1] = $high;
	
	# while interval is open
	while ($interval->[1] - $interval->[0] > 1) {
		
		# compute the midpoint
		$k = int(($interval->[1] + $interval->[0])/2);
		
		# if midpoint value >= target value
		if ($source->[$k][$channel] >= $target) {
			
			# set higher index to midpoint
			$interval->[1] = $k;
			
		} else {
			
			# set lower index to midpoint
			$interval->[0] = $k;
			
		}
		
	}
	
	# copy low and high indices
	$interval->[2] = $low;
	$interval->[3] = $high;
	
	# while interval is open
	while ($interval->[3] - $interval->[2] > 1) {
		
		# compute the midpoint
		$k = int(($interval->[3] + $interval->[2])/2);
		
		# if midpoint value > target value
		if ($source->[$k][$channel] > $target) {
			
			# set higher index to midpoint
			$interval->[3] = $k;
			
		} else {
			
			# set lower index to midpoint
			$interval->[2] = $k;
			
		}
		
	}
	
	# return interval array
	return($interval);
	
}

# linear search
# locates the closest source sample based on Manhattan distance
# parameters: (source_array, target_vector)
# returns: (low_index, high_index)
sub _lin_search {
	
	# get parameters
	my ($source, $target) = @_;
	
	# local variables
	my ($d0, $d1, $d2, $low, $high);
	
	# set initial difference
	$d0 = @{$target};
	
	# for each source sample
	for my $i (0 .. $#{$source}) {
		
		# clear differences
		$d1 = $d2 = 0;
		
		# for each channel
		for my $j (0 .. $#{$target}) {
			
			# add difference to target sample
			$d1 += abs($source->[$i][$j] - $target->[$j]);
			
			# add difference to previous sample
			$d2 += abs($source->[$i][$j] - $source->[$i - 1][$j]) if ($i > 0);
			
		}
		
		# if new difference less
		if ($d1 < $d0) {
			
			# save index
			$low = $high = $i;
			
			# update difference
			$d0 = $d1;
			
		}
			
		# if duplicate sample
		if ($d0 == $d1 && $d2 == 0) {
			
			# save index
			$high = $i;
			
		}
		
	}
	
	# return
	return($low, $high);
	
}

# add average sample
# assumes device values (if any) are same for each sample
# averages measurements values - spectral, XYZ, L*a*b*, or density
# L*a*b* values are converted to xyz for averaging, then back to L*a*b*
# density values are converted to reflectance for averaging, then back to density
# parameters: (object_reference, row_slice, linear_slice, L*a*b*_slice, density_slice, id_slice, name_slice, hash)
# returns: (average_sample_index)
sub _add_avg {

	# get parameters
	my ($self, $rows, $c1, $c2, $c3, $id, $name, $hash) = @_;

	# local variables
	my ($n, $next, @xyz, $sid, $sn);

	# get number of samples
	$n = @{$rows};

	# get index of next data row
	$next = $#{$self->[1]} + 1;

	# copy first sample
	$self->[1][$next] = [@{$self->[1][shift(@{$rows})]}];

	# for each group of L*a*b* columns
	for (my $j = 0; $j < @{$c2}; $j += 3) {
		
		# convert to L*a*b* values to xyz
		@{$self->[1][$next]}[@{$c2}[$j .. $j + 2]] = ICC::Shared::_Lab2xyz(@{$self->[1][$next]}[@{$c2}[$j .. $j + 2]]);
		
	}
	
	# for each density column
	for my $j (@{$c3}) {
		
		# convert to density to reflectance
		$self->[1][$next][$j] = POSIX::pow(10, -$self->[1][$next][$j]);
		
	}

	# for remaining samples
	for my $i (@{$rows}) {
		
		# for each linear column
		for my $j (@{$c1}) {
			
			# add value
			$self->[1][$next][$j] += $self->[1][$i][$j];
			
		}
		
		# for each group of L*a*b* columns
		for (my $j = 0; $j < @{$c2}; $j += 3) {
			
			# get xyz values
			@xyz = ICC::Shared::_Lab2xyz(@{$self->[1][$i]}[@{$c2}[$j .. $j + 2]]);
			
			# add to self
			$self->[1][$next][$c2->[$j]] += $xyz[0];
			$self->[1][$next][$c2->[$j + 1]] += $xyz[1];
			$self->[1][$next][$c2->[$j + 2]] += $xyz[2];
			
		}
		
		# for each density column
		for my $j (@{$c3}) {
			
			# add temp reflectance
			$self->[1][$next][$j] += POSIX::pow(10, -$self->[1][$i][$j]);
			
		}
		
	}

	# for each measurement column
	for my $j (@{$c1}, @{$c2}, @{$c3}) {
		
		# divide by number of samples
		$self->[1][$next][$j] /= $n;
		
	}

	# for each group of L*a*b* columns
	for (my $j = 0; $j < @{$c2}; $j += 3) {
		
		# convert to xyz values to L*a*b*
		@{$self->[1][$next]}[@{$c2}[$j .. $j + 2]] = ICC::Shared::_xyz2Lab(@{$self->[1][$next]}[@{$c2}[$j .. $j + 2]]);
		
	}

	# for each density column
	for my $j (@{$c3}) {
		
		# convert to reflectance to density
		$self->[1][$next][$j] = -POSIX::log10($self->[1][$next][$j]);
		
	}

	# get SAMPLE_ID value from hash
	$sid = $hash->{'id'};

	# for each SAMPLE_ID column
	for my $i (@{$id}) {
		
		# if SAMPLE_ID defined
		if (defined($sid)) {
			
			# set to hash value
			$self->[1][$next][$i] = $sid;
			
		} else {
			
			# set to row index
			$self->[1][$next][$i] = $next;
			
		}
		
	}

	# get SAMPLE_NAME value from hash
	$sn = $hash->{'name'};

	# for each SAMPLE_NAME column
	for my $i (@{$name}) {
		
		# if SAMPLE_NAME defined
		if (defined($sn)) {
			
			# set to hash value
			$self->[1][$next][$i] = $sn;
			
		} else {
			
			# append '_AVG' to existing value
			$self->[1][$next][$i] .= '_AVG';
			
		}
		
	}

	# return row
	return($next);

}

# get averaging groups
# returns column slices for each averaging method
# parameters: (object_reference, hash)
# returns: (linear_slice, L*a*b*_slice, density_slice)
sub _avg_groups {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my (@c1, @c2, @c3, @cs);

	# for each format field
	for my $i (0 .. $#{$self->[1][0]}) {
		
		# add column if XYZ or spectral field
		push(@c1, $i) if ($self->[1][0][$i] =~ m/^(?:.*\|)?(?:XYZ_[XYZ]|(?:nm|SPECTRAL_NM_|SPECTRAL_NM|SPECTRAL_|NM_|R_)\d{3})$/);
		
		# add column if L*a*b* field
		push(@c2, $i) if ($self->[1][0][$i] =~ m/^(?:.*\|)?LAB_[LAB]$/);
		
		# add column if density field
		push(@c3, $i) if ($self->[1][0][$i] =~ m/^(?:.*\|)?D_(?:RED|GREEN|BLUE|VIS)$/);
		
	}
	
	# linear averaging method (L*a*b* values are converted to xyz, density values are converted to reflectance)
	if (! defined($hash->{'method'}) || $hash->{'method'} eq 'LINEAR') {
		
		# verify number of L*a*b* fields
		(@c2 % 3 == 0) || croak('wrong number of L*a*b* fields');
		
		# for each group of L*a*b* columns
		for (my $j = 0; $j < @c2; $j += 3) {
			
			# sort by field name
			@cs = sort {$self->[1][0][$a] cmp $self->[1][0][$b]} @c2[$j .. $j + 2];
			
			# verify field consistency
			(join('', map {substr($_, -1, 1)} @{$self->[1][0]}[@cs]) eq 'ABL') || croak('L*a*b* field inconsistency');
			
			# save columns in LAB order
			@c2[$j .. $j + 2] = @cs[2, 0, 1];
			
		}
		
	# if simple averaging method
	} elsif (defined($hash->{'method'}) && $hash->{'method'} eq 'SIMPLE') {
		
		# copy L*a*b* and density columns to XYZ or spectral array
		push(@c1, @c2, @c3);
		
		# clear L*a*b* and density arrays
		@c2 = ();
		@c3 = ();
		
	} else {
		
		# error
		croak('unsupported averaging method');
		
	}

	# return slices
	return(\@c1, \@c2, \@c3);

}

# add OBA effect to XYZ array
# parameters: (chart_object, M1_slice, M2_slice, XYZ_array, oba_factor, hash)
sub _add_oba {

	# get parameters
	my ($self, $spec1, $spec2, $xyz, $oba, $hash) = @_;

	# local variables
	my ($color, $illum, @m1, @m2, $spectral, $xyzoba);

	# save illuminant
	$illum = $hash->{'illuminant'};

	# if illuminant an array reference
	if (defined($hash->{'illuminant'}) && ref($hash->{'illuminant'}) eq 'ARRAY') {
		
		# set illuminant to CIE D50
		$hash->{'illuminant'} = ['CIE', 'D50'];
		
	} else {
		
		# set illuminant to ASTM D50
		$hash->{'illuminant'} = 'D50';
		
	}

	# make 'Color.pm' object (D50 illuminant)
	$color = ICC::Support::Color->new($hash);

	# restore illuminant
	$hash->{'illuminant'} = $illum;

	# for each sample
	for my $i (1 .. $#{$self->[1]}) {
		
		# get M1 spectral values
		@m1 = @{$self->[1][$i]}[@{$spec1}];
		
		# get M2 spectral values
		@m2 = @{$self->[1][$i]}[@{$spec2}];
		
		# compute (M1 - M2) spectral values
		$spectral->[$i - 1] = [map {$m1[$_] - $m2[$_]} (0 .. $#m1)];
		
	}

	# transform (M1 - M2) spectral to D50 XYZ (hash may contain 'encoding' key)
	$xyzoba = ICC::Support::Color::_trans2($color, $spectral, $hash);

	# for each sample
	for my $i (0 .. $#{$xyz}) {
		
		# for each XYZ
		for my $j (0 .. 2) {
			
			# add scaled OBA effect
			$xyz->[$i][$j] += $xyzoba->[$i][$j] * $oba;
			
		}
		
	}
	
}

# get/set data
# common routine called by get/set methods
# row_slice and column_slice may be either a scalar or array reference
# an empty array reference indicates all samples or fields
# replacement_data is reference to a 2-D array of replacement values
# array dimensions must match size of row_slice and column_slice
# data_slice is Math::Matrix object, defined by row_slice and column_slice
# get_code_ref and set_code_ref transform the data when getting and setting
# parameters: (object_ref, object_index, row_slice, column_slice, replacement_data, get_code_ref, set_code_ref)
# if column_slice undefined, returns: ()
# if row_slice undefined, returns: (column_slice)
# if replacement_data undefined, returns: (data_slice)
# otherwise, sets replacement data and returns: (column_slice)
sub _getset {

	# get parameters
	my ($self, $ix, $rows, $cols, $data, $get, $set) = @_;

	# return empty if no column slice
	defined($cols) || return();

	# if column slice an empty array reference
	if (ref($cols) eq 'ARRAY' && @{$cols} == 0) {
		
		# use all columns
		$cols = [0 .. $#{$self->[$ix][0]}];
		
	} else {
		
		# flatten column slice
		$cols = ICC::Shared::flatten($cols);
		
		# verify column slice contents
		(@{$cols} == grep {! ref() && $_ == int($_) && $_ >= 0} @{$cols}) || croak('invalid column slice');
		
	}

	# return columns slice if no row slice
	defined($rows) || return($cols);

	# if row slice an empty array reference
	if (ref($rows) eq 'ARRAY' && @{$rows} == 0) {
		
		# use all rows
		$rows = [1 .. $#{$self->[$ix]}];
		
	} else {
		
		# flatten row slice
		$rows = ICC::Shared::flatten($rows);
		
		# verify row slice contents
		(@{$rows} == grep {! ref() && $_ == int($_) && $_ >= 0} @{$rows}) || croak('invalid row slice');
		
	}

	# no replacement data (get)
	if (! defined($data)) {
		
		# verify 'get' code ref, or use identity function
		$get = (defined($get) && ref($get) eq 'CODE') ? $get : sub {@_};
		
		# for each row
		for my $i (0 .. $#{$rows}) {
			
			# get transformed data row
			@{$data->[$i]} = &$get(@{$self->[$ix][$rows->[$i]]}[@{$cols}]);
			
		}
		
		# return data slice as a Math::Matrix object
		return(bless($data, 'Math::Matrix'));
		
	# with replacement data (set)
	} else {
		
		# verify replacement data is 2-D array or Math::Matrix object
		((ref($data) eq 'ARRAY' || UNIVERSAL::isa($data, 'Math::Matrix')) && ref($data->[0]) eq 'ARRAY') || croak('replacement data not a 2-D array reference');
		
		# verify replacement data size
		($#{$data} == $#{$rows} && $#{$data->[0]} == $#{$cols}) || croak('replacement data is wrong sized');
		
		# verify 'set' code ref, or use identity function
		$set = (defined($set) && ref($set) eq 'CODE') ? $set : sub {@_};
		
		# for each row
		for my $i (0 .. $#{$rows}) {
			
			# set transformed data row
			@{$self->[$ix][$rows->[$i]]}[@{$cols}] = &$set(@{$data->[$i]});
			
		}
		
		# return column slice
		return($cols);
		
	}
	
}

# get accumulated sample values
# sample dimensions are in pixels
# used by _readChartTIFF to extract samples from a data stripe
# parameters: (reference_to_data, sample_offset, sample_width, number_channels)
# returns: (accumulated_sample_values)
sub _getSample {
	
	# get parameters
	my ($data, $so, $sx, $c) = @_;
	
	# initialize sample values
	my @sv = (0) x $c;
	
	# for each row
	for my $i (0 .. $#{$data}) {
		
		# for each pixel
		for my $j (0 .. $sx - 1) {
			
			# for each channel
			for my $k (0 .. $c - 1) {
				
				# accumulate sample value
				$sv[$k] += $data->[$i][($so + $j) * $c + $k];
				
			}
			
		}
		
	}
	
	# return sample values
	return(@sv);
	
}

# get row length
# parameters: (object_reference, hash)
# returns: (row_length)
sub _getRowLength {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($rows, $n, $square);

	# if 'rows' hash key is defined
	if (defined($hash->{'rows'})) {
		
		# get row length value
		$rows = $hash->{'rows'};
		
		# if valid row length
		if (Scalar::Util::looks_like_number($rows) && $rows > 0 && $rows == int($rows)) {
			
			# return
			return($rows);
			
		} else {
			
			# warn
			warn('invalid \'rows\' parameter');
			
		}
		
	}
	
	# if LGOROWLENGTH keyword
	if ($rows = keyword($self, 'LGOROWLENGTH')) {
		
		# if valid row length
		if (Scalar::Util::looks_like_number($rows) && $rows > 0 && $rows == int($rows)) {
			
			# return
			return($rows);
			
		} else {
			
			# warn
			warn('invalid \'LGOROWLENGTH\' value');
			
		}
		
	}
	
	# if NUMBER_OF_STRIPS keyword
	if ($rows = keyword($self, 'NUMBER_OF_STRIPS')) {
		
		# if valid row length
		if (Scalar::Util::looks_like_number($rows) && $rows > 0 && $rows == int($rows)) {
			
			# return
			return($rows);
			
		} else {
			
			# warn
			warn('invalid \'NUMBER_OF_STRIPS\' value');
			
		}
		
	}
	
	# if 'NumberPatchRows' key is defined
	if (defined($self->[0]{'xrp:CustomAttributes'}{'NumberPatchRows'})) {
		
		# get row length value
		$rows = $self->[0]{'xrp:CustomAttributes'}{'NumberPatchRows'};
		
		# if valid row length
		if (Scalar::Util::looks_like_number($rows) && $rows > 0 && $rows == int($rows)) {
			
			# return
			return($rows);
			
		} else {
			
			# warn
			warn('invalid \'NumberPatchRows\' attribute');
			
		}
		
	}

	# get number of samples
	$n = $#{$self->[1]};

	# return if 0
	return(0) if ($n == 0);

	# return if 1 or 2
	return(1) if ($n < 3);

	# compute size of square chart
	$square = POSIX::ceil(sqrt($n));

	# return if chart is square
	return($square) if ($n == $square**2);

	# set row length one less than square chart
	$rows = $square - 1;

	# while modulus is non-zero, decrement row length
	while ($n % $rows) {$rows--}

	# return row length, choosing full rectangle if possible
	return($rows > $square/2 ? $rows : $square);

}

# get illuminant white point
# returns XYZ vector from colorimetry array
# returns D50 if CAT or undefined
# parameter: (object_reference, column_slice, [hash])
# returns: (XYZ_vector)
sub _illumWP {

	# get parameters
	my ($self, $cols, $hash) = @_;

	# if XYZ values are valid
	if (3 == grep {defined() && ! ref() && $_ > 0} @{$self->[2][2]}[@{$cols}]) {
		
		# return XYZ vector
		return([@{$self->[2][2]}[@{$cols}]]);
		
	} else {
		
		# return D50 vector
		return(ICC::Shared::D50);
		
	}

}

# compute media white point
# multiple samples are averaged
# result also stored in colorimetry array
# parameter: (object_reference, column_slice, [hash])
# returns: (XYZ_vector)
sub _mediaWP {

	# get parameters
	my ($self, $cols, $hash) = @_;

	# local variables
	my ($WPxyz, $dev, $mwv, $n, @XYZ, @XYZs);

	# if column slice is L*a*b*
	if ((3 == grep {$self->[1][0][$_] =~ m/LAB_[LAB]$/} @{$cols})) {
		
		# get illuminant white point
		$WPxyz = defined($self->[2][2][$cols->[0]]) ? [@{$self->[2][2]}[@{$cols}]] : ICC::Shared::D50;
		
	# if column slice is not XYZ
	} elsif ((3 != grep {$self->[1][0][$_] =~ m/XYZ_[XYZ]$/} @{$cols})) {
		
		# warning
		warn('column slice not XYZ or L*a*b* data');
		
		# return empty
		return();
		
	}

	# if no device data (using 'device' context)
	if (! ($dev = device($self, {'context' => $hash->{'device'}}))) {
		
		# warning
		warn('no device data');
		
		# return empty
		return();
		
	}

	# set media white device value (255 if RGB, 0 otherwise)
	$mwv = ($self->[1][0][$dev->[0]] =~ m/RGB_R$/) ? 255 : 0;

	# for each sample
	for my $i (1 .. $#{$self->[1]}) {
		
		# if all device channels are white
		if (@{$dev} == grep {$_ == $mwv} @{$self->[1][$i]}[@{$dev}]) {
			
			# if L*a*b* data
			if ($WPxyz) {
				
				# convert L*a*b* values to XYZ
				@XYZs = ICC::Shared::_Lab2XYZ(@{$self->[1][$i]}[@{$cols}], $WPxyz);
				
				# accumulate XYZ values
				$XYZ[0] += $XYZs[0];
				$XYZ[1] += $XYZs[1];
				$XYZ[2] += $XYZs[2];
				
			# if XYZ data
			} else {
				
				# accumulate XYZ values
				$XYZ[0] += $self->[1][$i][$cols->[0]];
				$XYZ[1] += $self->[1][$i][$cols->[1]];
				$XYZ[2] += $self->[1][$i][$cols->[2]];
				
			}
			
			# increment count
			$n++;
			
		}
		
	}

	# if media white sample(s)
	if ($n) {
		
		# store average XYZ values in colorimetry array, and return XYZ vector
		return([@{$self->[2][3]}[@{$cols}] = map {$_/$n} @XYZ]);
		
	} else {
		
		# warning
		warn('no media white sample found');
		
		# return empty
		return();
		
	}
	
}

# compute media black point
# multiple samples are averaged
# result also stored in colorimetry array
# parameter: (object_reference, column_slice, [hash])
# returns: (XYZ_vector)
sub _mediaBP {

	# get parameters
	my ($self, $cols, $hash) = @_;

	# local variables
	my ($WPxyz, $dev, $mbv, $n, @XYZ, @XYZs);

	# if column slice is L*a*b*
	if ((3 == grep {$self->[1][0][$_] =~ m/LAB_[LAB]$/} @{$cols})) {
		
		# get illuminant white point
		$WPxyz = defined($self->[2][2][$cols->[0]]) ? [@{$self->[2][2]}[@{$cols}]] : ICC::Shared::D50;
		
	# if column slice is not XYZ
	} elsif ((3 != grep {$self->[1][0][$_] =~ m/XYZ_[XYZ]$/} @{$cols})) {
		
		# warning
		warn('column slice not XYZ or L*a*b* data');
		
		# return empty
		return();
		
	}

	# if no device data (using 'device' context)
	if (! ($dev = device($self, {'context' => $hash->{'device'}}))) {
		
		# warning
		warn('no device data');
		
		# return empty
		return();
		
	}

	# set media black device value (0 if RGB, 100 otherwise)
	$mbv = ($self->[1][0][$dev->[0]] =~ m/RGB_R$/) ? 1 : 100;

	# for each sample
	for my $i (1 .. $#{$self->[1]}) {
		
		# if all device channels are black
		if (@{$dev} == grep {$_ == $mbv} @{$self->[1][$i]}[@{$dev}]) {
			
			# increment count
			$n++;
			
			# if L*a*b* data
			if ($WPxyz) {
				
				# convert L*a*b* values to XYZ
				@XYZs = ICC::Shared::_Lab2XYZ(@{$self->[1][$i]}[@{$cols}], $WPxyz);
				
				# accumulate XYZ values
				$XYZ[0] += $XYZs[0];
				$XYZ[1] += $XYZs[1];
				$XYZ[2] += $XYZs[2];
				
			# if XYZ data
			} else {
				
				# accumulate XYZ values
				$XYZ[0] += $self->[1][$i][$cols->[0]];
				$XYZ[1] += $self->[1][$i][$cols->[1]];
				$XYZ[2] += $self->[1][$i][$cols->[2]];
				
			}
			
		}
		
	}

	# if media black sample(s)
	if ($n) {
		
		# store average XYZ values in colorimetry array, and return XYZ vector
		return([@{$self->[2][4]}[@{$cols}] = map {$_/$n} @XYZ]);
		
	} else {
		
		# warning
		warn('no media black sample found');
		
		# return empty
		return();
		
	}
	
}

# make SAMPLE_ID hash
# if no SAMPLE_ID field, hash is initialized
# parameter: (object_reference)
sub _makeSampleID {

	# get object reference
	my $self = shift();

	# if SAMPLE_ID column(s) exist
	if (my @id = grep {$self->[1][0][$_] =~ m/^(?:.*\|)?(?:SAMPLE_ID|SampleID)$/} (0 .. $#{$self->[1][0]})) {
	
		# make the SAMPLE_ID hash, omitting undefined ID values
		$self->[4] = {map {defined($self->[1][$_][$id[0]]) ? ($self->[1][$_][$id[0]], $_) : ()} (1 .. $#{$self->[1]})};
	
	} else {
	
		# initialize the hash
		$self->[4] = {};
	
	}

}

# add colorimetry metadata
# called when creating a new object
# parameter: (object_reference)
sub _addColorMeta {

	# get object reference
	my $self = shift();

	# local variables
	my (@cols, $hash, $illum, $spec, $nm, $str, $color, $WPxyz, @values);

	# if object contains colorimetric data
	if (@cols = grep {$self->[1][0][$_] =~ m/^(?:(.*)\|)?(?:LAB_[LAB]|XYZ_[XYZ]|STDEV_[LABXYZ]|MEAN_DE|STDEV_DE|CHI_SQD_PAR)$/} (0 .. $#{$self->[1][0]})) {
		
		# set default hash values
		$hash = {'illuminant' => 'D50', 'observer' => '2'};
		
		# if CxF3 'TristimulusSpec' node
		if (defined($self->[0]{'CxF3_dom'}) && 0) {
			
			##### to be implemented #####
			
		# if 'WEIGHTING_FUNCTION' keyword(s)
		} elsif (@values = keyword($self, 'WEIGHTING_FUNCTION')) {
			
			# join values into string
			$str = join(';', @values);
			
			# match illuminant and save in hash
			$hash->{'illuminant'} = $1 if ($str =~ m/ILLUMINANT\s*,\s*(\w+)"/);
			
			# match observer and save in hash
			$hash->{'observer'} = $1 if ($str =~ m/OBSERVER\s*,\s*(\d+).*"/);
			
		}
		
		# if non-standard illuminant
		if ($hash->{'illuminant'} ne 'D50' || $hash->{'observer'} ne '2') {
			
			# make an empty 'Color.pm' object
			$color = ICC::Support::Color->new();
			
			# if illuminant is an ARRAY reference
			if (ref($hash->{'illuminant'}) eq 'ARRAY') {
				
				# initialize object for CIE method
				ICC::Support::Color::_cie($color, $hash);
				
			} else {
				
				# initialize object for ASTM method
				ICC::Support::Color::_astm($color, $hash);
				
			}
			
			# use computed white point
			$WPxyz = $color->iwtpt();
			
		} else {
			
			# use D50
			$WPxyz = ICC::Shared::D50;
			
		}
		
		# for each colorimetric field
		for my $i (@cols) {
			
			# if field name ends in L or X
			if ($self->[1][0][$i] =~ m/[LX]$/) {
				
				# save WP X-value
				$self->[2][2][$i] = $WPxyz->[0];
				
			# if field name ends in A or Y
			} elsif ($self->[1][0][$i] =~ m/[AY]$/) {
				
				# save WP Y-value
				$self->[2][2][$i] = $WPxyz->[1];
				
			# if field name ends in B or Z
			} elsif ($self->[1][0][$i] =~ m/[BZ]$/) {
				
				# save WP Z-value
				$self->[2][2][$i] = $WPxyz->[2];
				
			}
			
		}
		
	}
	
}

# read chart from list of data files
# averages color measurement data (spectral, XYZ, L*a*b* or density)
# files must have identical structure (rows and cols)
# parameters: (object_reference, ref_to_file_list, hash)
# returns: (number_of_files_averaged)
sub _readChartAvg {

	# get parameters
	my ($self, $list, $hash) = @_;

	# local variables
	my ($n, $result, $c1, $c2, $c3, $keys, $temp, @xyz);
	my ($charts, $fstat, @ctx1, @ctx2, $add_hash);

	# initialize file count
	$n = 0;

	# if hash is defined
	if (defined($hash)) {
		
		# for each hash key
		for (keys(%{$hash})) {
			
			# if XYZ based stat requested
			if (m/^STDEV_XYZ$/) {
				
				# if value is a scalar
				if (! ref($hash->{$_})) {
					
					# save XYZ context
					push(@ctx1, $hash->{$_});
					
				} elsif (ref($hash->{$_}) eq 'ARRAY') {
					
					# save XYZ contexts
					push(@ctx1, @{$hash->{$_}});
					
				}
				
				# increment flag
				$fstat++;
				
			# if L*a*b* based stat requested
			} elsif (m/^(MEAN_DE|STDEV_LAB|CHI_SQD_PAR)$/) {
				
				# if value is a scalar
				if (! ref($hash->{$_})) {
					
					# save L*a*b* context
					push(@ctx2, $hash->{$_});
					
				} elsif (ref($hash->{$_}) eq 'ARRAY') {
					
					# save L*a*b* contexts
					push(@ctx2, @{$hash->{$_}});
					
				}
				
				# increment flag
				$fstat++;
				
			}
			
		}
		
	}

	# for each file
	for my $file (@{$list}) {
		
		# if first file
		if ($n == 0) {
			
			# if file read successfully
			if (! ($result = _readChart($self, $file, $hash))) {
				
				# add colorimetric metadata
				_addColorMeta($self);
				
				# make format key string
				$keys = join(':', map {defined() ? $_ : '-'} @{$self->[1][0]});
				
				# for each XYZ context
				for my $ctx (@ctx1) {
					
					# copy the hash
					$add_hash = Storable::dclone($hash);
					
					# set the context (undef for no context)
					$add_hash->{'context'} = defined($ctx) && length($ctx) ? $ctx : undef;
					
					# delete the 'added' context
					delete($add_hash->{'added'});
					
					# add the XYZ values
					add_xyz($self, $add_hash);
					
				}
				
				# for each L*a*b* context
				for my $ctx (@ctx2) {
					
					# copy the hash
					$add_hash = Storable::dclone($hash);
					
					# set the context (undef for no context)
					$add_hash->{'context'} = defined($ctx) && length($ctx) ? $ctx : undef;
					
					# delete the 'added' context
					delete($add_hash->{'added'});
					
					# add the L*a*b* values
					add_lab($self, $add_hash);
					
				}
				
				# save copy of chart data, if needed for stats
				$charts->[0] = Storable::dclone($self->[1]) if ($fstat);
				
				# get averaging groups
				($c1, $c2, $c3) = _avg_groups($self, $hash);
				
				# if there are L*a*b* or density groups
				if (@{$c2} || @{$c3}) {
					
					# for each sample
					for my $i (1 .. $#{$self->[1]}) {
						
						# for each group of L*a*b* columns
						for (my $j = 0; $j < @{$c2}; $j += 3) {
							
							# convert to L*a*b* values to xyz
							@{$self->[1][$i]}[@{$c2}[$j .. $j + 2]] = ICC::Shared::_Lab2xyz(@{$self->[1][$i]}[@{$c2}[$j .. $j + 2]]);
							
						}
						
						# for each density column
						for my $j (@{$c3}) {
							
							# convert to density to reflectance
							$self->[1][$i][$j] = POSIX::pow(10, -$self->[1][$i][$j]);
							
						}
						
					}
					
				}
				
				# increment file count
				$n++;
				
			} else {
				
				# print warning
				warn("chart $file $result, ignored\n");
				
			}
			
		} else {
			
			# make temporary Chart object
			$temp = ICC::Support::Chart->new();
			
			# if file read successfully
			if (! ($result = _readChart($temp, $file, $hash))) {
				
				# if charts have same structure (rows and cols)
				if ($#{$self->[1]} == $#{$temp->[1]} && $keys eq join(':', map {defined() ? $_ : '-'} @{$temp->[1][0]})) {
					
					# for each XYZ context
					for my $ctx (@ctx1) {
						
						# copy the hash
						$add_hash = Storable::dclone($hash);
						
						# set the context (undef for no context)
						$add_hash->{'context'} = defined($ctx) && length($ctx) ? $ctx : undef;
						
						# delete the 'added' context
						delete($add_hash->{'added'});
						
						# add the XYZ values
						add_xyz($temp, $add_hash);
						
					}
					
					# for each L*a*b* context
					for my $ctx (@ctx2) {
						
						# copy the hash
						$add_hash = Storable::dclone($hash);
						
						# set the context (undef for no context)
						$add_hash->{'context'} = defined($ctx) && length($ctx) ? $ctx : undef;
						
						# delete the 'added' context
						delete($add_hash->{'added'});
						
						# add the L*a*b* values
						add_lab($temp, $add_hash);
						
					}
					
					# save copy of chart data, if needed for stats
					$charts->[$n] = $temp->[1] if ($fstat);
					
					# for each sample
					for my $i (1 .. $#{$self->[1]}) {
						
						# for each linear column
						for my $j (@{$c1}) {
							
							# add temp value
							$self->[1][$i][$j] += $temp->[1][$i][$j];
							
						}
						
						# for each group of L*a*b* columns
						for (my $j = 0; $j < @{$c2}; $j += 3) {
							
							# get temp xyz values
							@xyz = ICC::Shared::_Lab2xyz(@{$temp->[1][$i]}[@{$c2}[$j .. $j + 2]]);
							
							# add to self
							$self->[1][$i][$c2->[$j]] += $xyz[0];
							$self->[1][$i][$c2->[$j + 1]] += $xyz[1];
							$self->[1][$i][$c2->[$j + 2]] += $xyz[2];
							
						}
						
						# for each density column
						for my $j (@{$c3}) {
							
							# add temp reflectance
							$self->[1][$i][$j] += POSIX::pow(10, -$temp->[1][$i][$j]);
							
						}
						
					}
					
					# increment file count
					$n++;
					
				} else {
					
					# print warning
					warn("chart $file has different structure, ignored\n");
					
				}
			
			} else {
				
				# print warning
				warn("chart $file $result, ignored\n");
				
			}
			
		}
		
	}

	# if any files were read
	if ($n) {
		
		# if there are measurement values
		if (@{$c1} || @{$c2} || @{$c3}) {
			
			# for each sample
			for my $i (1 .. $#{$self->[1]}) {
				
				# for each measurement column
				for my $j (@{$c1}, @{$c2}, @{$c3}) {
					
					# divide by n
					$self->[1][$i][$j] /= $n;
					
				}
				
				# for each group of L*a*b* columns
				for (my $j = 0; $j < @{$c2}; $j += 3) {
					
					# convert to xyz values to L*a*b*
					@{$self->[1][$i]}[@{$c2}[$j .. $j + 2]] = ICC::Shared::_xyz2Lab(@{$self->[1][$i]}[@{$c2}[$j .. $j + 2]]);
					
				}
				
				# for each density column
				for my $j (@{$c3}) {
					
					# convert reflectance to density
					$self->[1][$i][$j] = -POSIX::log10($self->[1][$i][$j]);
					
				}
				
			}
			
		}
		
		# add ISO statistics, if requested
		_addStats($self, $charts, $hash) if ($fstat);
		
		# print message
		print "$n files read in directory $self->[0]{'file_path'}\n\n";
		
		# save number of files read
		$self->[0]{'files_read'} = $n;
		
	}

	# return
	return($n);

}

# add ISO statistics
# the object_reference contains the mean values
# the individual charts are in the array_of_chart_objects
# parameters: (object_reference, array_of_chart_objects, hash)
sub _addStats {

	# get parameters
	my ($self, $charts, $hash) = @_;

	# local variables
	my (@ctx, $cols, $scols);

	# for each hash key
	for (keys(%{$hash})) {
		
		# if value is a scalar
		if (! ref($hash->{$_})) {
			
			# save context value
			@ctx = ($hash->{$_});
			
		} elsif (ref($hash->{$_}) eq 'ARRAY') {
			
			# save context values
			@ctx = @{$hash->{$_}};
			
		}
		
		# if 'STDEV_XYZ'
		if (m/^STDEV_XYZ$/) {
			
			# for each context
			for my $context (@ctx) {
				
				# resolve context value
				$context = defined($context) && length($context) ? $context : undef;
				
				# if no STDEV_XYZ columns with context
				if (! test($self, 'STDEVXYZ', $context)) {
					
					# get XYZ columns
					$cols = cols($self, map {defined($context) ? "$context|$_" : $_} qw(XYZ_X XYZ_Y XYZ_Z));
					
					# add STDEV_XYZ columns
					$scols = add_fmt($self, map {defined($context) ? "$context|$_" : $_} qw(STDEV_X STDEV_Y STDEV_Z));
					
					# for each XYZ
					for my $i (0 .. 2) {
						
						# add STDEV_XYZ values
						_addStdDevCol($self, $charts, $cols->[$i], $scols->[$i]);
						
					}
					
				}
				
				# set origin
				@{$self->[2][0]}[@{$scols}] = ($cols) x 3;
				
				# save illuminant white point
				@{$self->[2][2]}[@{$scols}] = @{$self->[2][2]}[@{$cols}];
				
			}
			
		# if 'STDEV_LAB' or 'CHI_SQD_PAR'
		} elsif (m/^(STDEV_LAB|CHI_SQD_PAR)$/) {
			
			# for each context
			for my $context (@ctx) {
				
				# resolve context value
				$context = defined($context) && length($context) ? $context : undef;
				
				# if no STDEV_LAB columns with context
				if (! test($self, 'STDEVLAB', $context)) {
					
					# get L*a*b* columns
					$cols = cols($self, map {defined($context) ? "$context|$_" : $_} qw(LAB_L LAB_A LAB_B));
					
					# add STDEV_LAB columns
					$scols = add_fmt($self, map {defined($context) ? "$context|$_" : $_} qw(STDEV_L STDEV_A STDEV_B));
					
					# for each L*a*b*
					for my $i (0 .. 2) {
						
						# add STDEV_LAB values
						_addStdDevCol($self, $charts, $cols->[$i], $scols->[$i]);
						
					}
					
					# set origin
					@{$self->[2][0]}[@{$scols}] = ($cols) x 3;
					
					# save illuminant white point
					@{$self->[2][2]}[@{$scols}] = @{$self->[2][2]}[@{$cols}];
					
				}
				
				# if 'CHI_SQD_PAR'
				if ($1 eq 'CHI_SQD_PAR') {
					
					# get STDEV_LAB columns
					$cols = cols($self, map {defined($context) ? "$context|$_" : $_} qw(STDEV_L STDEV_A STDEV_B));
					
					# add CHI_SQD_PAR column
					$scols = add_fmt($self, map {defined($context) ? "$context|$_" : $_} qw(CHI_SQD_PAR));
					
					# for each sample
					for my $i (1 .. $#{$self->[1]}) {
						
						# set CHI_SQD_PAR value (average of L*a*b* standard deviations)
						$self->[1][$i][$scols->[0]] = List::Util::sum(@{$self->[1][$i]}[@{$cols}])/3;
						
					}
					
					# set origin
					$self->[2][0][$scols->[0]] = $cols;
					
				}
				
			}
			
		# if 'MEAN_DE'
		} elsif (m/^MEAN_DE$/) {
			
			# for each context
			for my $context (@ctx) {
				
				# resolve context value
				$context = defined($context) && length($context) ? $context : undef;
				
				# if no MEAN_DE columns with context
				if (! test($self, 'MEAN_DE', $context)) {
					
					# get L*a*b* columns
					$cols = cols($self, map {defined($context) ? "$context|$_" : $_} qw(LAB_L LAB_A LAB_B));
					
					# add MEAN_DE column
					$scols = add_fmt($self, map {defined($context) ? "$context|$_" : $_} qw(MEAN_DE));
					
					# add MEAN_DE values
					_addMeanDECol($self, $charts, $cols, $scols->[0]);
					
					# set origin
					$self->[2][0][$scols->[0]] = $cols;
					
				}
				
			}
			
		}
		
	}
	
}

# add standard deviation column
# the object_reference contains the mean values
# the individual charts are in the array_of_chart_objects
# parameters: (object_reference, array_of_chart_objects, mean_column, std_dev_column)
sub _addStdDevCol {

	# get parameters
	my ($self, $charts, $m, $s) = @_;

	# local variables
	my ($n);

	# get number of charts
	$n = @{$charts};

	# for each sample
	for my $i (1 .. $#{$self->[1]}) {
		
		# initialize value
		$self->[1][$i][$s] = 0;
		
		# if number of charts > 0
		if ($n) {
			
			# for each chart
			for my $j (0 .. $#{$charts}) {
				
				# add squared difference
				$self->[1][$i][$s] += ($charts->[$j][$i][$m] - $self->[1][$i][$m])**2;
				
			}
			
			# complete calculation
			$self->[1][$i][$s] = sqrt($self->[1][$i][$s]/$n);
			
		} else {
			
			# error
			croak('can\'t compute standard deviation with zero samples');
			
		}
		
	}
	
}

# add mean dEab column
# the object_reference contains the mean values
# the individual charts are in the array_of_chart_objects
# parameters: (object_reference, array_of_chart_objects, mean_L*a*b*_columns, mean_dE_column)
sub _addMeanDECol {

	# get parameters
	my ($self, $charts, $m, $s) = @_;

	# local variables
	my ($n, $dE);

	# get number of charts
	$n = @{$charts};

	# for each sample
	for my $i (1 .. $#{$self->[1]}) {
		
		# initialize value
		$self->[1][$i][$s] = 0;
		
		# if number of charts > 0
		if ($n) {
			
			# for each chart
			for my $j (0 .. $#{$charts}) {
				
				# initialize dE
				$dE = 0;
				
				# for each L*a*b*
				for my $k (0 .. 2) {
					
					# add squared difference
					$dE += ($self->[1][$i][$m->[$k]] - $charts->[$j][$i][$m->[$k]])**2;
					
				}
				
				# add dE for this chart
				$self->[1][$i][$s] += sqrt($dE);
				
			}
			
			# complete calculation
			$self->[1][$i][$s] /= $n;
			
		} else {
			
			# error
			croak('can\'t compute mean dE with zero samples');
			
		}
		
	}
	
}

# read chart from list of data files
# files must have identical structure (cols)
# reads first chart, then appends other charts
# parameters: (object_reference, ref_to_file_list, hash)
# returns: (number_of_files_appended)
sub _readChartAppend {

	# get parameters
	my ($self, $list, $hash) = @_;

	# local variables
	my ($n, $result, $keys, $temp);

	# initialize file counter
	$n = 0;

	# for each file
	for my $file (@{$list}) {
		
		# if first file
		if ($n == 0) {
			
			# if file read successfully
			if (! ($result = _readChart($self, $file, $hash))) {
				
				# add colorimetric metadata
				_addColorMeta($self);
				
				# make format key string
				$keys = join(':', map {defined() ? $_ : '-'} @{$self->[1][0]});
				
				# increment counter
				$n++;
				
			} else {
				
				# print warning
				warn("chart $file $result, ignored\n");
				
			}
			
		} else {
			
			# make temporary Chart object
			$temp = ICC::Support::Chart->new();
			
			# if file read successfully
			if (! ($result = _readChart($temp, $file, $hash))) {
				
				# if charts have same structure (cols)
				if ($keys eq join(':', map {defined() ? $_ : '-'} @{$temp->[1][0]})) {
					
					# append temp samples
					push(@{$self->[1]}, @{$temp->[1]}[1 .. $#{$temp->[1]}]);
					
					# increment counter
					$n++;
					
				} else {
					
					# print warning
					warn("chart $file has different structure, ignored\n");
					
				}
				
			} else {
				
				# print warning
				warn("chart $file $result, ignored\n");
				
			}
			
		}
		
	}

	# print message if any files were read
	print "$n files read in directory $self->[0]{'file_path'}\n\n" if ($n);

	# return
	return($n);

}

# read chart
# parameters: (object_reference, path_to_file, hash)
# returns: (result)
sub _readChart {

	# get parameters
	my ($self, $path, $hash) = @_;

	# local variables
	my ($fh, $buf, $result);

	# open the file (read-only)
	open($fh, '<', $path) || return("$! when opening $path");

	# set binary mode
	binmode($fh);

	# read start of file
	read($fh, $buf, 1024);

	# reset file pointer
	seek($fh, 0, 0);

	# if an ASE file
	if ($buf =~ m/^ASEF/) {
		
		# save file type
		$self->[0]{'file_type'} = 'ASEF';
		
		# read ASE file
		$result = _readChartASE($self, $fh, $hash);
		
	# if a TIFF file
	} elsif ($buf =~ m/^(II\*\x00|MM\x00\*)/) {
		
		# save file type
		$self->[0]{'file_type'} = 'TIFF';
		
		# read TIFF file
		$result = _readChartTIFF($self, $fh, $hash);
		
	# if an ICC profile
	} elsif (substr($buf, 36, 4) eq 'acsp') {
		
		# save file type
		$self->[0]{'file_type'} = 'prof';
		
		# read ICC file
		$result = _readChartICC($self, $fh, $hash);
		
	# if an XML file
	} elsif ($buf =~ m/<\?xml/) {
		
		# save file type
		$self->[0]{'file_type'} = 'CXFX';
		
		# read CxF3 file
		$result = _readChartCxF3($self, $fh, $hash);
		
	# if an SS3 file
	} elsif (substr($buf, 0, 4) eq "\x00\x20\x00\x00" || substr($buf, 0, 4) eq "\x00\x32\x00\x00") {
		
		# save file type
		$self->[0]{'file_type'} = 'SS3';
		
		# read SS3 file
		$result = _readChartSS3($self, $fh, $hash);
		
	} else {
		
		# check for CR-LF (DOS/Windows)
		if ($buf =~ m/\015\012/) {
			
			# set record separator
			$self->[0]{'read_rs'} = "\015\012";
			
		# check for LF (Unix/OSX)
		} elsif ($buf =~ m/\012/) {
			
			# set record separator
			$self->[0]{'read_rs'} = "\012";
			
		# check for CR (Mac)
		} elsif ($buf =~ m/\015/) {
			
			# set record separator
			$self->[0]{'read_rs'} = "\015";
			
		# not a text file
		} else {
			
			# close the file
			close($fh);
			
			# return
			return('unknown file type');
			
		}
		
		# save file type
		$self->[0]{'file_type'} = 'TEXT';
		
		# read ASCII file
		$result = _readChartASCII($self, $fh, $hash);
		
	}

	# close the file
	close($fh);

	# return
	return($result);

}

# read chart from ISO 28178 ASCII data file
# parameters: (object_reference, file_handle, hash)
# returns: (result)
sub _readChartASCII {

	# get parameters
	my ($self, $fh, $hash) = @_;

	# local variables
	my ($state, $iflag, $eflag, $index);
	my (@fields, $illum, $append);

	# localize input record separator
	local $/ = $self->[0]{'read_rs'};

	# localize loop variable
	local $_;

	# initialize variables
	$self->[1] = [[]];
	$illum = [[]];
	$index = 1;
	$state = 0;
	$iflag = 0;

	# read the file, line by line
	while (<$fh>) {
		
		# add appended text, as is
		$append .= $_ if ($state == 4);
		
		# remove leading spaces/tabs and trailing whitespace
		s/^[ \t]*(.*?)[\s,]*$/$1/;
		
		# if normal comment line (all comments are removed)
		if (s/#[\s]*(.*)// && $state == 0) {
			
			# if remaining line blank
			if (length() == 0) {
				
				# add comment to header array
				push(@{$self->[3]}, ['#', $1]);
				
			} else {
				
				# restore comment to header line
				# preserves time in ProfileMaker 'CREATED' lines
				$_ .= "# $1";
				
			}
			
		}
		
		# skip blank lines
		next if (length() == 0);
		
		# begin data format
		if (m/^BEGIN_DATA_FORMAT$/) {
			
			# set state
			$state = 1;
			
		# end data format
		} elsif (m/^END_DATA_FORMAT$/) {
			
			# set state
			$state = 2;
			
		# begin data
		} elsif (m/^BEGIN_DATA$/) {
			
			# set state
			$state = 3;
			
		# end data
		} elsif (m/^END_DATA$/) {
			
			# set state
			$state = 4;
			
		# begin ProfileMaker illuminant section
		} elsif (m/^BEGIN_DATA_EMISSION$/) {
			
			# set illuminant flag
			$iflag = 1;
			
			# reset index
			$index = 1;
			
		# end ProfileMaker illuminant section
		} elsif (m/^END_DATA_EMISSION$/) {
			
			# clear illuminant flag
			$iflag = 0;
			
			# reset appended data
			$append = '';
			
		# anything else
		} else {
			
			# format
			if ($iflag == 0 && $state == 1) {
				
				# change 'SampleID' to 'SAMPLE_ID'
				# non-standard notation used by ProfileMaker
				s/SampleID/SAMPLE_ID/;
				
				# parse and save format keys
				push(@{$self->[1][0]}, split(/[\s,]+/));
				
			# data
			} elsif ($iflag == 0 && $state == 3) {
				
				# if Euro flag not defined
				if (! defined($eflag)) {
					
					# split data
					@fields = split(/[\s,]+/);
					
					# set flag for Euro decimal notation (e.g. 6,3 becomes 6.3)
					$eflag = m/,/ && @fields > (@{$self->[1][0]} || 0);
					
				}
				
				# fix Euro decimal notation (e.g. 6,3 becomes 6.3)
				s/(\d),(\d)/$1.$2/g if ($eflag);
				
				# parse and save data
				$self->[1][$index++] = [split(/[\s,]+/)];
				
			# illuminant format
			# may be different from data format
			} elsif ($iflag == 1 && $state == 1) {
				
				# change 'SampleID' to 'SAMPLE_ID'
				# non-standard notation used by ProfileMaker
				s/SampleID/SAMPLE_ID/;
				
				# parse and save illuminant format keys
				push(@{$illum->[0]}, split(/[\s,]+/));
				
			# illuminant data
			} elsif ($iflag == 1 && $state == 3) {
				
				# fix Euro decimal notation (e.g. 6,3 becomes 6.3)
				s/(\d),(\d)/$1.$2/g if ($eflag);
				
				# parse and save illuminant data
				$illum->[$index++] = [split(/[\s,]+/)];
				
			# header lines
			} elsif ($iflag == 0 && ($state == 0 || $state == 2)) {
				
				# match keyword/value
				m/^([^\s,]*)[\s,]*(.*?)$/;
				
				# add to header array
				push(@{$self->[3]}, [$1, $2]) if (length($1));
				
			}
			
		}
		
	}

	# save illuminant data, if any
	$self->[0]{'illuminant'} = $illum if defined($illum->[1]);

	# save appended data, if any
	$self->[0]{'append'} = $append if (defined($append));

	# apply rotation/flip (special keywords)
	_rotateChartASCII($self);

	# return success flag
	return($state == 4 ? () : "ASCII read failed with state $state");

}

# apply rotation/flip to ASCII chart data
# if LGOROWLENGTH and (DPLGROTATE or DPLGFLIP) keywords are present
# parameter: (object_reference)
sub _rotateChartASCII {

	# get object reference
	my $self = shift();

	# local variables
	my ($rot, $flip, $mat, $rows);

	# get the rotation and flip values
	$rot = keyword($self, 'DPLGROTATE');
	$flip = keyword($self, 'DPLGFLIP');

	# if LGOROWLENGTH and (DPLGROTATE or DPLGFLIP) keywords
	if (keyword($self, 'LGOROWLENGTH') && ($rot || $flip)) {
		
		# get selection matrix
		$mat = select_matrix($self)->rotate($rot)->flip($flip);
		
		# flatten matrix
		$rows = ICC::Shared::flatten($mat);
		
		# prepend DATA_FORMAT row index (0)
		unshift(@{$rows}, 0);
		
		# rearrange chart data
		$self->[1] = [@{$self->[1]}[@{$rows}]];
		
		# update LGOROWLENGTH
		keyword($self, 'LGOROWLENGTH', scalar(@{$mat->[0]}));
		
	}
	
}

# read chart from Adobe Swatch Exchange (.ase) file
# optional hash key: 'colorspace'
# 'colorspace' values: 'CMYK', 'LAB ', 'RGB ' or 'Gray'
# 'Gray' swatches are mapped to CMYK values
# parameters: (object_reference, file_handle, hash)
# returns: (result)
sub _readChartASE {

	# get parameters
	my ($self, $fh, $hash) = @_;

	# local variables
	my ($cs, $le, $buf, @header, $sn);
	my ($mark, $type, $blen, $slen);
	my ($name, $space, $cmyk, $rgb, $Lab, $dev);

	# set colorspace selector
	$cs = $hash->{'colorspace'} if defined($hash->{'colorspace'});

	# get little-endian flag
	$le = ($Config{'byteorder'} =~ m/1234/);

	# read header (file signature, version, number of blocks)
	read($fh, $buf, 12);

	# unpack buffer
	@header = unpack('A4nnN', $buf);

	# verify file signature
	($header[0] eq 'ASEF') || return('not a valid ASE file');

	# add SAMPLE_NAME field
	$sn = add_fmt($self, 'SAMPLE_NAME');

	# set file pointer
	$mark = 12;

	# for each block
	for my $s (1 .. $header[3]) {
		
		# read block type, block length, and string length
		read($fh, $buf, 8);
		
		# unpack buffer
		($type, $blen, $slen) = unpack('nNn', $buf);
		
		# if color entry type
		if ($type == 1) {
			
			# read color name
			read($fh, $buf, 2 * $slen);
			
			# decode color name
			$name = decode('UTF-16BE', $buf);
			
			# trim trailing '0'
			$name =~ s/\x00$//;
			
			# change spaces to underscores
			$name =~ s/\s/_/g;
			
			# read color space
			read($fh, $space, 4);
			
			# if colorspace is CMYK
			if (($space eq 'CMYK' && (! defined($cs)) || $cs eq 'CMYK')) {
				
				# store color as SAMPLE_NAME
				$self->[1][$s][$sn->[0]] = $name;
				
				# init device array
				$dev = [];
				
				# for each CMYK value
				for my $i (0 .. 3) {
					
					# read 32-bit floating point value
					read($fh, $buf, 4);
					
					# reverse bytes if long-endian system
					$buf = reverse($buf) if ($le);
					
					# unpack buffer
					$dev->[$i] = unpack('f', $buf);
					
				}
				
				# if CMYK slice undefined
				if (! defined($cmyk)) {
					
					# add CMYK slice
					$cmyk = add_fmt($self, qw(CMYK_C CMYK_M CMYK_Y CMYK_K));
					
				}
				
				# store CMYK values
				@{$self->[1][$s]}[@{$cmyk}] = map {100 * $_} @{$dev};
				
			# if colorspace is RGB
			} elsif (($space eq 'RGB ' && (! defined($cs)) || $cs eq 'RGB ')) {
				
				# store color as SAMPLE_NAME
				$self->[1][$s][$sn->[0]] = $name;
				
				# init device array
				$dev = [];
				
				# for each RGB value
				for my $i (0 .. 2) {
					
					# read 32-bit floating point value
					read($fh, $buf, 4);
					
					# reverse bytes if long-endian system
					$buf = reverse($buf) if ($le);
					
					# unpack buffer
					$dev->[$i] = unpack('f', $buf);
					
				}
				
				# if RGB slice undefined
				if (! defined($rgb)) {
					
					# add RGB slice
					$rgb = add_fmt($self, qw(RGB_R RGB_G RGB_B));
					
				}
				
				# store RGB values
				@{$self->[1][$s]}[@{$rgb}] = map {255 * $_} @{$dev};
				
			# if colorspace is L*a*b*
			} elsif (($space eq 'LAB ' && (! defined($cs)) || $cs eq 'LAB ')) {
				
				# store color as SAMPLE_NAME
				$self->[1][$s][$sn->[0]] = $name;
				
				# init device array
				$dev = [];
				
				# for each L*a*b* value
				for my $i (0 .. 2) {
					
					# read 32-bit floating point value
					read($fh, $buf, 4);
					
					# reverse bytes if long-endian system
					$buf = reverse($buf) if ($le);
					
					# unpack buffer
					$dev->[$i] = unpack('f', $buf);
					
				}
				
				# if L*a*b* slice undefined
				if (! defined($Lab)) {
					
					# add L*a*b* fields
					$Lab = add_fmt($self, qw(LAB_L LAB_A LAB_B));
					
				}
				
				# store L*a*b* values
				@{$self->[1][$s]}[@{$Lab}] = (100 * $dev->[0], $dev->[1], $dev->[2]);
				
			# if colorspace is Grayscale
			} elsif (($space eq 'Gray' && (! defined($cs)) || $cs eq 'Gray')) {
				
				# store color as SAMPLE_NAME
				$self->[1][$s][$sn->[0]] = $name;
				
				# read 32-bit floating point value
				read($fh, $buf, 4);
				
				# reverse bytes if long-endian system
				$buf = reverse($buf) if ($le);
				
				# unpack buffer
				$dev = [unpack('f', $buf)];
				
				# if CMYK slice is undefined
				if (! defined($cmyk)) {
					
					# add CMYK slice
					$cmyk = add_fmt($self, qw(CMYK_C CMYK_M CMYK_Y CMYK_K));
					
				}
				
				# store CMYK values
				@{$self->[1][$s]}[@{$cmyk}] = (0, 0, 0, 100 * (1 - $dev->[0]));
				
			}
		
		}
		
		# set file pointer to next block
		$mark += $blen + 6;
		
		# seek next block
		seek($fh, $mark, 0);
		
	}

	# return
	return();

}

# read chart from ICC profile
# some profiles have tags containing chart data
# parameters: (object_reference, file_handle, hash)
# returns: (result)
sub _readChartICC {

	# get parameters
	my ($self, $fh, $hash) = @_;

	# local variables
	my (@header, @tagtab, %offset, %tags, $type, $class);
	my ($temp, $data, $text, $result);

	# load ICC::Profile modules, if not already included
	require ICC::Profile;

	# read the profile header
	ICC::Profile::_readICCheader($fh, \@header) || return('failed reading ICC profile header');

	# read the profile tag table
	ICC::Profile::_readICCtagtable($fh, \@tagtab) || return('failed reading ICC profile tag table');

	# for each tag
	for my $tag (@tagtab) {
		
		# if tag contains measurement data
		if ($tag->[0] =~ m/^(?:CxF |DevD|CIED|DEVD|targ)$/) {
			
			# if a duplicate tag
			if (exists($offset{$tag->[1]})) {
				
				# use original tag
				$tags{$tag->[0]} = $offset{$tag->[1]};
				
			} else {
				
				# seek to start of tag
				seek($fh, $tag->[1], 0);
				
				# read tag type signature
				read($fh, $type, 4);
				
				# convert non-word characters to underscores
				$type =~ s|\W|_|g;
				
				# form class specifier
				$class = 'ICC::Profile::' . $type;
				
				# if 'class->new_fh' method exists
				if ($class->can('new_fh')) {
					
					# create specific tag object
					$tags{$tag->[0]} = $class->new_fh($self, $fh, $tag);
					
				} else {
					
					# create generic tag object
					$tags{$tag->[0]} = ICC::Profile::Generic->new_fh($self, $fh, $tag);
					
				}
				
				# save tag in hash
				$offset{$tag->[1]} = $tags{$tag->[0]};
				
			}
			
		}
		
	}
	
	# if creator is i1Profiler and 'CxF ' tag exists
	if ($header[23] eq 'XRCM' && exists($tags{'CxF '})) {
		
		# close file handle
		close($fh);
		
		# open file handle to CxF3 string
		open($fh, '<', \$tags{'CxF '}->text());
		
		# make chart from CxF3 string
		return(_readChartCxF3($self, $fh, $hash));
		
	# if creator is ProfileMaker and 'DevD' / 'CIED' tags exist
	} elsif ($header[23] eq 'LOGO' && exists($tags{'DevD'}) && exists($tags{'CIED'})) {
		
		# close file handle
		close($fh);
		
		# open file handle to 'DevD' text string
		open($fh, '<', \$tags{'DevD'}->text());
		
		# read chart from text
		($result = _readChartASCII($self, $fh, $hash)) && return("failed reading ICC profile DEVD tag, $result");
		
		# close file handle
		close($fh);
		
		# make temporary chart object
		$temp = ICC::Support::Chart->new();
		
		# open file handle to 'CIED' text string
		open($fh, '<', \$tags{'CIED'}->text());
		
		# read chart from text
		($result = _readChartASCII($temp, $fh, $hash)) && return("failed reading ICC profile CIED tag, $result");
		
		# get data slice (all rows, spectral, XYZ and L*a*b* columns)
		$data = slice($temp, [0 .. $#{$temp->[1]}], [grep {$temp->[1][0][$_] =~ m/^(nm\d{3}|XYZ_(X|Y|Z)|LAB_(L|A|B))$/} (0 .. $#{$temp->[1][0]})]);
		
		# append to chart
		add_cols($self, $data);
		
		# for each keyword
		for my $key (@{$temp->[3]}) {
			
			# if keyword not in main chart
			if (0 == grep {$key->[0] eq $_->[0]} @{$self->[3]}) {
				
				# append keyword/value
				push(@{$self->[3]}, $key);
				
			}
			
		}
		
		# return
		return();
		
	# if creator is Monaco and 'DEVD' tag exists (some old profiles are identified by preferred CMM)
	} elsif (($header[23] eq 'MONS' || $header[1] eq 'mnco') && exists($tags{'DEVD'})) {
		
		# read chart from Monaco 'DEVD' tag
		return(_readMonacoDEVD($self, $tags{'DEVD'}->data(), \@header));
		
	# if 'targ' tag exists
	} elsif (exists($tags{'targ'})) {
		
		# get 'targ' tag text string
		$text = $tags{'targ'}->text();
		
		# if reference to ICC Characterization Data Registry
		if ($text =~ m/^ICCHDAT (.*)$/) {
			
			# return
			return("profile derived from $1 characterization data, available at www.color.org");
			
		} else {
			
			# close file handle
			close($fh);
			
			# open file handle to text string
			open($fh, '<', \$text);
			
			# read chart from text
			return(_readChartASCII($self, $fh, $hash));
			
		}
		
	}

	# return
	return('failed reading ICC profile characterization data');

}

# read chart from Monaco 'DEVD' tag
# parameters: (object_reference, tag_data, profile_header)
# returns: (result)
sub _readMonacoDEVD {

	# get parameters
	my ($self, $data, $header) = @_;

	# local variables
	my ($big, %cshash, $cs, $nc, $fix, $ix, $tag, $tac, $limit, $mult, $dev, $lab);
	my ($ns, $sec, @devfix, @nd, $nt, @devstep, @dev, @cmy, @sum, @temp, $m, @dat);

	# get big-endian flag (true if our system is big-endian)
	$big = ($Config{'byteorder'} =~ m/4321/);

	# colorspace hash (colorspace => number_channels)
	%cshash = ('RGB ' => 3, 'CMYK' => 4, '5CLR' => 5, '6CLR' => 6, '7CLR' => 7, '8CLR' => 8);

	# initialize fixed value array
	@devfix = ();

	# get colorspace from profile header
	$cs = $header->[4];

	# lookup number of channels
	$nc = $cshash{$cs};

	# set number of fixed channels
	$fix = $nc - 3;

	# set index to start of first tag
	$ix = 28;

	# set tag value
	$tag = pack('N', 0x002D);

	# find TAC tag
	do {$ix = index($data, $tag, $ix)} while ($ix >= 0 && $ix % 4 && $ix++);

	# verify tag found
	($ix >= 0) || return('failed reading TAC from Monaco DEVD tag');

	# get TAC value
	$tac = 100 * unpack('d', $big ? substr($data, $ix + 4, 8) : reverse(substr($data, $ix + 4, 8)));

	# if RGB colorspace
	if ($cs eq 'RGB ') {
		
		# add device fields
		$dev = add_fmt($self, qw(RGB_R RGB_G RGB_B));
		
		# set device multiplier
		$mult = 255;
		
	# if CMYK colorspace
	} elsif ($cs eq 'CMYK') {
		
		# add device fields
		$dev = add_fmt($self, qw(CMYK_C CMYK_M CMYK_Y CMYK_K));
		
		# set device multiplier
		$mult = 100;
		
	} else {
		
		# add device fields
		$dev = add_fmt($self, map {"$cs\_$_"} (1 .. $nc));
		
		# set device multiplier
		$mult = 100;
		
	}

	# add L*a*b* fields
	$lab = add_fmt($self, qw(LAB_L LAB_A LAB_B));

	# advance index
	$ix += 12;

	# set tag value
	$tag = pack('N', 0x0027);

	# find data group tag
	do {$ix = index($data, $tag, $ix)} while ($ix >= 0 && $ix % 4 && $ix++);

	# verify tag found
	($ix >= 0) || return('failed reading data group from Monaco DEVD tag');

	# get number data sections in group
	$ns = unpack('N', substr($data, $ix + 4, 4));

	# advance index
	$ix += 8;

	# for data each section
	for my $s (0 .. $ns - 1) {
		
		# verify tag 0x0028
		(substr($data, $ix, 4) eq pack('N', 0x0028)) || return(0);
		
		# get section index
		$sec = unpack('N', substr($data, $ix + 4, 4));
		
		# verify section index is correct
		($sec == $s) || return('failed reading section index from Monaco DEVD tag');
		
		# advance index
		$ix += 8;
		
		# verify tag 0x002A (fixed device values)
		(substr($data, $ix, 4) eq pack('N', 0x002A)) || return('failed reading fixed device values from Monaco DEVD tag');
		
		# if fixed device values (none for RGB)
		if ($fix) {
			
			# get fixed device values (black plus any extra colors, e.g. orange or green)
			@devfix = unpack("d$fix", $big ? substr($data, $ix + 4, 8 * $fix) : reverse(substr($data, $ix + 4, 8 * $fix)));
			
			# reverse array if little-endian
			@devfix = reverse(@devfix) if (! $big);
			
			# apply multiplier
			@devfix = map {$_ * $mult} @devfix;
			
		}
		
		# advance index
		$ix += 8 * $fix + 4;
		
		# verify tag 0x002B (step counts by color)
		(substr($data, $ix, 4) eq pack('N', 0x002B)) || return('failed reading step counts from Monaco DEVD tag');
		
		# get device step counts
		@nd = unpack('N3', substr($data, $ix + 4, 12));
		
		# get total number of steps
		$nt = $nd[0] + $nd[1] + $nd[2];
		
		# advance index
		$ix += 16;
		
		# verify tag 0x002C (step values by color)
		(substr($data, $ix, 4) eq pack('N', 0x002C)) || return('failed reading step values from Monaco DEVD tag');
		
		# get step values
		@devstep = unpack("d$nt", $big ? substr($data, $ix + 4, 8 * $nt) : reverse(substr($data, $ix + 4, 8 * $nt)));
		
		# reverse array if little-endian
		@devstep = reverse(@devstep) if (! $big);
		
		# apply multiplier
		@devstep = map {$_ * $mult} @devstep;
		
		# advance index
		$ix += 8 * $nt + 4;
		
		# initialize arrays
		@dev = ();
		@sum = ();
		@temp = ();
		
		# if RGB colorspace
		if ($cs eq 'RGB ') {
			
			# for each blue step
			for my $i (0 .. $nd[2] - 1) {
				
				# for each green step
				for my $j (0 .. $nd[1] - 1) {
					
					# for each red step
					for my $k (0 .. $nd[0] - 1) {
						
						# save RGB values
						push(@dev, $devstep[$k], $devstep[$j + $nd[0]], $devstep[$i + $nd[0] + $nd[1]]);
						
					}
					
				}
				
			}
			
		# if CMYK or NCLR colorspace
		} else {
			
			# for each yellow step
			for my $i (0 .. $nd[2] - 1) {
				
				# for each cyan step
				for my $j (0 .. $nd[0] - 1) {
					
					# for each magenta step
					for my $k (0 .. $nd[1] - 1) {
						
						# get CMY values
						@cmy = ($devstep[$j], $devstep[$k + $nd[0]], $devstep[$i + $nd[0] + $nd[1]]);
						
						# save CMY values
						push(@temp, [@cmy]);
						
						# save total ink value
						push(@sum, List::Util::sum(@cmy, @devfix));
						
					}
					
				}
				
			}
			
			# initialize actual ink limit
			$limit = $nc * 100;
			
			# find actual ink limit (smallest value greater than TAC)
			for (@sum) {$limit = $_ if ($_ > $tac && $_ < $limit)};
			
			# for each sample
			for my $i (0 .. $#sum) {
				
				# get cmy values
				@cmy = @{$temp[$i]};
				
				# if sample within ink limit, or a corner point
				if ($sum[$i] <= $limit || ((0 < grep {$_ == 0} @cmy) && (0 < grep {$_ == 100} @cmy))) {
					
					# copy cmy values
					push(@dev, @cmy);
					
				}
				
			}
			
		}
		
		# verify tag 0x0032 (L*a*b* sample data)
		(substr($data, $ix, 4) eq pack('N', 0x0032)) || return('failed reading L*a*b* data from Monaco DEVD tag');
		
		# get number of values
		$m = unpack('N', substr($data, $ix + 4, 4)) * 3;
		
		# get L*a*b* color data
		@dat = unpack("d$m", $big ? substr($data, $ix + 8, 8 * $m) : reverse(substr($data, $ix + 8, 8 * $m)));
		
		# reverse array if little-endian
		@dat = reverse(@dat) if (! $big);
		
		# advance index
		$ix += 8 * $m + 8;
		
		# verify @dev and @dat are same size
		(scalar(@dev) == scalar(@dat)) || return('failed comparing data counts of Monaco DEVD tag');
		
		# for each sample (3 values per sample)
		for my $i (0 .. ($m/3 - 1)) {
			
			# add sample data to object
			push (@{$self->[1]}, [@dev[($i * 3) .. ($i * 3 + 2)], @devfix, @dat[($i * 3) .. ($i * 3 + 2)]]);
			
		}
		
		# verify tag 0x0029 (end of section)
		(substr($data, $ix, 4) eq pack('N', 0x0029)) || return('failed reading section end from Monaco DEVD tag');
		
		# advance index
		$ix += 4;
		
	}

	# verify tag 0x0030 (end of data)
	(substr($data, $ix, 4) eq pack('N', 0x0030)) || return('failed reading data end from Monaco DEVD tag');

	# add 'CREATED' keyword/value from header date/time
	push(@{$self->[3]}, ['CREATED', sprintf('%.4d-%.2d-%.2dT%.2d:%.2d:%.2dZ', @{$header}[6 .. 11])]);

	# return
	return();

}

# read chart from SpectraShop (.ss3) file
# parameters: (object_reference, file_handle, hash)
sub _readChartSS3 {

	# get parameters
	my ($self, $fh, $hash) = @_;

	# local variables
	my (%fmt, $buf, @data, $notes);
	my ($meta, $measure, %tally, @keys, $value, $nm);

	# metadata format array (v32)
	$fmt{'32'} = [
		[qw(Identifier_1 SAMPLE_NAME P)],
		[qw(Identifier_2 SAMPLE_ID2 P)],
		[qw(Identifier_3 SAMPLE_ID3 P)],
		[qw(Material MATERIAL P)],
		[qw(Manufacturer MANUFACTURER P)],
		[qw(Model MODEL P)],
		[qw(Serial_Number SERIAL_NUMBER P)],
		[qw(Production_Date PROD_DATE P)],
		[qw(Surface SURFACE P)],
		[qw(Originator ORIGINATOR P)],
		[qw(Creation_Date CREATED P)],
		[qw(Comments NOTE P)],
		[qw(Instrument INSTRUMENTATION P)],
		[qw(Spectrum_Type SPECTRUM_TYPE n), [qw(Emissive-light Emissive-monitor Observer Reflective Transmissive)]],
		[qw(Filter MEASUREMENT_FILTER P)],
		[qw(Geometry MEASUREMENT_GEOMETRY P)],
		[qw(Aperture MEASUREMENT_APERTURE P)],
		[qw(Data_Reference DATA_REFERENCE P)],
		[qw(Illuminant MEASUREMENT_SOURCE P)],
		[qw(Backing SAMPLE_BACKING P)],
		[qw(Measurements NSAMPLES n)],
		[qw(Notes ACQUIRE_NOTE P)],
	];

	# metadata format array (v50)
	$fmt{'50'} = [
		[qw(Identifier_1 SAMPLE_NAME P)],
		[qw(Identifier_2 SAMPLE_ID2 P)],
		[qw(Identifier_3 SAMPLE_ID3 P)],
		[qw(Material MATERIAL P)],
		[qw(Manufacturer MANUFACTURER P)],
		[qw(Model MODEL P)],
		[qw(Serial_Number SERIAL_NUMBER P)],
		[qw(Production_Date PROD_DATE P)],
		[qw(Surface SURFACE P)],
		[qw(Originator ORIGINATOR P)],
		[qw(Creation_Date CREATED P)],
		[qw(Comments NOTE P)],
		[qw(Instrument INSTRUMENTATION P)],
		[qw(Serial_Number INSTRUMENT_SERIAL_NUMBER P)],
		[qw(Spectrum_Type SPECTRUM_TYPE n), [qw(Emissive-light Emissive-monitor Observer Reflective Transmissive)]],
		[qw(Filter MEASUREMENT_FILTER P)],
		[qw(Geometry MEASUREMENT_GEOMETRY P)],
		[qw(Aperture MEASUREMENT_APERTURE P)],
		[qw(Data_Reference DATA_REFERENCE P)],
		[qw(Illuminant MEASUREMENT_SOURCE P)],
		[qw(Backing SAMPLE_BACKING P)],
		[qw(Measurements NSAMPLES n)],
		[qw(Notes ACQUIRE_NOTE P)],
	];

	# read version, samples, Collection Notes length
	read($fh, $buf, 7);

	# unpack
	@data = unpack('nx2nC', $buf);

	# read Collection Notes string
	read($fh, $notes, $data[2]);

	# for each sample
	for my $i (0 .. ($data[1] - 1)) {
		
		# for each metadata field
		for my $j (0 .. $#{$fmt{$data[0]}}) {
			
			# if a Pascal string
			if ($fmt{$data[0]}[$j][2] eq 'P') {
				
				# read string length
				read($fh, $buf, 1);
				
				# read string
				read($fh, $meta->[$i][$j], unpack('C', $buf));
				
			# if an unsigned short integer
			} elsif ($fmt{$data[0]}[$j][2] eq 'n') {
				
				# read short integer
				read($fh, $buf, 2);
				
				# unpack
				$meta->[$i][$j] = unpack('n', $buf);
				
			}
			
		}
		
		# read wavelength parameters (start, end, increment, count)
		read($fh, $buf, 8);
		
		# unpack (unsigned short integer)
		$measure->[$i][0] = [unpack('n4', $buf)];
		
		# for each wavelength
		for my $j (1 .. $measure->[$i][0][3]) {
			
			# read measurements (avg, low, high, std_dev)
			read($fh, $buf, 16);
			
			# unpack (32-bit float, big endian)
			$measure->[$i][$j] = [unpack('(f4)>', $buf)];
			
		}
		
	}

	# add Collection Notes to header line array, if not null string
	push(@{$self->[3]}, ['FILE_DESCRIPTOR', "\"$notes\""]) if (length($notes));

	# for each metadata field
	for my $j (0 .. $#{$meta->[0]}) {
		
		# init hash
		%tally = ();
		
		# for each sample
		for my $i (0 .. $#{$meta}) {
			
			# increment hash value
			$tally{$meta->[$i][$j]}++;
			
		}
		
		# get hash keys
		@keys = keys(%tally);
		
		# if one hash key
		if (@keys == 1) {
			
			# if not the null string
			if (length($keys[0])) {
				
				# if value is string
				if ($fmt{$data[0]}[$j][2] eq 'P') {
					
					# wrap in quotes
					$value = "\"$keys[0]\"";
					
				} else {
					
					# if value is an enumeration
					if (defined($fmt{$data[0]}[$j][3])) {
						
						# look up enumerated value and wrap in quotes
						$value = "\"$fmt{$data[0]}[$j][3][$keys[0]]\"";
						
					} else {
						
						# use value as-is
						$value = $keys[0];
						
					}
					
				}
				
				# add KEYWORD/VALUE to header line array
				push(@{$self->[3]}, [$fmt{$data[0]}[$j][1], $value]);
				
			}
			
		} else {
			
			# add keyword to DATA_FORMAT array
			push(@{$self->[1][0]}, $fmt{$data[0]}[$j][1]);
			
			# for each sample
			for my $i (0 .. $#{$meta}) {
				
				# if value is an enumeration
				if (defined($fmt{$data[0]}[$j][3])) {
					
					# look up enumerated value
					$value = $fmt{$data[0]}[$j][3][$meta->[$i][$j]];
					
				} else {
					
					# use value as-is
					$value = $meta->[$i][$j];
					
				}
				
				# add value to DATA array
				push(@{$self->[1][$i + 1]}, $meta->[$i][$j]);
				
			}
			
		}
		
	}

	# for each wavelength parameter (start, end, increment, count)
	for my $j (0 .. 3) {
		
		# init hash
		%tally = ();
		
		# for each sample
		for my $i (0 .. $#{$measure}) {
			
			# increment hash value
			$tally{$measure->[$i][0][$j]}++;
			
		}
		
		# get hash keys
		@keys = keys(%tally);
		
		# verify all samples have same wavelength parameter value
		(@keys == 1) || return('samples have varied spectral range');
		
	}

	# for each wavelength
	for my $j (0 .. ($#{$measure->[0]} - 1)) {
		
		# compute wavelength from start and increment values
		$nm = $measure->[0][0][0] + $j * $measure->[0][0][2];
		
		# add keyword to DATA_FORMAT array
		push(@{$self->[1][0]}, "nm$nm");
		
		# for each sample
		for my $i (0 .. $#{$measure}) {
			
			# add average measurement to DATA array
			push(@{$self->[1][$i + 1]}, $measure->[$i][$j + 1][0]);
			
		}
		
	}

	# return
	return();

}

# read data from TIFF file
# RGB, CMYK, and CIE L*a*b* color spaces supported
# 8-bit, 16-bit or 32-bit, Intel or Motorola byte order supported
# alpha and spot channels in RGB and CMYK files supported
# optional hash keys: 'rows', 'columns', 'crop', 'ratio', 'aperture', 'udf', 'format'
# default 'rows' and 'columns' are taken from image size, default 'ratio' is 0.5
# 'crop' is an array containing the left, right, upper and lower crop values in pixels
# 'ratio' is a value between 0 and 1, sample is a single pixel when 'ratio' is 0
# 'aperture' is in millimeters, and take precedence over 'ratio'
# 'udf' is a code reference to a pixel processing function
# 'format' is an array reference containing the format fields
# parameters: (object_reference, file_handle, hash)
# returns: (result)
sub _readChartTIFF {

	# get parameters
	my ($self, $fh, $hash) = @_;

	# local variables
	my ($buf, $short, $long, $fp, @header, $tags);
	my ($cols, $rows, $bits, $pi, $samples);
	my ($context, $fmt, $upf, $udf, $dev, $div, $dab);
	my ($trows, $tcols, $crop, $roff, $coff);
	my ($res, $size, $frac, $ratio, $rxo, $cxo, $pixels, $width);
	my ($lower, $upper, $left, $right, $band, $pval, @data, @pix);

	# read the header
	read($fh, $buf, 8);

	# if big-endian (Motorola)
	if (substr($buf, 0, 2) eq 'MM') {
		
		# set 'unpack' formats
		$short = 'n';
		$long = 'N';
		$fp = 'f>'; # might not be IEEE FP on some platforms
		
	# if little-endian (Intel)
	} elsif (substr($buf, 0, 2) eq 'II'){
		
		# set 'unpack' formats
		$short = 'v';
		$long = 'V';
		$fp = 'f<'; # might not be IEEE FP on some platforms
		
	} else {
		
		# error
		return('TIFF byte order incorrect');
		
	}

	# unpack the header
	@header = unpack("A2 $short $long", $buf);

	# verify file signature
	($header[1] == 42) || return('TIFF file signature incorrect');

	# read TIFF image file directory (IFD)
	$tags = _readTIFFdir($fh, $header[2], $short, $long);

	# verify compression (1 = uncompressed)
	($tags->{'259'}[0] == 1) || return('TIFF compression unsupported');

	# verify orientation (1 = normal)
	(! exists($tags->{'274'}) || $tags->{'274'}[0] == 1) || warn('TIFF orientation rotated and/or flipped');

	# verify planar configuration (1 = chunky)
	(! exists($tags->{'284'}) || $tags->{'284'}[0] == 1) || return('TIFF planar configuration unsupported');

	# verify not tiled
	(! exists($tags->{'322'})) || return('TIFF tiled layout unsupported');

	# get TIFF columns (width)
	$cols = $tags->{'256'}[0];

	# get TIFF rows (length)
	$rows = $tags->{'257'}[0];

	# get TIFF bits per sample
	$bits = $tags->{'258'}[0];

	# verify bits per sample
	($bits == 8 || $bits == 16 || $bits == 32) || return('TIFF bits per sample unsupported');

	# get the photometric interpretation
	$pi = $tags->{'262'}[0];

	# if 32-bits per sample
	if ($bits == 32) {
		
		# verify 32-bit IEEE FP format, RGB image
		($tags->{'339'}[0] == 3 && $pi == 2) || return('TIFF format unsupported');
		
	}

	# get TIFF samples per pixel
	$samples = $tags->{'277'}[0];

	# verify bits per sample array
	($samples == grep {$_ == $bits} @{$tags->{'258'}}) || return('TIFF image structure unsupported');

	# get context (if any)
	$context = $hash->{'context'};

	# get user defined function (if any)
	$udf = $hash->{'udf'};

	# verify UDF is a code reference
	(ref($udf) eq 'CODE') || return('UDF not a code reference') if (defined($udf));

	# set device value divisor
	$dev = ($bits == 8) ? 255 : 65535;

	# add fields for udf (if any)
	$fmt = add_fmt($self, map {defined($context) ? "$context|$_" : $_} @{$hash->{'format'}}) if defined($hash->{'format'});

	# if RGB file
	if ($pi == 2 && $samples < 13) {
		
		# add RGB and ALPHA fields, if not already defined
		$fmt = add_fmt($self, map {defined($context) ? "$context|$_" : $_} (qw(RGB_R RGB_G RGB_B), map {"RGB_A$_"} (1 .. $samples - 3))) if (! defined($fmt));
		
		# set unpack format (8, 16 or 32 bits)
		$upf = ($bits == 8) ? 'C*' : ($bits == 16) ? "$short*" : "$fp*";
		
		# set divisor (8, 16 or 32 bits)
		$div = ($bits == 8) ? 1 : ($bits == 16) ? 257 : 1/255;
		
	# if CMYK file
	} elsif ($pi == 5 && $samples == 4) {
		
		# add CMYK fields, if not already defined
		$fmt = add_fmt($self, map {defined($context) ? "$context|$_" : $_} qw(CMYK_C CMYK_M CMYK_Y CMYK_K)) if (! defined($fmt));
		
		# set unpack format (8 or 16 bits)
		$upf = ($bits == 8) ? 'C*' : "$short*";
		
		# set divisor (8 or 16 bits)
		$div = ($bits == 8) ? 2.55 : 655.35;
		
	# if nCLR file
	} elsif ($pi == 5 && $samples > 4 && $samples < 16) {
		
		# add nCLR fields, if not already defined
		$fmt = add_fmt($self, map {defined($context) ? "$context|$_" : $_} map {sprintf('%xCLR_%x', $samples, $_)} (1 .. $samples)) if (! defined($fmt));
		
		# set unpack format (8 or 16 bits)
		$upf = ($bits == 8) ? 'C*' : "$short*";
		
		# set divisor (8 or 16 bits)
		$div = ($bits == 8) ? 2.55 : 655.35;
		
	# if CIE L*a*b* file
	} elsif ($pi == 8 && $samples == 3) {
		
		# add L*a*b* fields, if not already defined
		$fmt = add_fmt($self, map {defined($context) ? "$context|$_" : $_} qw(LAB_L LAB_A LAB_B)) if (! defined($fmt));
		
		# set unpack format (8 or 16 bits)
		$upf = ($bits == 8) ? '(Ccc)*' : "$short*";
		
		# set divisors (8 or 16 bits)
		$div = ($bits == 8) ? 2.55 : 655.35; # L*
		$dab = ($bits == 8) ? 1 : 256; # a* and b*
		
	} else {
		
		# return error
		return('TIFF color space unsupported');
		
	}

	# get target rows (could be undefined)
	$trows = $hash->{'rows'};

	# get target columns (could be undefined)
	$tcols = $hash->{'columns'};

	# if 'crop' parameter is defined
	if (defined($hash->{'crop'})) {
		
		# get crop parameter
		$crop = $hash->{'crop'};
		
		# verify array reference
		(ref($crop) eq 'ARRAY') || return('TIFF crop parameter not an array reference');
		
		# verify array contains four non-negative integers
		(4 == @{$crop} && 4 == grep {$_ == int($_) && $_ >= 0} @{$crop}) || return('TIFF crop parameter(s) invalid');
		
		# adjust rows and columns
		$rows -= $crop->[2] + $crop->[3];
		$cols -= $crop->[0] + $crop->[1];
		
		# verify cropped size
		($rows > 0 && $cols > 0) || return('TIFF crop size too small');
		
		# set offset values
		$roff = $crop->[2];
		$coff = $crop->[0];
		
	} else {
		
		# set offset values
		$roff = 0;
		$coff = 0;
		
	}

	# if aperture is defined in hash
	if (defined($hash->{'aperture'})) {
		
		# compute image resolution
		$res = $tags->{'283'}[0]/$tags->{'283'}[1];
		
		# convert to lines/mm if resolution unit is inch
		$res /= 25.4 if ($tags->{'296'}[0] == 2);
		
		# convert to lines/mm if resolution unit is cm
		$res /= 10 if ($tags->{'296'}[0] == 3);
		
		# if target rows or target columns are defined
		if (defined($trows) || defined($tcols)) {
			
			# use image rows if target rows undefined
			$trows = $rows if (! defined($trows));
			
			# use image columns if target columns undefined
			$tcols = $cols if (! defined($tcols));
			
			# compute aperture size (diameter in pixels)
			($frac, $size) = POSIX::modf(sqrt(ICC::Shared::PI/4) * $res * $hash->{'aperture'});
			
			# if fractional part < 0.25
			if ($frac < 0.25) {
				
				# set row and column index offsets
				$rxo = $cxo = $size - 1;
				
			# if fractional part < 0.75
			} elsif ($frac < 0.75) {
				
				# set row index offset
				$rxo = $size - 1;
				
				# set column index offset
				$cxo = $size;
				
			} else {
				
				# set row and column index offsets
				$rxo = $cxo = $size;
				
			}
			
			# verify aperture is within sample area
			($rxo <= $rows/$trows && $cxo <= $cols/$tcols) || croak('TIFF aperture exceeds sample area')
			
		} else {
			
			# compute aperture area (in pixels)
			$size = ICC::Shared::PI * ($res * $hash->{'aperture'}/2)**2;
			
			# compute the target rows
			$trows = int(sqrt($size * $rows/$cols) + 0.5);
			
			# compute the target columns
			$tcols = int($size/$trows + 0.5);
			
			# set row and column indices (single pixel sample)
			$rxo = $cxo = 0;
			
		}
		
	} else {
		
		# use image rows if target rows undefined
		$trows = $rows if (! defined($trows));
		
		# use image columns if target columns undefined
		$tcols = $cols if (! defined($tcols));
		
		# get mask ratio (default 0.5)
		$ratio = defined($hash->{'ratio'}) ? $hash->{'ratio'} : 0.5;
		
		# verify mask ratio
		($ratio >= 0 && $ratio <= 1) || croak('TIFF mask ratio < 0 or > 1');
		
		# compute row index offset
		$rxo = int($ratio * $rows/$trows - 0.5);
		
		# compute column index offset
		$cxo = int($ratio * $cols/$tcols - 0.5);
		
	}

	# warn if large target size
	($trows * $tcols <= 10000) || warn('TIFF target size > 10000 samples');

	# compute number of pixels
	$pixels = ($rxo + 1) * ($cxo + 1);

	# compute row width (bytes)
	$width = $tags->{'256'}[0] * List::Util::sum(@{$tags->{'258'}})/8;

	# for each target row
	for my $i (0 .. $trows - 1) {
		
		# compute sample lower row
		$lower = int(($i + 0.5) * $rows/$trows - $rxo/2) + $roff;
		
		# compute sample upper row
		$upper = $lower + $rxo;
		
		# get sample band data
		$band = _readTIFFband($fh, $tags, $lower, $upper, $width, $upf);
		
		# for each target column
		for my $j (0 .. $tcols - 1) {
			
			# compute sample left column
			$left = int(($j + 0.5) * $cols/$tcols - $cxo/2) + $coff;
			
			# compute sample right column
			$right = $left + $cxo;
			
			# initialize data
			@data = ();
			
			# for each row (band)
			for my $m (0 .. $#{$band}) {
				
				# for each column
				for my $n ($left .. $right) {
					
					# get pixel value (all samples)
					@pix = @{$band->[$m]}[$n * $samples .. ($n + 1) * $samples - 1];
					
					# if 16-bit L*a*b*
					if ($pi == 8 && $bits == 16) {
						
						# adjust a* and b* if pixel value negative (signed 16-bit)
						$pix[1] += -65536 if ($pix[1] > 32767);
						$pix[2] += -65536 if ($pix[2] > 32767);
						
					}
					
					# if user defined function provided
					if (defined($udf)) {
						
						# if L*a*b* file
						if ($pi == 8) {
							
							# convert values
							$pix[0] /= $div;
							$pix[1] /= $dab;
							$pix[2] /= $dab;
							
						} else {
							
							# convert to device values
							@pix = map {$_/$dev} @pix;
							
							# if a CMYK file
							if ($pi == 5) {
								
								# for alpha/spot colors (if any)
								for my $s (4 .. $samples - 1) {
									
									# invert device value
									$pix[$s] = 1 - $pix[$s];
									
								}
								
							}
							
						}
						
						# call user defined function
						@pix = &$udf(@pix);
						
					}
					
					# for each channel (may be different from TIFF samples)
					for my $s (0 .. $#pix) {
						
						# accumulate pixel values
						$data[$s] += $pix[$s]
						
					}
					
				}
				
			}
			
			# if user defined function provided
			if (defined($udf)) {
				
				# save data in object
				@{$self->[1][$j * $trows + $i + 1]}[@{$fmt}] = map {$_/$pixels} @data;
				
			# if L*a*b* file
			} elsif ($pi == 8) {
				
				# save data in object
				$self->[1][$j * $trows + $i + 1][$fmt->[0]] = $data[0]/($pixels * $div);
				$self->[1][$j * $trows + $i + 1][$fmt->[1]] = $data[1]/($pixels * $dab);
				$self->[1][$j * $trows + $i + 1][$fmt->[2]] = $data[2]/($pixels * $dab);
				
			# all others
			} else {
				
				# normalize data values
				@data = map {$_/($pixels * $div)} @data;
				
				# if a CMYK file
				if ($pi == 5) {
					
					# for alpha/spot colors (if any)
					for my $s (4 .. $samples - 1) {
						
						# invert %-dot value
						$data[$s] = 100 - $data[$s];
						
					}
					
				}
				
				# save data in object
				@{$self->[1][$j * $trows + $i + 1]}[@{$fmt}] = @data;
				
			}
			
		}
		
	}

	# save the tag hash in object header
	$self->[0]{'TIFF_tag'} = $tags;

	# add LGOROWLENGTH keyword
	keyword($self, 'LGOROWLENGTH', $trows);

	# return
	return();

}

# read TIFF image file directory (IFD)
# parameters: (file_handle, offset, short_format, long_format)
# returns: (IFD_hash)
sub _readTIFFdir {

	# get parameters
	my ($fh, $start, $short, $long) = @_;

	# local variables
	my (@ts, $buf, $id, $type, $count, $size, $mark, $offset, $num, $denom, $tags);

	# field type size (in bytes)
	@ts = (0, 1, 1, 2, 4, 8, 1, 1, 2, 4, 8, 4, 8, 4);

	# seek start of IFD
	seek($fh, $start, 0);

	# read number entries
	read($fh, $buf, 2);

	# read the directory
	for (1 .. unpack($short, $buf)) {
		
		# read first part of IFD entry
		read($fh, $buf, 8);
		
		# unpack first three fields (ID, type, count)
		($id, $type, $count) = unpack("$short$short$long", $buf);
		
		# read last part of IFD entry
		read($fh, $buf, 4);
		
		# determine value/offset size (size * count) + (1 if ASCII string)
		$size = $ts[$type] * $count + (($type == 2) ? 1 : 0);
		
		# if an offset
		if ($size > 4) {
			
			# mark file location
			$mark = tell($fh);
			
			# unpack offset
			$offset = unpack($long, $buf);
			
			# seek values
			seek($fh, $offset, 0);
			
			# if binary string
			if ($type == 1 || $type == 7) {
				
				# read binary string
				read($fh, $buf, $count);
				
				# unpack value
				$tags->{$id} = [unpack("a$count", $buf)];
				
			# if ASCII string
			} elsif ($type == 2) {
				
				# read ASCII string
				read($fh, $buf, $count);
				
				# unpack null-terminated ASCII string
				$tags->{$id} = [unpack("Z$count", $buf)];
				
			# if short values
			} elsif ($type == 3) {
				
				# read values
				read($fh, $buf, 2 * $count);
				
				# unpack values
				$tags->{$id} = [unpack("$short$count", $buf)];
				
			# if long values
			} elsif ($type == 4) {
				
				# read values
				read($fh, $buf, 4 * $count);
				
				# unpack values
				$tags->{$id} = [unpack("$long$count", $buf)];
				
			# if rational values
			} elsif ($type == 5) {
				
				# double count (one rational value is two long values)
				$count *= 2;
				
				# read values
				read($fh, $buf, 4 * $count);
				
				# unpack values
				$tags->{$id} = [unpack("$long$count", $buf)];
				
			}
			
			# reset file pointer
			seek($fh, $mark, 0);
			
		# if binary string
		} elsif ($type == 1 || $type == 7) {
			
			# unpack binary string
			$tags->{$id} = [unpack("a$count", $buf)];
			
		# if ASCII string
		} elsif ($type == 2) {
			
			# unpack null-terminated ASCII string
			$tags->{$id} = [unpack("Z$count", $buf)];
			
		# if short value(s)
		} elsif ($type == 3) {
			
			# unpack value(s)
			$tags->{$id} = [unpack("$short$count", $buf)];
			
		# if long value
		} elsif ($type == 4) {
			
			# unpack value
			$tags->{$id} = [unpack($long, $buf)];
			
		} else {
			
			# save packed value
			$tags->{$id} = [$buf];
			
		}
		
	}

	# return
	return($tags);

}

# read TIFF image band
# row zero is top of image
# parameters: (file_handle, IFD_hash, lower_row, upper_row, row_width, unpack_format)
# returns: (2D_array)
sub _readTIFFband {

	# get parameters
	my ($fh, $tags, $lower, $upper, $width, $upf) = @_;

	# local variables
	my ($offset, $rows, $buf, $band);

	# get strip offset array
	$offset = $tags->{'273'};

	# get rows per strip
	$rows = $tags->{'278'}[0];

	# for each row
	for my $i ($lower .. $upper) {
		
		# set file pointer
		seek($fh, $offset->[int($i/$rows)] + ($i % $rows) * $width, 0);
		
		# read row data
		read($fh, $buf, $width);
		
		# unpack data
		$band->[$i - $lower] = [unpack($upf, $buf)];
		
	}

	# return
	return($band);

}

# write TIFF image file directory (IFD)
# parameters: (file_handle, offset, short_format, long_format, IFD_hash)
sub _writeTIFFdir {

	# get parameters
	my ($fh, $ifd, $short, $long, $tags) = @_;

	# local variables
	my (@ts, @sid, $mark, $type, $count, $size, $fmt);

	# field type size (in bytes)
	@ts = (0, 1, 1, 2, 4, 8, 1, 1, 2, 4, 8, 4, 8, 4);

	# make list of tag ids, sorted numerically
	@sid = sort {$a <=> $b} keys(%{$tags});

	# seek start of IFD
	seek($fh, $ifd, 0);

	# write number of tags
	print $fh pack($short, scalar(@sid));

	# set data pointer
	$mark = $ifd + 12 * @sid + 6;

	# for each tag
	for my $id (@sid) {
		
		# get data type
		$type = $tags->{$id}[0];
		
		# if a binary string
		if ($type == 1 || $type == 7) {
			
			# set count to string length
			$count = length($tags->{$id}[1]);
			
		# if an ASCII string
		} elsif ($type == 2) {
			
			# set count to string length + 1
			$count = length($tags->{$id}[1]) + 1;
			
		# if a rational value
		} elsif ($type == 5) {
			
			# set count to number of values/2
			$count = $#{$tags->{$id}}/2;
			
		} else {
			
			# set count to number of values
			$count = $#{$tags->{$id}};
			
		}
		
		# if size of value/offset > 4
		if (($size = $count * $ts[$type]) > 4) {
			
			# write directory entry with offset
			print $fh pack("$short$short$long$long", $id, $type, $count, $mark);
			
			# increment data pointer
			$mark += $size;
			
			# make a word boundary
			$mark += $mark % 2;
			
		} else {
			
			# if a binary string
			if ($type == 1 || $type == 7) {
				
				# set pack format
				$fmt = 'a4';
				
			# if an ASCII string
			} elsif ($type == 2) {
				
				# set pack format
				$fmt = 'Z4';
				
			# if a short value
			} elsif ($type == 3) {
				
				# set pack format (one or two values)
				$fmt = $count == 1 ? $short . 'x2' : $short . '2';
				
			# if a long value
			} elsif ($type == 4) {
				
				# set pack format
				$fmt = $long;
				
			} else {
				
				# error
				croak('unsupported TIFF data type, stopped');
				
			}
			
			# write directory entry (12 bytes) with value(s)
			print $fh pack("$short$short$long$fmt", $id, $type, $count, @{$tags->{$id}}[1 .. $#{$tags->{$id}}]);
			
		}
		
	}

	# set data pointer
	$mark = $ifd + 12 * @sid + 6;

	# for each tag
	for my $id (@sid) {
		
		# get data type
		$type = $tags->{$id}[0];
		
		# if a binary string
		if ($type == 1 || $type == 7) {
			
			# set count to string length
			$count = length($tags->{$id}[1]);
			
		# if an ASCII string
		} elsif ($type == 2) {
			
			# set count to string length + 1
			$count = length($tags->{$id}[1]) + 1;
			
		# if a rational value
		} elsif ($type == 5) {
			
			# set count to number of values/2
			$count = $#{$tags->{$id}}/2;
			
		} else {
			
			# set count to number of values
			$count = $#{$tags->{$id}};
			
		}
		
		# if size of value/offset > 4
		if (($size = $count * $ts[$type]) > 4) {
			
			# if a binary string
			if ($type == 1 || $type == 7) {
				
				# set pack format
				$fmt = "a$count";
				
			# if an ASCII string
			} elsif ($type == 2) {
				
				# set pack format
				$fmt = "Z$count";
				
			# if a short value
			} elsif ($type == 3) {
				
				# set pack format
				$fmt = "$short$count";
				
			# if a long value
			} elsif ($type == 4) {
				
				# set pack format
				$fmt = "$long$count";
				
			# if a rational value
			} elsif ($type == 5) {
				
				# set pack format
				$fmt = "$long$#{$tags->{$id}}";
				
			} else {
				
				# error
				croak('unsupported TIFF data type, stopped');
			}
			
			# set file pointer
			seek($fh, $mark, 0);
			
			# write the data value(s)
			print $fh pack($fmt, @{$tags->{$id}}[1 .. $#{$tags->{$id}}]);
			
			# increment data pointer
			$mark += $size;
			
			# make a word boundary
			$mark += $mark % 2;
			
		}
		
	}
	
}

# write TIFF data strip
# parameters: (file_handle, IFD_hash, patch_width, gap_width, left_edge_width, right_edge_width, strip_index, strip_data_array, pack_format, dither_value)
sub _writeTIFFstrip {

	# get parameters
	my ($fh, $tags, $width, $gap, $left, $right, $sx, $data, $fmt, $dither) = @_;

	# local variables
	my ($pi, $samples, $bits, $max, $diff, $edge, $w, @spot, $rms, $gdata, @row, $strip);

	# get photometric interpretation
	$pi = $tags->{'262'}[1];

	# get number of samples (channels)
	$samples = $tags->{'277'}[1];

	# get bits per sample
	$bits = $tags->{'258'}[1];

	# max binary value (8, 16 or 32 bits)
	$max = ($bits == 8) ? 255 : ($bits == 16) ? 65535 : 1;

	# make list of spot channel indices
	@spot = (4 .. $tags->{'277'}[1] - 1);

	# for each patch
	for my $i (0 .. $#{$data}) {
		
		# if RGB data
		if ($pi == 2) {
			
			# compute white and black differences
			$diff->[$i][0] = sqrt(($max - $data->[$i][0])**2 + ($max - $data->[$i][1])**2 + ($max - $data->[$i][2])**2);
			$diff->[$i][1] = sqrt($data->[$i][0]**2 + $data->[$i][1]**2 + $data->[$i][2]**2);
			
		# if CMYK data
		} elsif ($pi == 5) {
			
			# compute rms value of CMY + spot channels (CMY weighted and spot channels inverted)
			$rms = sqrt(List::Util::sum(1.5 * $data->[$i][0]**2, $data->[$i][1]**2, 0.5 * $data->[$i][2]**2, (map {($max - $data->[$i][$_])**2} @spot))/(3 + @spot));
			
			# compute white and black differences (black * color)
			$diff->[$i][0] = $max - ($max - $data->[$i][3]) * ($max - $rms)/$max;
			$diff->[$i][1] = ($max - $data->[$i][3]) * ($max - $rms)/$max;
			
		# L*a*b* data
		} else {
			
			# compute white and black differences (approx dEab)
			$diff->[$i][0] = sqrt(($max - $data->[$i][0])**2 + 6.55 * $data->[$i][1]**2 + 6.55 * $data->[$i][2]**2);
			$diff->[$i][1] = sqrt($data->[$i][0]**2 + 6.55 * $data->[$i][1]**2 + 6.55 * $data->[$i][2]**2);
			
		}
		
		# skip first patch
		if ($i > 0) {
			
			# if RGB data
			if ($pi == 2) {
				
				# if max white difference > max black difference
				if (($diff->[$i - 1][0] > $diff->[$i][0] ? $diff->[$i - 1][0] : $diff->[$i][0]) > ($diff->[$i - 1][1] > $diff->[$i][1] ? $diff->[$i - 1][1] : $diff->[$i][1])) {
					
					# gap is white
					$gdata->[$i - 1] = [($max) x 3];
					
				} else {
					
					# gap is black
					$gdata->[$i - 1] = [0, 0, 0];
					
				}
				
			# if CMYK data
			} elsif ($pi == 5) {
				
				# if max white difference > max black difference
				if (($diff->[$i - 1][0] > $diff->[$i][0] ? $diff->[$i - 1][0] : $diff->[$i][0]) > ($diff->[$i - 1][1] > $diff->[$i][1] ? $diff->[$i - 1][1] : $diff->[$i][1])) {
					
					# gap is white
					$gdata->[$i - 1] = [0, 0, 0, 0, ($max) x ($samples - 4)];
					
				} else {
					
					# gap is black
					$gdata->[$i - 1] = [0, 0, 0, ($max) x ($samples - 3)];
					
				}
				
			# L*a*b* data
			} else {
				
				# if max white difference > max black difference
				if (($diff->[$i - 1][0] > $diff->[$i][0] ? $diff->[$i - 1][0] : $diff->[$i][0]) > ($diff->[$i - 1][1] > $diff->[$i][1] ? $diff->[$i - 1][1] : $diff->[$i][1])) {
					
					# gap is white
					$gdata->[$i - 1] = [$max, 0, 0];
					
				} else {
					
					# gap is black
					$gdata->[$i - 1] = [0, 0, 0];
					
				}
				
			}
			
		}
		
	}

	# compute edge pixel values (black)
	$edge = ($pi == 5) ? [0, 0, 0, ($max) x ($samples - 3)] : [0, 0, 0];

	# for each patch
	for my $i (0 .. $#{$data}) {
		
		# if first patch
		if ($i == 0) {
			
			# add left edge data
			push(@row, (@{$edge}) x $left->[0]);
			
			# set patch width
			$w = $width - $left->[1];
			
		# if last patch
		} elsif ($i == $#{$data}) {
			
			# set patch width
			$w = $width - $right->[1];
			
		# others
		} else {
			
			# set patch width
			$w = $width;
			
		}
		
		# if dither enabled or 32-bits
		if (defined($dither) || $bits == 32) {
			
			# add patch data
			push(@row, (@{$data->[$i]}) x $w);
			
		} else {
			
			# add patch data, adding/subtracting 0.5 to round to the nearest integer (by 'pack', below)
			push(@row, (map {$_ < 0 ? $_ - 0.5 : $_ + 0.5} @{$data->[$i]}) x $w);
			
		}
		
		# if last patch
		if ($i == $#{$data}) {
			
			# add right edge data
			push(@row, (@{$edge}) x $right->[0]);
			
		} else {
			
			# add gap data
			push(@row, (@{$gdata->[$i]}) x $gap);
			
		}
		
	}

	# set file pointer to strip offset
	seek($fh, $tags->{'273'}[$sx + 1], 0);
	
	# if dither enabled and 8-bit
	if (defined($dither) && $bits == 8) {
		
		# for each strip row
		for my $i (0 .. $tags->{'278'}[1] - 1) {
			
			# write packed data with dithering
			print $fh pack($fmt, map {$_ < 0 ? $_ - rand() : $_ + rand()} @row);
			
		}
		
	} else {
		
		# for each strip row
		for my $i (0 .. $tags->{'278'}[1] - 1) {
			
			# write packed data
			print $fh pack($fmt, @row);
			
		}
		
	}
	
}

# read chart from CxF3 data file
# parameters: (object_reference, file_handle, hash)
# returns: (result)
sub _readChartCxF3 {

	# get parameters
	my ($self, $fh, $hash) = @_;

	# local variables
	my ($dom, $root, $ns, $uri, %keys, @info, @obj, $ops_hash, $ops);
	my ($ix, $type, $name, $value, $node, @data, $xrp, @attr);

	# parse CxF3 document
	eval{$dom = XML::LibXML->load_xml('IO' => $fh)} || return('failed parsing CxF3 document');

	# validate the CxF3 document
	_validateCxF3($dom) if (defined($hash->{'validate'}) && $hash->{'validate'});

	# get root element
	$root = $dom->documentElement();

	# get the namespace prefix and URI
	$ns = $root->prefix();
	$uri = $root->namespaceURI();

	# verify CxF3 document or return
	($uri eq 'http://colorexchangeformat.com/CxF3-core') || return('CxF3 document has wrong URI');

	# get cc:Object elements
	@obj = $root->findnodes("$ns:Resources/$ns:ObjectCollection/$ns:Object");

	# get cc:FileInformation elements (optional)
	@info = $root->findnodes("$ns:FileInformation/*");

	# save root element
	# this method only reads data from cc:Object nodes
	# all other CxF3 info is kept in the dom object
	# and accessed as needed by other methods
	$self->[0]{'CxF3_dom'} = $root;

	# save record separator in header
	# note: XML files might not have record separators
	# so we use Perl's input record separator instead
	$self->[0]{'read_rs'} = $/;

	# make CxF3 => ASCII mapping table (from ISO 17972-1, Annex A)
	%keys = ('Creator' => 'ORIGINATOR', 'Description' => 'FILE_DESCRIPTOR', 'CreationDate' => 'CREATED', 'Comment' => 'CXF3_COMMENT');

	# for each cc:FileInformation element
	for my $s (@info) {
		
		# if cc:Tag node
		if ($s->nodeName() eq "$ns:Tag") {
			
			# get name attribute
			$name = $s->getAttribute('Name');
			
			# get value attribute
			$value = $s->getAttribute('Value');
			
		} else {
			
			# get node name
			$name = $s->nodeName();
			
			# remove namespace prefix
			$name =~ s/^\w+://;
			
			# lookup name in hash
			$name = defined($keys{$name}) ? $keys{$name} : $name;
			
			# get node value
			$value = $s->textContent();
			
		}
		
		# add name/value to header array
		push(@{$self->[3]}, [$name, "\"$value\"", 'FileInformation']);
		
	}

	# make the operations hash and add format fields
	$ops_hash = _makeCxF3readops($self, $root, $ns, \@obj, $hash);

	# initialize sample index
	$ix = 0;

	# for each cc:Object element
	for my $s (@obj) {
		
		# get the ObjectType attribute
		$type = $s->getAttribute('ObjectType');
		
		# get the Name attribute
		$name = $s->getAttribute('Name');
		
		# if ObjectType is 'Target' or '...Measurement'
		if ($type =~ m/^Target$|Measurement$/) {
			
			# match numeric part of Name attribute
			$name =~ m/(\d+)$/;
			
			# set row index
			$ix = $1;
			
		} else {
			
			# increment row index
			$ix++;
			
		}
		
		# get operation list for this ObjectType
		$ops = $ops_hash->{$type};
		
		# for each operation
		for my $i (0 .. $#{$ops}) {
			
			# get main Xpath node
			($node) = $s->findnodes($ops->[$i][1]);
			
			# if subpaths
			if (@{$ops->[$i][2]}) {
				
				# if data class is NCLR
				if ($ops->[$i][0] eq 'NCLR') {
					
					# get the CMYK values
					@data = map {$node->findvalue($_)} @{$ops->[$i][2]};
					
					# for each SpotColor
					for my $spotcolor ($node->findnodes("$ns:SpotColor")) {
						
						# push SpotColor value
						push(@data, $spotcolor->findvalue("$ns:Percentage"));
						
					}
					
					# set chart data (CMYK + SPOT values)
					@{$self->[1][$ix]}[@{$ops->[$i][3]}] = @data;
					
				} else {
					
					# set chart data using subpaths
					@{$self->[1][$ix]}[@{$ops->[$i][3]}] = map {$node->findvalue($_)} @{$ops->[$i][2]};
					
				}
				
			# if no subpaths and one field
			} elsif (@{$ops->[$i][3]} == 1) {
				
				# set chart data to text content
				$self->[1][$ix][$ops->[$i][3][0]] = $node->textContent();
				
			# if no subpaths and multiple fields (e.g. spectral data)
			} elsif (@{$ops->[$i][3]} > 1) {
				
				# set chart data splitting text content
				@{$self->[1][$ix]}[@{$ops->[$i][3]}] = split(/ /, $node->textContent());
				
			}
			
		}
		
	}

	# read CxF3 ColorSpecification nodes
	_readCxF3colorspec($self, $root, $ns);

	# make XPathContext object for X-Rite Prism namespace
	$xrp = XML::LibXML::XPathContext->new($root);
	$xrp->registerNs('xrp', 'http://www.xrite.com/products/prism');

	# get the xrp:CustomAttributes node
	if (($node) = $xrp->findnodes("$ns:CustomResources/xrp:Prism/xrp:CustomAttributes")) {
		
		# get the attribute list
		@attr = $node->attributes();
		
		# add xrp:CustomAttributes hash
		$self->[0]{'xrp:CustomAttributes'} = {map {$_->nodeName, $_->getValue()} @attr};
		
	}

	# return
	return();

}

# make CxF3 read operations hash
# adds the format fields to object
# parameters: (object_reference, CxF3_root, CxF3_prefix, CxF3_object_array_reference, hash)
# returns: (hash_ref)
sub _makeCxF3readops {

	# get parameters
	my ($self, $root, $ns, $obj, $hash) = @_;

	# local variables
	my (@attr, @tags, %keys, $table, $k, $m, $n, $t, $type, $entry, $ops_hash);
	my (@format, @nodes, $node, @data, $name, $colorspec, $start, $inc);

	# if cc:Object filter parameter provided
	if (defined($hash->{'cc:Object'}) && ref($hash->{'cc:Object'}) eq 'ARRAY') {
		
		# for each entry
		for (@{$hash->{'cc:Object'}}) {
			
			# match type/attribute
			m/^([^\s\/]*?)\/?([^\s\/]*)$/;
			
			# save matched values
			$entry = [$1, $2];
			
			# if a valid attribute (see CxF3_Core.xsd)
			if ($2 =~ m/^(?:|ObjectType|Name|Id|GUID|\*)$/) {
				
				# push on array
				push(@attr, $entry);
				
			} else {
				
				# print warning
				warn('invalid cc:Object attribute');
				
			}
			
		}
		
	}

	# if cc:Tag filter parameter provided
	if (defined($hash->{'cc:Tag'}) && ref($hash->{'cc:Tag'}) eq 'ARRAY') {
		
		# for each entry
		for (@{$hash->{'cc:Tag'}}) {
			
			# match type/key
			m/^([^\s\/]*?)\/?([^\s\/]*)$/;
			
			# push on array
			push(@tags, [$1, $2]);
			
		}
		
	}

	# make hash for sort order of certain keys
	%keys = ('SampleID' => -2, 'SampleName' => -1, 'Id' => -2, 'Name' => -1);

	# table [data_class, CxF3_main_path, [CxF3_sub_paths], [CGATS/ASCII field names]]
	# some mappings have no sub-paths, which is indicated by an empty sub_path array
	# the 'NCLR', 'SPECTRAL' and 'DENSITY' data classes are special cases
	$table = [
		['RGB', "$ns:DeviceColorValues/$ns:ColorRGB", ["$ns:R", "$ns:G", "$ns:B"], [qw(RGB_R RGB_G RGB_B)]],
		['CMYK', "$ns:DeviceColorValues/$ns:ColorCMYK", ["$ns:Cyan", "$ns:Magenta", "$ns:Yellow", "$ns:Black"], [qw(CMYK_C CMYK_M CMYK_Y CMYK_K)]],
		['NCLR', "$ns:DeviceColorValues/$ns:ColorCMYKPlusN", ["$ns:Cyan", "$ns:Magenta", "$ns:Yellow", "$ns:Black"], [qw(nCLR)]],
		['SPECTRAL', "$ns:ColorValues/$ns:ReflectanceSpectrum", [], [qw(nm)]],
		['DENSITY', "$ns:ColorValues/$ns:ColorDensity/$ns:Density", [], [qw(D_RED D_GREEN D_BLUE D_VIS)]],
		['XYZ', "$ns:ColorValues/$ns:ColorCIEXYZ", ["$ns:X", "$ns:Y", "$ns:Z"], [qw(XYZ_X XYZ_Y XYZ_Z)]],
		['XYY', "$ns:ColorValues/$ns:ColorCIExyY", ["$ns:x", "$ns:y", "$ns:Y"], [qw(XYY_X XYY_Y XYY_YCAP)]],
		['LAB', "$ns:ColorValues/$ns:ColorCIELab", ["$ns:L", "$ns:A", "$ns:B"], [qw(LAB_L LAB_A LAB_B)]],
		['LCH', "$ns:ColorValues/$ns:ColorCIELCh", ["$ns:L", "$ns:C", "$ns:H"], [qw(LAB_L LAB_C LAB_H)]],
		['DE', "$ns:ColorDifferenceValues/$ns:DeltaCIELab/$ns:dE", [], [qw(LAB_DE)]],
		['DE94', "$ns:ColorDifferenceValues/$ns:DeltaCIELab/$ns:dE94", [], [qw(LAB_DE94)]],
		['DECMC', "$ns:ColorDifferenceValues/$ns:DeltaCIELab/$ns:dEcmc", [], [qw(LAB_CMC)]],
		['DE2000', "$ns:ColorDifferenceValues/$ns:DeltaCIELab/$ns:dE2000", [], [qw(LAB_2000)]],
	];

	# set next table index
	$m = $#{$table} + 1;

	# for each CxF3 'Object'
	for my $s (@{$obj}) {
		
		# get the 'ObjectType' attribute
		$type = $s->getAttribute('ObjectType');
		
		# if 'ObjectType' not in hash
		if (! defined($ops_hash->{$type})) {
			
			# add 'ObjectType' to hash
			$ops_hash->{$type} = [];
			
			# if 'Object' attributes are mapped
			if (@attr) {
				
				# for each 'Object' attribute (GUID is optional)
				for my $t (qw(ObjectType Name Id GUID)) {
					
					# if attribute exists and is mapped
					if ($s->exists("\@$t") && grep {($_->[0] eq $type || $_->[0] =~ m/^\*?$/) && ($_->[1] eq $t || $_->[1] =~ m/^\*?$/)} @attr) {
						
						# get sort order
						$k = defined($keys{$t}) ? $keys{$t} : $m++;
						
						# push table entry on hash array (note: attribute XPaths begin with @)
						push(@{$ops_hash->{$type}}, $entry = ["ATTR:$t", "\@$t", [], [$t], $type, $k]);
						
						# push table entry on format array
						push(@format, $entry);
						
					}
					
				}
				
			} else {
				
				# if ObjectType not 'Target' or '...Measurement'
				if ($type !~ m/^Target$|Measurement$/) {
					
					# push table entry on hash array (note: attribute XPaths begin with @)
					push(@{$ops_hash->{$type}}, $entry = ['NAME', '@Name', [], ['SAMPLE_NAME'], $type, -1]);
					
					# push table entry on format array
					push(@format, $entry);
					
				}
				
			}
			
			# for each table entry
			for my $i (0 .. $#{$table}) {
				
				# get table entry
				$t = $table->[$i];
				
				# if main XPath exists
				if ($s->exists($t->[1])) {
					
					# get ColorSpecification attribute (if any)
					$colorspec = $s->findvalue("$t->[1]/\@ColorSpecification");
					
					# push table entry on hash array
					push(@{$ops_hash->{$type}}, $entry = [@{$t}, $type, $i, $colorspec]);
					
					# push table entry on format array
					push(@format, $entry);
					
					# if an 'NCLR' entry
					if ($entry->[0] eq 'NCLR') {
						
						# get cc:SpotColor nodes
						@nodes = $s->findnodes(".//$ns:SpotColor");
						
						# get number of colors
						$n = @nodes + 4;
						
						# add format fields
						$entry->[3] = [map {sprintf('%xCLR_%x', $n, $_)} (1 .. $n)];
						
					# if a 'SPECTRAL' entry
					} elsif ($entry->[0] eq 'SPECTRAL') {
						
						# get the ReflectanceSpectrum data
						@data = split(/ /, $s->findvalue($t->[1]));
						
						# get the ColorSpecification node (linked by the ColorSpecification attribute)
						($node) = $root->findnodes("$ns:Resources/$ns:ColorSpecificationCollection/$ns:ColorSpecification[\@Id='$colorspec']");
						
						# get the StartWL attribute
						$start = $node->findvalue("$ns:MeasurementSpec/$ns:WavelengthRange/\@StartWL");
						
						# get the Increment attribute
						$inc = $node->findvalue("$ns:MeasurementSpec/$ns:WavelengthRange/\@Increment");
						
						# add format fields
						$entry->[3] = [map {'nm' . ($start + $_ * $inc)} (0 .. $#data)];
						
					}
					
				}
				
			}
			
			# if Tags are mapped
			if (@tags) {
				
				# for each Tag
				for my $t ($s->findnodes("$ns:TagCollection/$ns:Tag")) {
					
					# get Tag Name attribute
					$name = $t->getAttribute('Name');
					
					# if this Tag is mapped
					if (grep {($_->[0] eq $type || $_->[0] =~ m/^\*?$/) && ($_->[1] eq $name || $_->[1] =~ m/^\*?$/)} @tags) {
						
						# get sort order
						$k = defined($keys{$name}) ? $keys{$name} : $m++;
						
						# push table entry on hash array (note: attribute XPaths begin with @)
						push(@{$ops_hash->{$type}}, $entry = ["TAG:$name", "$ns:TagCollection/$ns:Tag[\@Name = '$name']/\@Value", [], [$name], $type, $k]);
						
						# push table entry on format array
						push(@format, $entry);
						
					}
					
				}
				
			}
			
		}
		
	}

	# sort format array by table index
	@format = sort {$a->[5] <=> $b->[5]} @format;
	
	# for each format entry
	for my $fmt (@format) {
		
		# add format fields to data array and replace keys with column indices
		$fmt->[3] = add_fmt($self, map {"$fmt->[4]|$_"} @{$fmt->[3]});
		
		# if entry has ColorSpecification
		if (defined($fmt->[6])) {
			
			# add ColorSpecification attribute to colorimetry array
			for (@{$fmt->[3]}) {$self->[2][5][$_] = $fmt->[6]}
			
		}
		
	}

	# return
	return($ops_hash);

}

# read CxF3 ColorSpecification nodes
# parameters: (object_reference, CxF3_root, CxF3_prefix)
sub _readCxF3colorspec {

	# get parameters
	my ($self, $root, $ns) = @_;

	# local variables
	my (@keys, @cspec, $id, $node, $child, $value);

	# make CxF3 => ASCII mapping table (from ISO 17972-1, Annex A)
	@keys = (
		["$ns:MeasurementSpec/$ns:GeometryChoice" => 'MEASUREMENT_GEOMETRY'],
		["$ns:MeasurementSpec/$ns:Device/$ns:DeviceFilter" => 'FILTER'],
		["$ns:MeasurementSpec/$ns:Device/$ns:DeviceIllumination" => 'MEASUREMENT_SOURCE'],
		["$ns:MeasurementSpec/$ns:CalibrationStandard" => 'DEVCALSTD'],
	);

	# find the ColorSpecification nodes
	@cspec = $root->findnodes("$ns:Resources/$ns:ColorSpecificationCollection/$ns:ColorSpecification");

	# for each ColorSpecification node
	for my $s (@cspec) {
		
		# get the Id attribute and skip if 'Unknown'
		next if (($id = $s->getAttribute('Id')) eq 'Unknown');
		
		# for each entry in mapping table
		for my $i (0 .. $#keys) {
			
			# if XPath is found
			if (($node) = $s->findnodes($keys[$i][0])) {
				
				# get the first non-blank child node
				if (($child) = $node->nonBlankChildNodes()) {
					
					# if child is an element node
					if ($child->nodeType() == 1) {
						
						# serialize node
						$value = $node->toString(1);
						
						# remove tabs and endlines
						$value =~ s/[\t\n]+//g;
						
						# remove namespace prefix
						$value =~ s/([<\/])$ns:/$1/g;
						
					# if child is a text node
					} elsif ($child->nodeType() == 3) {
						
						# get the value
						$value = $node->textContent();
						
					}
					
					# save in header line array
					push(@{$self->[3]}, [$keys[$i][1], "\"$value\"", $id]);
					
				}
				
			}
			
		}
		
	}
	
}

# make CxF3 FileInformation nodes
# optional hash parameter contains 'cc:FileInformation' filter array
# parameters: (object_reference, CxF3_root, CxF3_prefix, CxF3_namespace_URI, hash)
# returns: (datetime)
sub _makeCxF3fileinfo {

	# get parameters
	my ($self, $root, $ns, $nsURI, $hash) = @_;

	# local variables
	my (@filter, $t, $datetime, $info, %keys);
	my ($keyword, $value, $source, $node, $child);

	# get filter array (if any)
	@filter = @{ICC::Shared::flatten($hash->{'cc:FileInformation'})} if (defined($hash->{'cc:FileInformation'}));

	# make Time::Piece object
	$t = localtime();

	# get the 'FileInformation' node
	($info) = $root->findnodes("$ns:FileInformation");

	# make ASCII => CxF3 mapping table (from ISO 17972-1, Annex A)
	%keys = ('ORIGINATOR' => "$ns:Creator", 'FILE_DESCRIPTOR' => "$ns:Description", 'CXF3_COMMENT' => "$ns:Comment");

	# for each file header line
	for (@{$self->[3]}) {
		
		# get keyword, value and source
		($keyword, $value, $source) = @{$_};
		
		# strip quotes from value
		$value =~ s/^\"(.*)\"$/$1/;
		
		# if keyword is 'CREATED'
		if ($keyword eq 'CREATED') {
			
			# make Time::Piece object from 'CREATED' value
			$t = _makeTimePiece($value);
			
		# if source is 'FileInformation' or keyword is in filter array
		} elsif ((defined($source) && $source eq 'FileInformation') || grep {$_ eq $keyword} @filter) {
			
			# if keyword in mapping table
			if (exists($keys{$keyword})) {
				
				# if XPath exists in FileInformation element
				if (($node) = $info->findnodes($keys{$keyword})) {
					
					# if text content exists
					if ((($child) = $node->nonBlankChildNodes) && $child->nodeType == 3) {
						
						# update text content
						$child->setData($value);
						
					}
					
				}
				
			# must be a 'Tag' element
			} else {
				
				# if XPath exists in FileInformation element
				if (($node) = $info->findnodes("$ns:Tag[\@Name='$keyword']")) {
					
					# update the Value attribute
					$node->setAttribute('Value', $value);
					
				} else {
					
					# add new Tag element
					$node = $info->appendChild(XML::LibXML::Element->new('Tag'));
					$node->setAttribute('Name', $keyword);
					$node->setAttribute('Value', $value);
					$node->setNamespace($nsURI, $ns);
					
				}
				
			}
			
		}
		
	}

	# make ISO 8601 datetime string from Time::Piece object
	$datetime = $t->strftime('%Y-%m-%dT%T%z');
	substr($datetime, -2, 0, ':');

	# get the 'CreationDate' node
	($node) = $info->findnodes("$ns:CreationDate");

	# if text content exists
	if ((($child) = $node->nonBlankChildNodes) && $child->nodeType == 3) {
		
		# update text content
		$child->setData($datetime);
		
	}

	# return datetime
	return($datetime);

}

# make CxF3 write operations array
# parameters: (object_reference, CxF3_root, CxF3_prefix, column_slice)
# returns: (array_ref)
sub _makeCxF3writeops {

	# get parameters
	my ($self, $root, $ns, $cols) = @_;

	# local variables
	my ($n, %keys, $table, $class, $prefix, $key, $ops, $groups, $sort);

	# if column slice defined
	if (defined($cols)) {
		
		# if column slice an empty array reference
		if (ref($cols) eq 'ARRAY' && @{$cols} == 0) {
			
			# use all columns
			$cols = [0 .. $#{$self->[1][0]}];
			
		} else {
			
			# flatten column slice
			$cols = ICC::Shared::flatten($cols);
			
		}
		
	} else {
		
		# use all columns
		$cols = [0 .. $#{$self->[1][0]}];
		
	}

	# get number of fields
	$n = @{$cols};

	# remove undefined keys
	@{$cols} = grep {defined($self->[1][0][$_])} @{$cols};

	# warn if undefined keys
	($n == @{$cols}) || warn('undefined keys in column slice');

	# get number of fields
	$n = @{$cols};

	# remove duplicate keys
	@{$cols} = grep {! $keys{$self->[1][0][$_]}++} @{$cols};

	# warn if duplicate keys
	($n == @{$cols}) || warn('duplicate keys in column slice');

	# table structure: [data_class, CxF3_main_path, [CxF3_sub_paths], regex, sort_order]
	# some mappings have no sub-paths, which is indicated by an empty sub_path array
	# sort_order array contains the last character(s) of the format keys, and is optional
	# the 'NCLR', 'SPECTRAL' and 'DENSITY' data classes are special cases
	$table = [
		['RGB', "$ns:DeviceColorValues/$ns:ColorRGB", ["$ns:R", "$ns:G", "$ns:B"], qr/^(?:(.*)\|)?RGB_[RGB]$/, [qw(R G B)]],
		['CMYK', "$ns:DeviceColorValues/$ns:ColorCMYK", ["$ns:Cyan", "$ns:Magenta", "$ns:Yellow", "$ns:Black"], qr/^(?:(.*)\|)?CMYK_[CMYK]$/, [qw(C M Y K)]],
		['NCLR', "$ns:DeviceColorValues/$ns:ColorCMYKPlusN", ["$ns:Cyan", "$ns:Magenta", "$ns:Yellow", "$ns:Black"], qr/^(?:(.*)\|)?[2-9A-F]CLR_[1-9A-F]$/],
		['SPECTRAL', "$ns:ColorValues/$ns:ReflectanceSpectrum", [], qr/^(?:(.*)\|)?(?:nm|SPECTRAL_NM_|SPECTRAL_NM|SPECTRAL_|NM_|R_)\d{3}$/],
		['DENSITY', "$ns:ColorValues/$ns:ColorDensity/$ns:Density", [], qr/^(?:(.*)\|)?D_(?:RED|GREEN|BLUE|VIS)$/, [qw(RED GREEN BLUE VIS)]],
		['XYZ', "$ns:ColorValues/$ns:ColorCIEXYZ", ["$ns:X", "$ns:Y", "$ns:Z"], qr/^(?:(.*)\|)?XYZ_[XYZ]$/, [qw(X Y Z)]],
		['XYY', "$ns:ColorValues/$ns:ColorCIExyY", ["$ns:x", "$ns:y", "$ns:Y"], qr/^(?:(.*)\|)?XYY_(?:X|Y|CAPY)$/, [qw(_X _Y _CAPY)]],
		['LAB', "$ns:ColorValues/$ns:ColorCIELab", ["$ns:L", "$ns:A", "$ns:B"], qr/^(?:(.*)\|)?LAB_[LAB]$/, [qw(L A B)]],
		['LCH', "$ns:ColorValues/$ns:ColorCIELCh", ["$ns:L", "$ns:C", "$ns:H"], qr/^(?:(.*)\|)?LAB_[LCH]$/, [qw(L C H)]],
		['DE', "$ns:ColorDifferenceValues/$ns:DeltaCIELab/$ns:dE", [], qr/^(?:(.*)\|)?LAB_DE$/],
		['DE94', "$ns:ColorDifferenceValues/$ns:DeltaCIELab/$ns:dE94", [], qr/^(?:(.*)\|)?LAB_DE94$/],
		['DECMC', "$ns:ColorDifferenceValues/$ns:DeltaCIELab/$ns:dEcmc", [], qr/^(?:(.*)\|)?LAB_CMC$/],
		['DE2000', "$ns:ColorDifferenceValues/$ns:DeltaCIELab/$ns:dE2000", [], qr/^(?:(.*)\|)?LAB_2000$/],
	];

	# following section builds operations array from column slice
	#
	# sort keys alphabetically
	@{$cols} = sort {$self->[1][0][$a] cmp $self->[1][0][$b]} @{$cols};

	# for each field
	for my $i (@{$cols}) {
		
		# if key matches current class and prefix (prefix could be undefined)
		if (defined($class) && $self->[1][0][$i] =~ /$table->[$class][3]/ && (defined($prefix) ? $prefix : "\n") eq (defined($1) ? $1 : "\n")) {
			
			# add index to current operation
			push(@{$ops->[-1][4]}, $i);
			
		} else {
			
			# for each data class
			for my $j (0 .. $#{$table}) {
				
				# if key matches class
				if ($self->[1][0][$i] =~ /$table->[$j][3]/) {
					
					# save current prefix
					$prefix = $1;
					
					# save current class
					$class = $j;
					
					# add new operation
					push(@{$ops}, [$table->[$j][0], $prefix, $table->[$j][1], $table->[$j][2], [$i], {}, $j]);
					
					# quit loop
					last;
					
				# if no match found in table
				} elsif ($j == $#{$table}) {
					
					# match prefix/key
					$self->[1][0][$i] =~ m/^(?:(.*)\|)?(.*)/;
					
					# save matched values
					$prefix = $1;
					$key = $2;
					
					# set current class
					$class = undef;
					
					# if prefix defined, and not Target or ...Measurement, and key is SAMPLE_NAME
					if (defined($prefix) && $prefix !~ m/^Target$|Measurement$/ && $key =~ m/^SAMPLE_NAME$|^SampleName$/) {
						
						# add special operation to set 'Object' 'Name' attribute to SAMPLE_NAME
						push(@{$ops}, ['TAG', $prefix, '', [], [], {'Name' => [$i]}, -1]);
						
					} else {
						
						# add Tag operation
						push(@{$ops}, ['TAG', $prefix, "$ns:TagCollection/$ns:Tag", [], [], {'Name' => $key, 'Value' => [$i]}, 100]);
						
					}
					
				}
				
			}
			
		}
		
	}

	# following section sorts and verifies column slices, sets default prefixes and checks for multiple elements
	#
	# init loop variable
	%keys = ();
	
	# for each array entry
	for my $t (@{$ops}) {
		
		# if sort order is defined
		if (defined($table->[$t->[6]][4])) {
			
			# arrange column indices in sort order
			@{$t->[4]} = map {my $end = $_; grep {$self->[1][0][$_] =~ m/$end$/} @{$t->[4]}} @{$table->[$t->[6]][4]};
			
		}
		
		# if class is SPECTRAL
		if ($t->[0] eq 'SPECTRAL') {
			
			# verify spectral slice
			(@{$t->[4]} == @{_spectral($self, $t->[1])}) || warn("invalid column slice - SPECTRAL class");
			
		# if class is DENSITY
		} elsif ($t->[0] eq 'DENSITY') {
			
			# to be done
			
		# if class is NCLR
		} elsif ($t->[0] eq 'NCLR') {
			
			# match first key to get number of channels
			$self->[1][0][$t->[4][0]] =~ m/([2-9A-F])CLR_[1-9A-F]$/;
			
			# verify nCLR slice
			(@{$t->[4]} == CORE::hex($1)) || warn("invalid column slice - NCLR class");
			
		# all others
		} else {
			
			# verify subpaths match column slice
			(@{$t->[4]} == @{$t->[3]} || (@{$t->[4]} == 1 && @{$t->[3]} == 0)) || warn("invalid column slice - $t->[0] class");
			
		}
		
		# if prefix undefined
		if (! defined($t->[1])) {
			
			# if XPath contains 'ColorValues' or 'ColorDifferenceValues'
			if ($t->[2] =~ m/^$ns:(?:ColorValues|ColorDifferenceValues)\//) {
				
				# set prefix to M0_Measurement
				$t->[1] = 'M0_Measurement';
				
			# if XPath contains 'DeviceColorValues'
			} elsif ($t->[2] =~ m/^$ns:DeviceColorValues\//) {
				
				# set prefix to Target
				$t->[1] = 'Target';
				
			# all others
			} else {
				
				# set prefix to '~~'
				$t->[1] = '~~';
				
			}
			
		}
		
		# for 'ColorValues' or 'DeviceColorValues'
		if ($t->[2] =~ m/^$ns:(ColorValues|DeviceColorValues)\//) {
			
			# warn on multiple elements (not allowed by i1Profiler)
			print "warning: multiple $1 elements in CxF3 $t->[1] object\n" if ($keys{"$1/$t->[1]"}++ == 1);
			
		}
		
	}

	# following section groups operations by prefix
	#
	# sort by prefix, then by table index
	@{$ops} = sort {($a->[1] cmp $b->[1]) or ($a->[6] <=> $b->[6])} @{$ops};

	# init loop variable
	$prefix = undef;

	# for each operation
	for my $t (@{$ops}) {
		
		# if same prefix as last operation
		if (defined($prefix) && $prefix eq $t->[1]) {
			
			# add operation to last group
			push(@{$groups->[-1]}, $t);
			
		# if class is TAG and prefix is '~~'
		} elsif ($t->[0] eq 'TAG' && $t->[1] eq '~~') {
			
			# for each group
			for my $g (@{$groups}) {
				
				# add operation
				push(@{$g}, $t);
				
			}
			
			# set prefix
			$prefix = undef;
			
		# others
		} else {
			
			# add new group
			push(@{$groups}, [$t]);
			
			# set prefix
			$prefix = $t->[1];
			
		}
		
	}

	# return
	return($groups);

}

# make CxF3 ColorSpecification nodes
# parameters: (object_reference, CxF3_root, CxF3_prefix, CxF3_namespace_URI, operations_array)
sub _makeCxF3colorspec {

	# get parameters
	my ($self, $root, $ns, $nsURI, $ops) = @_;

	# local variables
	my (@illum, @filter, $cscol, $template, $unknown);
	my (%table, %cspec, %hash, $keyword, $value, $source);
	my ($Id, $cs, @nodes, $node, $child, @wav);
	my ($parser, $frag, $std, $xpath);

	# illumination types
	@illum = qw(M0_Incandescent M1_Daylight M2_UVExcluded M3_Polarized);

	# filter types
	@filter = qw(Filter_None Filter_None Filter_UVExcluded Filter_None);

	# get the 'ColorSpecificationCollection' node
	($cscol) = $root->findnodes("$ns:Resources/$ns:ColorSpecificationCollection");

	# get the 'ColorSpecification' node with Id = 'template'
	($template) = $cscol->findnodes("$ns:ColorSpecification[\@Id='template']");

	# get the 'ColorSpecification' node with Id = 'Unknown'
	($unknown) = $cscol->findnodes("$ns:ColorSpecification[\@Id='Unknown']");

	# make ASCII => CxF3 mapping table (from ISO 17972-1, Annex A)
	%table = (
		'MANUFACTURER' => "$ns:MeasurementSpec/$ns:Device/$ns:Manufacturer",
		'MODEL' => "$ns:MeasurementSpec/$ns:Device/$ns:Model",
		'SERIAL_NUMBER' => "$ns:MeasurementSpec/$ns:Device/$ns:SerialNumber",
		'MEASUREMENT_GEOMETRY' => "$ns:MeasurementSpec/$ns:GeometryChoice",
		'MEASUREMENT_SOURCE' => "$ns:MeasurementSpec/$ns:Device/$ns:DeviceIllumination",
		'FILTER' => "$ns:MeasurementSpec/$ns:Device/$ns:DeviceFilter",
		'POLARIZATION' => "$ns:MeasurementSpec/$ns:Device/$ns:DevicePolarization",
		'SAMPLE_BACKING' => "$ns:MeasurementSpec/$ns:Backing",
		'DEVCALSTD' => "$ns:MeasurementSpec/$ns:CalibrationStandard",
	);

	# for each group
	for my $group (@{$ops}) {
		
		# for each operation
		for my $t (@{$group}) {
			
			# if ColorValues (only ColorValues reference a ColorSpecification)
			if ($t->[2] =~ m/^$ns:ColorValues\//) {
				
				# set Id to saved value, if defined, or add '_spec' to prefix
				# the ColorSpecification Id is saved in the Colorimetry array when reading a CxF3 file
				$Id = defined($self->[2][5][$t->[4][0]]) ? $self->[2][5][$t->[4][0]] : "$t->[1]\_spec";
				
				# set attribute hash
				$t->[5]{'ColorSpecification'} = $Id;
				
				# if 'ColorSpecification' undefined
				if (! $cspec{$Id}++) {
					
					# initialize keyword hash
					%hash = ();
					
					# add cloned 'ColorSpecification' element to 'ColorSpecificationCollection'
					$cs = $cscol->appendChild($template->cloneNode(1));
					
					# set the Id
					$cs->setAttribute('Id', $Id);
					
					# if spectral data
					# there are three types of spectral data, reflective, transmissive and emissive
					# spectral data has a WavelengthRange node which contains the starting wavelength and increment
					if ($t->[2] =~ m/(Reflectance|Transmittance|Emissive)Spectrum$/) {
						
						# get the 'MeasurementType' node
						($node) = $cs->findnodes("$ns:MeasurementSpec/$ns:MeasurementType");
						
						# if text content exists
						if ((($child) = $node->nonBlankChildNodes) && $child->nodeType == 3) {
							
							# update text content
							$child->setData("Spectrum_$1");
							
						}
						
						# for first two data columns
						for ($t->[4][0], $t->[4][1]) {
							
							# match wavelength in format key
							$self->[1][0][$_] =~ m/(\d{3})$/;
							
							# push to array
							push(@wav, $1);
							
						}
						
						# find the 'WavelengthRange' node
						($node) = $cs->findnodes("$ns:MeasurementSpec/$ns:WavelengthRange");
						
						# set the 'StartWL' attribute
						$node->setAttribute('StartWL', $wav[0]);
						
						# set the 'Increment' attribute
						$node->setAttribute('Increment', $wav[1] - $wav[0]);
						
						# set operation 'StartWL' attribute
						$t->[5]{'StartWL'} = $wav[0];
						
					} else {
						
						# find the 'WavelengthRange' node
						($node) = $cs->findnodes("$ns:MeasurementSpec/$ns:WavelengthRange");
						
						# unbind the node (used only with spectral data)
						$node->unbindNode();
						
					}
					
					# for each file header entry
					for (@{$self->[3]}) {
						
						# get keyword, value and source
						($keyword, $value, $source) = @{$_};
						
						# strip quotes from value
						$value =~ s/^\"(.*)\"$/$1/;
						
						# if source is ColorSpecification Id
						if (defined($source) && $source eq $Id) {
							
							# add keyword to hash
							$hash{$keyword}++;
							
							# if keyword in table
							if (exists($table{$keyword})) {
								
								# if XPath does not exist in ColorSpecification element
								if (! (($node) = $cs->findnodes($table{$keyword}))) {
									
									# set node
									$node = $cs;
									
									# initialize XPath
									$xpath = undef;
									
									# for each segment
									for (split(/\//, $table{$keyword})) {
										
										# add segment to XPath
										$xpath = defined($xpath) ? "$xpath/$_" : $_;
										
										# if XPath does not exist in ColorSpecification element
										if (! (($node) = $cs->findnodes($xpath))) {
											
											# add element for XPath segment
											$node = $node->appendChild(XML::LibXML::Element->new($_));
											$node->setNamespace($nsURI, $ns);
											
										}
										
									}
									
								}
								
								# get the first non-blank child node
								($child) = $node->nonBlankChildNodes();
								
								# make a parser object
								$parser = XML::LibXML->new();
								
								# if value is an XML balanced chunk
								if ($value =~ m/</ && eval{$frag = $parser->parse_balanced_chunk($value)}) {
									
									# get all element nodes
									@nodes = $frag->findnodes('//*');
									
									# replace existing node
									$node->replaceNode($frag);
									
									# set namespace of each element
									for (@nodes) {$_->setNamespace($nsURI, $ns)};
									
								# if no child node
								} elsif (! defined($child)) {
									
									# set text content to value
									$node->appendText($value);
									
								# if child node is text type
								} elsif ($child->nodeType == 3) {
									
									# modify existing text content
									$child->setData($value);
									
								}
								
							}
							
						}
						
					}
					
					# match illumination standard in prefix (M0, M1, M2, M3)
					$std = ($t->[1] =~ m/^M([0-3])/) ? $1 : 0;
					
					# if 'MEASUREMENT_SOURCE' not a keyword
					if (! exists($hash{'MEASUREMENT_SOURCE'})) {
						
						# find the 'DeviceIllumination' node
						($node) = $cs->findnodes("$ns:MeasurementSpec/$ns:Device/$ns:DeviceIllumination");
						
						# if text content exists
						if ((($child) = $node->nonBlankChildNodes) && $child->nodeType == 3) {
							
							# update text content
							$child->setData($illum[$std]);
							
						}
						
					}
					
					# if 'FILTER' not a keyword
					if (! exists($hash{'FILTER'})) {
						
						# find the 'DeviceFilter' node
						($node) = $cs->findnodes("$ns:MeasurementSpec/$ns:Device/$ns:DeviceFilter");
						
						# if text content exists
						if ((($child) = $node->nonBlankChildNodes) && $child->nodeType == 3) {
							
							# update text content
							$child->setData($filter[$std]);
							
						}
						
					}
					
					# if 'POLARIZATION' not a keyword and M3 standard
					if (! exists($hash{'POLARIZATION'}) && $std == 3) {
						
						# get the 'Device' node
						($node) = $cs->findnodes("$ns:MeasurementSpec/$ns:Device");
						
						# add 'Polarization' node
						$node = $node->appendChild(XML::LibXML::Element->new("$ns:Polarization"));
						$node->appendText(XML::LibXML::Boolean->True);
						$node->setNamespace($nsURI, $ns);
						
					}
					
				}
				
			# if 'DeviceColorValues'
			} elsif ($t->[2] =~ m/^$ns:DeviceColorValues\//) {
				
				# set attributes hash
				$t->[5]{'ColorSpecification'} = 'Unknown';
				
				# increment 'ColorSpecification' hash
				$cspec{'Unknown'}++;
				
			}
			
		}
		
	}

	# unbind 'template' node
	$template->unbindNode();

	# unbind 'Unknown' node, if not referenced
	$unknown->unbindNode() if (! $cspec{'Unknown'});

}

# validate CxF3 document
# prints warning and error info
# parameters: (document_reference)
sub _validateCxF3 {

	# get document reference
	my $doc = shift();

	# load CxF3 schema
	state $xmlschema = XML::LibXML::Schema->new('location' => ICC::Shared::getICCPath('Templates/CxF3_Core.xsd'));

	# validate the document
	if (! defined(eval {$xmlschema->validate($doc)})) {
		
		# print warning on failure
		print "warning: invalid CxF3 document\n$@\n";
		
	}
	
}

# make patch set
# supported hash keys: 'colorspace', 'template', 'sort', 'limit'
# parameters: (object_reference, hash)
# returns: (result)
sub _makePatchSet {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($cs, $template, $sort, $tac, $n, $data, $eps);
	my (@fields, $loop, $limit, @inc, $init, $s, $code);

	# get the colorspace parameter
	(defined($cs = $hash->{'colorspace'})) || return('colorspace parameter missing');

	# get the template parameter
	(defined($template = $hash->{'template'})) || return('template parameter missing');

	# get the sort parameter (optional)
	$sort = $hash->{'sort'};

	# get the ink limit parameter (optional)
	$tac = $hash->{'limit'};

	# get number of elements in first group
	$n = @{$template->[0]};

	# for each group
	for my $i (0 .. $#{$template}) {
		
		# verify number of elements
		($n == @{$template->[$i]}) || return("wrong number of elements in template group $i");
		
		# verify number of array references
		($n == grep {ref() eq 'ARRAY'} @{$template->[$i]}) || return("non-array element(s) in template group $i");
		
		# for each element
		for my $j (0 .. $#{$template->[$i]}) {
			
			# verify element contains only numeric scalars
			(@{$template->[$i][$j]} > 0 && @{$template->[$i][$j]} == grep {! ref() && Scalar::Util::looks_like_number($_)} @{$template->[$i][$j]}) || return("non-numeric element in template group $i, $j");
			
		}
		
	}

	# if RGB colorspace
	if ($cs eq 'RGB') {
		
		# verify number of channels
		($n == 3) || return('wrong number of template elements for RGB colorspace');
		
		# set fields
		@fields = qw(RGB_R RGB_G RGB_B);
		
	# if CMYK colorspace
	} elsif ($cs eq 'CMYK') {
		
		# verify number of channels
		($n == 4) || return('wrong number of template elements for CMYK colorspace');
		
		# set fields
		@fields = qw(CMYK_C CMYK_M CMYK_Y CMYK_K);
		
	# if nCLR colorspace
	} elsif ($cs eq 'nCLR') {
		
		# verify number of channels
		($n > 0 && $n < 16) || return('wrong number of template elements for nCLR colorspace');
		
		# set fields
		@fields = map {$n . "CLR_$_"} (1 .. $n);
		
	# if L*a*b* colorspace
	} elsif ($cs eq 'Lab') {
		
		# verify number of channels
		($n == 3) || return('wrong number of template elements for L*a*b* colorspace');
		
		# set fields
		@fields = qw(LAB_L LAB_A LAB_B);
		
	} else {
		
		# error
		return('invalid colorspace parameter');
		
	}

	# make loop variable list
	$loop = join(', ', map {"\$i$_"} (0 .. $n - 1));

	# make initial code fragment
	$init = "\$data->[\$s++] = [$loop]";

	# initialize index
	$s = 0;

	# for each group
	for my $i (0 .. $#{$template}) {
		
		# copy initial code fragment
		$code = $init;
		
		# for each device channel (in reverse order)
		for my $j (reverse(0 .. $#{$template->[$i]})) {
			
			# add loop code to fragment
			$code = "for my \$i$j (" . join(', ', @{$template->[$i][$j]}) . ") {$code}";
			
		}
		
		# evaluate code fragment
		eval($code);
		
	}

	# if ink limit defined and color space is CMYK or nCLR
	if (defined($tac) && ($cs eq 'CMYK' || $cs eq 'nCLR')) {
		
		# compute max comparison error
		$eps = 1E-12;
		
		# verify ink limit is a number
		if (! ref($tac) && Scalar::Util::looks_like_number($tac)) {
			
			# for each patch
			for (@{$data}) {
				
				# add the total ink value
				push(@{$_}, List::Util::sum(@{$_}));
				
			}
			
			# make sort code fragment (sorts in ascending order by columns K ... total_ink_value)
			$code = '@{$data} = sort {' . join(' || ', map {"\$a->[$_] <=> \$b->[$_]"} (3 .. $n)) . '} @{$data}';
			
			# sort data
			eval($code);
			
			# for each patch
			for my $i (0 .. $#{$data}) {
				
				# undefine limit if new group (different black or spot values)
				undef($limit) if (grep {$data->[$i][$_] != $data->[$i ? $i - 1 : 0][$_]} (3 .. $n - 1));
				
				# select patch if limit undefined or total ink <= limit or a CMY corner point
				push(@inc, [@{$data->[$i]}[0 .. $n - 1]]) if (! defined($limit) || ($data->[$i][-1] - $limit <= $eps) || ((grep {$data->[$i][$_] == 0} (0 .. 2)) && (grep {$data->[$i][$_] == 100} (0 .. 2))));
				
				# set limit if undefined and total ink > TAC
				$limit = $data->[$i][-1] if (! defined($limit) && $data->[$i][-1] - $tac > $eps);
				
			}
			
			# set data to selected patches
			$data = \@inc;
			
		} else {
			
			# display warning
			carp("invalid ink limit parameter, ink limiting failed\n");
			
		}
		
	}

	# if sort parameter defined
	if (defined($sort)) {
		
		# verify sort parameter is an array of integer scalars
		if (ref($sort) eq 'ARRAY' && @{$sort} == grep {! ref() && Scalar::Util::looks_like_number($_) && $_ == int($_) && abs($_) > 0 && abs($_) <= $n} @{$sort}) {
			
			# make sort code fragment
			$code = '@{$data} = sort {' . join(' || ', map {my $dir = m/-/; my $col = abs($_) - 1; $dir ? "\$b->[$col] <=> \$a->[$col]" : "\$a->[$col] <=> \$b->[$col]"} @{$sort}) . '} @{$data}';
			
			# evaluate code fragment
			eval($code);
			
		} else {
			
			# display warning
			carp("invalid sort parameter, sorting failed\n");
			
		}
		
	}

	# add format fields
	unshift(@{$data}, [@fields]);

	# set object reference
	$self->[1] = $data;

	# return
	return();

}

# make Time::Piece object from text string
# parses most common date/time notations
# no object returned if parsing fails
# parameter: (string -or- value)
# returns: (object)
sub _makeTimePiece {

	# get parameter
	my $str = shift();

	# local variables
	my ($parse, $fmt, $hr, $sec, $month);

	# if a numeric value (Unix time)
	if (Scalar::Util::looks_like_number($str)) {
		
		# return Time::Piece object from Unix time
		return(scalar(localtime($str)));
		
	} else {
		
		# if UTC offset matched (time string ends in '+/-hh:mm', '+/-hhmm', or '+/-hh')
		if ($str =~ s/(T[\d:]+)([+-]\d{2}):?(\d{2})?/$1/) {
			
			# set UTC offset to matched value
			$parse = $2 . (defined($3) ? $3 : '00');
			
			# set UTC format
			$fmt = '%z';
			
		# if Zulu time (time string ends in 'Z')
		} elsif ($str =~ s/(T[\d:]+)Z/$1/) {
			
			# set UTC offset to 0
			$parse = '+0000';
			
			# set UTC format
			$fmt = '%z';
			
		} else {
			
			# initialize strings
			$parse = $fmt = '';
			
		}
		
		# if time matched (time string 'hh:mm' or 'hh:mm:ss', 'AM' or 'PM' optional)
		if ($str =~ s/(\d{1,2})(:\d{1,2})(:\d{1,2})?\s*(AM|PM)?//) {
			
			# if 12 AM
			if (defined($4) && $4 eq 'AM' && $1 == 12) {
				
				# set hour
				$hr = 0;
				
			# if 1 PM - 11 PM
			} elsif (defined($4) && $4 eq 'PM' && $1 > 0 && $1 < 12) {
				
				# set hour
				$hr = $1 + 12;
				
			} else {
				
				# set hour
				$hr = $1;
				
			}
			
			# set seconds
			$sec = defined($3) ? $3 : ':00';
			
			# add time string
			$parse = "T$hr$2$sec$parse";
			
			# add time format
			$fmt = "T%T$fmt";
			
		}
		
		# if three number date matched
		if ($str =~ m/(\d{1,4})[\/-](\d{1,2})[\/-](\d{1,4})/) {
			
			# if first value > 99
			if ($1 > 99) {
				
				# add date string
				$parse = "$1-$2-$3$parse";
				
			# if last value > 99
			} elsif ($3 > 99) {
				
				# add date string
				$parse = "$3-$1-$2$parse";
				
			# last value is two digit year
			} else {
				
				# add date string
				$parse = ($3 > 68 ? 1900 + $3 : 2000 + $3) . "-$1-$2$parse";
				
			}
			
			# add date format
			$fmt = "%Y-%m-%d$fmt";
			
		# if text month matched
		} elsif (uc($str) =~ m/(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)/) {
			
			# save month
			$month = $1;
			
			# if two numbers matched
			if ($str =~ m/(\d{1,4})[^\d]+(\d{1,4})/) {
				
				# if first value > 99
				if ($1 > 99) {
					
					# add date string
					$parse = "$1-$month-$2$parse";
					
				# if last value > 99
				} elsif ($2 > 99) {
					
					# add date string
					$parse = "$2-$month-$1$parse";
					
				# last value is two digit year
				} else {
					
					# add date string
					$parse = ($2 > 68 ? 1900 + $2 : 2000 + $2) . "/$month/$1$parse";
					
				}
				
			# if one number matched
			} elsif ($str =~ m/(\d{1,4})/) {
				
				# if value > 99
				if ($1 > 99) {
					
					# add date string
					$parse = "$1-$month-1$parse";
					
				} else {
					
					# add date string
					$parse = ($1 > 68 ? 1900 + $1 : 2000 + $1) . "/$month/1$parse";
					
				}
				
			}
			
			# add date format
			$fmt = "%Y-%b-%d$fmt";
			
		}
		
		# return Time::Piece object, if string parsed successfully
		return(Time::Piece->strptime($parse, $fmt)) if (length($parse));
		
	}
	
}

# get file list
# uses Perl 'bsd_glob' function
# parameter: (path)
# returns: (ref_to_file_list)
sub _files {

	# get path
	my $path = shift();

	# get list of files and/or directories
	my @files = grep {-e} File::Glob::bsd_glob($path);

	# if list is just one directory
	if (@files == 1 && -d $files[0]) {
		
		# get files in that directory
		@files = grep {-f} File::Glob::bsd_glob("$path/*");
		
	} else {
		
		# filter the files
		@files = grep {-f} @files;
		
	}

	# return file list
	return(\@files);

}

# compute Mahalanobis distance
# assumes parameters are valid
# parameters: (vector1, vector2, inverse_covariance_matrix)
# returns: (distance)
sub _mahal {

	# get parameters
	my ($x, $y, $sinv) = @_;

	# local variables
	my ($d, $dT);

	# for each dimension
	for my $i (0 .. $#{$x}) {
		
		# save difference
		$d->[0][$i] = $dT->[$i][0] = $x->[$i] - $y->[$i];
		
	}

	# bless matrices
	bless($d, 'Math::Matrix');
	bless($dT, 'Math::Matrix');

	# return Mahalanobis distance
	return(sqrt(($d * $sinv * $dT)->[0][0]));

}

# get L*a*b* encoding code refs
# parameter: (object_reference, hash)
# returns: (get_code_ref, set_code_ref)
sub _lab_encoding {

	# get object reference
	my ($self, $hash) = @_;

	# local variable
	my ($encode);

	# get encoding parameter from hash
	$encode = $hash->{'encoding'};

	# if encoding parameter undefined
	if (! defined($encode)) {
		
		# return code refs (identity)
		return(sub {@_}, sub {@_});
		
	# if encoding is 8/16-bit ICC CIELAB
	} elsif ($encode == 0) {
		
		# return code refs
		return(sub {defined($_[0]) ? $_[0] / 100 : $_[0], defined($_[1]) ? ($_[1] + 128)/255 : $_[1], defined($_[2]) ? ($_[2] + 128)/255 : $_[2]},
		       sub {defined($_[0]) ? $_[0] * 100 : $_[0], defined($_[1]) ? $_[1] * 255 - 128 : $_[1], defined($_[2]) ? $_[2] * 255 - 128 : $_[2]});
		
	# if encoding is 16-bit ICC legacy L*a*b*
	} elsif ($encode == 1) {
		
		# return code refs
		return(sub {defined($_[0]) ? $_[0] * 256/25700 : $_[0], defined($_[1]) ? ($_[1] + 128) * 256/65535 : $_[1], defined($_[2]) ? ($_[2] + 128) * 256/65535 : $_[2]},
		       sub {defined($_[0]) ? $_[0] * 25700/256 : $_[0], defined($_[1]) ? $_[1] * 65535/256 - 128 : $_[1], defined($_[2]) ? $_[2] * 65535/256 - 128 : $_[2]});
		
	# if encoding is 16-bit EFI/Monaco L*a*b*
	} elsif ($encode == 2) {
		
		# return code refs
		return(sub {defined($_[0]) ? $_[0]/100 : $_[0], defined($_[1]) ? ($_[1] + 128) * 256/65535 : $_[1], defined($_[2]) ? ($_[2] + 128) * 256/65535 : $_[2]},
		       sub {defined($_[0]) ? $_[0] * 100 : $_[0], defined($_[1]) ? $_[1] * 65535/256 - 128 : $_[1], defined($_[2]) ? $_[2] * 65535/256 - 128 : $_[2]});
		
	# if encoding is L*a*b*
	} elsif ($encode == 3) {
		
		# return code refs (identity)
		return(sub {@_}, sub {@_});
		
	# if encoding is LxLyLz
	} elsif ($encode == 4) {
		
		# return code refs
		return(sub {if (defined($_[0]) && defined($_[1]) && defined($_[2])) {$_[0] + 116 * $_[1]/500, $_[0], $_[0] - 116 * $_[2]/200} else {@_}},
			   sub {if (defined($_[0]) && defined($_[1]) && defined($_[2])) {$_[1], 500 * ($_[0] - $_[1])/116, 200 * ($_[1] - $_[2])/116} else {@_}});
		
	# if encoding is unit LxLyLz
	} elsif ($encode == 5) {
		
		# return code refs
		return(sub {if (defined($_[0]) && defined($_[1]) && defined($_[2])) {map {$_/100} ($_[0] + 116 * $_[1]/500, $_[0], $_[0] - 116 * $_[2]/200)} else {@_}},
		       sub {if (defined($_[0]) && defined($_[1]) && defined($_[2])) {map {$_ * 100} ($_[1], 500 * ($_[0] - $_[1])/116, 200 * ($_[1] - $_[2])/116)} else {@_}});
		
	} else {
		
		# error
		croak('invalid L*a*b* encoding');
		
	}

}

# get XYZ encoding code refs
# assumes there are XYZ columns
# parameter: (object_reference, column_slice, [hash])
# returns: (get_code_ref, set_code_ref)
sub _xyz_encoding {

	# get object reference
	my ($self, $cols, $hash) = @_;

	# local variable
	my ($encode, $wtpt);

	# get encoding parameter from hash
	$encode = $hash->{'encoding'};

	# if encoding parameter undefined
	if (! defined($encode)) {
		
		# return code refs (identity)
		return(sub {@_}, sub {@_});
		
	# if encoding is L*
	} elsif ($encode eq 'L*' || $encode == 4) {
		
		# get illuminant white point
		($wtpt = _illumWP($self, $cols, $hash)) || croak('illuminant white point required for LxLyLz encoding');
		
		# return code refs
		return(sub {defined($_[0]) ? ICC::Shared::x2L($_[0] / $wtpt->[0]) : $_[0], defined($_[1]) ? ICC::Shared::x2L($_[1] / $wtpt->[1]) : $_[1], defined($_[2]) ? ICC::Shared::x2L($_[2] / $wtpt->[2]) : $_[2]},
		       sub {defined($_[0]) ? ICC::Shared::L2x($_[0]) * $wtpt->[0] : $_[0], defined($_[1]) ? ICC::Shared::L2x($_[1]) * $wtpt->[1] : $_[1], defined($_[2]) ? ICC::Shared::L2x($_[2]) * $wtpt->[2] : $_[2]});
		
	# if encoding is 16-bit ICC XYZ
	} elsif ($encode == 7) {
		
		# return code refs
		return(sub {map {defined() ? $_ / 199.9969482421875 : $_} @_}, sub {map {defined() ? $_ * 199.9969482421875 : $_} @_});
		
	# if encoding is 32-bit ICC XYZNumber
	} elsif ($encode == 8) {
		
		# return code refs
		return(sub {map {defined() ? $_ / 100 : $_} @_}, sub {map {defined() ? $_ * 100 : $_} @_});
		
	# if encoding is xyz
	} elsif ($encode == 9) {
		
		# get illuminant white point
		($wtpt = _illumWP($self, $cols, $hash)) || croak('illuminant white point required for xyz encoding');
		
		# return code refs
		return(sub {defined($_[0]) ? $_[0] / $wtpt->[0] : $_[0], defined($_[1]) ? $_[1] / $wtpt->[1] : $_[1], defined($_[2]) ? $_[2] / $wtpt->[2] : $_[2]},
		       sub {defined($_[0]) ? $_[0] * $wtpt->[0] : $_[0], defined($_[1]) ? $_[1] * $wtpt->[1] : $_[1], defined($_[2]) ? $_[2] * $wtpt->[2] : $_[2]});
		
	# if encoding is XYZ
	} elsif ($encode == 10) {
		
		# return code refs (identity)
		return(sub {@_}, sub {@_});
		
	# if encoding is media relative xyz
	} elsif ($encode == 11) {
		
		# get media white point
		($wtpt = _mediaWP($self, $cols, $hash)) || croak('media white point required for media relative xyz encoding');
		
		# return code refs
		return(sub {defined($_[0]) ? $_[0] / $wtpt->[0] : $_[0], defined($_[1]) ? $_[1] / $wtpt->[1] : $_[1], defined($_[2]) ? $_[2] / $wtpt->[2] : $_[2]},
		       sub {defined($_[0]) ? $_[0] * $wtpt->[0] : $_[0], defined($_[1]) ? $_[1] * $wtpt->[1] : $_[1], defined($_[2]) ? $_[2] * $wtpt->[2] : $_[2]});
		
	} else {
		
		# error
		croak('invalid XYZ encoding');
		
	}

}

# get density encoding code refs
# parameter: (object_reference, hash)
# returns: (get_code_ref, set_code_ref)
sub _density_encoding {

	# get object reference
	my ($self, $hash) = @_;

	# get encoding parameter from hash
	my $encode = $hash->{'encoding'};

	# if encoding parameter undefined or density
	if (! defined($encode) || $encode eq 'density') {
		
		# return code refs (identity)
		return(sub {@_}, sub {@_});
		
	# if encoding is linear (RGBV)
	} elsif ($encode eq 'linear') {
		
		# return code refs
		return(sub {map {defined() ? 100 * POSIX::pow(10, -$_) : $_} @_}, sub {map {if (defined()) {if ($_ > 0) {-POSIX::log10($_/100)} else {warn("log of $_"); 99}} else {$_}} @_});
		
	# if encoding is unit
	} elsif ($encode eq 'unit') {
		
		# return code refs
		return(sub {map {defined() ? POSIX::pow(10, -$_) : $_} @_}, sub {map {if (defined()) {if ($_ > 0) {-POSIX::log10($_)} else {warn("log of $_"); 99}} else {$_}} @_});
		
	# if encoding is L*
	} elsif ($encode eq 'L*') {
	
		# return code refs
		return(sub {map {defined() ? ICC::Shared::x2L(POSIX::pow(10, -$_)) : $_} @_}, sub {map {if (defined()) {if ($_ > 0) {-POSIX::log10(ICC::Shared::L2x($_))} else {warn("log of $_"); 99}} else {$_}} @_});
	
	} else {
		
		# error
		croak('invalid density encoding');
		
	}

}

# get rgbv encoding code refs
# parameter: (object_reference, hash)
# returns: (get_code_ref, set_code_ref)
sub _rgbv_encoding {

	# get object reference
	my ($self, $hash) = @_;

	# get encoding parameter from hash
	my $encode = $hash->{'encoding'};

	# if encoding parameter undefined or linear
	if (! defined($encode) || $encode eq 'linear'|| $encode eq 'RGBV') {
		
		# return code refs (identity)
		return(sub {@_}, sub {@_});
		
	# if encoding is unit
	} elsif ($encode eq 'unit') {
		
		# return code refs
		return(sub {map {$_/100} @_}, sub {map {$_ * 100} @_});
		
	# if encoding is density
	} elsif ($encode eq 'density') {
		
		# return code refs
		return(sub {map {if (defined()) {if ($_ > 0) {-POSIX::log10($_/100)} else {warn("log of $_"); 99}} else {$_}} @_}, sub {map {defined() ? 100 * POSIX::pow(10, -$_) : $_} @_});
		
	# if encoding is L*
	} elsif ($encode eq 'L*') {
	
		# return code refs
		return(sub {map {ICC::Shared::x2L($_/100)} @_}, sub {map {ICC::Shared::L2x($_) * 100} @_});
		
	} else {
		
		# error
		croak('invalid rgbv encoding');
		
	}

}

#--------- additional Math::Matrix methods ---------

package Math::Matrix;

# rotate matrix
# rotation: 0 = None, 1 = 90° CW, 2 = 180°, 3 = 90° CCW
# note: rotation describes appearance in MeasureTool
# parameter: (rotation)
# returns: (rotated_matrix)
sub rotate {

	# get parameters
	my ($self, $rot) = @_;

	# local variables
	my ($rows, $cols, $replace);

	# return if rotation undefined
	return($self) if (! defined($rot));

	# resolve rotation parameter
	$rot = int($rot) % 4;

	# get upper row index
	$rows = $#{$self};

	# get upper column index
	$cols = $#{$self->[0]};

	# if rotation = 0 (none)
	if ($rot == 0) {
	
		# for each row
		for my $i (0 .. $rows) {
		
			# for each column
			for my $j (0 .. $cols) {
			
				# copy matrix element
				$replace->[$i][$j] = $self->[$i][$j];
			
			}
		
		}
	
	# if rotation = 1 (90° CW)
	} elsif ($rot == 1) {
	
		# for each row
		for my $i (0 .. $rows) {
		
			# for each column
			for my $j (0 .. $cols) {
			
				# copy matrix element
				$replace->[$j][$i] = $self->[$i][$cols - $j];
			
			}
		
		}
	
	# if rotation = 2 (180°)
	} elsif ($rot == 2) {
	
		# for each row
		for my $i (0 .. $rows) {
		
			# for each column
			for my $j (0 .. $cols) {
			
				# copy matrix element
				$replace->[$i][$j] = $self->[$rows - $i][$cols - $j];
			
			}
		
		}
	
	# if rotation = 3 (90° CCW)
	} elsif ($rot == 3) {
	
		# for each row
		for my $i (0 .. $rows) {
		
			# for each column
			for my $j (0 .. $cols) {
			
				# copy matrix element
				$replace->[$j][$i] = $self->[$rows - $i][$j];
			
			}
		
		}
	
	}

	# return new object
	return(bless($replace, 'Math::Matrix'));

}

# flip matrix
# flip: 0 = transpose, 1 = horizontal, 2 = cross transpose, 3 = vertical
# note: flip describes appearance in MeasureTool
# parameter: (flip)
# returns: (flipped_matrix)
sub flip {

	# get parameters
	my ($self, $flip) = @_;

	# local variables
	my ($rows, $cols, $replace);

	# return if flip undefined
	return($self) if (! defined($flip));

	# resolve flip parameter
	$flip = int($flip) % 4;

	# get upper row index
	$rows = $#{$self};

	# get upper column index
	$cols = $#{$self->[0]};

	# if flip = 0 (transpose)
	if ($flip == 0) {
	
		# for each row
		for my $i (0 .. $rows) {
		
			# for each column
			for my $j (0 .. $cols) {
			
				# copy matrix element
				$replace->[$j][$i] = $self->[$i][$j];
			
			}
		
		}
	
	# if flip = 1 (horizontal)
	} elsif ($flip == 1) {
	
		# for each row
		for my $i (0 .. $rows) {
		
			# for each column
			for my $j (0 .. $cols) {
			
				# copy matrix element
				$replace->[$i][$j] = $self->[$rows - $i][$j];
			
			}
		
		}
	
	# if flip = 2 (cross transpose)
	} elsif ($flip == 2) {
	
		# for each row
		for my $i (0 .. $rows) {
		
			# for each column
			for my $j (0 .. $cols) {
			
				# copy matrix element
				$replace->[$j][$i] = $self->[$rows - $i][$cols - $j];
			
			}
		
		}
	
	# if flip = 3 (vertical)
	} elsif ($flip == 3) {
	
		# for each row
		for my $i (0 .. $rows) {
		
			# for each column
			for my $j (0 .. $cols) {
			
				# copy matrix element
				$replace->[$i][$j] = $self->[$i][$cols - $j];
			
			}
		
		}
	
	}

	# return new object
	return(bless($replace, 'Math::Matrix'));

}

# randomize matrix
# returns: (randomized_matrix)
sub randomize {

	# get object reference
	my $self = shift();

	# local variables
	my (@ix, $rows, $cols, $replace);

	# flatten and randomize matrix
	@ix = List::Util::shuffle(@{ICC::Shared::flatten($self)});

	# get upper row index
	$rows = $#{$self};

	# get upper column index
	$cols = $#{$self->[0]};

	# for each row
	for my $i (0 .. $rows) {
		
		# for each column
		for my $j (0 .. $cols) {
			
			# set element
			$replace->[$i][$j] = $ix[$i * ($cols + 1) + $j];
			
		}
		
	}

	# return new object
	return(bless($replace, 'Math::Matrix'));

}

1;

