#############################################################################
## Name:        Encode.pm
## Purpose:     HDB::Encode - Common things for HDB modules.
## Author:      Graciliano M. P.
## Modified by:
## Created:     15/01/2003
## RCS-ID:      
## Copyright:   (c) 2002 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package HDB::Encode ;

use strict qw(vars);
no warnings ;

our $VERSION = '1.0' ;

########
# VARS #
########

  my %VER = (
  PACKED_HASH => '1.0' ,
  PACKED_ARRAY => '1.0' ,
  ) ;
  
########
# PACK #
########

sub Pack {
  if ( ref($_[0]) eq 'HASH' ) { return &Pack_HASH($_[0]) ;}
  if ( ref($_[0]) eq 'ARRAY' ) { return &Pack_ARRAY($_[0]) ;}
}

#############
# PACK_HASH #
#############

sub Pack_HASH {
  my ( $hash ) = @_ ;
  
  if (ref($hash) ne 'HASH') { return( undef ) ;}
  
  my ($pack_init,$pack) ;
  
  $pack_init = "%HDB_PACKED_HASH%[$VER{PACKED_HASH}]{0}:" if !$_[1] ;
  
  foreach my $key ( keys %$hash ) {
    my ($blk,$tp,$value) ;
    if    ( ref( $$hash{$key} ) eq 'HASH' ) { $tp = 1 ; $value = &Pack_HASH( $$hash{$key} , 1 ) }
    elsif ( ref( $$hash{$key} ) eq 'ARRAY' ) { $tp = 2 ; $value = &Pack_ARRAY( $$hash{$key} , 1 ) ;}
    elsif ( UNIVERSAL::isa($$hash{$key} ,'UNIVERSAL') ) { next ;} ## ignore objects.
    else { $tp = 0 ; $value = $$hash{$key} ;}
    
    $blk .= $tp ;
    $blk .= length($key) . ":" ;
    $blk .= $key ;
    $blk .= length($value) . ":" ;
    $blk .= $value ;
    
    $pack .= $blk ;
  }
  
  if ( !$_[1] ) {
    my $sz = length($pack) ;
    $pack_init =~ s/\{0}/\{$sz}/s ;
  }
  
  return( $pack_init . $pack ) ;
}

##############
# PACK_ARRAY #
##############

sub Pack_ARRAY {
  my ( $array ) = @_ ;
  
  if (ref($array) ne 'ARRAY') { return( undef ) ;}
  
  my ($pack_init,$pack) ;
  
  $pack_init = "%HDB_PACKED_ARRAY%[$VER{PACKED_ARRAY}]{0}:" if !$_[1] ;
  
  foreach my $array_i ( @$array ) {
    my ($blk,$tp,$value) ;
    if    ( ref( $array_i ) eq 'HASH' ) { $tp = 1 ; $value = &Pack_HASH( $array_i , 1 ) ;}
    elsif ( ref( $array_i ) eq 'ARRAY' ) { $tp = 2 ; $value = &Pack_ARRAY( $array_i , 1 ) ;}
    elsif ( UNIVERSAL::isa($array_i ,'UNIVERSAL') ) { next ;} ## ignore objects.
    else { $tp = 0 ; $value = $array_i ;}
    
    $blk .= $tp ;
    $blk .= length($value) . ":" ;
    $blk .= $value ;
    
    $pack .= $blk ;
  }
  
  if ( !$_[1] ) {
    my $sz = length($pack) ;
    $pack_init =~ s/\{0}/\{$sz}/s ;
  }
  
  return( $pack_init . $pack ) ;
}

##########
# UNPACK #
##########

sub UnPack {
  if ( &Is_Packed_HASH($_[0]) ) { return &UnPack_HASH($_[0]) ;}
  if ( &Is_Packed_ARRAY($_[0]) ) { return &UnPack_ARRAY($_[0]) ;}
  return( $_[0] ) ;
}

###############
# UNPACK_HASH #
###############

sub UnPack_HASH {
  my %hash ;
  
  my $pos = 0 ;
  
  if ( !$_[1] ) {
    if ( !&Is_Packed_HASH($_[0]) ) { return() ;}
    elsif ( !&Check_Pack_Size($_[0]) ) { return("SIZE_ERROR: $_[0]") ;}
    else { $pos = index($_[0],':') + 1 ;}
  }
  
  my $lng = length($_[0]) ;
  
  while( $pos < $lng ) {
    my $tp = substr($_[0],$pos++,1) ;
    my $key = &blk_read($_[0],$pos) ;
    my $val = &blk_read($_[0],$pos) ;
    
    if ($tp == 1) {
      my %val = &UnPack_HASH($val,1) ;
      $val = \%val ;
    }
    elsif ($tp == 2) {
      my @val = &UnPack_ARRAY($val,1) ;
      $val = \@val ;
    }
    
    $hash{$key} = $val ;
  }

  if ( wantarray ) { return( %hash ) ;}
  else { return( \%hash ) ;}
}

################
# UNPACK_ARRAY #
################

sub UnPack_ARRAY {
  my @array ;
  
  my $pos = 0 ;
  
  if ( !$_[1] ) {
    if ( !&Is_Packed_ARRAY($_[0]) ) { return() ;}
    elsif ( !&Check_Pack_Size($_[0]) ) { return("SIZE_ERROR: $_[0]") ;}
    else { $pos = index($_[0],':') + 1 ;}
  }
  
  my $lng = length($_[0]) ;
  
  while( $pos < $lng ) {
    my $tp = substr($_[0],$pos++,1) ;
    my $val = &blk_read($_[0],$pos) ;
    
    if ($tp == 1) {
      my %val = &UnPack_HASH($val,1) ;
      $val = \%val ;
    }
    elsif ($tp == 2) {
      my @val = &UnPack_ARRAY($val,1) ;
      $val = \@val ;
    }
    
    push(@array , $val) ;
  }
  
  if ( wantarray ) { return( @array ) ;}
  else { return( \@array ) ;}
}

############
# BLK_READ #
############

sub blk_read {
  my ( undef , undef , $lng ) = @_ ;
  
  if (!$lng) { $lng = length( $_[0] ) ;}
  
  my ($s,$sz) ;
  
  while( $_[1] <= $lng ) {
    $s = substr( $_[0]  , $_[1] , 1) ;
    $_[1]++ ;
    if ($s eq ':') { last ;}
    $sz .= $s ;
  }
  
  my $blk = substr( $_[0] , $_[1] , $sz) ;
  
  $_[1] += $sz ;

  return( $blk ) ;
}

##################
# IS_PACKED_HASH #
##################

sub Is_Packed_HASH {
  if ( $_[0] =~ /^\s*\%HDB_PACKED_HASH%\[[\d\.]+]\{\d+}:/ ) { return( 1 ) ;}
  return( undef ) ;
}

###################
# IS_PACKED_ARRAY #
###################

sub Is_Packed_ARRAY {
  if ( $_[0] =~ /^\s*\%HDB_PACKED_ARRAY%\[[\d\.]+]\{\d+}:/ ) { return( 1 ) ;}
  return( undef ) ;
}

###################
# CHECK_PACK_SIZE #
###################

sub Check_Pack_Size {
  if ( $_[0] =~ /^(\s*\%HDB_PACKED_(?:HASH|ARRAY)%\[[\d\.]+]\{)(\d+)(}:)/s ) {
    my $lng = length($1) + length($3) ;
    my $sz = $2 ;
    $lng += length($sz) + $sz ;
    if ( length($_[0]) == $lng ) { return( 1 ) ;}
  }
  return( undef ) ;
}

###############
# PACKED_SIZE #
###############

sub Packed_SIZE {
  my ( $ref ) = @_ ;
  if ( ref($ref) eq 'HASH' ) { return &Packed_SIZE_HASH($ref) ;}
  if ( ref($ref) eq 'ARRAY' ) { return &Packed_SIZE_ARRAY($ref) ;}
}

####################
# PACKED_SIZE_HASH #
####################

sub Packed_SIZE_HASH {
  my ( $hash ) = @_ ;
  
  if (ref($hash) ne 'HASH') { return( undef ) ;}
  
  my ($pack_init,$size) ;
  
  $pack_init = "%HDB_PACKED_HASH%[$VER{PACKED_HASH}]{0}:" if !$_[1] ;
  
  foreach my $key ( keys %$hash ) {
    my ($blk_sz,$value_sz) ;
    if    ( ref( $$hash{$key} ) eq 'HASH' ) { $value_sz = &Packed_SIZE_HASH( $$hash{$key} , 1 ) }
    elsif ( ref( $$hash{$key} ) eq 'ARRAY' ) { $value_sz = &Packed_SIZE_ARRAY( $$hash{$key} , 1 ) ;}
    elsif ( UNIVERSAL::isa($$hash{$key} ,'UNIVERSAL') ) { next ;} ## ignore objects.
    else { $value_sz = length( $$hash{$key} ) ;}
    
    $blk_sz += 1 ;
    $blk_sz += length(length($key)) + 1 ;
    $blk_sz += length($key) ;
    $blk_sz += length($value_sz) + 1 ;
    $blk_sz += $value_sz ;
    
    $size += $blk_sz ;
  }
  
  if ( !$_[1] ) { $pack_init =~ s/\{0}/\{$size}/s ;}
  
  $size += length($pack_init) if !$_[1] ;
  
  return( $size ) ;
}

#####################
# PACKED_SIZE_ARRAY #
#####################

sub Packed_SIZE_ARRAY {
  my ( $array ) = @_ ;
  
  if (ref($array) ne 'ARRAY') { return( undef ) ;}
  
  my ($pack_init,$size) ;
  
  $pack_init = "%HDB_PACKED_ARRAY%[$VER{PACKED_ARRAY}]{0}:" if !$_[1] ;
  
  foreach my $array_i ( @$array ) {
    my ($blk_sz,$value_sz) ;
    if    ( ref( $array_i ) eq 'HASH' ) { $value_sz = &Packed_SIZE_HASH( $array_i , 1 ) ;}
    elsif ( ref( $array_i ) eq 'ARRAY' ) { $value_sz = &Packed_SIZE_ARRAY( $array_i , 1 ) ;}
    elsif ( UNIVERSAL::isa($array_i ,'UNIVERSAL') ) { next ;} ## ignore objects.
    else { $value_sz = length($array_i) ;}
    
    $blk_sz += 1 ;
    $blk_sz += length($value_sz) + 1 ;
    $blk_sz += $value_sz ;
    
    $size += $blk_sz ;
  }
  
  if ( !$_[1] ) { $pack_init =~ s/\{0}/\{$size}/s ;}
  
  $size += length($pack_init) if !$_[1] ;
  
  return( $size ) ;
}

#######
# END #
#######

# 0 => key & val || line
# 1 => hash ref
# 2 => array ref

1; 

__END__

=head1 NAME

HDB::Encode - Hybrid DataBase - HASH/ARRAY enconding.

=head1 DESCRIPTION

You can save HASH and ARRAY structures inside columns of a table in the database.

** The column that will receive the encoded data need to have a good size for the encoded HASH/ARRAY!

=head1 USAGE

  my %HASH = (
  'a' => 1 ,
  'b' => 2 ,
  'c' => 3 ,
  'd' => { 'da' => 41 , 'db' => 42 } ,
  'e' => [qw(x y z)] ,
  ) ;
  
  $HDB->insert( 'users' , {
  user => 'joe' ,
  name => 'joe tribianny' ,
  more => \%HASH ,
  } ) ;
  
  ...
  
  $HDB->insert( 'users' , {
  user => 'joe' ,
  name => 'joe tribianny' ,
  more => { a => 1 , b => 2 } ,
  } ) ;
  
  ...
  
  my %hash = $HDB->select( 'users' , 'user == joe' , col => 'more' , '$$@' ) ; # $$@ to return directly the HASH.

=head1 METHODS

B<** You don't need to use this methods, HDB will make everything automatically.>

=head2 Pack (\%HASH or \@ARRAY)

Encode a HASH/ARRAY.
Will use Pack_HASH & Pack_ARRAY.

=head2 Pack_HASH (\%HASH)

Encode a HASH.

=head2 Pack_ARRAY (\@ARRAY)

Encode an ARRAY.

=head2 UnPack (ENCODED_HASH or ENCODED_ARRAY)

Decode a HASH/ARRAY.
Will use UnPack_HASH & UnPack_ARRAY.

=head2 UnPack_HASH (ENCODED_HASH)

Decode a HASH.

=head2 UnPack_ARRAY (ENCODED_ARRAY)

Decode an ARRAY.

=head2 Is_Packed_HASH (DATA)

Check if the encoded data is a HASH.

=head2 Is_Packed_ARRAY (DATA)

Check if the encoded data is an ARRAY.

=head2 Check_Pack_Size (DATA)

Check if the encoded data is ok.

=head2 Packed_SIZE (\%HASH or \@ARRAY)

Return the size of the HASH/ARRAY encoded.
This will calculate the size without generate the encoded data.

Will use Packed_SIZE_HASH & Packed_SIZE_ARRAY.

=head2 Packed_SIZE_HASH (\%HASH)

Return the size of the HASH encoded without generate it.

=head2 Packed_SIZE_ARRAY (\@ARRAY)

Return the size of the ARRAY encoded without generate it.

=head1 ENCODED DATA

The encoded HASH/ARRAY are very similar:

  %HDB_PACKED_HASH%[1.0]{50}:DATA

  1.0  >> Format version.
  50   >> DATA size.
  DATA >> The encoded data.
  
  # For ARRAY is:
  %HDB_PACKED_ARRAY%...
  
  ** The data has this begin to identify the encoded data in the database.
  ** The size is used to check if the data is crashed.
  
  DATA for HASH:
  
  02:aa4:bbbb
  
  0    >> normal value. 1 for HASH in the value. 2 for ARRAY in the value.
  2    >> size of key.
  aa   >> key
  4    >> size of value.  
  bbbb >> value
  
  DATA for ARRAY:
  
  02:aa
  
  0  >> normal value. 1 for HASH in the value. 2 for ARRAY in the value.
  2  >> size of value.
  aa >> value

=head1 SEE ALSO

L<HDB>, L<HDB::CMDS>, L<HDB::sqlite>, L<HDB::mysql>.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

