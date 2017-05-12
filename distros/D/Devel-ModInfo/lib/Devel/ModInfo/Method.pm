# This code is a part of ModInfo, and is released under the Perl Artistic 
#  License.
# Copyright 2002 by James Tillman and Todd Cushard. See README and COPYING
# for more information, or see 
#  http://www.perl.com/pub/a/language/misc/Artistic.html.
# $Id: Method.pm,v 1.3 2002/08/17 23:24:17 jtillman Exp $

# MODINFO module Devel::ModInfo::Method
package Devel::ModInfo::Method;

# MODINFO dependency module strict
use strict;
# MODINFO dependency module warnings
use warnings;

# MODINFO dependency module Devel::ModInfo::Function
require Devel::ModInfo::Function;
# MODINFO dependency module Exporter
require Exporter;

# MODINFO parent_class Devel::ModInfo::Function
our @ISA    = qw(Exporter Devel::ModInfo::Function);
our @EXPORT = qw();

# MODINFO version 2.04
our $VERSION = '2.04';


# Preloaded methods go here.
# MODINFO constructor new
sub new{
	my ($class, %attribs) = @_;
	
	#Call superclass
	my $self  = $class->SUPER::new(%attribs);

	return bless $self => $class;
}

1;

__END__



=head1 Devel::ModInfo::Method

Devel::ModInfo::Method - Defines an object-oriented function that can be accessed in 
a Perl module

=head1 SYNOPSIS

Not meant to be used outside the ModInfo system.
  
=head1 DESCRIPTION

Devel::ModInfo::Method provides the name, description, and parameters for a method in 
a Perl module.  It is not meant to model non-object-oriented functions, 
which are instead handled by ModInfo::Function.

=head1 AUTHOR

jtillman@bigfoot.com
tcushard@bigfoot.com

=head1 SEE ALSO

Devel::ModInfo::Tutorial

Devel::ModInfo::Function

Devel::ModInfo::Parameter

Devel::ModInfo::ParamHash

Devel::ModInfo::ParamArray

perl(1).

=cut
