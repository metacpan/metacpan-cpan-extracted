# This code is a part of ModInfo, and is released under the Perl Artistic 
#  License.
# Copyright 2002 by James Tillman and Todd Cushard. See README and COPYING
# for more information, or see 
#  http://www.perl.com/pub/a/language/misc/Artistic.html.
# $Id: Feature.pm,v 1.3 2002/08/17 23:24:17 jtillman Exp $

# MODINFO module Devel::ModInfo::Feature
package Devel::ModInfo::Feature;

# MODINFO dependency module strict
use strict;
# MODINFO dependency module warnings
use warnings;

# MODINFO dependency module Exporter
require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw();

# MODINFO version 2.04
our $VERSION = '2.04';


# Preloaded methods go here.
# MODINFO constructor new
# MODINFO paramkey attribs  Attributes for the new object
# MODINFO key short_description  A short description of the feature
# MODINFO key name				 An internal name for the feature
# MODINFO key display_name		 A more "friendly" name for the feature
# MODINFO key attributes		 A hashref of freeform "attributes" for the feature
sub new{
	my ($class, %attribs) = @_;
	
	my $display_name = $attribs{display_name} || $attribs{name};
	
	my $self = {
		short_description => $attribs{short_description},
		name => $attribs{name},
		display_name => $display_name,
		attributes => $attribs{attributes},
	};
	return bless $self => $class;
}


# MODINFO function short_description  Provides a short description of the feature
# MODINFO retval STRING
sub short_description{$_[0]->{short_description}}

# MODINFO function name  The internal name of the feature
# MODINFO retval STRING
sub name{$_[0]->{name}}

# MODINFO function display_name  A more "friendly" name for the feature
# MODINFO retval STRING
sub display_name{$_[0]->{display_name}}

# MODINFO function attributes  A hash of attributes for the feature
# MODINFO retval HASHREF
sub attributes{$_[0]->{attributes}}

1;

__END__


=head1 Devel::ModInfo::Feature

Devel::ModInfo::Feature - A superclass for defining certain "features" a Perl module might have

=head1 SYNOPSIS

Not meant to be used outside the ModInfo system.
  
=head1 DESCRIPTION

Devel::ModInfo::Feature serves as a base class for several other ModInfo classes.  It defines a 
simple data structure that allows a certain Module "feature" such as a method or 
function, to be named and described.  Other classes flesh out the definition of their 
respective features.

=head1 AUTHOR

jtillman@bigfoot.com
tcushard@bigfoot.com

=head1 SEE ALSO

Devel::ModInfo::Tutorial

perl(1).

=cut
