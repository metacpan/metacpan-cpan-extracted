# This code is a part of ModInfo, and is released under the Perl Artistic 
#  License.
# Copyright 2002 by James Tillman and Todd Cushard. See README and COPYING
# for more information, or see 
#  http://www.perl.com/pub/a/language/misc/Artistic.html.
# $Id: Key.pm,v 1.3 2002/08/17 23:25:23 jtillman Exp $

# MODINFO module Devel::ModInfo::ParamHash::Key
package Devel::ModInfo::ParamHash::Key;

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
# MODINFO function new
sub new{
	my ($class, %attribs) = @_;
	#Call superclass
	my $self  = $class->SUPER::new(%attribs);

	return bless $self => $class;
}

1;

__END__

=head1 Devel::ModInfo::ParamHash::Key

Devel::ModInfo::ParamHash::Key - Defines a single key/value pair that is expected
to be provided to a method, function, or constructor

=head1 SYNOPSIS

Not meant to be used outside the ModInfo system.
  
=head1 DESCRIPTION

Devel::ModInfo::ParamHash::Key is a specialized version of Devel::ModInfo::Parameter 
which is meant to be part of a ParamHash.

=head1 AUTHOR

jtillman@bigfoot.com

tcushard@bigfoot.com

=head1 SEE ALSO

Devel::ModInfo::Tutorial

Devel::ModInfo::ParamHash

perl(1).
