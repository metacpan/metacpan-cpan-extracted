# This code is a part of ModInfo, and is released under the Perl Artistic 
#  License.
# Copyright 2002 by James Tillman and Todd Cushard. See README and COPYING
# for more information, or see 
#  http://www.perl.com/pub/a/language/misc/Artistic.html.
# $Id: Parameter.pm,v 1.3 2002/08/17 23:24:17 jtillman Exp $

# MODINFO module Devel::ModInfo::Parameter
package Devel::ModInfo::Parameter;

# MODINFO dependency module strict
use strict;
# MODINFO dependency module warnings
use warnings;

# MODINFO dependency module Exporter
require Exporter;

# MODINFO parent_class Devel::ModInfo::Feature
our @ISA    = qw(Exporter Devel::ModInfo::Feature);
our @EXPORT = qw();

# MODINFO version 2.04
our $VERSION = '2.04';


# Preloaded methods go here.
# MODINFO constructor new
# MODINFO paramhash attribs  Attributes for the new object
# MODINFO key data_type STRING  The data type of the parameter

sub new{
	my ($class, %attribs) = @_;
	#Call superclass
	my $self  = $class->SUPER::new(%attribs);

	#Set up local properties	
	$self->{data_type} = $attribs{data_type};

	return bless $self => $class;
}

# MODINFO function data_type
# MODINFO retval STRING
sub data_type{$_[0]->{data_type}}

1;

__END__


=head1 Devel::ModInfo::Parameter

Devel::ModInfo::Parameter - Defines a particular parameter expected by a function, 
method, or constructor

=head1 SYNOPSIS

Not meant to be used outside the ModInfo system.
  
=head1 DESCRIPTION

Devel::ModInfo::Parameter has a name, description, and data type.  The data type is 
one of those defined in Devel::ModInfo::DataTypes.

=head1 AUTHOR

jtillman@bigfoot.com

tcushard@bigfoot.com

=head1 SEE ALSO

Devel::ModInfo::Tutorial

Devel::ModInfo::Function

perl(1).
