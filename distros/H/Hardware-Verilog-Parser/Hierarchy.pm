
##################################################################
# Copyright (C) 2000 Greg London   All Rights Reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
##################################################################

##################################################################
package Hardware::Verilog::Hierarchy;
use Hardware::Verilog::Parser;
@ISA = ( 'Hardware::Verilog::Parser' );
##################################################################
use vars qw ( $VERSION );
$VERSION = '0.03';
##################################################################

##################################################################
sub new
##################################################################
{
 my ($pkg) = @_;

 # make Hardware::Verilog::Hierarchy object, use SUPER:: to find the method via @ISA
 my $r_hash = $pkg->SUPER::new;

# $r_hash -> Replace ( q( 
#name_of_instance  : 
#         module_instance_identifier
#        range(?)
#
#		{ print "INSTANCENAME $item{module_instance_identifier} \n"; }
#
#module_declaration_identifier :
#	identifier
#		{ print "MODULENAME $item{identifier} \n"; }
#
# ));


 # bless it as a vhdl_hierarchy object
 bless $r_hash, $pkg;
 return $r_hash;
} 

