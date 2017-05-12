package Goo::Thing::pm::Method;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author: 		Nigel Hamilton
# Filename:		Goo::Thing::pm::Method.pm
# Description: 	Object for modelling methods
#
# Date	 		Change
# -----------------------------------------------------------------------------
# 20/02/2005	Auto generated file
# 20/02/2005	Needed one for the Goo's PerlCoder module
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Template;
use Goo::WebDBLite;
use base qw(Goo::Object);		# Method isa Object

my $method_template = "perl-method.tpl";


###############################################################################
#
# new - construct a method object
#
###############################################################################

sub new {

	my ($class, $params) = @_;

	my $this = $class->SUPER::new();

	$this->{method}			= $params->{method}; 
	$this->{description} 	= $params->{description};
	$this->{signature}		= $params->{signature};

	return $this;

}


###############################################################################
#
# get_method - return the name of the method
#
###############################################################################

sub get_method {

	my ($this) = @_;
	
	return $this->{method};

}


###############################################################################
#
# to_string - return a template for a method
#
###############################################################################

sub to_string {

        my ($this) = @_;

	if ($this->{signature}) {
        	$this->{signature} = "my ($this->{signature}) = \@\_;";
	}

        return Goo::Template::replace_tokens_in_string(Goo::WebDBLite::get_template($method_template), 
								      $this);
      
}


1;


__END__

=head1 NAME

Goo::Thing::pm::Method - Object for modelling methods

=head1 SYNOPSIS

use Goo::Thing::pm::Method;

=head1 DESCRIPTION



=head1 METHODS

=over

=item new

construct a method object

=item get_method

return the name of the method

=item to_string

return a filled in template for a method

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

