#############################################################################
## Name:        CORE.pm
## Purpose:     HDB::CORE
## Author:      Graciliano M. P.
## Modified by:
## Created:     06/01/2003
## RCS-ID:      
## Copyright:   (c) 2002 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package HDB::CORE ;

use strict qw(vars) ;
no warnings ;

our $VERSION = '1.0' ;

##############
# PARSE_ARGS #
##############

sub parse_args {
  my ( $set , $types ) = @_ ;
  my %args = &lower_keys(@_[2..$#_]) ;
  
  foreach my $Key ( keys %$types ) {
    my @aliases = @{ $$types{$Key} } ;
    my $def ;
    if (ref $aliases[0] eq 'ARRAY') {
      $def = $aliases[-1] ;
      @aliases = @{ $aliases[0] } ;
    }
    
    my $was_set ;
    foreach my $aliases_i ( @aliases ) {
      if ( defined $args{$aliases_i} ) { $$set{$Key} = $args{$aliases_i} ; $was_set = 1 ; last ;}
    }
    
    if (! $was_set && defined $def) { $$set{$Key} = $def ;}
    
  }
}

############# (SCALAR|ARRAY|HASH REF \[$%@]var)
# PARSE_REF # Parse the reference of a var.
############# (@ARRAY)

sub parse_ref {
  my $ref = ref($_[0]) ;
  if ($ref eq '') {
    if (! wantarray) { return( $_[0] ) }
    return( @_ )
  }
  elsif ($ref eq 'ARRAY') {
    if (! wantarray) { return( (@{$_[0]})[0] ) }
    return( @{$_[0]} )
  }
  elsif ($ref eq 'HASH') {
    if (! wantarray) { return( (%{$_[0]})[0] ) }
    return( %{$_[0]} )
  }
  elsif ($ref eq 'SCALAR') {
    return( ${$_[0]} )
  }
  else {
    if (! wantarray) { return( $_[0] ) }
    return( @_ )
  }
}

##############
# LOWER_KEYS #
##############

sub lower_keys {
  my @hash = parse_ref(@_) ;
  
  for(my $i = 0 ; $i <= $#hash ; $i +=2) {
    $hash[$i] = lc($hash[$i]) ;
    $hash[$i] =~ s/[\W_]//gs ;
  }
  
  if ( @hash % 2 ) { push(@hash , undef) ;}
  
  return( @hash ) ;
}

########
# PATH #
########

sub path {
  my ( $path ) = @_ ;
  $path =~ s/[\\]/\//gs ;
  $path =~ s/(?:^(\/)\/([^\/])|\/+)/$1\/$2/gs ;
  return( $path ) ;
}

#######
# END #
#######

1;

