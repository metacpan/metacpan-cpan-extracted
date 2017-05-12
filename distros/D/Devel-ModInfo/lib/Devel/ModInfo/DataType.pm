# This code is a part of ModInfo, and is released under the Perl Artistic 
#  License.
# Copyright 2002 by James Tillman and Todd Cushard. See README and COPYING
# for more information, or see 
#  http://www.perl.com/pub/a/language/misc/Artistic.html.
# $Id: DataType.pm,v 1.3 2002/08/17 23:24:17 jtillman Exp $

# MODINFO module Devel::ModInfo::DataType
package Devel::ModInfo::DataType;

use strict;
use warnings;

# MODINFO parent_class Exporter
our @ISA = ('Exporter');
our @EXPORT_OK = qw( String2DataType );

# MODINFO version 2.04
our $VERSION = '2.04';

# MODINFO function SCALAR
# MODINFO retval STRING
sub SCALAR		{'SCALAR'}

# MODINFO function ARRAY
# MODINFO retval STRING
sub ARRAY 		{'ARRAY'}

# MODINFO function ARRAYREF
# MODINFO retval STRING
sub ARRAYREF 	{'ARRAYREF'}

# MODINFO function BLESSED
# MODINFO retval STRING
sub BLESSED		{'BLESSED'}

# MODINFO function BOOLEAN
# MODINFO retval STRING
sub BOOLEAN		{'BOOLEAN'}

# MODINFO function CODEREF
# MODINFO retval STRING
sub CODEREF		{'CODEREF'}

# MODINFO function HASH
# MODINFO retval STRING
sub HASH		{'HASH'}

# MODINFO function HASHREF
# MODINFO retval STRING
sub HASHREF		{'HASHREF'}

# MODINFO function INTEGER
# MODINFO retval STRING
sub INTEGER		{'INTEGER'}

# MODINFO function REFERENCE
# MODINFO retval STRING
sub REFERENCE	{'REFERENCE'}

# MODINFO function STRING
# MODINFO retval STRING
sub STRING		{'STRING'}

# MODINFO function ANY
# MODINFO retval ANY
sub ANY		{'ANY'}


my $data_types = {
	'SCALAR' 	=> SCALAR,
	'ARRAY'		=> ARRAY,
	'ARRAYREF'	=> ARRAYREF,
	'BLESSED'	=> BLESSED,
	'BOOLEAN'	=> BOOLEAN,
	'CODEREF'	=> CODEREF,
	'HASH'		=> HASH,
	'HASHREF'	=> HASHREF,
	'INTEGER'	=> INTEGER,
	'REFERENCE' => REFERENCE,
	'STRING'	=> STRING,
	'ANY'		=> ANY,
};

# MODINFO function String2DataType Converts a string to one of the ModInfo data type constants
# MODINFO param  in_string
# MODINFO retval STRING
sub String2DataType {$data_types->{$_[0]} or undef;}

__END__


=head1 Devel::ModInfo::DataType

Devel::ModInfo::DataType - Non object-oriented module defining the data types ModInfo will describe

=head1 SYNOPSIS

This module is not meant for use outside the ModInfo system.
  
=head1 DESCRIPTION

The data type definitions that ModInfo uses are simply strings that attempt to describe Perl 
data types.  Since Perl doesn't have strongly typed variables or subroutine return values, it is 
difficult to really nail down what these data types should be.  We've settled on a collection 
that allows you to adequately describe how Perl data based on how much you can predict about 
the data.  For example, you might know that your function returns a reference to something, 
but not what that something would be.  Or you might know that your method returns a blessed object, 
but not what package the object will be blessed into.

=over 4

=item * SCALAR

While any single-valued Perl variable could be considered a scalar, what SCALAR 
represents is the fact that the only thing you can predict about the value this 
data type represents is that it will be a single value, rather than an array or 
hash.

=item * ARRAY

Self-explanatory

=item * ARRAYREF

Self-explanatory

=item * BLESSED

The BLESSED datatype means that all you can predict about the value is that it will 
be "blessed" into a Perl package (see perltoot for more info on this).

=item * BOOLEAN

Obviously, Perl doesn't explicitly support a BOOLEAN data type, but through common Perl 
code, you will find uses of perl variables in a boolean context.  This data type means 
that the value is expected to be treated as a boolean.

=item *	CODEREF

Self-explanatory

=item * HASH

Self-explanatory

=item * HASHREF

Self-explantory

=item * INTEGER

INTEGER means the Perl variable can be expected to contain an integer value.

=item * REFERENCE

Again, this data type means that all you can predict about the value is that it will be 
a Perl reference.  If you know the 

=item * STRING

=item * A package name

This indicates that you know the value will contain a blessed reference to a 
pre-defined package name.

=back


=head1 AUTHOR

jtillman@bigfoot.com
tcushard@bigfoot.com

=head1 SEE ALSO

Devel::ModInfo::Tutorial

pl2modinfo.pl

modinfo2xml.pl

modinfo2html.pl

perl(1).

=cut
