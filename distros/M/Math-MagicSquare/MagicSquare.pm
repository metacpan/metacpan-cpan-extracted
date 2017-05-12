#
# MagicSquare.pm, version 2.04 13 Dec 2003
#
# Copyright (c) 2003 Fabrizio Pivari Italy
# fabrizio@pivari.com
#
# Free usage under the same Perl Licence condition.
#

package Math::MagicSquare;

use Carp;
use GD;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use Exporter();
@ISA= qw(Exporter);
@EXPORT=qw();
@EXPORT_OK=qw(new check print printhtml rotation reflection);
$VERSION='2.04';

sub new {
  my $type = shift;
  my $self = [];
  my $len = scalar(@{$_[0]});
  my $numelem = 0;
  for (@_) {
    push(@{$self}, [@{$_}]);
    $numelem += scalar(@{$_});
    }
  croak "Math::MagicSquare::new(): number of rows and columns must be equal"
    if ($numelem != $len*$len);
  bless $self, $type;
  }

sub check {
  my $self = shift;
  my $i=0; my $j=0;
  my $line1=0; my $line2=0; my $diag1=0; my $diag2=0; my $SUM=0;
  my $sms=1;
  my $len = scalar(@{$self});

# Magic Constant for a Magic Square 1,2,...,n
  my $sum=$len*($len*$len+1)/2;
# Generic Magic Constant
  for ($i=0;$i<$len;$i++) {
    $SUM+=$self->[$i][0];
    }
  if ($SUM != $sum) {$sum=$SUM;}
# Check lines and columns
  for ($i=0;$i<$len;$i++) {
    $j=0; $line1=0; $line2=0;
    for ($j=0;$j<$len;$j++) {
      $line1+=$self->[$i][$j];
      $line2+=$self->[$j][$i];
      }
    if ($line1 != $sum || $line2 != $sum) {
# This isn't a Magic
      return(0);
      }
    }
# Check diagonals and broken diagonals
  for ($j=0;$j<$len;$j++) {
    $i=0; $diag1=0; $diag2=0;
    for ($i=0;$i<$len;$i++) {
      $diag1+=$self->[$i][($i+$j)%$len];
      $diag2+=$self->[$len-1-$i][($i+$j)%$len];
      }
    if ($j == 0) {
      if ($diag1 != $sum || $diag2 != $sum) {
# This is a Semimagic Square
        return(1);
        }
      } else {
      if ($diag1 != $sum || $diag2 != $sum) {
# This is a Magic Square
        return(2);
        }
      }
    }
# This is a Panmagic Square
  return(3);
  }

sub print {
  my $self = shift;
  my $initialtext = shift;
  my $i=0; my $j=0;
  my $len = scalar(@{$self});
    
  print "$initialtext\n" if $initialtext;
  print @_ if scalar(@_);
  for ($j=0;$j<$len;$j++) {
    for ($i=0;$i<$len;$i++) {
      printf "%5d ", $self->[$j][$i];
      }
    print "\n";
    }
  }

sub printhtml {
  my $self = shift;
  my $i=0; my $j=0;
  my $len = scalar(@{$self});

  print qq!<TABLE border=3 width="2" height="2" cellpadding=1 cellspacing=1>\n!;
  for ($j=0;$j<$len;$j++) {
    print "<TR>\n";
    for ($i=0;$i<$len;$i++) {
      print "<TD align=right><FONT size=+2><B>$self->[$j][$i]</B></font></TD>\n";
      }
    print "</TR>\n";
    }
  print "</TABLE>\n";
  }

sub printimage {
  my $self = shift;
  my $i=0; my $j=0;
  my $len = scalar(@{$self});

  my $CELLGRIDSIZE = 31;
  my $GRIDSIZE = 8+($len -1)*2+$len*$CELLGRIDSIZE;
  my $im=new GD::Image($GRIDSIZE,$GRIDSIZE);
  my $bg=$im->colorAllocate(255,255,255);
  my $fg=$im->colorAllocate(0,0,0);

   # GRID
#   $im->transparent($bg);
   $im->filledRectangle(0,0,255,255,$bg);
   $im->filledRectangle(0,0,4,$GRIDSIZE,$fg);
   $im->filledRectangle(0,0,$GRIDSIZE,4,$fg);
   my $tmp = $GRIDSIZE -5;
   $im->filledRectangle($tmp,0,$GRIDSIZE,$GRIDSIZE,$fg);
   $im->filledRectangle(0,$tmp,$GRIDSIZE,$GRIDSIZE,$fg);
   my $xy = 4 + $CELLGRIDSIZE;
   my $xy2 = $xy +2;
   for (1..$len-1)
      {
      $im->filledRectangle($xy,0,$xy2,$GRIDSIZE,$fg);
      $im->filledRectangle(0,$xy,$GRIDSIZE,$xy2,$fg);
      $xy = $xy2 + $CELLGRIDSIZE;
      $xy2 = $xy + 2;
      }

   # NUMBERS
   my $x1 = 4 + 8;
   my $y1 = 4 + 9;
   $j=0;
   for ($j=0;$j<$len;$j++)
      {
      $i=0;
      for ($i=0;$i<$len;$i++)
         {
         # to hit the centre with numbers < -9
         if ($self->[$j][$i] < -9) { $x1 = $x1 - 3; }
         # to hit the centre with numbers between -9 and -1
         if ($self->[$j][$i] < 0 && $self->[$j][$i] > -10) { $x1 = $x1 - 2; }
         # to hit the centre with numbers between 0 and 9
         if ($self->[$j][$i] < 10 && $self->[$j][$i] >= 0) { $x1 = $x1 + 4; }
         # to hit the centre with numbers > 99
         if ($self->[$j][$i] > 99) { $x1 = $x1 - 4; }
         $im->string(gdLargeFont,$x1,$y1,"$self->[$j][$i]",$fg);
         $x1 = $x1 + $CELLGRIDSIZE + 2;
         if ($self->[$j][$i] < -9) { $x1 = $x1 + 3; }
         if ($self->[$j][$i] < 0 && $self->[$j][$i] > -10) { $x1 = $x1 + 2; }
         if ($self->[$j][$i] < 10 && $self->[$j][$i] >= 0) { $x1 = $x1 - 4; }
         if ($self->[$j][$i] > 99) { $x1 = $x1 + 4; }
         }
      $x1 = 4 + 8;
      $y1 = $y1 + $CELLGRIDSIZE + 2;
      } 

   binmode STDOUT;
   print $im -> png;
   }

sub rotation {
  my $self = shift;
  my $i=0; my $j=0;
  my @TMP;
  my $len = scalar(@{$self});

  for ($j=0;$j<$len;$j++) {
    for ($i=0;$i<$len;$i++) {
      $TMP[$j][$i]=$self->[$j][$i];
      }
    }
  for ($j=0;$j<$len;$j++) {
    for ($i=0;$i<$len;$i++) {
      $self->[$j][$i]=$TMP[$len-1-$i][$j];
      }
    }
  }

sub reflection {
  my $self = shift;
  my $i=0; my $j=0;
  my @TMP;
  my $len = scalar(@{$self});

  for ($j=0;$j<$len;$j++) {
    for ($i=0;$i<$len;$i++) {
      $TMP[$j][$i]=$self->[$j][$i];
      }
    }
  for ($j=0;$j<$len;$j++) {
    for ($i=0;$i<$len;$i++) {
      $self->[$i][$j]=$TMP[$i][$len-1-$j];
      }
    }
  }

1;

__END__

=pod

=head1 NAME

Math::MagicSquare - Magic Square Checker and Designer

=head1 SYNOPSIS

  use Math::MagicSquare;

  $a= Math::MagicSquare -> new ([num,...,num],
                                 ...,
                                [num,...,num]);
  $a->print("string");
  $a->printhtml();
  $a->printimage();
  $a->check();
  $a->rotation();
  $a->reflection();

=head1 DESCRIPTION

The following methods are available:

=head2 new

Constructor arguments are a list of references to arrays of the same
length.

    $a = Math::MagicSquare -> new ([num,...,num],
                                    ...,
                                   [num,...,num]);

=head2 check

This function can return 4 value

=over

=item *

B<0:> the Square is not Magic

=item *

B<1:> the Square is a B<Semimagic Square> (the sum of the rows and the columns
is equal)

=item *

B<2:> the Square is a B<Magic Square> (the sum of the rows, the columns and the
diagonals is equal)

=item *

B<3:> the Square ia B<Panmagic Square> (the sum of the rows, the columns, the
diagonals and the broken diagonals is equal)

=back

=head2 print

Prints the Square on STDOUT. If the method has additional parameters,
these are printed before the Magic Square is printed.

=head2 printhtml

Prints the Square on STDOUT in an HTML format (exactly a inside a TABLE)

=head2 printimage

Prints the Square on STDOUT in png format.

=head2 rotation

Rotates the Magic Square of 90 degree clockwise

=head2 reflection

Reflect the Magic Square

=head1 REQUIRED

GD perl module.

=head1 EXAMPLE

    use Math::MagicSquare;

    $A = Math::MagicSquare -> new ([8,1,6],
                                   [3,5,7],
                                   [4,9,2]);
    $A->print("Magic Square A:\n");
    $A->printhtml();
    $i=$A->check();
    if($i == 2) {print "This is a Magic Square.\n";}
    $A->rotation();
    $A->print("Rotation:\n");
    $A->reflection();
    $A->print("Reflection:\n");
    $A->printimage();

 This is the output:
    Magic Square A:
        8     1     6 
        3     5     7 
        4     9     2 
    <TABLE border=3 width="2" height="2" cellpadding=1 cellspacing=1>
    <TR>
    <TD align=right><FONT size=+2><B>8</B></font></TD>
    <TD align=right><FONT size=+2><B>1</B></font></TD>
    <TD align=right><FONT size=+2><B>6</B></font></TD>
    </TR>
    <TR>
    <TD align=right><FONT size=+2><B>3</B></font></TD>
    <TD align=right><FONT size=+2><B>5</B></font></TD>
    <TD align=right><FONT size=+2><B>7</B></font></TD>
    </TR>
    <TR>
    <TD align=right><FONT size=+2><B>4</B></font></TD>
    <TD align=right><FONT size=+2><B>9</B></font></TD>
    <TD align=right><FONT size=+2><B>2</B></font></TD>
    </TR>
    </TABLE>
    This is a Magic Square.
    Rotation:
        4     3     8 
        9     5     1 
        2     7     6
    Reflection:
        8     3     4
        1     5     9
        6     7     2

=head1 AUTHOR

 Fabrizio Pivari fabrizio@pivari.com
 http://www.pivari.com/

=head1 Copyright 

 Copyright 2003, Fabrizio Pivari fabrizio@pivari.com
 This library is free software; you can redistribute it and/or modify it under
 the same terms as Perl itself. 
 Are you interested in a Windows cgi distribution?
 Test http://www.pivari.com/squaremaker.html and contact me.

=head1 Availability

 The latest version of this library is likely to be available from:
 http://www.pivari.com/magicsquare.html
 and at any CPAN mirror

=head1 Information about Magic Square

 Do you like Magic Square?
 Do you want to know more information about Magic Square?
 Try to visit

=over

=item A very good introduction on Magic Square

http://mathworld.wolfram.com/MagicSquare.html

=item Whole collections of links and documents in Internet

http://mathforum.org/alejandre/magic.square.html
http://mathforum.org/te/exchange/hosted/suzuki/MagicSquare.html

=item A good collection of strange Magic Square

http://www.geocities.com/pivari/examples.html

=back

=cut
