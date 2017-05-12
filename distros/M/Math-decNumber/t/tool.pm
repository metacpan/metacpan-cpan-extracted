use strict;
use warnings;
use Math::decNumber ':all';

# A module to use the testcases for General Decimal Arithmetic.
# See: http://speleotrove.com/decimal/dectest.html
# (c) 2014 J-L Morel (jl_morel@bribes.org) web: http://bribes.org/perl/

my %rounding_mode = (
ceiling     => ROUND_CEILING,
down        => ROUND_DOWN,
floor       => ROUND_FLOOR,
half_down   => ROUND_HALF_DOWN,
half_even   => ROUND_HALF_EVEN,
half_up     => ROUND_HALF_UP,
up          => ROUND_UP,
'05up'      => ROUND_05UP,
);

my %function1 = (       # 1 arg functions 
'abs' => \&Abs,
'squareroot' => \&SquareRoot, 
'exp' => \&Exp,
'ln' => \&Ln,
'log10' => \&Log10,
'logb' => \&LogB,
'invert' =>  \&Invert,
'minus' => \&Minus,
'nextminus' => \&NextMinus,
'plus' => \&Plus,
'nextplus' => \&NextPlus,
'reduce' => \&Reduce,
'tointegral' => \&ToIntegralValue,
'tointegralx' => \&ToIntegralExact,
'trim' => \&Trim,
'copy' => \&Copy,
'copyabs' => \&CopyAbs,
'copynegate' => \&CopyNegate,
);

my %function2 = (       # 2 args functions 
'add' => \&Add,
'multiply' => \&Multiply,
'subtract' => \&Subtract,
'divide' => \&Divide,
'and'   => \&And,
'or'  => \&Or,
'power' => \&Power,
'xor'  => \&Xor,
'compare' => \&Compare,
'comparesig' => \&CompareSignal,
'comparetotal' => \&CompareTotal,
'comparetotmag' => \&CompareTotalMag,
'divideint' => \&DivideInteger,
'max' => \&Max,
'maxmag' => \&MaxMag,
'min' => \&Min,
'minmag' => \&MinMag,
'nexttoward' => \&NextToward,
'quantize' => \&Quantize,
'remainder' =>  \&Remainder,
'remaindernear' => \&RemainderNear,
'rescale' => \&Rescale,
'rotate' => \&Rotate,
'samequantum' => \&SameQuantum,
'scaleb' => \&ScaleB,
'shift' => \&Shift,
'copysign' => \&CopySign,
);

my %function3 = (       # 3 args functions 
'fma' =>  \&FMA,
);

# operands should not be rounded
sub NoRounded {
  my $emax = ContextMaxExponent(999999999);
  my $emin = ContextMinExponent(-999999999);
  my $p = ContextPrecision( 128 );
  my $r = FromString( $_[0] );
  ContextPrecision( $p );
  ContextMaxExponent($emax);
  ContextMinExponent($emin);
  ContextZeroStatus();
  return $r;
}

# parse a line of a .decTest file
sub parse_line {
  my $line = shift;
  my @elem;
   
  if ( $line =~ /[\'\"]/ ) {   
    $line =~ /^([^\'\"]*)([\'\"])(.*)$/;    
    my $delim = $2;
    $line = $3;    
    push @elem, split /\s+/, $1 if ( defined $1 );   
    if ( defined $line ) {
      $line =~ /^([^$delim]*)$delim(.*)$/;
      push @elem, $1;
      if ( defined $2 ) {
        $line = $2;
        $line =~ s/^\s*//s;
        # print STDERR "______ $line\n";
        push @elem, parse_line($line);
      }
    }  
  }
  else {
    push @elem, split /\s+/, $line;
  }
  return @elem;
}

# return the status from a line of a .decTest file
sub expected_status {
  my $line = shift;
  my $status = 0;
  $status |= DEC_Conversion_syntax if $line =~ /Conversion_syntax/;
  $status |= DEC_Division_by_zero if $line =~ /Division_by_zero/;
  $status |= DEC_Division_impossible if $line =~ /Division_impossible/;
  $status |= DEC_Division_undefined if $line =~ /Division_undefined/;
  $status |= DEC_Insufficient_storage if $line =~ /Insufficient_storage/;
  $status |= DEC_Inexact if $line =~ /Inexact/;
  $status |= DEC_Invalid_context if $line =~ /Invalid_context/;
  $status |= DEC_Invalid_operation if $line =~ /Invalid_operation/;
  $status |= DEC_Lost_digits if $line =~ /Lost_digits/;
  $status |= DEC_Overflow if $line =~ /Overflow/;
  $status |= DEC_Clamped if $line =~ /Clamped/;
  $status |= DEC_Rounded if $line =~ /Rounded/;
  $status |= DEC_Subnormal if $line =~ /Subnormal/;
  $status |= DEC_Underflow if $line =~ /Underflow/;

  return $status;
  }
  
# run the tests of a .decTest file
sub test_file {

  open my $TEST, "<", $_[0] or die $!;  # the .decTest file to run
  open my $LOG, ">>", "log.txt";        # a log file to locate errors (if any!)
  
  print $LOG "============| $_[0]\n";

  while ( <$TEST> ) {
    chomp;
    next if /^\s*--/;		# comment
    next if /^\s*$/;	  # blank line
    $_ =~ s/-- .*$//s;   # remove end of line comment
    next if /#\d/;
    my @elem = parse_line( $_ );
    my $status = expected_status( $_ );

    if ( $elem[0] =~ /:$/ ) {               # Directive
      $elem[0] = lc $elem[0];
      if ( $elem[0] eq 'version:' ) {
        # nothing to do
      }
      elsif ( $elem[0] eq 'precision:' ) {
        ContextPrecision( $elem[1] );
        my $p = ContextPrecision();
        print $LOG "**** bad precision\n" if $p != $elem[1];
      }
      elsif ( $elem[0] eq 'rounding:' ) {
        ContextRounding( $rounding_mode{$elem[1]} );
        my $r = ContextRounding();
        print $LOG "**** bad rounding\n" if $r != $rounding_mode{$elem[1]};
      }
      elsif ( lc($elem[0]) eq 'maxexponent:' ) {
        ContextMaxExponent( $elem[1] );
        my $e = ContextMaxExponent();
        print $LOG "**** bad max exponent\n" if $e != $elem[1];
      }
      elsif ( lc($elem[0]) eq 'minexponent:' ) {
        ContextMinExponent( $elem[1] );
        my $e = ContextMinExponent();
        print $LOG "**** bad min exponent\n" if $e != $elem[1];
      }
      elsif ( lc($elem[0]) eq 'extended:' ) {
        ContextExtended( $elem[1] );
        my $c = ContextExtended();
        print $LOG "**** bad extended mode\n" if $c != $elem[1];
      }
      elsif ( lc($elem[0]) eq 'clamp:' ) {
      ContextClamp( $elem[1] );
      my $c = ContextClamp();
      print $LOG "**** bad clamp mode\n" if $c != $elem[1];
    }
      
      else {
        print $LOG "**** unknown directive: $elem[0] ????\n\n";
      }

    }
    else {                                  # Operation
      my $r;
      if ( $elem[1] eq 'apply' ) {
        $r = FromString($elem[2]);
        ok( ToString($r) eq $elem[4] );
        if ( ToString($r) ne $elem[4] ) {
          print $LOG "$elem[0] : ", ToString($r), " =/= $elem[4]\n";
        }
      }
      if ( $elem[1] eq 'toSci' ) {
        $r = FromString($elem[2]);
        ok( ToString($r) eq $elem[4] );
        if ( ToString($r) ne $elem[4] ) {
          print $LOG "$elem[0] : ", ToString($r), " =/= $elem[4]\n";
        }
      }
      if ( $elem[1] eq 'toEng' ) {
        $r = FromString($elem[2]);
        ok( ToEngString($r) eq $elem[4] );
        if ( ToEngString($r) ne $elem[4] ) {
          print $LOG "$elem[0] : ", ToString($r), " =/= $elem[4]\n";
        }
      }
      if ( $elem[1] eq 'class' ) {
        $r = ClassToString(Class(FromString($elem[2])));
        ok( $r eq $elem[4] );
        if ( $r ne $elem[4] ) {
          print $LOG "$elem[0] : ", ToString($r), " =/= $elem[4]\n";
        }
      }
      elsif ( exists $function1{$elem[1]} ) {
        $r = $function1{$elem[1]}->( NoRounded($elem[2]) );
        ContextSetStatus( DEC_Invalid_operation ) if $elem[2] eq '#';
        ok( ToString($r) eq $elem[4] );
        if ( ToString($r) ne $elem[4] ) {
          print $LOG "$elem[0] : ", ToString($r), " =/= $elem[4]\n";
        }
        ok( $status == ContextGetStatus( ) );
        if ( $status != ContextGetStatus( ) ) {     
          print $LOG "$elem[0] : status expected = $status != ", ContextGetStatus( ), "\n";      
        }
      }      
      elsif ( exists $function2{$elem[1]} ) {
        $r = $function2{$elem[1]}->( NoRounded($elem[2]), NoRounded($elem[3]) );
        ContextSetStatus( DEC_Invalid_operation ) if $elem[2] eq '#' or $elem[3] eq '#';
        ok( ToString($r) eq $elem[5] );
        if ( ToString($r) ne $elem[5] ) {     
          print $LOG "$elem[0] : !", ToString($r), "! =/= $!elem[5]!\n";
        }    
        ok( $status == ContextGetStatus( ) );
        if ( $status != ContextGetStatus( ) ) {     
          print $LOG "$elem[0] : status expected = $status != ", ContextGetStatus( ), "\n";      
        }     
      }
      elsif ( exists $function3{$elem[1]} ) {
        $r = $function3{$elem[1]}->( NoRounded($elem[2]), NoRounded($elem[3]), NoRounded($elem[4]) );
        ContextSetStatus( DEC_Invalid_operation ) if $elem[2] eq '#' or $elem[3] eq '#' or $elem[4] eq '#';
        ok( ToString($r) eq $elem[6] );
        if ( ToString($r) ne $elem[6] ) {     
          print $LOG "$elem[0] : !", ToString($r), "! =/= $!elem[5]!\n";
        }   
        ok( $status == ContextGetStatus( ) );
        if ( $status != ContextGetStatus( ) ) {     
          print $LOG "$elem[0] : status expected = $status != ", ContextGetStatus( ), "\n";      
        }       
      }
    }
  }
close $TEST;  
close $LOG;
}

1;



