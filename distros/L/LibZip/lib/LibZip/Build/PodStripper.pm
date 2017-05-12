#############################################################################
## Name:        PodStripper.pm
## Purpose:     LibZip::Build::PodStripper
## Author:      Graciliano M. P.
## Modified by:
## Created:     2004-06-06
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package LibZip::Build::PodStripper ;
use 5.006 ;

use strict qw(vars) ;
use vars qw($VERSION) ;

$VERSION = '0.01' ;

use Pod::Stripper ;

use vars qw(@ISA) ;
@ISA = qw(Pod::Stripper) ;

#########
# PARSE #
#########

sub parse {
  my $this = shift ;
  my $file = shift ;

  local(*PODIN , *PODOUT) ;
  
  my $output ;
  tie(*PODOUT => 'LibZip::Build::PodStripper::TiehHandler' , \$output) ;
  
  $this->{OUTPUT} = \$output ;
  $this->{TIEDOUTPUT} = \*PODOUT ;
  
  my $io ;
  if ( ref($file) eq 'GLOB' ) { $io = $file ;}
  elsif ( $file =~ /[\r\n]/s && !-e $file ) {
    tie(*PODIN => 'LibZip::Build::PodStripper::TiehHandler' , \$file) ;
    $io = \*PODIN ;
  }

  if ( $io ) { $this->parse_from_filehandle(\*PODIN , \*PODOUT) ; $file = '<DATA>' ;}
  else { $this->parse_from_file($file , \*PODOUT) ;}

  delete $this->{TIEDOUTPUT} ;
  delete $this->{OUTPUT} ;

  close(PODOUT) ;
  untie (*PODOUT) ;
  close(PODIN) ;
  untie (*PODIN) ;

  return( $output ) ;
}

###########################################
# LIBZIP::BUILD::PODSTRIPPER::TIEHHANDLER #
###########################################

package LibZip::Build::PodStripper::TiehHandler ;

use strict qw(vars) ;

use vars qw($VERSION @ISA) ;
$VERSION = '0.01' ;

sub TIEHANDLE {
  my $class = shift ;
  my $scalar = shift ;
  return bless({SCALAR => $scalar} , $class) ;
}

sub PRINT {
  my $this = shift ;
  ${ $this->{SCALAR} } .= join("", (@_[0..$#_]) ) ;
  return 1 ;
}

sub PRINTF { &PRINT($_[0],sprintf($_[1],@_[2..$#_])) ;}

sub READ      { shift->read(@_) }
sub READLINE  { wantarray ? shift->getlines(@_) : shift->getline(@_) }

sub GETC      {
  my $this = shift;
  return undef if $this->EOF ;
  substr( ${ $this->{SCALAR} } , $this->{POS}++ , 1) ;
}

sub SEEK {
  my $this = shift ;
  my ($pos, $whence) = @_ ;

  my $eofpos = length( ${ $this->{SCALAR} } ) ;

  if    ($whence == 0) { $this->{POS} = $pos }             ### SEEK_SET
  elsif ($whence == 1) { $this->{POS} += $pos }            ### SEEK_CUR
  elsif ($whence == 2) { $this->{POS} = $eofpos + $pos}    ### SEEK_END

  if ($this->{POS} < 0)       { $this->{POS} = 0 }
  if ($this->{POS} > $eofpos) { $this->{POS} = $eofpos }
  
  1 ;
}

sub TELL { $_[0]->{POS} ;}

sub EOF {
  my $this = shift ;
  ( $this->{POS} >= length( ${ $this->{SCALAR} } ) )
}

sub WRITE {}

sub FILENO {}

sub CLOSE {}
sub UNTIE {}
sub DESTROY {}

##
## From IO::Scalar:
##

sub getline {
  my $this = shift;
  return undef if $this->EOF ;

  my $sr = $this->{SCALAR} ;
  my $i  = $this->{POS} ;

  ### Case 1: $/ is undef: slurp all...
  if (!defined($/)) {
    $this->{POS} = length $$sr ;
    return substr($$sr, $i) ;
  }

  ### Case 2: $/ is "\n": zoom zoom zoom...
  elsif ($/ eq "\012") {
    ### Seek ahead for "\n"... yes, this really is faster than regexps.
    my $len = length($$sr);
    for (; $i < $len; ++$i) {
      last if ord (substr ($$sr, $i, 1)) == 10;
    }

    ### Extract the line:
    my $line;
    if ($i < $len) {                ### We found a "\n":
      $line = substr ($$sr, $this->{POS}, $i - $this->{POS} + 1);
      $this->{POS} = $i+1;            ### Remember where we finished up.
    }
    else {                          ### No "\n"; slurp the remainder:
      $line = substr ($$sr, $this->{POS}, $i - $this->{POS});
      $this->{POS} = $len;
    }
    return $line;
  }

  ### Case 3: $/ is ref to int. Do fixed-size records.
  ###        (Thanks to Dominique Quatravaux.)
  elsif (ref($/)) {
    my $len = length($$sr);
    my $i = ${$/} + 0;
    my $line = substr ($$sr, $this->{POS}, $i);
    $this->{POS} += $i;
    $this->{POS} = $len if ($this->{POS} > $len);
    return $line;
  }

  ### Case 4: $/ is either "" (paragraphs) or something weird...
  ###         This is Graham's general-purpose stuff, which might be
  ###         a tad slower than Case 2 for typical data, because
  ###         of the regexps.
  else {
    pos($$sr) = $i;

	### If in paragraph mode, skip leading lines (and update i!):
    length($/) or (($$sr =~ m/\G\n*/g) and ($i = pos($$sr))) ;

    ### If we see the separator in the buffer ahead...
    if ( length($/) ? $$sr =~ m,\Q$/\E,g          ###   (ordinary sep) TBD: precomp!
                    : $$sr =~ m,\n\n,g            ###   (a paragraph)
       ) {
           $this->{POS} = pos $$sr;
           return substr($$sr, $i, $this->{POS}-$i);
    }
    ### Else if no separator remains, just slurp the rest:
    else {
      $this->{POS} = length $$sr;
      return substr($$sr, $i);
    }
  }
}

sub getlines {
  my $this = shift ;
  my ($line, @lines) ;
  push @lines, $line while (defined($line = $this->getline)) ;
  @lines ;
}

#######
# END #
#######

1;


