# This code is a part of ModInfo, and is released under the Perl Artistic 
#  License.
# Copyright 2002 by James Tillman and Todd Cushard. See README and COPYING
# for more information, or see 
#  http://www.perl.com/pub/a/language/misc/Artistic.html.
# $Id: Property.pm,v 1.3 2002/08/17 23:24:17 jtillman Exp $

# MODINFO module Devel::ModInfo::Property
package Devel::ModInfo::Property;

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
# MODINFO read_method   STRING  The name of the method that returns the value of this property
# MODINFO write_method  STRING  The name of the method that will accept a value to update this property
# MODINFO key data_type STRING  The data type of the parameter
sub new{
	my ($class, %attribs) = @_;
	#Call superclass
	my $self  = $class->SUPER::new(%attribs);
	$self->{read_method} = $attribs{read_method};
	$self->{write_method} = $attribs{write_method};
	$self->{data_type} = $attribs{data_type};

	return bless $self => $class;
}

# MODINFO function read_method
# MODINFO retval STRING
sub read_method{$_[0]->{read_method}}

# MODINFO function write_method
# MODINFO retval STRING
sub write_method{$_[0]->{write_method}}

# MODINFO function data_type
# MODINFO retval STRING
sub data_type{$_[0]->{data_type}}

1;

__END__


=head1 Devel::ModInfo::Property

Devel::ModInfo::Property - Defines a particular value in a Perl module that can be 
accessed and possibly updated

=head1 SYNOPSIS

Not meant to be used outside the ModInfo system.
  
=head1 DESCRIPTION

Devel::ModInfo::Property has no real corollary in actual Perl code.  It is a logical 
construct which defines a dicrete value in a Perl module that can be accessed and perhaps 
updated via either direct access to the Perl variable, or via accessor/mutator combinations.

An example would be if you defined a lexically scoped variable in your module that you wanted 
to make available via a "get_value" method and make updatable via a "set_value" method.  You 
might name the property "Value" and define the two methods as the read_method and write_method, 
respectively.

There is no run-time Perl syntax support for any ModInfo constructs, certainly not ones that 
do not even exist in Perl.  Properties and other ModInfo features are mainly for design-time 
inspection of the interfaces defined by Perl modules.

=head1 AUTHOR

jtillman@bigfoot.com

tcushard@bigfoot.com

=head1 SEE ALSO

Devel::ModInfo::Tutorial

perl(1).

=cut
