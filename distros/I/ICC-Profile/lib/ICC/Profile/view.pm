package ICC::Profile::view;

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

# create new view tag object
# parameters: ()
# parameters: (ref_to_attribute_hash)
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();
	
	# create empty view object
	my $self = [
				{},		# object header
				[],		# illuminant XYZ array
				[],		# surround XYZ array
				0		# illuminant type
			];

	# if single parameter is a hash reference
	if (@_ == 1 && ref($_[0]) eq 'HASH') {

		# set object attributes
		_newICCview($self, @_);

	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# create view tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty view object
	my $self = [
				{},		# object header
				[],		# illuminant XYZ array
				[],		# surround XYZ array
				0		# illuminant type
			];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read view data from profile
	_readICCview($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes view tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write view data to profile
	_writeICCview($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {
	
	# get parameters
	my ($self) = @_;
	
	# return size
	return(36);
	
}

# get XYZ values
# index: illuminant = 0, surround = 1
# returns: (ref_to_XYZ_array)
sub XYZ {

	# get parameters
	my $self = shift();
	
	# get index
	my $i = shift();
	
	# verify index
	($i == 0 || $i == 1) || croak('invalid view index');

	# return XYZ values
	return($self->[$i + 1]);

}

# get/set illuminant type
# 0 = unknown, 1 = D50, 2 = D65, 3 = D93, 4 = F2, 5 = D55, 6 = A, 7 = Equi_Power, 8 = F8
# parameters: ([type_value])
# returns: (type_value)
sub type {

	# get object reference
	my $self = shift();
	
	# if parameter supplied
	if (@_) {
		
		# get type value
		my $type = shift();
		
		# verify type value
		($type == int($type) && $type >= 0 && $type <= 8) || croak('invalid illuminant type');
		
		# save it
		$self->[3] = $type;
		
	}
	
	# return illuminant type
	return($self->[3]);

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

# make new view tag from attribute hash
# hash may contain pointers to header, illuminant XYZ array, surround XYZ array, illuminant type
# keys are: ('header', 'illuminant', 'surround', 'type')
# tag elements not specified in the hash are left empty
# parameters: (ref_to_object, ref_to_attribute_hash)
sub _newICCview {
	
	# get parameters
	my ($self, $hash) = @_;
	
	# local variables
	my (%list);
	
	# set attribute list (key => [reference_type, array_index])
	%list = ('header' => ['HASH', 0], 'illuminant' => ['ARRAY', 1], 'surround' => ['ARRAY', 2], 'type' => ['', 3]);
	
	# for each attribute
	for my $attr (keys(%list)) {
		
		# if attribute specified
		if (exists($hash->{$attr})) {
			
			# if correct reference type
			if (ref($hash->{$attr}) eq $list{$attr}[0]) {
				
				# set tag element
				$self->[$list{$attr}[1]] = $hash->{$attr};
				
			} else {
				
				# error
				croak('wrong reference type');
				
			}
			
		}
		
	}
	
}

# read view tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCview {
	
	# get parameters
	my ($self, $parent, $fh, $tag) = @_;
	
	# local variables
	my ($buf, $i);
	
	# save tag signature
	$self->[0]{'signature'} = $tag->[0];
	
	# seek start of tag data
	seek($fh, $tag->[1] + 8, 0);
	
	# read illuminant XYZ values
	read($fh, $buf, 12);
	
	# unpack and save values
	$self->[1] = [ICC::Shared::s15f162v(unpack('N3', $buf))];
	
	# read surround XYZ values
	read($fh, $buf, 12);
	
	# unpack and save values
	$self->[2] = [ICC::Shared::s15f162v(unpack('N3', $buf))];
	
	# read illuminant type
	read($fh, $buf, 4);
	
	# unpack and save value
	$self->[3] = unpack('N', $buf);
	
}

# write view tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCview {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($buf, $XYZ);

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write tag
	print $fh pack('a4 x4 N3 N3 N', 'view', ICC::Shared::v2s15f16(@{$self->[1]}), ICC::Shared::v2s15f16(@{$self->[2]}), $self->[3]);

}

1;