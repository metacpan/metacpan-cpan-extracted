#
# OO methods that calculates #B(n) on Thompson group F
#
# Author: Roberto Alamos Moreno <ralamosm@cpan.org>
#
# Copyright (c) 2004 Roberto Alamos Moreno. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# November 2004. Antofagasta, Chile.
#
package Math::Group::Thompson;

$VERSION = '0.96';

use strict;
use warnings;

use FileHandle;

=head1 NAME

Math::Group::Thompson - OO methods that calculates the cardinality
of the ball of radius 'n' of Thompson group F

=head1 SYNOPSIS

  use Math::Group::Thompson;

  my $F = Math::Group::Thompson->new( VERBOSE => 0 );
  my $card = $F->cardBn(3,'');

  print "#B(3) = $card\n";

=head1 DESCRIPTION

The Math::Group::Thompson module provides objetct oriented methods 
that calculates the cardinality of the ball of radius 'n'
of Thompson group F.

This module uses the presentation of F

F = < A,B | [AB^(-1),A^(-1)BA] = [AB^(-1),A^(-2)BA^2] = e >

where A,B are formal symbols, [x,y] is the usual commutator and e
is the identity element of F.

[x,y] = xyx^(-1)y^(-1)

This means that for every g in F, g can be written as word

g = a_{1}a_{2} ... a_{n}

where all the a_{i} are A,B,A^(-1) or B^(-1) for all i <= n.
Internally, Math::Group::Thompson representates A,B,A^(-1),B^(-1) as
A,B,C,D respectively.

Considering the set S = { A,B,A^(-1),B^(-1) } as a generator set for F.
One can define the length function L, as

L(g) = min{ n | g can be written as a word with n elements of S }

We have to define L(e) = 0

With this definition, the ball of radius n of F, can be defined as

B(n) = { g in F | L(g) <= n }

So, what this module do is to calculate #B(n) or #(gB(n) - B(n)),
where g in F, depending on what you need. Note that by definition of S,

B(n+1) = (AB(n)-B(n))U(BB(n)-B(n))U(CB(n)-B(n))U(DB(n)-B(n)) U B(n)

so

#B(n+1) = #(AB(n)-B(n))+#(BB(n)-B(n))+#(CB(n)-B(n))+#(DB(n)-B(n))+#B(n)

Also, this module stores some special relations derived from 
[AB^(-1),A^(-1)BA] = [AB^(-1),A^(-2)BA^2] = e that must me avoided when 
counting the elements of B(n). For example, from [AB^(-1),A^(-1)BA] = e 
it can be derived the relations

A^(-1)BAA = AB^(-1)A^(-1)BAB
A^(-1)BAAB^(-1) = AB^(-1)A^(-1)BA

among many other relations. The first relation show us that if
we have a word g that contains AB^(-1)A^(-1)BAB it MUST NOT be counted
as an element of B(n) for some n, because the word AB^(-1)A^(-1)BAB
can be reduced to A^(-1)BAA and this implies that g was already counted
as an element of B(n). Second relation tell us that if we have
a word w that contains A^(-1)BAAB^(-1) it MUST NOT be counted as an
element of B(n) because w was already counted (or will be counted) as
and element of B(n).

Resuming, relation [AB^(-1),A^(-1)BA] = 1, allow us to derive relations
between words with length 4 and length 6, and between words of length 5.
And the second relation [AB^(-1),A^(-2)BA^2] = 1 can be used to derive
relations between words with length 6 and words with length 8, and 
between words of length 7.

=head1 METHODS

=over 4

=item new

Creates the Thompson object.

Usage: my $F = new->Math::Group::Thompson( VERBOSE => $v );

Verbose argument tells Math::Group::Thompson whether print every
word generated ($v == 1) or not ($v == 0), or store them
in a file, where $v is the name of the file (obviously different
to 0 or 1). If the verbose file exists it is replaced, so you have to
check for its integrity.

  NOTE:
  It's not recommend to store the words on a file because for
  very small values of n, #B(n) or #gB(n)-B(n) are very very large.
  For example for n = 19, #B(n) ~ 3^n = 1162261467 ~ 1.1 Giga, but
  the space ocupped by the file will be (in bytes):

  #B(1) + sum(i=2 to 19){i*(#B(i) - #B(i-1))} = 

=cut
sub new {
  my $class = shift || undef;
  if(!defined $class) {
    return undef;
  }

  my %args = ( VERBOSE => 0, # By default don't print anything
	       @_ );

  # Inverse elements
  my $inv = { B => 'D', # B is the inverse of B^(-1)
	      A => 'C', # A is the inverse of A^(-1)
	      D => 'B', # B^(-1) is the inverse of B
	      C => 'A', # A^(-1) is the inverse of A
  };

  # Prohibited words
  # Words of length 5
  my @rel5 = (
		'BAADC',
		'ABCCD',
		'AADCD',
		'BABCC',
		'ADCDA',
		'CBABC',
		'DCDAB',
		'DCBAB',
		'CDABC',
		'ADCBA',
	     );

  # Words of length 6
  my @rel6 = (
		'AADCBA',
                'DAADCB',
                'CBAADC',
                'BAADCD',
                'DABCCB',
                'CDABCC',
                'BABCCD',
                'ABCCDA',
                'CDAADC',
                'AADCDA',
                'ABCCBA',
                'CBABCC',
                'CCDAAD',
                'ADCDAB',
                'BCCBAA',
                'DCBABC',
                'BCCDAA',
                'DCDABC',
                'CCBAAD',
                'ADCBAB',
 	     );

  # Words of length 7
  my @rel7 = (
                'CBAAADC',
                'ABCCCDA',
                'BAAADCC',
                'AABCCCD',
                'AAADCCD',
                'BAABCCC',
                'AADCCDA',
                'CBAABCC',
                'ADCCDAA',
                'CCBAABC',
                'DCCDAAB',
                'DCCBAAB',
                'CCDAABC',
                'ADCCBAA',
	     );

  # Words of length 8
  my @rel8 = (
                'AADCCBAA',
                'AAADCCBA',
                'CCBAAADC',
                'CBAAADCC',
                'CDAABCCC',
                'CCDAABCC',
                'AABCCCDA',
                'ABCCCDAA',
                'DAAADCCB',
                'BAAADCCD',
                'DAABCCCB',
                'BAABCCCD',
                'CDAAADCC',
                'AAADCCDA',
                'AABCCCBA',
                'CBAABCCC',
                'CCDAAADC',
                'AADCCDAA',
                'ABCCCBAA',
                'CCBAABCC',
                'CCCDAAAD',
                'ADCCDAAB',
                'BCCCBAAA',
                'DCCBAABC',
                'BCCCDAAA',
                'DCCDAABC',
                'CCCBAAAD',
                'ADCCBAAB',
	     );


  # Define the generator set S = { A,B,A^(-1),B^(-1) }
  my @generators = ('B','A','D','C');

  # Open filehandle if we have to
  my $fh;
  if($args{VERBOSE}) {
    if($args{VERBOSE} ne '1') {
      $fh = new FileHandle ">".$args{VERBOSE} || undef;
    }
  }

  return bless { INV => $inv,                          # Inverse relations
		 REL => [\@rel5,\@rel6,\@rel7,\@rel8], # Prohibited words
		 GEN => \@generators,                  # Generator set
		 COUNTER => 0,                         # Element counter
		 FIRST_ELEMENT => '',		       # F's element passed to the firs call of method cardBn
		 FIRST_CALL => 1,                      # Flag of first call to method cardBn
		 VERBOSE => $args{VERBOSE},            # Verbose mode
                 FILEHANDLE => \$fh,                   # Filehandler
	       }, $class;
}

=item cardBn

This method calculates #B(n) or #(gB(n) - B(n)) depending on if
the argument passed to the first call of cardBn is '' or not.

Usage: my $c = $F->cardBn($radius,$g);

where

$radius is an integer number >= 0 and
$g is an element of F (word written with A,B,C or D).

If the first time cardBn is called $g is not equal to '', then
cardBn returns the cardinality of the set

gB(n) - B(n) = { w in F | w in gB(n) and w not in B(n) }

If the firs time cardBn is callen $g is equal to '', then
cardBn returns #B(n).

This algorithm runs on exponential time because
F is of exponential growth (more "exactly", this algorithm is
O(3^n) ).

=cut
sub cardBn {
  my ($self,$n,$g) = @_;
  if(!defined $g) { $g = ""; }
  if(!defined $self || !ref $self || !defined $n || $n < 0 || $n =~ /\D/ || $g =~ /[^ABCD]/) {
    return undef;
  }
  if($n == 0) {
    # We have to calculate #B(0) or #(gB(0) - B(0)). In any case is 1
    return 1;
  }

  # Check if we are in the first call of cardBn
  if($self->{FIRST_CALL}) {
    # The first element passed to cardBn is $g. Keep it
    $self->{FIRST_ELEMENT} = $g || '';
    $self->{FIRST_CALL} = 0;
    if($self->{FIRST_ELEMENT} eq '') {
      $self->note('e');
    }
  }

  # For every element A,B,A^(-1) and B^(-1)
  for(0..3) {
    my $aux_g = $self->multiply($g,$self->{GEN}->[$_]) || ''; # Multiple $g by one of the generators
    my $i = 0; # Flag that say if the new word contains

    # Check if the new word is one letter larger than the previous one
    my ($length_g,$length_auxg) = (0,0);
    if($g ne '') {
      $length_g += length($g);
    }
    if($aux_g ne '') {
      $length_auxg += length($aux_g);
    }
    if($length_auxg == ($length_g + 1)) {
      # Check if some prohibited word is in $aux_g
      LOOP: for(5..8) {
	if($length_auxg >= $_) {
	  # Check if the word contains any prohibited relation
	  foreach my $rel (@{$self->{REL}->[$_-5]}) {
	    if($aux_g =~ /$rel$/) {
	      # Prohibited word found
	      $i++;
	      last LOOP;
	    }
	  }
	}
      }

      # Check if we foun any prohibited word
      if($i == 0) {
	# Determine if we are calculating #B(n) or #(gB(n) - B(n)) where g is the first argument received by cardBn
	if($self->{FIRST_ELEMENT} ne '') {
	  # First element wasn't ''. We are calculating #(gB(n) - B(n))
	  if(length($aux_g) < ($n + length($self->{FIRST_ELEMENT}))) {
	    $self->cardBn($n,$aux_g);
	  } else {
            # Count this element
	    # Print word if VERBOSE == 1
	    $self->note($aux_g);
	    $self->{COUNTER}++;
	  }
	} else {
	  # Count this element
	  # Print word if VERBOSE == 1
	  $self->note($aux_g);
	  $self->{COUNTER}++;

	  # First element was empty. We are calculating #B(n)
	  if(length($aux_g) < $n) {
	    # Word's length is < $n, continue
	    $self->cardBn($n,$aux_g);
	  }
	}
      }
    }
  }

  # Return
  if($self->{FIRST_ELEMENT} eq '') {
    return $self->{COUNTER} + 1; # Returns #B(n). The 1 is for the identity element
  } else {
    return $self->{COUNTER};     # Returns #(gB(n)-B(n).
  }
}

=item reset

Resets the counter used on cardBn method, set
the FIRST_ELEMENT property at '', and the FIRST_CALL
proporty to 1.

Usage: $F->reset;

=cut
sub reset {
  my $self = shift || undef;
  if(!defined $self) {
    return;
  }

  $self->{COUNTER} = 0;
  $self->{FIRST_ELEMENT} = '';
  $self->{FIRST_CALL} = 1;

  return 1;
}

=item multiply

Multiplication between two words of F. This method
considers the inverse relations stored in the attribute
INV.

Usage: my $mul = $F->multiply($g,$w);

where $g and $w are elements of F, and $mul is the
result of $g$w.

=cut
sub multiply {
  my ($self,$g,$h) = @_;
  if(!defined $self) {
    return;
  }
  if(!defined $g && !defined $h) {
    return undef;
  } elsif($g eq '' && $h eq '') {
    return undef;
  }
  if(!defined $h) {
    return $g;
  } elsif ($h eq '') {
    return $g;
  }
  if(!defined $g) {
    return $h;
  } elsif($g eq '') {
    return $h;
  }

  # Get inverse relations
  my %inv = $self->get_inv;

  # Multiply
  my @h = split(//,$h);
  foreach my $el (@h) {
    $g =~ /(.)$/;
    if($1 ne $inv{$el}) {
      return $g.$h;
    } else {
      $g =~ s/.$//;
      $h =~ s/^.//;
    }

    if($g eq '' && $h ne '') {
      return $h
    } elsif($h eq '' && $g ne '') {
      return $g;
    } elsif($g eq '' && $h eq '') {
      return undef;
    }
  }
}

=item rotate

This module receives as argument a word in F and
puts the last letter on word in its first place.

Usage: $w = 'ABC';
       $W = $self->rotate($w); # $W is now equal to 'CBA'

=cut
sub rotate {
  my ($self,$word) = @_;
  if(!defined $self || !defined $word) {
    return undef;
  }

  $word =~ s/(.)$//;
  return $1.$word;
}

=item inverse

This method receives a word in F and returns its inverse.

Usage: $w = 'ABC';
       $W = $self->inverse($w); # $W == 'ADC'

=cut
sub inverse {
  my ($self,$word) = @_;
  if(!defined $self || !defined $word) {
    return undef;
  }

  my %inv = $self->get_inv;
  my @word = split(//,$word);

  for(0..$#word) {
    $word[$_] = $inv{$word[$_]};
  }

  $word = join('',@word);
  return reverse $word;
}

=item divide

This method receives a word in F and returns a 2-dimensional
array where the first element is the first half
of the word, and the second is the inverse of the
second half of the word.

Usage: $w = 'AABC';
       ($w1,$w2) = $self->divide($w); # Now $w1 == 'AA' and $w2 == 'AD'

=cut
sub divide {
  my ($self,$word) = @_;
  if(!defined $self || !defined $word) {
    return undef;
  }

  my $largo = length($word);
  my @word = split(//,$word);
  $word = join('',@word[0..($largo/2)-1]);
  my $word2 = join('',@word[($largo/2)..$#word]);
  $word2 = $self->inverse($word2);

  return ($word,$word2);
}

=item get_inv

This method return the hash of inverse relations
between the generators elements of F.

=cut
sub get_inv {
  my $self = shift || undef;
  if(!defined $self) {
    return undef;
  }

  return %{$self->{INV}};
}

=item note

This method prints in STDERR the string received or
puts it on the correspondent file.

Usage: $F->note('AA'); # Print AA."\n" or store it on a file.

=cut
sub note {
  my $self = shift || undef;
  if(!defined $self) {
    return undef;
  }

  my $g = shift || return undef;

  if($self->{VERBOSE}) {
    if($self->{VERBOSE} eq '1') {
      # Print word to STDERR
      print STDERR $g,"\n";
    } else {
      # Put word on the correspondent file
      if($self->{FILEHANDLE} && ref(${$self->{FILEHANDLE}}) eq 'FileHandle') {
        my $fh = ${$self->{FILEHANDLE}};
        print $fh $g,"\n";
      }
    }
  }
}

# Destroy function. Closes the filehandle opened in 'new' method (if it was opened).
sub DESTROY {
  my $self = shift || undef;
  if(!defined $self) {
    return undef;
  }

  if($self->{VERBOSE}) {
    if($self->{VERBOSE} ne '1' && ref(${$self->{FILEHANDLE}}) eq 'FileHandle') {
      ${$self->{FILEHANDLE}}->close if $self->{FILEHANDLE};
    }
  }
}

=back 4

=head1 BUGS

There isn't reported bugs yet, but that doesn't mean that there aren't ;) .

=head1 AUTHOR

Roberto Alamos Moreno <ralamosm@cpan.org>

Thanks to professor Juan Rivera Letelier for his support to my thesis work, and help in the design
of cardBn algorithm :) .

=head1 COPYRIGHT

Copyright (c) 2004 Roberto Alamos Moreno. All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
1;
