package t::lib::Boot;

use strict;
use Carp;
use vars qw(@ISA $VERSION);

$VERSION = 0.11;

# revised 2015-03-21
#
# Copyright © 2004-2018 by William B. Birkett
#
# reads an ICC profile's profile header and tag table

# create bootstrap profile object
# parameters: (path_to_profile)
# returns: (ref_to_profile_object)
sub new {

	# get object class
	my $class = shift();
	
	# create empty profile object
	my $self = [
				{},		# object header
				[],		# profile header
				[]		# tag table
			];
			
	# if one parameter, a file path
	if (@_ == 1 && ! ref($_[0]) && -f $_[0]) {
		
		# read data from ICC profile
		_readICCprofile($self, @_) || croak("couldn't read profile: $_[0]\n");
		
	}

	# bless object
	bless($self, $class);
	
	# return object reference
	return($self);
	
}

# get reference to profile header
# returns: (ref_to_profile_header_array)
sub profile_header {

	# get tag reference
	my $self = shift();

	# return reference to header
	return($self->[1]);

}

# get reference to profile tag table
# returns: (ref_to_profile_tag_table_array)
sub tag_table {

	# get tag reference
	my $self = shift();

	# return reference to header
	return($self->[2]);

}

# get file handle
# returns: (file_handle)
sub fh {

	# get tag reference
	my $self = shift();

	# return file handle
	return($self->[3]);

}

# read data from ICC profile
# parameters: (ref_to_object, path_to_profile)
# returns: (success_flag)
sub _readICCprofile {
	
	# get parameters
	my ($self, $path) = @_;

	# local variables
	my ($fh, $buf);
	
	# open the profile file
	open($fh, $path) || return(0);
	
	# save file handle
	$self->[3] = $fh;
	
	# set binary mode
	binmode($fh);
	
	# seek to profile file signature
	seek($fh, 36, 0);
	
	# read profile file signature
	read($fh, $buf, 4);
	
	# return if not an ICC profile
	($buf eq 'acsp') || return(0);
	
	# read the header
	_readICCheader($fh, $self->[1]) || return(0);
	
	# read the tag table
	_readICCtagtable($fh, $self->[2]) || return(0);
	
	# return
	return(1);
	
}

# read ICC header
# parameters: (file_handle, ref_to_header_array)
# returns: (success_flag)
sub _readICCheader {

	# get parameters
	my ($fh, $header) = @_;
	
	# local variables
	my ($buf, $check);
	
	# seek to start of header
	seek($fh, 0, 0);
	
	# read the header (128 bytes)
	(read($fh, $buf, 128) == 128) || return(0);
	
	# unpack the header
	@{$header} = unpack('N a4 H8 a4 a4 a4 n6 a4 a4 N a4 a4 N2 N N3 a4 H32 x28', $buf);
	
	# return success if profile file signature verified
	return($header->[12] eq 'acsp' ? 1 : 0);

}

# read ICC tag table
# parameters: (file_handle, ref_to_tag_table_array)
# returns: (success_flag)
sub _readICCtagtable {

	# get parameters
	my ($fh, $tagtab) = @_;
	
	# local variables
	my ($buf, $i, $n);
	
	# seek to start of tag table
	seek($fh, 128, 0);
	
	# read tag count (4 bytes)
	(read($fh, $buf, 4) == 4) || return(0);
	
	# unpack tag count
	$n = unpack('N', $buf);
	
	# read tag entries
	for $i (0 .. $n - 1) {
	
		# read tag entry (12 bytes)
		(read($fh, $buf, 12) == 12) || return(0) ;
		
		# unpack tag entry
		@{$tagtab->[$i]} = unpack('a4 N N', $buf);
		
	}
	
	# return
	return(1);

}

1;
