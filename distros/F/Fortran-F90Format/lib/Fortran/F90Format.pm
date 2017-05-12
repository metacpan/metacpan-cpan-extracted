package Fortran::F90Format;

use Carp;

our $VERSION = '0.40';

sub new {
  my $class = shift;
  my $self =  {};

  bless $self,$class;

  return $self->init(@_)

}

sub init {
   my $self = shift;
   my %opt = (
     fmt   => '',
      @_,
   );
  croak "No format string !\n" unless $opt{fmt};
  $self->{for_fmt} = $opt{fmt};
  if ( $self->{for_fmt} ne '*' ) {
     $self->parse();
  }
  return $self   
}
sub read {
  my $self = shift;
  my $line = shift;
  my $val =[] ;
  if ( $self->{for_fmt} eq '*' ) {
     $val = $self->parse_val($line);
  }
  else {   
     $val = [ unpack($self->{pack_fmt},$line) ]; 
  }
  return  wantarray ? @$val : $val;
}
sub for2for {
  my $self = shift;
  my $f = shift;
  my $p=[];
  my ($n,$w,$m,$d,$e,$ed)=('')x6;
  if ( $f =~ /^(\'|\").+(\'|\")$/ ) {
     $f=~ s/^(\'|\")//;	   
     $f=~ s/(\'|\")$//;	   
     push @$p ,( {str => $f } ); 	   
     return $p     
   }
   elsif( $f =~ /^(\d+)(H)/i ){
     my $l = $1;
     $f =~ s/^\d+[Hh]//;
     push @$p ,( {str => pack("a$l",$f) } ); 	   
     return $p
   }
   elsif ( $f =~ /^(\p{Letter})+$/ ) {
     $n=1; $ed = $1;
   } 
   elsif ( $f =~ /^(\p{Letter})+(\d+)$/ ) {
     $n = 1; $ed = $1; $w=$2;
   }
   elsif ( $f =~ /^(\p{Letter})+(\d+)\.(\d+)$/ ) {
     $n = 1; $ed = $1; $w=$2;$d=$3;
   }
   elsif ( $f =~ /^(\p{Letter})+(\d+)\.(\d+)(E|e)(\d+)$/ ) {
     $n = 1; $ed = $1; $w=$2; $d=$3;$e=$5; 
   }
   elsif ( $f =~ /^(\d+)(\p{Letter})+$/ ) {
     $n = $1; $ed = $2;
   }
   elsif ( $f =~ /^(\d+)(\p{Letter})+(\d+)$/ ) {
     $n = $1; $ed = $2; $w=$3;
   }
   elsif ( $f =~ /^(\d+)(\p{Letter})+(\d+)\.(\d+)$/ ) {
     $n = $1; $ed = $2; $w=$3; $d=$4;
   }
   elsif ( $f =~ /^(\d+)(\p{Letter})+(\d+)\.(\d+)(E|e)(\d+)$/ ) {
     $n = $1; $ed = $2; $w=$3; $d=$4;$e=$6; 
   } 
   push @$p , ( { ed => $ed , w => $w , d => $d  , e => $e } ) x $n;
   return $p 
}
sub wrt_F {
   my $h   = shift;
   my $val = shift; 
   my ($l,$r,$sign,$int,$dot,$frac)=('')x6;
   my @fn;
   my $fmt = '%'; 
   $val=sprintf "% .*f",length(trim($val))+3,$val;
   $val=~ /(-|\+| )(\d+)(\.)(\d+)/;
   $l = $h->{d}+1;
   $sign = $1; $int=$2; $dot=$3; $frac=pack("A$l",$4);
   @fn=split('',pack("A$l",$4));
   $sign =~ s/(\+| )//;
   $int = '' if ! $int;
   if ( $frac == 0 && ! $int ) {
      $sign = '';
      $int = '0';
   }
   $r = $h->{w} - length("$sign$int$dot") - $h->{d};
   if ( $r < 0 ) { return '*'x$h->{w}; }
   $frac = join('',@fn[0..$h->{d}-1]);
   $frac++ if $fn[$#fn] >= 5;
   $frac = pack("a$h->{d}",$frac);
   $val = sprintf "% $h->{w}s","$sign$int$dot$frac";
   return  $val
}
sub wrt_E {
   my $h = shift;
   my $val = shift;
   my ($sign,$int,$dot,$frac,$e_d,$e_d_s,$exp)=('')x7;
   $val=sprintf "% .*e",$h->{w}+1,$val;
   $val =~ /(-|\+| )(\d+)(\.)(\d+)([Ee])(\+|-)(\d+)/;
   $sign  = $1 eq ' ' ? '' : $1 ; 
   $int   = $2; 
   $dot   = $3; 
   $frac  = $4; 
   $e_d   = $5; 
   $e_d_s = $6; 
   $exp   = $7;
   $exp-- if $int && $e_d_s eq '-';
   $exp++ if $int && $e_d_s eq '+';
   $e_d = $h->{ed};
   if ( $h->{e} ) {
     if ( $exp <= (10**$h->{e}-1) ) {
       $exp = sprintf("%0$h->{e}d",$exp);
     } 
   }elsif ( $exp <= 99 ) {
       $exp = sprintf("%02d",$exp);
   }elsif( 99 < $exp && $exp <= 999 ) {
       $exp = sprintf("%03d",$exp);
   }
   $frac="$int$frac";
   $l=$h->{d}+1;
   @fn=split('',pack("A$l",$frac));
   $frac = join('',@fn[0..$#fn-1]); 
   $frac++ if $fn[$#fn] >= 5;
   $frac = pack("a$h->{d}",$frac);
   my $v= sprintf("% $h->{w}s","${sign}0.$frac$e_d$e_d_s$exp");
   return $v
}
sub wrt_I {
  my $h = shift;
  my $val = shift;
  my $int = abs($val);
  croak "Bad integer $val\n" if int($val) != $val ;
  my $plus = '';
  my $sign = $val < 0 ? '-' : $plus;
   
  my ($w,$d);
  $w= $h->{w} || 7;
  $d = $h->{d} || '';
  if ( ! $d ) { 
     if ( $val ) {
        $val = sprintf ( "%*d",$w,$val) ; 
     }else  {
       if ( $d eq '' ) {
        $val = sprintf ( "% *d",$w,0);
       } else {
         $val = sprintf ( "% *s",$w,' ');
       }
     }
  } else {
     $val = sprintf( "%*.*d",$w,$d,$val);
  }
  if ( $d > $w || length("$sign$int") > $w ) {
        $val = '*'x$w; 
  }
  return $val
}
sub wrt_X {
  my $h = shift;
  my $w = $h->{w}||1;
  my $n = $w;
  return ' 'x$n
}
sub wrt_A {
  my $h = shift;
  my $val = shift;
  if ( $h->{w} ) {
     return pack("a$h->{w}",sprintf ("% *s",$h->{w},"$val") );
  } else {
    return sprintf('%s',$val);
  }
}

sub write {
  my $self = shift;
  my @vals = @_;
  my ($i,$j,$ed);
  if ( $self->{for_fmt} eq '*' ) {
    return "@vals\n";
  }
  my $out='';
  foreach my $f ( @{$self->{for_array}} ){
     $ed = uc $f->{ed};
     if( $ed eq 'X' ){
         $out .= wrt_X($f);
     }elsif ( exists $f->{str} ) {
         $out .= $f->{str};
     }else{
       if ( $ed eq 'A' ) {
         $out .= wrt_A($f,$vals[$i]);
       }elsif ( $ed eq 'I' ) {
         $out .= wrt_I($f,$vals[$i]);  
       }elsif ( $ed eq 'F' ) {
         $out .= wrt_F($f,$vals[$i]);  
       }elsif(  $ed eq 'E' || $ed eq 'D'){
         $out .= wrt_E($f,$vals[$i]);
       }
       last if $i++ > $#vals;
    }
  }
  return "$out\n"
}

sub parse {
   my $self= shift;
   my $fmt = shift || $self->{for_fmt};
   my @chars = split '',$fmt;
   my @vars;
   my ($c,$r,$t,$d,@desc,$s);
   my (@rep,@tok,@stack);
   while (  @chars ) {   
       $c = shift @chars;
       $s.=$c;
       if (  ($c eq "'" || $c eq "\"") && ! $t ) {
	 $t=$c;
	 my $ch = shift @chars;
	 while ( $ch ne $c ) {
	    $t.=$ch;
	    $ch = @chars ? shift @chars : 
                           croak "unfinished quotedstring:|$t|\n";
	 }  
	 $t.=$ch;
         if ( ! @rep ) { 
	     push @stack,$t if $t;
         } elsif ( @tok ) { 
	    unshift @tok,$t if $t;
	 }
	 $t='';
       } elsif ( "$t$c" =~ /^\d+$/ && $chars[0] =~ /H/i ) {
	 my $n = "$t$c";
	 my $h = shift @chars;
	 my $ch = shift @chars;
	 for ( 1..$n-1 ) { $ch.=shift @chars; }
         if ( ! @rep ) { 
	     push @stack,"$n$h$ch";
         } elsif ( @tok ) { 
	    unshift @tok,"$n$h$ch";
	 }
	 $t='';
       } elsif (  $c eq '(' ) {   #begin nested record 
	  if ( ! $t ) { $t=1 };
	  unshift @rep,$t; 
	  unshift @tok,$c;
	  $t='';
       } elsif ( $c eq ')') { # end processing nested record    
	  $r    = shift @rep;
	  unshift @tok,$t if $t;
	  $d = shift @tok;
	  while ( $d ne '(' ) { 
	    unshift @desc,$d;
	    $d = shift @tok;
	  }
	  $t= join('__,__',(@desc)x($r));
	  @desc=();
          if ( ! @rep ) { 
             my @bits = split(/__,__/,$t);
	     push @stack,@bits if $t;
          } else { 
	     unshift @tok, $t if $t;
	  } 
	  $t='';
       } elsif ( $c eq ',' ) { # save token
         if ( ! @rep ) { 
	     push @stack,$t if $t;
         } elsif ( @tok ) { 
	     unshift @tok,$t if $t;
	 } 
	 $t='';
       } else { 
          $t.=$c if $c ne ' '; 
       } 
   }  
   push @stack,$t if $t;
   my (@pack,@for);
   foreach my $v ( @stack ) {
	push @for, @{$self->for2for($v)};
	push @pack, $self->for2pack($v);
   }
   $self->{for_fmt}  = join(',',@stack);
   $self->{for_array} = \@for;
   $self->{pack_fmt} = join(" ",@pack);
   $self->{pack_array} = \@pack;
}

sub for2pack {
   my $self = shift;
   my $f = shift;
   my $p='';
   if ( $f =~ /^(\'|\").*(\'|\")$/ ) {
     $f=~ s/^(\'|\")//;	   
     $f=~ s/(\'|\")$//;	   
     $p='x'.length($f);
     return $p
   }elsif( $f =~ /^\d+[H]/i ){
     $f =~ s/^\d+[Hh]//;
     $p='x'.length($f);
     return $p
   }
   $f =~ /(\p{Letter}+)/; 
   my $d=$1;
   my ($n,$w)=split(/\p{Letter}+/,$f);
   $n||=1 ; 
   if ( $d =~ /(A|B|D|E|F|G|Q|I|L|O|Z)/i ) {
      $w = abs(int($w)) if $w;
      $w = '*' if ! $w && uc($d) eq 'A';
      $w||=1 ; 
      $d = 'a';
      $p = join(' ',("$d$w")x$n); 
   } elsif ( $d =~ /X/i ) {
     $w||=1 ; 
     $w = abs(int($w));
     $d ='x';
     $p = "$d$w"x$n; 
     $p = join(' ',("$d$w")x$n); 
   } 
   return $p 
}

sub parse_val {
   my $self = shift;
   my $val = shift;
   my $var = shift ||'';
   my $values = [];
   my $all = $val ;
   my $ok = 1;
   return  [$val]  if $val =~ /\.(true|false)\./i ;
   while ( $val =~ / (\s*,\s*|\s*)               # match starting null value   
                     ((\s*\d+\s*)\*|)            # match multiplier 
                     (                           # begin matching values
                       \s*\'.*?\'\s*           | #  quoted string
                       \s*\w+\s*               | #  quoted string
                         [DdEe_0-9\.\-\+\:]+   | #  numeric variable
                      \s*\(                      #  start complex number
                           [\s0-9\.DdEeIi\-\+]+  #    real part
                           \s* , \s*             #    comma  
                           [\s0-9\.DdEeIi\-\+]+  #    imaginary part
                         \)\s*                |  #  end complex  number 
                         \s*,\s*                 #  separator        
                     )                           # end matching values
                     (                           # begin separators:
                       \s*,\s* |                 #   match null value ',,'
                       \s*     |                 #   blanks spaces,tabs,etc
                       $                         #   end of string or new line
                     )                           # end separators
                  /xmsg ) {
      my $nv  = $1;
      my $ntimes = $2;
      my $n = $3 || 1;
      my $c = $4 ;
      my $sep = $5;
      my $pv = $c;
      $nv = trim($nv);
      push @$values,$nv if $nv;
     
      $pv =~ s/(\+|\(|\)|\.)/\\$1/g;
      $ntimes =~ s/(\*)/\\$1/g;
      $all =~ s/($nv$ntimes$pv$sep)?//;
      $ok = ! $sep && $c eq ',' ?  0 : 1;
      push @$values,(trim($c))x($n) if $ok ;
  }
  return $values 
}


sub trim {
  my $s = shift;
  $s =~ s/^\s+//;
  $s =~ s/\s+$//;
  return $s
}

1;

__DATA__


=head1 NAME

Fortran::F90Format - Read and write data using FORTRAN 90 I/0 formatting

=head1 SYNOPSYS

use Fortran::F90Format;

my $fmt = Fortran::F90Format->new(fmt=>"1x,a4,1x,i4,4(1x,i2)1x,f5.2");

my $input_string = ' STRG 1234  1  2  3  4  5    1000001.00';

my @input_values = $fmt->read( $input_string );

my @output_values = @input_values; 

my $output_string = $fmt->write(@output_values);

print $output_string;     # prints: " STRG 1234  1  2  3  4  5.00\n"

=head1 DESCRIPTION

F90Format implements basic I/O formatting based on the Digital 
FORTRAN 90 I/O formatting specifications (April 1997).
F90Format provides a consistent way of reading and writing fixed
length fields in tabular data, by using the same syntax for reading
and writing. The same task in Perl requires synchronizing the format 
strings in sprintf and pack/unpack functions. 
Although this is possible, sprintf sometimes exceeds the length of the 
desired field. This 'feature' of sprintf combined with the fact that 
pack/unpack never go beyond the desired field width may eventually result 
in corrupting the data table.

=head1 FORMAT SPECIFICATIONS
 
 A format specification takes the following form:

=over 1

=item    '(I<format-list>)'

=item     'I<format-list>' (extension)

=back 

=head2   Format List 

Is a list of one of more I<Data Edit Descriptors>, separated by commas. 
As an  extension F90Format allows ommitting the external parenthesis. 

=head2  Data Edit Descriptors
        
DED transfer or convert data to or from the internal representation.
DED take the following form:

=over 1

B<[r]C>

B<[r]Cw>

B<[r]Cw.m>

B<[r]Cw.d>

B<[r]Cw.d[Ee]>


=item B<r>

repeat r times

=item B<C>

Descriptor code, is one of the following ones: B<A,I,D,E,G,H,X>

=item B<w>

Total number of characters in the field

=item B<.>

Dot to indicate that a decimal digits, or minimum digits field follows.

=item B<d> 

Number of digits to the right of the decimal point.

=item B<m>

Minimum number of digits that must be in the field.

=item B<E>

Identifies exponent field

=item B<e> 

Number of digits in the exponent.

=back

=over 1

=head2 Summary of Data Edit Descriptors

=item B<A>[I<w>]


Transfers characters or Hollerith values.


   
=item B<I>w[.m]

Transfers integer values.

=item B<D>w.d

Transfers real values with the letter D in the exponent.

=item B<E>w.d[Ee]

Transfers real values with the letter E in the exponent. 

=item B<F>w.d 

Transfer real values with no exponent.

=item B<G>w.d[Ee]

Transfer values of all intrinsic types.

=item nB<H>ch[ch...]

Transfers n characters (ch) following the B<H Data Edit Descriptor>

=item nB<X>

Skips n character positions to the right at the current position of 
the I/O.

=item B<'ch[ch..]'> or B<"ch[ch...]">

Transfers the characters between the delimiters B<'> or B<">.

=back 

=head1 METHODS

=over

=item new

  my $fmt = Fortran::F90Format->new( fmt => $format_string );

  Creates a new object. 

=item read

  @output_values = $fmt->read( $input_string );

  Reads from a string and returns the values extracted from it to an
  array.

=item write

  my $output_string = $fmt->write( @values );
  
  Writes formatted values from the input array into a string.

=back

=head1 VERSION

0.40

=head1 SEE ALSO 

Fortran::Format 


=head1 AUTHOR

Victor Marcelo Santillan E<lt>vms@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2006 Victor Marcelo Santillan. All rights reserved. 
This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut


