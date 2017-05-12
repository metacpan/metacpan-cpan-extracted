package Math::FractionDemo;

# Math::Fraction v.53b (2 Feb 1998) Test Script

use Math::Fraction qw(:DEFAULT :STR_NUM);

require Exporter;
use vars qw($VERSION);
$VERSION = ".53";
@ISA = qw(Exporter);
@EXPORT = qw(frac_calc frac_demo);

sub frac_calc {
  local $^W = 0;
  sub pevel;

  local $f1 = Math::Fraction->new(1,2);
  local $f2 = Math::Fraction->new(1,3);
  local $f3 = Math::Fraction->new(5,3,MIXED);
  local $f4 = Math::Fraction->new(1,3,NO_REDUCE);

print <<'---';

Fraction "Calculator" for testing the Fraction Module.

Simply enter in any valid perl expression.  The results are printed
to the screen and stored the variable $ans for referring back to.

Examples:
 >5+5
 10
 >$ans*2
 20
 >frac(1,2)
 1/2
 >$ans*frac(1,2)
 1/4

To see a demonstration of the fraction module features type in "frac_demo".

---
  print "Pre-Set: \$f1=$f1  \$f2=$f2  \$f3=$f3  \$f4=$f4(NO_REDUCE)\n";

  print ">";
  local $ans;
  while(<>) {$ans = eval; print $@; print "$ans\n>";}
}

sub pevel {
  $ans = eval $_[0];
  if (not $test) {
    print $output "$space>$_[0]\n";
    print $output "$space $ans\n";
  } elsif ($test eq 'TESTCREATE') {
    print $output "  pevel q~$_[0]~, q~$ans~;\n";
  } else {
    if ("$ans" eq "$_[1]") {
      print "ok\n"
    } else {
      print STDERR qq~Test: $_[0]\n"$ans" ne\n"$_[1]"\n~;
      print "not ok\n"
    }
  }
}

sub evelp {
  eval $_[0];
  if (not $test) {
    print $output "$space>$_[0]\n";
  } elsif ($test eq 'TESTCREATE') {
    print $output "  evelp q~$_[0]~;\n";
  } else {
    print "ok\n"
  }
}

sub pause {
  if (not $test) {
    if ($output eq STDOUT) {
      print "Press Enter to go on\n";
      <STDIN>;
      Math::Fraction->load_set(DEFAULT);
    } else {
      print $output "$space\n";
    }
  } elsif ($test eq 'TESTCREATE') {
    print $output "  pause;\n";
  } else {
  }
}

sub s {
  my @ret = map {$_ eq undef() ? 'undef' : $_} @_;
  "@ret";
}

sub frac_demo {
  local $^W = 0;
  local($output) = $_[0] || STDOUT;
  local($test,$space);
  if ($_[1] eq 'TEST' || $_[1] eq 'TESTCREATE') {
    $test = $_[1] 
  } else {
     $space = " "x$_[1];
  }
  
  local($f1,$f2);

  my $set = Math::Fraction->temp_set unless $test;
  
  print "1..74\n" if $test eq 'TEST';

  pevel q~frac(1, 3)~, q~1/3~;
  pevel q~frac(4, 3, MIXED)~, q~1 1/3~;
  pevel q~frac(1, 1, 3)~, q~4/3~;
  pevel q~frac(1, 1, 3, MIXED)~, q~1 1/3~;
  pevel q~frac(10)~, q~10/1~;
  pevel q~frac(10, MIXED)~, q~10~;
  pevel q~frac(.66667)~, q~2/3~;
  pevel q~frac(1.33333, MIXED)~, q~1 1/3~;
  pevel q~frac("5/6")~, q~5/6~;
  pevel q~frac("1 2/3")~, q~5/3~;
  pevel q~frac(10, 20, NO_REDUCE)~, q~10/20~;
  pause;
  evelp q~$f1=frac(2,3); $f2=frac(4,5);~;
  pevel q~$f1 + $f2~, q~22/15~;
  pevel q~$f1 * $f2~, q~8/15~;
  pevel q~$f1 + 1.6667~, q~7/3~;
  evelp q~$f2->modify_tag(MIXED)~;
  pevel q~$f2 + 10~, q~10 4/5~;
  pevel q~frac($ans, NORMAL) # trick to create a new fraction with different tags~, q~54/5~;
  pevel q~$f1 + $f2          # Add two unlikes it goes to default mode~, q~22/15~;
  pevel q~$f1**1.2~, q~229739670999407/373719281884655~;
  pevel q~$f1->num**1.2~, q~0.614738607654485~;
  pevel q~frac(1,2)+frac(2,5)~, q~9/10~;
  pause;
  evelp q~$f1=frac(5,3,NORMAL); $f2=frac(7,5);~;
  pevel q~"$f1  $f2"~, q~5/3  7/5~;
  evelp q~Math::Fraction->modify_tag(MIXED)~;
  pevel q~"$f1  $f2"~, q~5/3  1 2/5~;
  pevel q~$f1 = frac("3267893629762/32678632179820")~, q~3267893629762/32678632179820~;
  pevel q~$f2 = frac("5326875886785/76893467996910")~, q~5326875886785/76893467996910~;
  pevel q~$f1->is_tag(BIG).",".$f2->is_tag(BIG) # Notice how neither of them is BIG ~, q~0,0~;
  pevel q~$f1+$f2~, q~21267734600460495169085706/125638667885089122116217810~;
  pevel q~$ans->is_tag(BIG)                     # But this answer is.~, q~1~;
  pevel q~$f1*$f2~, q~1740766377695750621849517/251277335770178244232435620~;
  pevel q~$ans->is_tag(BIG)                     # And so is this one.~, q~1~;
  pause;
  pevel q~$f1 = frac("3267893629762/32678632179820", BIG)~, q~3267893629762/32678632179820~;
  pevel q~$f1->is_tag(BIG)   # Notice how the big tag had no effect.~, q~0~;
  evelp q~$f1->modify_tag(NO_AUTO, BIG)~;
  pevel q~$f1->is_tag(BIG)   # But now it does.  You have to turn off AUTO.~, q~1~;
  pevel q~$f1->num~, q~.10000093063197482237806917498797382196606~;
  evelp q~Math::Fraction->modify_digits(15)~;
  pevel q~$f1->num~, q~.1000009306319748~;
  pevel q~$f1 = frac("0.1231231234564564564564564564561234567891234567891234")~, q~13680347037037036999999999999963000037/111111111000000000000000000000000000000~;
  evelp q~Math::Fraction->modify_digits(65)~;
  pevel q~$f1->num~, q~.123123123456456456456456456456123456789123456789123456789123456789~;
  pause;
  evelp q~$f1 = frac(7,5);~;
  evelp q~$f2 = frac("3267893629762/32678632179820", NO_AUTO, BIG)~;
  evelp q~Math::Fraction->modify_tag(MIXED); Math::Fraction->modify_digits(60)~;
  pevel q~"$f1 ".$f2->num~, q~1 2/5 .1000009306319748223780691749879738219660647769485035912494771~;
  evelp q~Math::Fraction->load_set(DEFAULT)~;
  pevel q~"$f1 ".$f2->num~, q~7/5 .10000093063197482237806917498797382196606~;
  evelp q~Math::Fraction->modify_digits(25)~;
  pevel q~"$f1 ".$f2->num~, q~7/5 .10000093063197482237806917~;
  evelp q~$s = Math::Fraction->temp_set~;
  evelp q~Math::Fraction->modify_tag(MIXED); Math::Fraction->modify_digits(15)~;
  pevel q~"$f1 ".$f2->num~, q~1 2/5 .1000009306319748~;
  evelp q~Math::Fraction->temp_set($s)~;
  pevel q~Math::Fraction->exists_set($s)~, q~~;
  pevel q~"$f1 ".$f2->num  # Notice how it goes back to the previous settings.~, q~7/5 .10000093063197482237806917~;
  pause;
  evelp q~Math::Fraction->name_set('temp1')~;
  evelp q~Math::Fraction->modify_tag(MIXED, NO_AUTO)~;
  evelp q~Math::Fraction->modify_digits(60)~;
  pevel q~&s(Math::Fraction->tags, Math::Fraction->digits)~, q~MIXED REDUCE SMALL NO_AUTO 60~;
  evelp q~Math::Fraction->save_set  # If no name is given it will be saved via~;
  evelp q~                          # its given name~;
  evelp q~Math::Fraction->load_set(DEFAULT)~;
  pevel q~&s(Math::Fraction->tags, Math::Fraction->digits)~, q~NORMAL REDUCE SMALL AUTO undef~;
  pevel q~&s(Math::Fraction->tags('temp1'), Math::Fraction->digits('temp1'))~, q~MIXED REDUCE SMALL NO_AUTO 60~;
  evelp q~  # ^^ Notice how this lets you preview other sets with out loading them.~;
  evelp q~Math::Fraction->load_set(DEFAULT)~;
  evelp q~Math::Fraction->use_set('temp1')~;
  evelp q~Math::Fraction->modify_tag(NO_REDUCE)~;
  pevel q~&s(Math::Fraction->tags, Math::Fraction->digits)~, q~MIXED NO_REDUCE SMALL NO_AUTO 60~;
  pevel q~&s(Math::Fraction->tags('temp1'), Math::Fraction->digits('temp1'))~, q~MIXED NO_REDUCE SMALL NO_AUTO 60~;
  evelp q~  # ^^ Notice how this also modifies the temp1 tag becuase it is being used~;
  evelp q~  #    if it was just loaded it would not do this becuase there is no link.~;
  pause;

  Math::Fraction->del_set('temp1') unless $test;
  Math::Fraction->temp_set($set)   unless $test;

  print "END\n" if $test eq 'TEST';
  
  return undef;
}

1;

__END__

=head1 NAME

Math::FractionDemo - Math::Fraction demo script (v.51b, Beta Release)

=head1 SYNOPSIS

C<perl -e "use Math::FractionDemo; frac_calc;">

=head1 DESCRIPTION

This is nothing but a simple perl "calculator" and demo script.

=head2 Functions

=over 4

=item frac_calc

A simple perl "calculator" for trying out the Math::Fraction package.

=item frac_demo [OUTPUT] [,INDENT]

A simple demo script.  OUTPUT will default to STDOUT unless otherwise
specified.  If OUTPUT is STDOUT it will run interactivly otehrwsise it will
dump the results to the OUTPUT file stream.

INDENT controles how many spaces each line is indented.  INDENT defaults
to 0 unless otherwise specified.

This script can also be run from frac_calc.

=back

=head1 SEE ALSO

L<Math::Fraction>, L<perl(1p)>

=head1 AUTHOR and COPYRIGHT 

Kevin Atkinson, kevina@clark.net

Copyright (c) 1997 Kevin Atkinson.  All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


