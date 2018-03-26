package ICC::Profile::clro;

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

# create new clro tag object
# parameters: ([ref_to_seq_array])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();
	
	# create empty clro object
	my $self = [
				{},		# object header
				[]		# colorant sequence array
			];

	# if parameter supplied
	if (@_) {
		
		# make new clro tag from colorant sequence array
		_newICCclro($self, @_);
		
	}

	# bless object
	bless($self, $class);
	
	# return object reference
	return($self);

}

# create clro tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty clro object
	my $self = [
				{},		# object header
				[]		# colorant sequence array
			];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read clro data from profile
	_readICCclro($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes clro tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write clro data to profile
	_writeICCclro($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {

	# get parameters
	my ($self) = @_;

	# return size
	return(12 + @{$self->[1]});

}

# get/set colorant sequence
# parameters: ([ref_to_seq_array])
# returns: (ref_to_seq_array)
sub sequence {

	# get object reference
	my $self = shift();
	
	# if parameter supplied
	if (@_) {
		
		# get ref to sequence array
		my $seq = shift();
		
		# initialize counter
		my $i = 0;

		# verify sequence array
		(@{$seq} == grep {$_ == $i++} sort {$a <=> $b} @{$seq}) || croak('bad sequence array');

		# save array
		$self->[1] = $seq;
		
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

# make new clro tag from colorant sequence array
# parameters: (ref_to_object, ref_to_seq_array)
sub _newICCclro {

	# get parameters
	my ($self, $seq) = @_;

	# initialize counter
	my $i = 0;

	# verify sequence array
	(@{$seq} == grep {$_ == $i++} sort {$a <=> $b} @{$seq}) || croak('bad sequence array');

	# copy array
	$self->[1] = [@{$seq}];

}

# read clro tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCclro {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($buf, $cnt);

	# save tag signature
	$self->[0]{'signature'} = $tag->[0];

	# seek start of tag
	seek($fh, $tag->[1], 0);
	
	# read tag type signature and colorant count
	read($fh, $buf, 12);

	# unpack colorant count
	$cnt = unpack('x8 N', $buf);

	# read colorant array
	read($fh, $buf, $cnt);

	# unpack colorant array
	$self->[1] = [unpack('C*', $buf)];

}

# write clro tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCclro {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write tag
	print $fh pack('a4 x4 N C*', 'clro', scalar(@{$self->[1]}), @{$self->[1]});

}

1;