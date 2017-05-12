# This code is a part of ModInfo, and is released under the Perl Artistic 
#  License.
# Copyright 2002 by James Tillman and Todd Cushard. See README and COPYING
# for more information, or see 
#  http://www.perl.com/pub/a/language/misc/Artistic.html.
# $Id: Dependency.pm,v 1.3 2002/08/17 23:24:17 jtillman Exp $

# MODINFO module Devel::ModInfo::Dependency
package Devel::ModInfo::Dependency;

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
# MODINFO key type   Type of dependency (currently either PERL (version) or MODULE)
# MODINFO key target Indicates the dependency, such as DBI or IO::Handle
sub new{
	my ($class, %attribs) = @_;
	my $self = {
		type => $attribs{type},
		target => $attribs{target},
	};
	return bless $self => $class;
}

# MODINFO function type
# MODINFO retval STRING
sub type{$_[0]->{type}}

# MODINFO function target
# MODINFO retval STRING
sub target{$_[0]->{target}}

1;

__END__

=head1 Devel::ModInfo::Dependency

Devel::ModInfo::Dependency - Defines a module's dependency on a particular version of Perl or a
 certain module

=head1 SYNOPSIS

Not meant to be used outside the ModInfo system.
  
=head1 DESCRIPTION

Devel::ModInfo::Dependency has two types of dependencies at present: PERL and MODULE.  PERL 
dependencies mean that a module requires a certain version of Perl, as declared in Perl 
code using something like the following:

require 5.005;

The MODULE dependency means that the module in question requires another module be 
available, as in defined in Perl using something like this:

use XML::DOM;

These statements appearing in your code are a good indicator that a ModInfo::Dependency 
could be defined.

=head1 AUTHOR

jtillman@bigfoot.com
tcushard@bigfoot.com

=head1 SEE ALSO

Devel::ModInfo::Tutorial

perl(1).

=cut
