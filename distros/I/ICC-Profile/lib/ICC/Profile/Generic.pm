package ICC::Profile::Generic;

use strict;
use Carp;

our $VERSION = 0.21;

# revised 2016-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# create new generic tag object
# parameters: ()
# parameters: (ref_to_attribute_hash)
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty generic object
	my $self = [
		{},     # object header
		''      # data
	];

	# if single parameter is a scalar
	if (@_ == 1 && ! ref($_[0])) {

		# set object data
		$self->[1] = shift();

	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# create generic tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty generic object
	my $self = [
		{},     # object header
		''      # data
	];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read generic data from profile
	_readICCgeneric($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes generic tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write generic data to profile
	_writeICCgeneric($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {
	
	# get parameters
	my ($self) = @_;
	
	# return size
	return(length($self->[1]));
	
}

# get/set data string
# parameters: ([data])
# returns: (data)
sub data {

	# get object reference
	my $self = shift();

	# if parameter supplied
	if (@_) {
		
		# save it
		$self->[1] = shift();
		
	}

	# return text string
	return($self->[1]);

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

# read generic tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCgeneric {
	
	# get parameters
	my ($self, $parent, $fh, $tag) = @_;
	
	# save tag signature
	$self->[0]{'signature'} = $tag->[0];
	
	# seek start of tag
	seek($fh, $tag->[1], 0);
	
	# read tag
	read($fh, $self->[1], $tag->[2]);
	
}

# write generic tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCgeneric {
	
	# get parameters
	my ($self, $parent, $fh, $tag) = @_;
	
	# seek start of tag
	seek($fh, $tag->[1], 0);
		
	# write tag
	print $fh $self->[1];
	
}

1;