# $Id: Hyphenate.pm,v 1.5 2002/07/23 17:45:23 engin Exp $
# Copyright © 2002 Engin Gunduz.  All Rights Reserved.

package Lingua::TR::Hyphenate;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lingua::TR::Hyphenate ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';

# An array and a hash for vowels. They will be used in
# FSM implementation.
my @sesliler=('a','â','e','ý','i','o','ö','u','ü',
              'A',    'E','I','Ý','O','Ö','U','Ü');
my %sesliler=('a'=>1,'â'=>1,'e'=>1,'ý'=>1,'i'=>1,'o'=>1,'ö'=>1,'u'=>1,'ü'=>1,
              'A'=>1,       'E'=>1,'I'=>1,'Ý'=>1,'O'=>1,'Ö'=>1,'U'=>1,'Ü'=>1);



# sub hyphenate takes a word to be hyphenated.
# returns hyphenated word or syllable array, or
# undef if the word can't be hyphenated.
sub hyphenate{
  my $string = shift;
  my $attr = shift;
  my $separator = '.'; # default separator
  if(ref $attr) {
    if(defined($attr->{Separator})){
      $separator = $attr->{Separator};
    }
  }

  my @harfler= split('',$string);
  my @heceler = ();
  my $pos = 0;  

  # Here is the implementation of the finite state machine
  my $state = 'STATE_NULL';
  while($pos <= length($string)){
    if($state eq 'STATE_NULL'){
      if(defined($sesliler{$harfler[$pos]})){
        $pos++; 
        $state = 'STATE_V';
        if($pos == length($string)){
          push @heceler, $harfler[$pos-1];
          last;
        }
      }else{
        $pos++;
        $state = 'STATE_C';  
        if($pos == length($string)){
          #print STDERR "impos: $string\n";
          return undef;
        }
      }
    next;
    }
    if($state eq 'STATE_C'){
      if($sesliler{$harfler[$pos]}){
        $pos++; 
        $state = 'STATE_CV';        
        if($pos == length($string)){
          push @heceler, $harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }else{
        $pos++;
        $state = 'STATE_CC';  
        if($pos == length($string)){
          #print STDERR "impos: $string\n";
          return undef;
        }
      }
    next;
    }
    if($state eq 'STATE_CC'){
      if($sesliler{$harfler[$pos]}){
        $pos++; 
        $state = 'STATE_CCV';
        if($pos == length($string)){
          push @heceler, $harfler[$pos-3].$harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }else{
        $pos++;
        #print STDERR "impos: $string\n";
        return undef;  
      }
    next;
    }
    if($state eq 'STATE_CCV'){
      if($sesliler{$harfler[$pos]}){
        $pos++; 
        $state = 'STATE_V';
        push @heceler, $harfler[$pos-4].$harfler[$pos-3].$harfler[$pos-2];
        if($pos == length($string)){
          push @heceler, $harfler[$pos-1];
          last;
        }
      }else{
        $pos++;
        $state = 'STATE_CCVC';
        if($pos == length($string)){
          push @heceler, $harfler[$pos-4].$harfler[$pos-3].$harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }
    next;
    }
    if($state eq 'STATE_CCVC'){
      if($sesliler{$harfler[$pos]}){
        $pos++; 
        $state = 'STATE_CV';
        push @heceler, $harfler[$pos-5].$harfler[$pos-4].$harfler[$pos-3];
        if($pos == length($string)){
          push @heceler, $harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }else{
        $pos++;
        $state = 'STATE_CCVCC';
        if($pos == length($string)){
          push @heceler, $harfler[$pos-5].$harfler[$pos-4].$harfler[$pos-3].$harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }
    next;
    }
    if($state eq 'STATE_CCVCC'){
      if($sesliler{$harfler[$pos]}){
        $pos++; 
        $state = 'STATE_CV';
        push @heceler, $harfler[$pos-6].$harfler[$pos-5].$harfler[$pos-4].$harfler[$pos-3];
        if($pos == length($string)){
          push @heceler, $harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }else{
        $pos++;
        $state = 'STATE_CCVCCC';
        if($pos == length($string)){
          #print STDERR "impos: $string\n";
          return undef;
        }
      }
    next;
    }
    if($state eq 'STATE_CCVCCC'){
      if($sesliler{$harfler[$pos]}){
        $pos++; 
        $state = 'STATE_CV';
        push @heceler, $harfler[$pos-7].$harfler[$pos-6].$harfler[$pos-5].$harfler[$pos-4].$harfler[$pos-3];
        if($pos == length($string)){
          push @heceler, $harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }else{
        $pos++;
        $state = 'STATE_CC';
        push @heceler, $harfler[$pos-7].$harfler[$pos-6].$harfler[$pos-5].$harfler[$pos-4].$harfler[$pos-3];
        if($pos == length($string)){
          #print STDERR "impos: $string\n";
          return undef;
        }
      }
    next;
    }
    if($state eq 'STATE_CV'){
      if($sesliler{$harfler[$pos]}){
        $pos++; 
        $state = 'STATE_V';
        push @heceler, $harfler[$pos-3].$harfler[$pos-2];
        if($pos == length($string)){
          push @heceler, $harfler[$pos-1];
          last;
        }
      }else{
        $pos++;
        $state = 'STATE_CVC';
        if($pos == length($string)){
          push @heceler, $harfler[$pos-3].$harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }
    next;
    }
    if($state eq 'STATE_CVC'){
      #print STDERR "\$pos = $pos\n";
      if($sesliler{$harfler[$pos]}){
        $pos++; 
        $state = 'STATE_CV';
        push @heceler, $harfler[$pos-4].$harfler[$pos-3];
        if($pos == length($string)){
          push @heceler, $harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }else{
        $pos++;
        $state = 'STATE_CVCC';
        if($pos == length($string)){
          push @heceler, $harfler[$pos-4].$harfler[$pos-3].$harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }
    next;
    }
    if($state eq 'STATE_CVCC'){
      if($sesliler{$harfler[$pos]}){
        $pos++; 
        $state = 'STATE_CV';
        push @heceler, $harfler[$pos-5].$harfler[$pos-4].$harfler[$pos-3];
        if($pos == length($string)){
          push @heceler, $harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }else{
        $pos++;
        $state = 'STATE_CVCCC';
        if($pos == length($string)){
          #print STDERR "impos: $string\n";
          return undef;
        }
      }
    next;
    }
    if($state eq 'STATE_CVCCC'){
      if($sesliler{$harfler[$pos]}){
        $pos++; 
        $state = 'STATE_CV';
        push @heceler, $harfler[$pos-6].$harfler[$pos-5].$harfler[$pos-4].$harfler[$pos-3];
        if($pos == length($string)){
          push @heceler, $harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }else{
        $pos++;
        #print STDERR "impos: $string\n";
        return undef;  
      }
    next;
    }
    if($state eq 'STATE_V'){
      if($sesliler{$harfler[$pos]}){
        $pos++; 
        $state = 'STATE_V';
        push @heceler, $harfler[$pos-2];
        if($pos == length($string)){
          push @heceler, $harfler[$pos-1];
          last;
        }
      }else{
        $pos++;
        $state = 'STATE_VC';
        if($pos == length($string)){
          push @heceler, $harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }
    next;
    }
    if($state eq 'STATE_VC'){
      if($sesliler{$harfler[$pos]}){
        $pos++; 
        $state = 'STATE_CV';
        push @heceler, $harfler[$pos-3];
        if($pos == length($string)){
          push @heceler, $harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }else{
        $pos++;
        $state = 'STATE_VCC';
        if($pos == length($string)){
          push @heceler, $harfler[$pos-3].$harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }
    next;
    }
    if($state eq 'STATE_VCC'){
      if($sesliler{$harfler[$pos]}){
        $pos++; 
        $state = 'STATE_CV';
        push @heceler, $harfler[$pos-4].$harfler[$pos-3];
        if($pos == length($string)){
          push @heceler, $harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }else{
        $pos++;
        $state = 'STATE_VCCC';
        if($pos == length($string)){
          #print STDERR "impos: $string\n";
          return undef;
        }
      }
    next;
    }
    if($state eq 'STATE_VCCC'){
      if($sesliler{$harfler[$pos]}){
        $pos++; 
        $state = 'STATE_CV';
        push @heceler, $harfler[$pos-5].$harfler[$pos-4].$harfler[$pos-3];
        if($pos == length($string)){
          push @heceler, $harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }else{
        $pos++;
        $state = 'STATE_VCCCC';
        if($pos == length($string)){
          #print STDERR "impos: $string\n";
          return undef;
        }
      }
    next;
    }
    if($state eq 'STATE_VCCCC'){
      if($sesliler{$harfler[$pos]}){
        $pos++; 
        $state = 'STATE_CCV';
        push @heceler, $harfler[$pos-6].$harfler[$pos-5].$harfler[$pos-4];
        if($pos == length($string)){
          push @heceler, $harfler[$pos-3].$harfler[$pos-2].$harfler[$pos-1];
          last;
        }
      }else{
        $pos++;
        #print STDERR "impos: $string\n";
        return undef;  
      }
    next;
    }
  }

  # if we were called in list context, return the syllable list.
  # Otherwise, first convert to a string.
  if(wantarray){
  
    return @heceler;

  }else{

    return join($separator,@heceler);

  }
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Lingua::TR::Hyphenate - A hyphenator for Turkish.

=head1 SYNOPSIS

  use Lingua::TR::Hyphenate;

  my @syllables = Lingua::TR::Hyphenate::hyphenate('bilgisayar');
  # OR,
  #@syllables = Lingua::TR::Hyphenate::hyphenate('bilgisayar',
  #    {Separator=>'.'});
  if(@syllables){

    print "The hyphenated word is: ", join('-',@syllables), "\n";

  }else{

    print "This word cannot be hyphenated.\n";

  }

  my $hyphenated = Lingua::TR::Hyphenate::hyphenate('bilgisayar', 
      {Separator=>'\-'});
  if(defined($hyphenated)){
  
    print "The hyphenated word is: $hyphenated\n";

  }else{

    print "This word cannot be hyphenated.\n";

  }


=head1 DESCRIPTION 

This module implements a deterministic hyphenator for Turkish.

The only subroutine, hyphenate, takes a word as its input. Optionally,
the separator can be given as an attribute to hyphenate subroutine.
The default separator is a dot ('.'). For example, if the result is
to be given to LaTeX, then '\-' can be used as the separator. 
The separator is not used if the subroutine is called in list context. 

=head1 RETURN VALUE

The hyphenate() method returns the hyphenated word, the segments
(hyphens, or syllables) separated by dots ('.') (or any string
given as separator) in scalar context, and returns the array of 
syllables in list context. If hyphenation is not possible for the 
given word, then it returns undef.

=head1 WARNINGS

Currently only ISO8859-9 input is accepted.

=head1 BUGS

No sanity check is made in the argument of hyphenator subroutine.

Some loanwords that contain 'r' are hyphenated incorrectly, such as
"antrparantez" (While it must be hyphenated as "antr-pa-ran-tez," the
module hyphenates it as "ant-rpa-ran-tez").

=head1 AUTHOR

Lingua::TR::Hyphenate was developed by Engin Gunduz <e.gunduz@computer.org>.

=head1 SEE ALSO

L<perl>.

=cut
