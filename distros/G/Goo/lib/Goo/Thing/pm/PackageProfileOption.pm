#!/usr/bin/perl

package Goo::Thing::pm::PackageProfileOption;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author: 		Nigel Hamilton
# Filename:		Goo::Thing::pm::PackageProfileOption.pm
# Description: 	Store individual options in the profile
#
# Date	 		Change
# ----------------------------------------------------------------------------
# 11/08/2005    Added method: test                                            
#
##############################################################################

use strict;

use Goo::Loader;
use Goo::ProfileOption;

use base qw(Goo::ProfileOption);


##############################################################################
#
# new - construct a package_profile_option
#
##############################################################################

sub new {

	my ($class, $params) = @_;

	my $this = $class->SUPER::new($params);
	
	$this->{package} = $params->{text};

	return $this;
}


##############################################################################
#
# do - carry out the action!
#
##############################################################################

sub do {

	my ($this) = @_;

	# jump to this package
	my $new_thing = Goo::Loader::load($this->{package} . ".pm");	

	$new_thing->do_action("P");

}

1;



__END__

=head1 NAME

Goo::Thing::pm::PackageProfileOption - Store individual options in the profile

=head1 SYNOPSIS

use Goo::Thing::pm::PackageProfileOption;

=head1 DESCRIPTION



=head1 METHODS

=over

=item new

constructor

=item do

Jump to another package.

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

