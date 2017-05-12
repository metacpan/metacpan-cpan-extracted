# This code is a part of ModInfo, and is released under the Perl Artistic 
#  License.
# Copyright 2002 by James Tillman and Todd Cushard. See README and COPYING
# for more information, or see 
#  http://www.perl.com/pub/a/language/misc/Artistic.html.
# $Id: Constructor.pm,v 1.3 2002/08/17 23:24:17 jtillman Exp $

# MODINFO module Devel::ModInfo::Constructor
package Devel::ModInfo::Constructor;

# MODINFO dependency module strict
use strict;
# MODINFO dependency module warnings
use warnings;

# MODINFO dependency module Exporter
require Exporter;
# MODINFO dependency module Devel::ModInfo::Function
require Devel::ModInfo::Function;
# MODINFO parent_class Devel::ModInfo::Function
our @ISA = qw(Exporter Devel::ModInfo::Function);
our @EXPORT = qw();

# MODINFO version 2.04
our $VERSION = '2.04';

# Preloaded methods go here.
# MODINFO constructor new
sub new{
	my ($class, %attribs) = @_;
	my $self  = $class->SUPER::new(%attribs);
	return bless $self => $class;
}

1;

__END__


=head1 Devel::ModInfo::Constructor

Devel::ModInfo::Constructor - Defines a function in an object-oriented Perl module that 
is expected to create and return an instance of the module class.

=head1 SYNOPSIS

Not meant to be used outside the ModInfo system.
  
=head1 DESCRIPTION

Devel::ModInfo::Constructor is a specialized version of Devel::ModInfo::Function which 
is expected to return an instance of the module class in which it is defined.  The 
presence of a constructor is one of the things that distinguishes an object-oriented 
module from a non-oo module.

=head1 AUTHOR

jtillman@bigfoot.com

tcushard@bigfoot.com

=head1 SEE ALSO

Devel::ModInfo::Tutorial
Devel::ModInfo::Function

perl(1).
