package PDL::Meschach;

# What are those for ?
# use strict;
# use vars qw($VERSION @ISA @EXPORT);

use Carp;  
use PDL;
use PDL::Core;
require Exporter;
require DynaLoader;

$VERSION = '0.03';

@ISA = qw(Exporter DynaLoader);


@EXPORT_OK = qw( ident diag_ diag ut_ ut lt_ lt mrand srand
             inv inv_ mpow mpow_ mm_
             chfac_ chsolve_ chsolve 
             qrfac_ qrsolve_ qrsolve qrcond
             lufac_  lusolve_ lusolve lucond
             symmeig_ symmeig svd_ svd
             ppdl redd tomat gset_verbose to_fro_m to_fro_v to_fro_px
             cl ml    
             );

@EXPORT = qw(ident diag ut lt inv mpow chsolve qrsolve
             lucond lusolve symmeig svd  cl ml );

                                # Redundant code 
%EXPORT_TAGS = 
  (Raw => [ qw(
               mm_ diag_ ut_ lt_ inv_ mpow_ 
               chfac_ chsolve_ 
               lufac_ lusolve_ lucond 
               qrfac_ qrsolve_ qrcond
               symmeig_ svd_ 
               ident diag ut inv mpow chsolve
               lusolve symmeig svd  cl ml )
           ],
  
  All => [qw( ident diag_ diag ut_ ut  lt_ lt mrand srand
             inv inv_ mpow mpow_ mm_
             chfac_ chsolve_ chsolve 
             qrfac_ qrsolve_  qrsolve qrcond
             lufac_  lusolve_ lusolve lucond 
             symmeig_ symmeig svd_ svd
             ppdl redd tomat gset_verbose to_fro_m to_fro_v to_fro_px
             cl ml )
             ]
                );

bootstrap PDL::Meschach $VERSION; 

# Returns a pdl filled with random values in [0,1].
# - If $_[0] is a pdl, mrand will fill it with random values in [0,1].
#   $_[1] is a  coercion-authorisation (default 0). 
# - Otherwise, @_ is considered as dimensions of a pdl that is
#   created, filled with random  values in [0,1], and returned.

sub mrand {

  my ($r,$c) = (ref($_[0]) ne "PDL") ?
    (zeroes(@_),1) :
      ($_[0], defined($_[1]) ? $_[1] : 0 ) ;

  mp_mrand($r,$c);
  $r;
}

# Seed Random
sub srand {
  $_[0] = 1 unless defined($_[1]);
  mp_smrand($_[0]);
}

# ident : returns an identity matrix.
# - ident ( dimx  [, dimy (default=dimx ] ) )
#     pads with zeroes if dimx != dimy 

sub ident {

  croak "usage : ident(\$row[,\$col]) " if $#_ == -1  ;

  my ($c,$r) = @_ ;

  $r = $c unless( defined($r) );
  my ($k,$l,$I) = ( 0, ($c<$r)?$c:$r ,  double(zeroes($c,$r)) );
  for( $k= 0; $k < $l ; $k++ ){
    set($I, $k,$k, 1) 
    }

  $I;
}


#   ut_( In_Out_mat )
#
#   zeroes In_Out_mat's strictly lower triangle (diagonal is kept).
#
#   ut_( Out_mat, In_mat )
#
#   Sets Out_mat to the upper triangle of In_mat
#   or  
#
#   ut_( Out_mat, Col, Row )
#   Return a thru $_[0] matrix of size (columns) $_[1], (rows) $_[2]
#   with upper triangle filled with 1, lower triangle filled with 0.

sub ut_ {

# print " To pdl  " if (ref($_[0]) ne "PDL"); CAUSES SEG FAULT
  $_[0] = pdl($_[0]) if (ref($_[0]) ne "PDL");

# print "One par "if( $#_ == 0 );
  $_[1] = $_[0] if( $#_ == 0 );

  if (ref($_[1]) ne "PDL"){			# 0s and 1s
    croak 
      "Usage : ut_(Out_mat, In_mat) or\n".
      "        ut_(Out_mat, Col, Row) \n"
        unless($#_ == 2);
    $_[0] = zeroes($_[1],$_[2]);
    my ($i,$j,$m);
    $m = ($_[1]>$_[2]) ? $_[2] : $_[1] ; # min
    for( $i=0; $i<$m; $i++){
      for( $j=$i; $j<$_[1]; $j++){
        set($_[0],$j,$i,1);
      }
    } 
  } else {

# HERE BUG

#   if( $_[0] == $_[1] ){print "No Copy Needed\n" ;}
#   else {print " Copy Needed \n" ;}
    $_[0] = $_[1] + 0;
#     unless $_[0]==$_[1];          # Mutator to enforce copy

    my ($i,$j,$m,$n);
    $m = ${${$_[1]}{Dims}}[0];
    $n = ${${$_[1]}{Dims}}[1];
    for( $i=0; $i<$m; $i++){
      for( $j=$i+1; $j<$n; $j++){
        set($_[0],$i,$j,0);
      }
    }
  }
  $_[0];
}

sub ut {
  my $t;
  ut_($t,@_);
  $t;
}


sub lt_ {

  $_[0] = pdl($_[0]) if (ref($_[0]) ne "PDL");

  $_[1] = $_[0] if( $#_ == 0 );

  if (ref($_[1]) ne "PDL"){			# 0s and 1s
    croak 
      "Usage : lt_(Out_mat, In_mat) or\n".
      "        lt_(Out_mat, Col, Row) \n"
        unless($#_ == 2);
    $_[0] = ones($_[1],$_[2]);
    my ($i,$j,$m);
    $m = ($_[1]>$_[2]) ? $_[2] : $_[1] ; # min
    for( $i=0; $i<$m; $i++){
      for( $j=$i+1; $j<$_[1]; $j++){
        set($_[0],$j,$i,0);
      }
    } 
  } else {


    $_[0] = $_[1] + 0;

    my ($i,$j,$m,$n);

    $m = ${${$_[1]}{Dims}}[0];
    $n = ${${$_[1]}{Dims}}[1];
    for( $i=0; $i<$n; $i++){
      for( $j=$i+1; $j<$m; $j++){
        set($_[0],$j,$i,0);
      }
    }
  }
  $_[0];
}

sub lt {
  my $t;
  lt_($t,@_);
  $t;
}

# Either :
#   Extract the diagonal of a matrix (given a matrix) ,  or
#   Build   a   diagonal matrix      (given a vector)

sub diag_ {

  $_[1] = pdl($_[1]) if (ref($_[1]) ne "PDL");

  $_[0] = pdl($_[0]) if (ref($_[0]) ne "PDL");
  
  if( $#{${$_[1]}{Dims}} == 0 ){

    my $m =  $_[2] || ml(dims($_[1])); # ${${$_[1]}{Dims}}[0] ;
    my $n =  $_[3] || $m;
    my ($i,$o);
    
    $_[0] = zeroes( $m, $n ); 
    $o = ml($m,$n, dims($_[1])) ;
    #  $o= ($m < $n) ? $m : $n ;

    for($i=0; $i<$o; $i++){
      set($_[0],$i,$i,at($_[1],$i));
    }
  } elsif( $#{${$_[1]}{Dims}} == 1 ){
    
    my $m =  ${${$_[1]}{Dims}}[0] ;
    $m = ${${$_[1]}{Dims}}[1] if ( ${${$_[1]}{Dims}}[1] < $m ) ;
    my $i;

    reshape($_[0], $m);
    for( $i=0;$i<$m;$i++){
      set($_[0],$i,at($_[1],$i,$i));
    }
  } else {
    croak " 2nd arg to diag, $_[1] is inappropriate " ;
  }

}

sub diag {
  my $a;
  diag_($a,@_);
  $a;
}



# $_[0] <- $_[1] * $_[2] (Matrix Multiply)
# Coerce type of result to double if $_[3]. Default : Yes.
sub mm_ {
  $_[0] = pdl($_[0]) if (ref($_[0]) ne "PDL");
  $_[3] = 1 unless defined($_[3]);

  mp_mm(@_);
}

sub mpow_ {
  $_[0] = pdl($_[0]) if (ref($_[0]) ne "PDL");
  $_[1] = pdl($_[1]) if (ref($_[1]) ne "PDL");
  $_[3] = 1 unless defined($_[3]);

  mp_pow(@_);
}

sub mpow {
  my $res;
  mpow_( $res, @_ );
  $res;
}


# $_[0] <- $_[1]^(-1)
sub inv_ {
  $_[0] = pdl($_[0]) if (ref($_[0]) ne "PDL");
  $_[1] = pdl($_[1]) if (ref($_[1]) ne "PDL");
  $_[2] = 1 unless defined($_[2]);

  mp_inv(@_);
} 

sub inv {
  my $res;
  inv_( $res, @_ );
  $res;
}



# Cholesky decomposition of $_[0]. 
# Assuming that $_[0] is symmetric 
# No error if $_[0] is not symmetric : Only lower triangle is used.
# Error    if $_[0] is not positive definite.

sub chfac_ {
  $_[0] = pdl($_[0]) if (ref($_[0]) ne "PDL");

  mp_chfac($_[0]);
} 


# Solve a x = b, given the CH decomposition of a, $_[2]. x is $_[0].
# b is $_[1].  
sub chsolve_ {

  $_[0] = pdl($_[0]) if (ref($_[0]) ne "PDL");
  $_[1] = pdl($_[1]) if (ref($_[1]) ne "PDL");
  $_[2] = pdl($_[2]) if (ref($_[2]) ne "PDL");

  mp_chsolve(@_);
} 

# ($CH,$x) = chsolve($b,$A)
# ($CH,$x) = chsolve($b,$CH,1)
#
# Third arg is optional. If true, the second argument is considered to
# be a Cholesky facorization. 

sub chsolve {

  my $b= shift @_;
  my $x= zeroes(@{$$b{Dims}});

  my $CH;

  if( $_[1] ) {
    $CH = $_[0];

  } else {

    $CH = $_[0] + 0 ;

    mp_chfac( $CH );

  } 

  mp_chsolve( $x, $b, $CH );

  return ( $CH, $x );
} 



sub qrfac_ {

  $_[0] = pdl($_[0]) if (ref($_[0]) ne "PDL");
  $_[1] = long(zeroes(${${$_[0]}{Dims}}[0])) if (ref($_[1]) ne "PDL");
  
  mp_qrfac(@_);
} 

# Solve a x = b, given the QR decomposition of a, in the form $_[2]
# (QR), $_[3] (R's diagonal). x is $_[0], b is $_[1]. 
sub qrsolve_ {

  $_[0] = pdl($_[0]) if (ref($_[0]) ne "PDL");
  $_[1] = pdl($_[1]) if (ref($_[1]) ne "PDL");
  $_[2] = pdl($_[2]) if (ref($_[2]) ne "PDL");
  $_[3] = pdl($_[3]) if (ref($_[3]) ne "PDL");

  mp_qrsolve(@_);
} 



sub qrsolve {

	if( ($#_>2) || (ref($_[0]) ne "PDL") || (ref($_[1])  ne "PDL") || 
		 ( ($#_==2) && (ref($_[0]) ne "PDL") ) ){
		print <<'EOD';

  qrsolve  : resolution of a linear system "A.x = b" by QR method.

Usage : 2 forms :

*	($QR,$D,$x) = qrsolve( $b, $A );

  $A is a non-singular square matrix, $b the right hand side.

  $QR and $v represent the QR decomposition of a matrix.
	$x is the solution.	

*	($QR,$v,$x) = qrsolve( $b, $QR, $v );

  Same, but $QR and $v need to have been previously computed, e.g.
	by a previous call to qrsolve or qrfac_ .

EOD
		return 0;
	}

  my $b= shift @_;
  my $x= zeroes(@{$$b{Dims}});

  my ($QR, $v);

  if( $#_ == 0 ) {

    $QR = $_[0] + 0 ;
    $v = double(zeroes(${$$QR{Dims}}[0]));

    mp_qrfac( $QR, $v );

  } elsif( $#_ == 1 ) {

    $v = pop @_ ;
    $QR = pop @_ ;

  } else {
    croak "Usage : qrsolve($b,$A) or qrsolve($b,$QR,$v)";
  }

  mp_qrsolve( $x, $b, $QR, $v );

  return ( $QR, $v, $x );
} 

sub qrcond {
  if( ($#_!=0) || (ref($_[0]) ne "PDL") ){
    print <<'EOD';

Usage : $condition = qrcond( $QR );

  $QR represent (part of) the QR decomposition of a matrix, e.g. as
	  returned by qrfac_() or qrsolve(). 
  $condition is an estimate of the ratio of the greater eigenvalue and
	  the smaller eigenvalue. 

EOD
	  return 0;
	}
	return mp_qrcond($_[0]);
}


# LU decomposition .
# $_[0] is overwritten by LU,  $_[1] is pivot permutation
sub lufac_ {

  $_[0] = pdl($_[0]) if (ref($_[0]) ne "PDL");
  $_[1] = long(zeroes(${${$_[0]}{Dims}}[0])) if (ref($_[1]) ne "PDL");
  
  mp_lufac(@_);
} 

# Solve a x = b, given the LU decomposition of a, in the form $_[2]
# (LU) $_[3] (permutation). x is $_[0], b is $_[1]. 
sub lusolve_ {

  $_[0] = pdl($_[0]) if (ref($_[0]) ne "PDL");
  $_[1] = pdl($_[1]) if (ref($_[1]) ne "PDL");
  $_[2] = pdl($_[2]) if (ref($_[2]) ne "PDL");
  $_[3] = pdl($_[3]) if (ref($_[3]) ne "PDL");

  mp_lusolve(@_);
} 

sub lucond {
  if( ($#_!=1) || (ref($_[0]) ne "PDL") || (ref($_[1])  ne "PDL") ){
    print <<'EOD';

Usage : $condition = lucond( $LU , $P );
  $LU and $P represent the LU decomposition of a matrix, e.g. as
	  returned by lufac_() or lusolve() . 
  $condition is an estimate of the ratio of the greater eigenvalue and
	  the smaller eigenvalue. 

EOD
	  return 0;
	}
	return mp_lucond($_[0],$_[1]);
}

# ($LU,$Perm,$x) = lusolve($b,$A)
# ($LU,$Perm,$x) = lusolve($b,$LU,$Perm)

sub lusolve {

	if( ($#_>2) || (ref($_[0]) ne "PDL") || (ref($_[1])  ne "PDL") || 
		 ( ($#_==2) && (ref($_[0]) ne "PDL") ) ){
		print <<'EOD';

  lusolve  : resolution of a linear system "A.x = b" by LU method.

Usage : 2 forms :

*	($LU,$Perm,$x) = lusolve( $b, $A );

  $A is a non-singular square matrix, $b the right hand side.

  $LU and $Perm represent the LU decomposition of a matrix.
	$x is the solution.	

*	($LU,$Perm,$x) = lusolve( $b, $LU, $Perm );

  Same, but $LU and $Perm need to have been previously computed, e.g.
	by a previous call to lusolve or lufac_ .

EOD
		return 0;
	}	

  my $b= shift @_;
  my $x= zeroes(@{$$b{Dims}});

  my ($LU, $Perm);

  if( $#_ == 0 ) {

    $LU = $_[0] + 0 ;
    $Perm = long(zeroes(${$$LU{Dims}}[0]));

    mp_lufac( $LU, $Perm );

  } elsif( $#_ == 1 ) {

    $Perm = pop @_ ;
    $LU = pop @_ ;

  } else {
    croak "Usage : lusolve($b,$A) or lusolve($b,$LU,$Perm)";
  }

  mp_lusolve( $x, $b, $LU, $Perm );

  return ( $LU, $Perm, $x );
} 

# Eigen values/vectors of a symmetric matix. 
# $_[0] : Eigenvectors (put in a matrix) (output)
# $_[1] : Eigenvalues  (put in a vector) (output)
# $_[2] : The symmetric matrix.          (input)

sub symmeig_ {
  $_[0] = pdl($_[0]) if (ref($_[0]) ne "PDL");

  if (ref($_[1]) ne "PDL") {
    $_[1] = pdl $_[1] ;
  }

  $_[2] = pdl($_[2]) if (ref($_[2]) ne "PDL");

  mp_symmeig(@_);
} 

# ($V,$l) = symmeig($A);
# Puts in ($V,$l) the eigen vectors/values of the symmetric matrix $A.

sub symmeig {
  my ($vec,$val);
  symmeig_($vec,$val,@_);
  ($vec,$val);
}

# Singular value decomposition diag($l) = $U x $A x $V ;
# svd_($U,$V,$l,$A) puts in 
# $U : left vectors
# $V : right vectors
# $l : singular values.


sub svd_ {
  croak " usage svd_(\$U,\$V,\$l,\$A) or svd_(\$l,\$A) " 
    unless( ($#_ == 1) || ($#_ == 3 ) );

  if( $#_ == 1 ) {

    $_[0] = pdl($_[0]) if (ref($_[0]) ne "PDL");
    $_[1] = pdl($_[1]) if (ref($_[1]) ne "PDL");

  # YUCK! should not be needed! Otherwise, seg fault

		my $nsv =  ml( dims($_[1]) );
    reshape($_[0],$nsv) unless 
      (( $#{${$_[0]}{Dims}} == 0)  &&
       ( ${${$_[0]}{Dims}}[0] == $nsv ) );

    mp_svd0(@_);

  } else {

    $_[0] = pdl($_[0]) if (ref($_[0]) ne "PDL");
    $_[1] = pdl($_[1]) if (ref($_[1]) ne "PDL");
    $_[2] = pdl($_[2]) if (ref($_[2]) ne "PDL");
    $_[3] = pdl($_[3]) if (ref($_[3]) ne "PDL");
    my @da=dims($_[3]); 

    # YUCK! should not be needed! Otherwise, seg fault

    reshape($_[0],$da[1],$da[1]) unless 
      (( $#{${$_[0]}{Dims}} == 1)  &&
       ( ${${$_[0]}{Dims}}[0] == $da[1] ) &&
       ( ${${$_[0]}{Dims}}[1] == $da[1] ) );

    reshape($_[1],$da[0],$da[0]) unless
      (( $#{${$_[1]}{Dims}} == 1) && 
       ( ${${$_[1]}{Dims}}[0] == $da[0]) &&
       ( ${${$_[1]}{Dims}}[1] == $da[0]) );

		my $nsv =  ml($da[1],$da[0]) ;
    reshape($_[2],$nsv) unless 
      (( $#{${$_[2]}{Dims}} == 0)  &&
       ( ${${$_[2]}{Dims}}[0] == $nsv ) );

    mp_svd(@_);
  }
	1;
} 

sub svd {
  my ($U,$V,$l);
  svd_($U,$V,$l,@_);
  ($U,$V,$l)
}


# Take off trailing ones from ${$_[0]}{Dims}
sub redd { 
  if ( ref($_[0]) eq "PDL" ) { 
    my $a; 
    while ( ($a= pop @{${$_[0]}{Dims}}) == 1 ){}; 
    push @{${$_[0]}{Dims}}, $a; 
  } 
} 

# Convert a vector to matrix, if needed.
sub tomat {
  my $n;
  $_[0] = pdl($_[0]) if (ref($_[0]) ne "PDL");
  if( ( $n = $#{${$_[0]}{Dims}} ) > 2 ) {
    printf "tomat with non-matriceable argument \n";
    return;
  } elsif ( $n == 0 ) {
    ${${$_[0]}{Dims}}[1] = 1 ;
  }
}

# Compare two ordered lists
sub cl {
  my ($a, $i, $x,$y ) = (0,0,$_[0],$_[1]);

  return 0 if ( $#{$x} != $#{$y} );
  foreach $a (@$x) { return 0 if( $a != $$y[$i++] ) }
  return 1;
}

sub ml {
  my $m= $_[0];
  foreach (@_[1..$#_]) {
    $m = $_ if $_ < $m ;
  }
  $m;
}

sub BEGIN {

  1;
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=cut
