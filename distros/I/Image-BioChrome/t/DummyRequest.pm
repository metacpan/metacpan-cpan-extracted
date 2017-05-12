#!/usr/bin/perl -w
#
# DummyRequest.pm
#
# Used by the tests to simulate the Apache environment 
#

use strict;

package Apache::Constants;

sub OK {
	return 200;
}

sub DECLINED {
	return 0;
}


# The Dummy Request module is designed to allow testing of the BioChrome apache
# handler interface without needing to configure and fire up an apache instance

package DummyRequest;

sub new {
	my $class = shift;
	my $params = shift;

	my $self = { };
	
	# copy the config params
	foreach (keys %$params) {
		$self->{ config }->{ $_ } = $params->{ $_ };
	}

	return bless $self, $class;
}

# make this a main request
sub is_main {
	return 1;
}


sub filename {
	my $self = shift;
	my $file = shift;

	$self->{ file } = $file if $file;

	return $self->{ file } || '';
}


sub dir_config {
	my $self = shift;
	my $name = shift || return;

	return $self->{ config }->{ $name };
}

sub pnotes {
	my $self = shift;
	my $name = shift || return;

	return $self->{ config }->{ $name };
}


sub uri {
	my $self = shift;

	return $self->{ config }->{ uri };
}

sub location {
	my $self = shift;

	return $self->{ config }->{ location };
}

1;
