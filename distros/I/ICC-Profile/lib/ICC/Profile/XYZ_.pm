package ICC::Profile::XYZ_;

use strict;
use Carp;

our $VERSION = 0.12;

# revised 2016-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# note that the XYZ tag contains an array of XYZ values, not a single XYZ value
# there is typically just one XYZ value in that array, which is accessed by the 'XYZ' method

# create new XYZ_ tag object
# parameters: ()
# parameters: (ref_to_XYZ_array)
# parameters: (ref_to_array_of_XYZ_arrays)
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty XYZ_ object
	my $self = [
		{},		# object header
		[],		# array of XYZ arrays
	];

	# if single parameter is an array reference
	if (@_ == 1 && ref($_[0]) eq 'ARRAY') {
		
		# set object attributes
		_newICCXYZ_($self, @_);
		
	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# create XYZ_ tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty XYZ_ object
	my $self = [
		{},		# object header
		[],		# array of XYZ arrays
	];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read XYZ_ data from profile
	_readICCXYZ_($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes XYZ_ tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write XYZ_ data to profile
	_writeICCXYZ_($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {

	# get parameters
	my ($self) = @_;

	# return size
	return(8 + @{$self->[1]} * 12);

}

# get reference to array of XYZ arrays
# returns: (ref_to_array_of_XYZ arrays)
sub array {

	# get parameters
	my $self = shift();

	# return reference to array of XYZ arrays
	return($self->[1]);

}

# get/set first XYZ array
# parameters: ([ref_to_XYZ_array])
# returns: (ref_to_XYZ_array)
sub XYZ {

	# get object reference
	my $self = shift();

	# if parameter supplied
	if (@_) {
		
		# verify array reference
		(ref($_[0]) eq 'ARRAY') || croak('parameter must be array reference');
		
		# save array reference
		$self->[1][0] = shift();
		
	}

	# return array reference
	return($self->[1][0]);

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

# make new XYZ_ tag from array
# array may be a single XYZ triplet, or an array of XYZ triplets
# parameters: (ref_to_object, ref_to_array)
sub _newICCXYZ_ {

	# get parameters
	my ($self, $array) = @_;

	# if first array element is an array
	if (ref($array->[0]) eq 'ARRAY') {
		
		# for each array element
		for my $i (0 .. $#{$array}) {
			
			# if first array element is not a reference
			if (! ref($array->[$i][0])) {
				
				# save XYZ triplet
				$self->[1][$i] = [@{$array->[$i]}];
				
			} else {
				
				# error
				croak('invalid parameters for XYZ tag');
				
			}
			
		}
		
	# if first array element is not a reference
	} elsif (! ref($array->[0])) {
		
		# save XYZ triplet
		$self->[1] = [[@{$array}]];
		
	} else {
		
		# error
		croak('invalid parameters for XYZ tag');
		
	}
	
}

# read XYZ_ tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCXYZ_ {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($buf);

	# save tag signature
	$self->[0]{'signature'} = $tag->[0];

	# seek start of tag data
	seek($fh, $tag->[1] + 8, 0);

	# for each XYZ triplet
	for my $i (0 .. ($tag->[2] - 20)/12) {
		
		# read XYZ values
		read($fh, $buf, 12);
		
		# unpack XYZ values
		$self->[1][$i] = [ICC::Shared::s15f162v(unpack('N3', $buf))];
		
	}
	
}

# write XYZ_ tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCXYZ_ {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# verify tag data
	(@{$self->[1]} > 0) || carp('writing \'XYZ_\' tag without values');

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write tag signature
	print $fh pack('a4 x4', 'XYZ ');

	# for each XYZ triplet
	for my $XYZ (@{$self->[1]}) {
		
		# write XYZ values
		print $fh pack('N3', map {$_ + 0.5} ICC::Shared::v2s15f16(@{$XYZ}));
		
	}
	
}

1;