###########################################################################
#
#   File_Pool.pm
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

use strict;

########################################################################
package Log::Agent::File_Pool;

#
# A pool of all created file objects, along with their rotation policies
#

my $POOL = undef;		# only one instance

#
# ->make
#
# Creation routine.
#
# Attributes:
#	info         records path ->
#					[Log::Agent::File objects, rotation policies, refcnt]
#
sub make {
	my $self = bless {}, shift;
	$self->{info} = {};
	return $self;
}

#
# Attribute access
#

sub info			{ $_[0]->{'info'} }

#
# file_pool			-- "once" routine
#
# Return the main pool
#
sub file_pool {
	return $POOL || ($POOL = Log::Agent::File_Pool->make());
}

#
# ->put
#
# Put new entry in pool.
#
sub put {
	my $self = shift;
	my ($path, $file, $rotate) = @_;

	my $info = $self->info;
	if (exists $info->{$path}) {
		$info->{$path}->[2]++;		# refcnt
	} else {
		$info->{$path} = [$file, $rotate, 1];
	}
}

#
# ->get
#
# Get record for existing entry, undef if none.
#
sub get {
	my $self = shift;
	my ($path) = @_;
	my $aref = $self->info->{$path};
	return defined $aref ? @$aref : ();
}

#
# ->remove
#
# Remove record.
# Returns true when file is definitively removed (no more reference on it).
#
sub remove {
	my $self = shift;
	my ($path) = @_;
	my $item = $self->info->{$path};
	return 1 unless defined $item;
	return 0 if --$item->[2];

	#
	# Reference count reached 0
	#

	delete $self->info->{$path};
	return 1;
}

1;	# for require
