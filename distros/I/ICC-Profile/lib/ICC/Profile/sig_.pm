package ICC::Profile::sig_;

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

# create new sig_ tag object
# parameters: ([text_string])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();
	
	# create empty sig_ object
	my $self = [
				{},		# object header
				'    '	# text string
			];

	# if parameter supplied
	if (@_) {
		
		# save as 4-byte string
		$self->[1] = pack('a4', shift());
		
	}

	# bless object
	bless($self, $class);
	
	# return object reference
	return($self);

}

# create sig_ tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty sig_ object
	my $self = [
				{},		# object header
				''		# text string
			];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read sig_ data from profile
	_readICCsig_($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes sig_ tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write sig_ data to profile
	_writeICCsig_($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {
	
	# get parameters
	my ($self) = @_;
	
	# return size
	return(12);
	
}

# get/set text string
# parameters: ([text_string])
# returns: (text_string)
sub text {

	# get object reference
	my $self = shift();
	
	# if parameter supplied
	if (@_) {
		
		# save it
		$self->[1] = pack('a4', shift());
		
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

# read sig_ tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCsig_ {
	
	# get parameters
	my ($self, $parent, $fh, $tag) = @_;
	
	# local variables
	my ($buf);
	
	# save tag signature
	$self->[0]{'signature'} = $tag->[0];
	
	# seek start of tag
	seek($fh, $tag->[1], 0);
		
	# read tag
	read($fh, $buf, 12);
	
	# unpack text string
	$self->[1] = unpack('x8 a4', $buf);
	
}

# write sig_ tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCsig_ {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write tag
	print $fh pack('a4 x4 a4', 'sig ', $self->[1]);

}

1;