#############################################################################
## Name:        Parser.pm
## Purpose:     HDB::Parser
## Author:      Graciliano M. P.
## Modified by:
## Created:     15/01/2003
## RCS-ID:      
## Copyright:   (c) 2002 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package HDB::Parser ;
our $VERSION = '1.0' ;

use strict qw(vars) ;
no warnings ;

my %CACHE ;

my @STR_LYB = qw(a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) ;

###############
# PARSE_WHERE #
###############

#use HDB::CORE ;
#print Parse_Where(['id == ?' , \'or' , qw(1 2 3)] , {} , 1) ;

sub Parse_Where {
  my ( $where , $this , $nowhere ) = @_ ;
  
  if ($where eq '') { return ;}
  
  my @where = &HDB::CORE::parse_ref($where) ;
  
  if (ref($where) && $#where <= 1 && $where[1] eq '') { return( $nowhere ? $where[0] : "WHERE( $where[0] )" ) ;}
  elsif (ref($where) eq 'ARRAY' && $#where >= 1) {
    my $cond = shift @where ;
    
    my $op = ref $where[0] eq 'ARRAY' ? @{ shift(@where) }[0] : (ref $where[0] eq 'SCALAR' ? ${ shift(@where) } : 'OR' ) ;

    $op =~ s/\s+//gs ;
    $op =~ s/^(?:&&?|and)$/AND/i ;
    $op =~ s/^(?:\|\|?|or)$/OR/i ;
    $op = 'OR' if $op !~ /^(?:AND|OR)$/ ;
    
    my $parser ;
          
    if ( $cond =~ /^\s*\(?\s*\?\s*\)?\s*$/s ) {
      foreach my $where_i ( @where ) {
        $where_i = Parse_Where($where_i,$this,1) ;
      }
      $parser = '(' . join(") $op (", @where) . ')' ;
    }
    else {
      $cond = '('. &Parse_Where($cond,$this,1) . ')' ;
      
      foreach my $where_i ( @where ) {
        my $val = &Value_Quote($where_i) ;
        $parser .= " $op " if $parser ne '' ;
        my $cond_new = $cond ;
        $cond_new =~ s/["']\?["']/$val/gs ;
        $parser .= $cond_new ;
      }
    }

    if ($nowhere) { return($parser) ;}
    else { return( "WHERE( $parser )" ) ;}
  }
  
  my $sql_id = $this ? "$this->{SQL}{REGEXP},$this->{SQL}{LIKE}" : '' ;
  my $where_id = "$sql_id#$where" ;
  
  if ( defined $CACHE{$where_id} ) { return( $nowhere ? $CACHE{$where_id} : "WHERE( $CACHE{$where_id} )" ) ;}
  
  my ($syntax,@quotes) = &Parse_Quotes($where) ;
  
  my @blocks = &Parse_Blocks($syntax) ;
  &Filter_Blocks( \@blocks , \@quotes , $this ) ;
  
  my ($parse,$lnk_last) ;
  
  foreach my $blocks_i ( @blocks ) {
    my @cond = @$blocks_i ;
    $parse .= " " if $parse =~ /\S$/s ;
    
    if ( $cond[0] =~ /^(?:AND|OR)$/ ) {
      my $add = shift @cond ;
      $parse .= $add ; $lnk_last = $add ;
    }
    
    my $cond = join(" ", @cond) ;
    
    $parse .= " " if ($cond ne '' && $parse =~ /\S$/s) ;
    
    if ($cond =~ /^\s*(?:AND|OR)\s*$/i) { $parse .= $cond ; $lnk_last = $cond ;}
    elsif ($cond =~ /\S/s) {
      if ($lnk_last !~ /\w/ && $parse =~ /\S/) { $parse .= "AND " ;}
      if ($cond =~ /\s(?:AND|OR)\s/) { $parse .= "($cond)" ;}
      else { $parse .= $cond ;}
      $lnk_last = undef ;
    }
  }

  $parse =~ s/%q_(\d+)%/$quotes[$1]/gs ;

  CLEAN_CACHE() ;

  $CACHE{$where_id} = $parse ;

  $parse = "WHERE( $parse )" if !$nowhere ;
  return( $parse ) ;
}

####################
# FILTER_CONDITION #
####################

sub Filter_Condition {
  my ( $string , $quotes , $this ) = @_ ;
  
  $string =~ s/\s+/ /gs ;
  $string =~ s/^\s+//g ;
  $string =~ s/\s+$//g ;
  
  my $split_mark = '%x%' ;
  while($string =~ /\Q$split_mark\E/s) { substr($split_mark,-2,1) .= &Rand_Str ;}
  
  $string .= ' ' ;
  $string =~ s/([^\w&]|^)(\|\||&&?|and|or)([^\w&])/$1$split_mark$2$split_mark$3/gi ;
  
  my @conds = split(/\Q$split_mark\E/s , $string) ;
  my @conds_ok ;
  
  foreach my $conds_i ( @conds ) {
    if ($conds_i !~ /\S/s) { next ;}
    if    ($conds_i =~ /^\s*(?:and|&&?)\s*$/s) { $conds_i = 'AND' ;}
    elsif ($conds_i =~ /^\s*(?:or|\|\|)\s*$/s) { $conds_i = 'OR' ;}
    else {
      my ($col,$cond,$val) = ( $conds_i =~ /^\s*(.*?)\s*(<>|!=|!~|=~|<=|>=|=>|=<|==?|>|<|\s+(?:eq|ne))\s*(.*)/ ) ;
      $cond =~ s/\s//s ;
      $val =~ s/\s*$//s ;

      if    ($cond =~ /^(?:!=|<>|ne)$/s) { $cond = '<>' ;}
      elsif ($cond =~ /^(?:<=|=<)$/s)    { $cond = '<=' ;}
      elsif ($cond =~ /^(?:>=|=>)$/s)    { $cond = '>=' ;}
      elsif ($cond =~ /^>$/s)            { $cond = '>' ;}
      elsif ($cond =~ /^<$/s)            { $cond = '<' ;}
      elsif ($cond =~ /^=~$/s)           { $cond = 'REGEXP' ;}
      elsif ($cond =~ /^!~$/s)           { $cond = 'NOT REGEXP' ;}
      elsif ($cond =~ /^(?:==?|eq)$/s)   { $cond = '=' ;}
      
      if ($cond =~ /REGEXP/ && $this && !$this->{SQL}{REGEXP} ) {
        if ( $this->{SQL}{LIKE} ) {
          ($cond , $val) = &Parse_REGEX_2_LIKE($cond , $val , $quotes) ;
          $this->Error("Can't use REGEXP on SQL syntax on module $this->{name}!!! Changing 'REGEXP' to 'LIKE' on syntax." , 1) ;
        }
        else {
          $this->Error("Can't use REGEXP on SQL syntax on module $this->{name}!!! Changing 'REGEXP' to '=' on syntax." , 1) ;
          $cond = '=' ;
        }
      }
      
      $val = &Value_Quote($val,$quotes) ;
      
      $conds_i = "$col $cond $val" ;
    }
    
    push(@conds_ok , $conds_i) ;
  }
  
  if ( wantarray ) { return( @conds_ok ) ;}
  else { return( join (" ", @conds_ok) ) ;}
}

#################
# FILTER_BLOCKS #
#################

sub Filter_Blocks {
  my ( $blk_ref , $quotes , $this ) = @_ ;
  
  for my $i (0..$#$blk_ref) {
    if ( ref( $$blk_ref[$i] ) eq 'ARRAY' ) { &Filter_Blocks( $$blk_ref[$i] ) ; next ;}
    my @cond = Filter_Condition( $$blk_ref[$i] , $quotes , $this ) ;
    $$blk_ref[$i] = \@cond ;
    #print ">> $$blk_ref[$i]\n" ;
  }
  
  return( $blk_ref ) ;
}

#print Parse_Blocks(q`aaa (bbb) ccc ( ddd (eee) fff ) ggg `) ;
#@blks = Parse_Blocks(q`col = and (col = x && col != y)`) ;
#print join ("\n", @blks) ;

################
# PARSE_BLOCKS #
################

sub Parse_Blocks {
  my ( $string ) = @_ ;

  my (@blocks,%b) ;
  
  while( $string =~ /(.*?)([\(\)])/gs ) {
    my $init .= $1 ;
    my $blk = $2 ;
    
    if ($blk eq '(') {
      if (! $b{o}) {
        my ($cond,$lnk) = ( $init =~ /(.*?[^\w&\|])\s*(\|\||&&?|and|or|)\s*$/gsi );
        push(@blocks , $cond) ;
        push(@blocks , $lnk) ;
      }
      $b{o}++ ;
      if ($b{o} > 1) { $b{d} .= $init ;}
      $b{d} .= $blk ;
    }
    elsif ($blk eq ')') {
      $b{d} .= $init . $blk ;
      $b{o}-- ;
      if ($b{o} <= 0) {
        $b{d} =~ s/^\(//gs ;
        $b{d} =~ s/\)$//gs ;
        
        my $block ;
        if ($b{d} =~ /\(.*?\)/s) {
          $block = [&Parse_Blocks( $b{d} )] ;
        }
        else { $block = $b{d} ;}
        
        push(@blocks , $block) ;
        $b{d} = undef ;        
      }
    }
  }
  
  if ( $string =~ /.*[\(\)](.*?)$/s ) { push(@blocks , $1) ;}
  else { push(@blocks , $string) ;}

  return( @blocks ) ;
}

#Parse_Quotes(q`aaa "b b b" ccc "\\\\" ddd \\\\ eee "f 'f' \"f\" f" ggg %bb`) ;
#Parse_Quotes(q`'x"x\''`) ;

################
# PARSE_QUOTES #
################

sub Parse_Quotes {
  my $string = $_[0] ;
  
  my ($string_ok,@quotes,%q) ;

  my $bb_mark = '%bb' ;
  while($string =~ /\Q$bb_mark\E/s) { $bb_mark .= &Rand_Str ;}

  $string =~ s/\\\\/$bb_mark/gs ;
  
  while( $string =~ /^(.*?(?:(?!\\).|))(['"])(.*)/s ) {
    my $init .= $1 ;
    my $quote = $2 ;
    $string = $3 ;
    
    if ($init =~ /\\$/) {
      $init .= $quote ;
      $quote = '' ;
    }
    
    if (! $q{o}) {
      $q{o}++ ;
      $q{q} = $quote ;
      $q{d} = undef ;
      $string_ok .= $init ;
      
      if (substr($string,0,1) eq $quote) {
        $q{o} = 0 ;
        push(@quotes , "$q{q}$q{q}") ;
        $string_ok .= "%q_$#quotes%" ;
        substr($string,0,1) = '' ;
      }
    }
    else {
      $q{d} .= $init ;
      if ($quote eq $q{q}) {
        $q{o} = 0 ;
        push(@quotes , "$q{q}$q{d}$q{q}") ;
        $string_ok .= "%q_$#quotes%" ;
      }
      else { $q{d} .= $quote ;}
    }
  }
  
  $string_ok .= $string ;
  $string_ok =~ s/$bb_mark/\\\\/gs ;
  
  #substr($string_ok,0,1) = '' ;
  #substr($string_ok,-1) = '' ;
  
  foreach my $quotes_i ( @quotes ) { $quotes_i =~ s/$bb_mark/\\\\/gs ;}
  
  #$string_ok =~ s/%q_(\d+)%/$quotes[$1]/gs ;
  
  #print "$string_ok <<@quotes>>\n" ;
  
  return( $string_ok , @quotes ) ;
}

###############
# VALUE_QUOTE #
###############

sub Value_Quote {
  my ( $val , $quotes ) = @_ ;
  
  $val =~ s/^\s+//gs ;
  $val =~ s/\s+$//gs ;
  
  if ($val !~ /^[\-\+]?(\d+|\d+\.\d+)$/s && (!$quotes || $val !~ /^%q_\d+%$/s) && $val !~ /^(?:NULL)$/si && $val ne '') {
    $val =~ s/%q_(\d+)%/$$quotes[$1]/gs if $quotes ;

    substr($val , 0 , 0) = ' ' ;
            
    $val = &Parse_REGEXP($val) ;

    $val =~ s/(?!\\)(.)"/$1\\"/gs ;
    substr($val , 0 , 1) = '' ;
    
    $val = qq`"$val"` ;
  }
  
  if ($val eq '') { $val = 'NULL' ;}

  return( $val ) ;
}

################
# PARSE_REGEXP #
################

sub Parse_REGEXP {
  my ( $string ) = @_ ;
  
  my $mark1 = '%box_o%' ;
  while($string =~ /\Q$mark1\E/s) { substr($mark1,-2,1) .= &Rand_Str ;}
  
  my $mark2 = '%box_c%' ;
  while($string =~ /\Q$mark2\E/s) { substr($mark2,-2,1) .= &Rand_Str ;}
  
  $string =~ s/\\\[/$mark1/gs ;
  $string =~ s/\\\]/$mark2/gs ;
  
  $string =~ s/(?!\\)(.)\\w/$1\[a-zA-Z0-9]/gs ;
  $string =~ s/(?!\\)(.)\\W/$1\[^a-zA-Z0-9]/gs ;
  $string =~ s/(?!\\)(.)\\d/$1\[0-9]/gs ;
  $string =~ s/(?!\\)(.)\\D/$1\[^0-9]/gs ;
  $string =~ s/(?!\\)(.)\\s/$1\[ \t\n\r]/gs ;
  $string =~ s/(?!\\)(.)\\S/$1\[^ \t\n\r]/gs ;

  while($string =~ /\[([^\[]*)\[([^\]]*)\]/gs) { $string =~ s/\[([^\[]*)\[([^\]]*)\]/\[$1$2/gs ;}

  $string =~ s/$mark1/\\\[/gs ;
  $string =~ s/$mark2/\\\]/gs ;

  return( $string ) ;
}

######################
# PARSE_REGEX_2_LIKE #
######################

sub Parse_REGEX_2_LIKE {
  my ( $cond , $regex , $quotes) = @_ ;
  
  $regex =~ s/%q_(\d+)%/$$quotes[$1]/gs if $quotes ;
  
  if    ($regex =~ /^"(.*?)"$/) { $regex = $1 ;}
  elsif ($regex =~ /^'(.*?)'$/) { $regex = $1 ;}
  
  if ($cond =~ /not/i ) { $cond = 'NOT LIKE' ;}
  else { $cond = 'LIKE' ;}
  
  if ( $regex =~ /^\^/ && $regex =~ /\$$/) {
    $regex =~ s/^\^// ;
    $regex =~ s/\$$// ;
  }
  elsif ( $regex =~ /^\^/) {
    $regex =~ s/^\^// ;
    $regex .= '%' ;
  }
  elsif ( $regex =~ /\$$/) {
    $regex =~ s/\$$// ;
    $regex = "%$regex" ;
  }
  else { $regex = "%$regex%" ;}
  
  $regex =~ s/\./_/gs ;
  
  return( $cond , $regex ) ;
}

############
# RAND_STR #
############

sub Rand_Str {
  return( @STR_LYB[rand(@STR_LYB)] ) ;
}

#####################
# FILTER_NULL_BYTES #
#####################

sub filter_null_bytes {
  return if $_[0] !~ /\0/s ;
  
  my $place_holder = "\1\2\1" ;
  my $x = 1 ;
  while( $_[0] =~ /\Q$place_holder\E/s ) {
    $place_holder = "\1" . ("\2" x ++$x) . "\1" ;
  }
  
  $_[0] =~ s/\0/$place_holder/gs ;
  $_[0] =~ s/^/$place_holder:/s ;
}

#######################
# UNFILTER_NULL_BYTES #
#######################

sub unfilter_null_bytes {
  my $b1 = "\1" ;
  my $b2 = "\2" ;
  return if $_[0] !~ /^($b1$b2+$b1):/s ;
  my $place_holder = $1 ;
  
  $_[0] =~ s/^\Q$place_holder\E://s ;
  $_[0] =~ s/\Q$place_holder\E/\0/gs ;
}

###############
# CLEAN_CACHE #
###############

sub CLEAN_CACHE {
  my @keys = keys %CACHE ;
  
  if ( @keys > 1000 ) {
    while( @keys > 500 ) {
      for(1..100) {
        delete $CACHE{ $keys[ rand(@keys) ] } ;
      }
      @keys = keys %CACHE ;
    }
  }
  
}

#########
# RESET #
#########

sub RESET {
  %CACHE = () ;
}

#######
# END #
#######

1;


