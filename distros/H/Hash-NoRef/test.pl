#########################

use Data::Dumper ;
##use Devel::Peek ;

use Test;
BEGIN { plan tests => 3900 } ;

use Hash::NoRef ;

use strict ;
use warnings qw'all' ;

my $DESTROIED ;
sub DESTROY { $DESTROIED = 1 ;}

for(1..100) {

my $hash = new Hash::NoRef() ;

#########################
{
 
  my $var = 123 ;

  my $ref = \$var ;
  
  my $refcnt = Hash::NoRef::SvREFCNT( $ref ) ;
  ok($refcnt , 2) ;

  $hash->{var} = $ref ;
  
  ok( $hash->{var} , $ref ) ;

  ok( ${$hash->{var}} , 123 ) ;
  
  $refcnt = Hash::NoRef::SvREFCNT( $ref ) ;
  
  ok($refcnt , 2) ;
  
  $hash->{var2} = $ref ;
  
  ok( ${$hash->{var2}} , 123 ) ;
  
  $refcnt = Hash::NoRef::SvREFCNT( $ref ) ;
  
  ok($refcnt , 2) ;
  
  my $hash2 = new Hash::NoRef() ;
  
  $hash2->{hash} = $hash ;
  
  ok( $hash2->{hash} , $hash ) ;
  
  $refcnt = Hash::NoRef::SvREFCNT( $hash ) ;
  
  ok($refcnt , 1) ;
  
  my $hold = $hash ;
  
  $refcnt = Hash::NoRef::SvREFCNT( $hash ) ;
  
  ok($refcnt , 2) ;

  $ref = undef ;
  
  $refcnt = Hash::NoRef::SvREFCNT( \$var ) ;  
  ok($refcnt , 2) ;
  
  $hash->{var} = undef ;
  
  ok( $hash->{var} , undef ) ;
  
}
#########################
{

  my $refcnt = Hash::NoRef::SvREFCNT( $hash->{var} ) ;  
  ok($refcnt , -1) ;
  $hash = undef ;

}
#########################
{

  my $hash = new Hash::NoRef() ;
  $DESTROIED = undef ;

  {
    my $obj = bless {} ;
    my $refcnt = Hash::NoRef::SvREFCNT( $obj ) ;
    ok($refcnt , 1) ;
    
    $hash->{var} = $obj ;
    
    $refcnt = Hash::NoRef::SvREFCNT( $obj ) ;
    ok($refcnt , 1) ;
    
    ok( ref($hash->{var}) , 'main' ) ;
    
    ok( $hash->{var} ) ;
    ok( $hash->{var} ) ;
    
    ok( $hash->{var} , $obj ) ;
    
    $refcnt = Hash::NoRef::SvREFCNT( $obj ) ;
    ok($refcnt , 1) ;
    
    ok(!$DESTROIED) ;
  }

  ok($DESTROIED) ;
  
  ok( !$hash->{var} ) ;
  
}
#########################
{

  my $hash = new Hash::NoRef() ;
  $DESTROIED = undef ;

  {
    my $obj = bless do { my $o = 'obj foo' ; \$o } ;
    my $refcnt = Hash::NoRef::SvREFCNT( $obj ) ;
    ok($refcnt , 1) ;
    
    $hash->{var} = $obj ;
    
    $refcnt = Hash::NoRef::SvREFCNT( $obj ) ;
    ok($refcnt , 1) ;
    
    ok( ref($hash->{var}) , 'main' ) ;
    
    ok( $hash->{var} , $obj ) ;
    
    $refcnt = Hash::NoRef::SvREFCNT( $obj ) ;
    ok($refcnt , 1) ;
    
    ok(!$DESTROIED) ;
  }
  ok($DESTROIED) ;
  
  ok( !$hash->{var} ) ; 
}
#########################
{

  my $hash = new Hash::NoRef() ;
  my $tied = tied(%$hash) ;

  {
    my $d = Data::Dumper->new( [ 'foo' ] ) ;
    $hash->{d} = $d ;
  }

  ok( !$hash->{d} ) ;
  
  delete $hash->{d} ;
  
}
#########################
{

  my $hash = new Hash::NoRef() ;

  {
    my @d = qw(foo bar) ;
    $hash->{d} = \@d ;
    ok( join(" ", @{$hash->{d}}) , 'foo bar' ) ;
  }

  my $d = $hash->{d} ;

  ok( !$hash->{d} ) ;
  
  delete $hash->{d} ;
  
}
#########################
{

  my $hash = new Hash::NoRef() ;

  {
    my $d = 'foo' ;
    $hash->{d} = \$d ;
    ok( $d , 'foo' ) ;    
  }

  ok( !$hash->{d} ) ;
  
  delete $hash->{d} ;
  
}
#########################
{
  my @d = qw(foo bar) ;
    
  {
    my $hash = new Hash::NoRef() ;  
    $hash->{d} = \@d ;
    ok( join(" ", @{$hash->{d}}) , 'foo bar' ) ;
  }
  
  ok( join(" ", @d) , 'foo bar' ) ;
  
}
#########################
{
  my $d = 'foo' ;
    
  {
    my $hash = new Hash::NoRef() ;  
    $hash->{d} = \$d ;
    ok( ${$hash->{d}} , 'foo' ) ;
  }
  
  ok($d , 'foo') ;
  
}
#########################

}

print "\nThe End! By!\n" ;

1 ;

