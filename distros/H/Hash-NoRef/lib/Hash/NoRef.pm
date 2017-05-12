#############################################################################
## Name:        NoRef.pm
## Purpose:     Hash::NoRef
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2004-04-16
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Hash::NoRef ;
use 5.006 ;

use strict qw(vars) ;

use vars qw($VERSION @ISA) ;

$VERSION = '0.03' ;

use DynaLoader ;
@ISA = qw(DynaLoader) ;
bootstrap Hash::NoRef $VERSION ;

no warnings 'all' ;

sub new {
  shift ;
  my %hash ;
  tie(%hash , 'Hash::NoRef',@_) ;
  return \%hash ;
}

sub TIEHASH {
  my $class = shift ;
  my $this = bless({} , $class) ;
  
  if (@_) {
    my %content = (@_) ;
    foreach my $Key ( keys %content ) {
      $this->STORE($Key , $content{$Key}) ;
    }
  }
  
  return $this ;
}

sub FETCH {
  my $this = shift ;
  my $k = shift ;
  no warnings ;
  
  if ( !defined $this->{$k} ) { $this->DELETE($k) ;}
  
  return $this->{$k} ;
}

sub STORE {
  my $this = shift ;
  my $k = shift ;
  no warnings ;
  
  $this->{$k} = $_[0] ;  

  if ( ref($_[0]) ) { weaken( $this->{$k} ) ;}

  return $this->{$k} ;
}

sub EXISTS {
  my $this = shift ;
  my $k = shift ;
  no warnings ;
  if ( !defined $this->{$k} ) { $this->DELETE($k) ;}
  return exists $this->{$k} ;
}

sub DELETE {
  my $this = shift ;
  my $k = shift ;
  my $no_check_alive = shift ;
  no warnings ;
  return delete $this->{$k} ;
}

sub CLEAR {
  my $this = shift ;
  no warnings ;
  return %{$this} = () ;
}

sub FIRSTKEY {
  my $this = shift ;
  my $tmp = keys %{$this} ;
  each %{$this} ;
}

sub NEXTKEY {
  my $this = shift ;
  each %{$this} ;
}

sub UNTIE { &DESTROY }

sub DESTROY {
  no warnings ;
  &CLEAR ;
  return ;
}

#######
# END #
#######

1;


__END__

=head1 NAME

Hash::NoRef - A HASH that store values without increase the reference count (weak references).

=head1 DESCRIPTION

This HASH will store it's values without increase the reference count.
This can be used to store objects but without interfere in the DESTROY mechanism, since the
reference in this HASH won't count.

=head1 USAGE

  use Hash::NoRef ;

  my %hash ;
  tie(%hash , 'Hash::NoRef') ;

  ...
  
  ## Or getting a HASH ref tied:

  my $hash = new Hash::NoRef() ;
  
  {
    my $obj = new FOO() ;
    $hash->{obj} = $obj ;
    ## When we exit this block $obj will be destroied,
    ## even with it stored in $hash->{obj}
  }
  
  $hash->{obj} ## is undef now!


=head1 FUNTIONS

=head2 SvREFCNT ( REF )

Return the reference count of a reference.
If a reference is not paste it will return -1.
Dead references will return 0.

=head2 SvREFCNT_inc ( REF )

Increase the reference count.

=head2 SvREFCNT_dec ( REF )

Decrease the reference count.

=head2 EXAMPLES

  my $var = 123 ;
  $refcnt = Hash::NoRef::SvREFCNT( \$var ) ; ## returns 1
  
  Hash::NoRef::SvREFCNT_inc(\$var) ; ## adda fake reference, so, it will never die.
  Hash::NoRef::SvREFCNT_dec(\$var) ; ## get back to the normal reference count.

=head1 SEE ALSO

L<Spy>, L<Devel::Peek>, L<Scalar::Util>, L<Safe::World>.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

