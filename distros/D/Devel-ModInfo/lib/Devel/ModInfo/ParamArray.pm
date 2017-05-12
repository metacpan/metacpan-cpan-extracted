# This code is a part of ModInfo, and is released under the Perl Artistic 
#  License.
# Copyright 2002 by James Tillman and Todd Cushard. See README and COPYING
# for more information, or see 
#  http://www.perl.com/pub/a/language/misc/Artistic.html.
# $Id: ParamArray.pm,v 1.3 2002/08/17 23:24:17 jtillman Exp $

# MODINFO module Devel::ModInfo::ParamArray
package Devel::ModInfo::ParamArray;

# MODINFO dependency module strict
use strict;
# MODINFO dependency module warnings
use warnings;

# MODINFO dependency module Exporter
require Exporter;

# MODINFO parent_class Devel::ModInfo::Parameter
our @ISA    = qw(Exporter Devel::ModInfo::Parameter);
our @EXPORT = qw();

# MODINFO version 2.04
our $VERSION = '2.04';


# Preloaded methods go here.
# MODINFO constructor new
sub new{
	my ($class, %attribs) = @_;
	#Call superclass
	my $self  = $class->SUPER::new(%attribs);

	#Set up local properties	
	return bless $self => $class;
}

1;

__END__


=head1 Devel::ModInfo::ParamArray

Devel::ModInfo::ParamArray - Defines a particular Perl module and contains collections of 
descriptors for that module

=head1 SYNOPSIS

Not meant to be used outside the ModInfo system.
  
=head1 DESCRIPTION

Devel::ModInfo::ParamArray provides the name and description of an array of parameters 
that can be provided to a Perl function.  A ParamArray is an array of undefined length, 
which means that the author has no idea how many parameters will really be provided to 
the function.  It should be used only when the function itself expects a variable 
number of parameters.  When the function anticipates a specific order of parameters, they 
should be explicitly defined using ParameterScalars instead.

=head1 AUTHOR

jtillman@bigfoot.com
tcushard@bigfoot.com

=head1 SEE ALSO

Devel::ModInfo::Parameter

Devel::ModInfo::Function

perl(1).

=cut
