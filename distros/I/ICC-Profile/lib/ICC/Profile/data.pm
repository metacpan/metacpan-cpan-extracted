package ICC::Profile::data;

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

# create new data tag object
# parameters: ([data_flag, data_string])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();
	
	# create empty data object
	my $self = [
				{},		# object header
				1,		# data flag
				''		# data string
			];

	# if parameter supplied
	if (@_) {
		
		# save data flag
		$self->[1] = (shift() == 0) ? 0 : 1;
		
		# save data string
		$self->[2] = shift();
		
	}

	# bless object
	bless($self, $class);
	
	# return object reference
	return($self);

}

# create data tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty data object
	my $self = [
				{},		# object header
				1,		# data flag
				''		# data string
			];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read data from profile
	_readICCdata($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes data tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write data to profile
	_writeICCdata($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {
	
	# get parameters
	my ($self) = @_;
	
	# return size
	return(12 + length($self->[2]) + ($self->[1] == 0 ? 1 : 0));
	
}

# get/set data string
# parameters: ([data_flag, data_string])
# returns: (data_string)
sub data {

	# get object reference
	my $self = shift();
	
	# if parameters supplied
	if (@_) {
		
		# save data flag
		$self->[1] = shift() == 0 ? 0 : 1;
		
		# save data string
		$self->[2] = shift();
		
	}
	
	# return data string
	return($self->[2]);

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

# read data tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCdata {
	
	# get parameters
	my ($self, $parent, $fh, $tag) = @_;
	
	# local variables
	my ($buf);
	
	# save tag signature
	$self->[0]{'signature'} = $tag->[0];
	
	# seek start of tag
	seek($fh, $tag->[1], 0);
		
	# read type and data flag
	read($fh, $buf, 12);
	
	# unpack data flag
	$self->[1] = unpack('x8 N', $buf);
	
	# read remaining data
	read($fh, $buf, $tag->[2] - 12);
	
	# if ASCII data
	if ($self->[1] == 0) {
		
		# unpack ASCII data (zero terminated)
		$self->[2] = unpack('Z*', $buf);
		
	# if binary data
	} elsif ($self->[1] == 1) {
		
		# unpack binary data
		$self->[2] = unpack('a*', $buf);
	
	} else {
		
		# print message
		carp('unknown data type');
		
	}
	
}

# write data tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCdata {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# if ASCII data
	if ($self->[1] == 0) {
		
		# write tag
		print $fh pack('a4 x4 N Z*', 'data', $self->[1], $self->[2]);
		
	# if binary data
	} elsif ($self->[1] == 1) {
		
		# write tag
		print $fh pack('a4 x4 N a*', 'data', $self->[1], $self->[2]);
		
	} else {
		
		# print message
		carp('unknown data type');
		
	}
	
}

1;