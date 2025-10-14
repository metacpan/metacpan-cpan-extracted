# Liberally adapted from:
# https://en.wikiversity.org/wiki/Reed%E2%80%93Solomon_codes_for_coders

package Math::ReedSolomon::Encoder;
use v5.24;
use warnings;
use experimental qw< signatures >;
{ our $VERSION = '0.001' }

use Exporter qw< import >;
our @EXPORT_OK = qw<
   rs_correction
   rs_correction_string
   rs_encode
   rs_encode_string
>;
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

our $ALPHA = 2;
our $PRIME_POLY = 0X11D;

########################################################################
#
# Public Interface

sub rs_correction ($msg, $nsym) {
   my $g = _rs_generator_poly($nsym);
   my ($quot, $rem) = _gf256_poly_div([$msg->@*, (0) x $nsym ], $g);
   return $rem;
}

sub rs_correction_string ($msg, $nsym) {
   my $aref = [ map { ord($_) } split m{}mxs, $msg ];
   return join '', map { chr($_) } rs_correction($aref, $nsym)->@*;
}

sub rs_encode ($msg, $nsym) {
   return [ $msg->@*, rs_correction($msg, $nsym)->@* ];
}

sub rs_encode_string ($msg, $nsym) {
   return $msg . rs_correction_string($msg, $nsym);
}


########################################################################
#
# Private Interface

sub _rs_generator_poly ($nsym) {
   state $gs = [ [1] ];
   push $gs->@*, _gf256_poly_mul($gs->[-1], [1, _gf256_pow($ALPHA, $gs->$#*)])
      while $nsym > $gs->$#*;
   return $gs->[$nsym];
}

sub _gf256_table_for {
   state $table_for = do {
      my (@exp, @log);
      my $x = 1;
      for my $i (0 .. 254) {
         $exp[$i] = $exp[$i + 255] = $x;
         $log[$x] = $i;
         $x <<= 1;
         $x ^= $PRIME_POLY if $x & 0x100;
      }
      { exp => \@exp, log => \@log };
   };
}

sub _gf256_mul ($x, $y) {
   state $table_for = _gf256_table_for();
   state $exp = $table_for->{exp};
   state $log = $table_for->{log};
   return 0 if $x == 0 || $y == 0;
   return $exp->[$log->[$x] + $log->[$y]];
}

sub _gf256_pow ($x, $pow) {
   state $table_for = _gf256_table_for();
   state $exp = $table_for->{exp};
   state $log = $table_for->{log};
   return $exp->[($log->[$x] * $pow) % 255];
}

sub _gf256_poly_mul ($p, $q) {
   my $lp = $p->@*;
   my $lq = $q->@*;
   my $lr = $lp + $lq - 1;
   my $r = [ (0) x $lr ];
   for my $i (0 .. ($lp - 1)) {
      for my $j (0 .. ($lq - 1)) {
         $r->[$i + $j] ^= _gf256_mul($p->[$i], $q->[$j]);
      }
   }
   return $r;
}

sub _gf256_poly_div ($x, $y) {
   my $retval = [ $x->@* ];
   for my $i (0 .. ($x->$#* - $y->$#*)) {
      my $c = $retval->[$i];
      if ($c != 0) {
         for my $j (1 .. $y->$#*) {
            if ($y->[$j] != 0) {
               $retval->[$i + $j] ^= _gf256_mul($y->[$j], $c);
            }
         }
      }
   }
   my $separator = $retval->$#* - $y->$#*;
   my $quot = [ $retval->@[0 .. $separator] ];
   my $rem  = [ $retval->@[$separator + 1 .. $retval->$#*] ];
   return ($quot, $rem);
}

1;
