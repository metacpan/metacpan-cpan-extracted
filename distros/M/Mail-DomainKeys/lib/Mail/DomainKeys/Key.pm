# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mail::DomainKeys::Key;

use strict;

our $VERSION = "0.88";

sub cork {
	my $self = shift;

	(@_) and
		$self->{'CORK'} = shift;

	$self->{'CORK'} or
		$self->convert;

	$self->{'CORK'};
}

sub data {
	my $self = shift;

	(@_) and 
		$self->{'DATA'} = shift;

	$self->{'DATA'};
}

sub errorstr {
	my $self = shift;

	(@_) and 
		$self->{'ESTR'} = shift;

	$self->{'ESTR'};
}

sub size {
	my $self = shift;

	return $self->cork->size * 8;
}

sub type {
	my $self = shift;

	(@_) and 
		$self->{'TYPE'} = shift;

	$self->{'TYPE'};
}

1;
