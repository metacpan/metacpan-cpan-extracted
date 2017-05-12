package Geo::Coordinates::Transform;
# 
# Troxel 
# Thu Apr  1 10:31:35 2010
#
# Geo::Coordinates::Transform - Transform to/from various lat/long formats in a list oriented way. 
#

use strict;
use warnings;
use diagnostics;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Data::Dumper; 

use vars qw($AUTOLOAD);

$VERSION     = '0.10';
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = (); 
 				 
sub new
{
  my $caller = shift;

  # In case someone wants to sub-class
  my $caller_is_obj  = ref($caller);
  my $class = $caller_is_obj || $caller;

  # Passing reference or hash
  my %arg_hsh;
  if ( ref($_[0]) eq "HASH" ) { %arg_hsh = %{ shift @_ } }
  else                        { %arg_hsh = @_ }

  # The object data structure
  my $self = bless {
                        'dd_fmt' => $arg_hsh{dd_fmt} || '%3.7f',
                        'dm_fmt' => $arg_hsh{dm_fmt} || '%3.5f',
                        'ds_fmt' => $arg_hsh{ds_fmt} || '%3.5f',
                      }, $class;
 
  return $self; 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -
# Use Autoload to wrap a common loop and validation 
# around input for the three transform functoins. 
# - - - - - - - - - - - - - - - - - - - - - - - - - -
sub AUTOLOAD 
{
 my $self = shift @_; 
 my $lst_ref = shift @_;  

 my ($func_ptr) = $AUTOLOAD =~ /.*::(.*)$/;
 $func_ptr = "_$func_ptr"; 

 # Act on only on resident functions
 unless( grep { $_ eq $func_ptr } qw( _cnv_to_dd _cnv_to_ddm _cnv_to_dms ) ) { return } 

 # Validate input
 if ( ref $lst_ref ne 'ARRAY' ) { die "Array reference is expected as input" }
  
 my @ll_out_lst;  
 foreach my $ll ( @{$lst_ref} ) 
 { 
    if ( $ll =~ /([^-+\s\d\.]+)/ ) 
	{ 
	    push @ll_out_lst, 'NaN';  
		warn "Illegal char in $ll";
   	}
	else
	{ 	 
        no strict 'refs'; 
		push @ll_out_lst, $self->${func_ptr}($ll);
	}		
 }	  
 
 return \@ll_out_lst; 
}

# - - - - - - - -
sub _cnv_to_ddm 
{
   my $self = shift @_;
   my $in = shift @_;
   
   $in = $self->_cnv_to_dd($in);
 
   my $deg = int($in);
   my $dm = abs($in - $deg) * 60;
  
   return sprintf("%d $self->{'dm_fmt'}",$deg, $dm);
}

# - - - - - - - -
sub _cnv_to_dms 
{
   my $self = shift @_;
   my $in = shift @_;
   
   $in = $self->_cnv_to_dd($in);
 
   my $deg = int($in);
   my $dm = abs($in - $deg) * 60;
  
   my $mm = int($dm); 
   my $ss = abs($mm - $dm) * 60;
    
   return sprintf("%d %d $self->{'ds_fmt'}",$deg, $mm, $ss);
}

# - - - - - - - -
sub _cnv_to_dd 
{
   my $self = shift @_;
   my $in = shift @_;
    
   my $sign; 
   if ($in =~ s/([-]+)//) { $sign = $1; } 

   my $dd = $in;
   if ( $in =~ /([\d+-]+)\s+(\d+)\s+([\d\.]+)/ )   # -dd dd dd	
   {
      $dd = $1 + $2/60 + $3/3600;    
   } 
   elsif ( $in =~ /([\d+-]+)\s+(\d+[\d\.]+)/ ) # -dd dd.ddd
   {
      $dd = $1 + $2/60;
   }   
   
   if ($sign ) { $dd = -1 * $dd }
   if ( (caller(1))[3] !~ /_cnv_to/ ) { $dd = sprintf("$self->{'dd_fmt'}",$dd);}
 
   return $dd;    
}


1;

__END__

=head1 NAME

Geo::Coordinates::Transform - Transform Latitude/Longitude between various different coordinate 
functions

=head1 SYNOPSIS

  use Geo::Coordinates::Convert;

  # List of a lat/longs in various formats. 
  my @lst = ( 47.9805, -116.5586, '47 58.8300', '-116 33.5160', '47 58 49', '-116 33 30'); 
 
  my $cnv = new Geo::Coordinates::Convert();

  my $out_ref = []; # Array reference
  
  # Convert List to Decimal-Degrees... DD.DDDD
  $out_ref = $cnv->cnv_to_dd(\@lst); 
  
  # Convert List to Degree Decimal-Degrees... DD MM.MMMM
  $out_ref = $cnv->cnv_to_ddm(\@lst); 

  # Convert List to Degrees Minutes Decimal Seconds DD MM SS.SSSS
  $out_ref = $cnv->cnv_to_dms(\@lst); 


=head1 DESCRIPTION

There are several formats used to present geographic coordinates. For example: 

 * DMS Degrees:Minutes:Seconds (48 30 30, -117 30' 30")
 * DM Degrees:Decimal-Minutes (48 30.5, -117 30.5'), 
 * DD Decimal-Degrees (48.5083333, -17.5083333)

This module converts a list of provided latitude and longitude coordinates in any of the three
formats above (mixed input is ok) and converts to the desired format.  Note that special characters 
or non-numerical characters such as " will throw an warning and return NaN for that list item. 

In addition, the input does not interpert N,S,W,E designators but expects coordinates to be in 
positive or negative representation. 

Format of the output can be controlled via input arguments in the constructor. The arguments are expected 
to be in the form of a hash reference. For example:

	# Change output format
	# Hash aruements are 
	# 'dd_fmt' = Decimal-Degrees format
	# 'dm_fmt' = Decimal-Minutes format
	# 'ds_fmt' = Decimal-Second format
	
	# Example 
	my $cnv = new Geo::Coordinates::Convert( {dd_fmt=>'%3.2f', dm_fmt=>'%3.1f', ds_fmt=>'%d'} );
 
Minimal sanity checks are performed. 75 minutes will be handled as 1 degree and 15 minutes. 
 
=head1 SEE ALSO

The Geographic Coordinate System wiki ia good place for background documentation
http://en.wikipedia.org/wiki/Geographic_coordinate_system

A useful web interface using this module can be found here. 

http://perlworks.com/calculate/latitude-longitude-conversion/

=head1 METHODS

Only three methods provided. Expected input is a reference to a list and output is a reference to list. 

  $out_ref = $cnv->cnv_to_dd(\@lst);   # To Degree Decimal-Degrees... DD.DDDDDDD
  $out_ref = $cnv->cnv_to_ddm(\@lst);  # To Degree Decimal-Minutes... DD MM.MMMM
  $out_ref = $cnv->cnv_to_dms(\@lst);  # To Degrees Minutes Decimal Seconds DD MM SS.SSSS

=head1 AUTHOR

E<lt>troxel at perlworks.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Troxel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
