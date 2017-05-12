# This code is a part of ModInfo, and is released under the Perl Artistic 
#  License.
# Copyright 2002 by James Tillman and Todd Cushard. See README and COPYING
# for more information, or see 
#  http://www.perl.com/pub/a/language/misc/Artistic.html.
# $Id: ParamHashRef.pm,v 1.2 2002/08/17 23:24:17 jtillman Exp $

# MODINFO module Devel::ModInfo::ParamHashRef
package Devel::ModInfo::ParamHashRef;

# MODINFO dependency module strict
use strict;
# MODINFO dependency module warnings
use warnings;
# MODINFO dependency module Devel::ModInfo::DataType
use Devel::ModInfo::DataType 'String2DataType';

# MODINFO dependency module Exporter
require Exporter;

# MODINFO parent_class Devel::ModInfo::Parameter
our @ISA    = qw(Exporter Devel::ModInfo::Parameter);
our @EXPORT = qw();

# MODINFO version 2.04
our $VERSION = '2.04';


# Preloaded methods go here.
# MODINFO constructor new
# MODINFO paramhash attribs  Attributes for the new object
# MODINFO paramkey
# MODINFO key keys  ARRAYREF Array of keys for this paramhash
sub new{
	my ($class, %attribs) = @_;
	#Call superclass
	my $self  = $class->SUPER::new(%attribs);

	$self->{keys} = $attribs{keys};
	$self->{data_type} = String2DataType('HASHREF');

	#Set up local properties	
	return bless $self => $class;
}

# MODINFO function keys
# MODINFO retval ARRAYREF
sub keys{$_[0]->{keys}}

1;

__END__



=head1 Devel::ModInfo::ParamHashRef

Devel::ModInfo::ParamHashRef - Defines a hash reference of parameters expected by a function, 
method, or constructor

=head1 SYNOPSIS

Not meant to be used outside the ModInfo system.
  
=head1 DESCRIPTION

Devel::ModInfo::ParamHashRef defines a hash reference which contains a collection of key/value pairs that should be passed into 
a method, function, or constructor.  The key/value pairs are defined by instances of the 
Devel::ModInfo::ParamHash::Key class.

The ParamHashRef describes a common Perl construct in which a Perl hash reference is used to provide 
parameters to a function.  It often looks like the following:

sub mysub {
	my ($self, $params) = @_;
        unlink($params->{file_name});
	#Do other stuff
}

The hash reference named $params will have all the key/value pairs passed into the function.  This 
method emulates what is called "named parameters" in some other languages.  In these 
constructs, the order of the parameters does not matter, as the name of each parameter, 
rather than its position, determines how the value is applied.

=head1 AUTHOR

jtillman@bigfoot.com

tcushard@bigfoot.com

=head1 SEE ALSO

Devel::ModInfo::Tutorial

Devel::ModInfo::ParamHash::Key

perl(1)
