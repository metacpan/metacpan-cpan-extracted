# -*- mode: perl; -*-

# todo: could be faster,storing values of tokes as Math::BigInt instead integer
#       makes it slower (due to $k < $last)
#       Roman.pm uses 4.2s for 1...4000 compared to our 6.5s (new())
#       and 5.7s (roman()), so actually we are pretty fast (we construct a
#       bigint on-the-fly, too!)
#
#       maybe: make 'use Roman qw(badd); print badd("M","X"),"\n";' work:
# just define the following and allow of export badd:
# sub badd
#   {
#   if ($_[0] eq $class)
#     {
#     shift;
#     }
#   $class->SUPER::badd(@_);
#   }
# The problem is the additional overhead (about 2%) and the problem to write
# the above for _all_ functions of Math::BigInt. That's rather long. AUTOLOAD does
# not work, since it steps in _after_ inheritance. Do we really need this?
# 2001-11-08: Don't think we need it, othe subclasses don't do it, either. Tels

package Math::Roman;

use strict;
use warnings;
use Math::BigInt;

require 5.006;          # requires this Perl version or later
require Exporter;

our ($VERSION, @ISA, @EXPORT_OK);

$VERSION   = '1.10';    # current version of this package
@ISA       = qw(Exporter Math::BigInt);
@EXPORT_OK = qw( as_number tokens roman error );

use overload;           # inherit from MBI

#############################################################################
# global variables

my $sh;       # hash of roman symbols (symbol => value)
my $sm;       # hash of roman symbols (value  => symbol)
my $ss;       # a list sorted by value
my $re;       # compiled regexps matching tokens
my $err;      # error message
my $bt;       # biggest token
my $bv;       # biggest value

# roman() is an exportable version of new()
sub roman {
    my $class = __PACKAGE__;
    return $class -> new(shift);
}

sub error {
    # return last error message in case of NaN
    return $err;
}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $value = shift;
    $value = 0 if !defined $value;

    # Try construct a number (if we got '1999').
    #
    # After Math::BigInt started supporting hexadecimal numbers with just the
    # "X" prefix, like CORE::hex(), the value can no longer be fed directly to
    # Math::BigInt->new(). For instance, Math::BigInt->new("X") used to return a
    # "NaN", now it returns 0, just like CORE::hex("X").

    my $self;
    if ($value =~ /[IVXLCDM]/) {
        $self = Math::Roman -> bzero();
        $self -> _initialize($value);
    } elsif (length $value) {
        $self = Math::BigInt -> new($value);
    } else {
        $self = Math::BigInt -> bzero();
    }

    bless $self, $class;            # rebless
}

#############################################################################
# self initalization

sub tokens
  {
  # set/return list of valid/invalid tokens
  # sorted by length to favour 'IM' over 'I' when matching
  # create hash and length sorted array
  my @sym = @_;
  # return current token set
  return map { $_, $sh->{$_} } keys %$sh if (@_ == 0);
  my $sl = []; # a list sorted by name-length
  $ss = [];
  $sh = {}; $sm = {};
  $bv = -1; $bt = ''; $re = "";
  my $i;
  for ($i = 0; $i<@sym;$i += 2)
    {
    #print "token $sym[$i] => $sym[$i+1]\n";
    push @$sl,$sym[$i];                # store all tokens in a tmp list
    $sh->{$sym[$i]} = int($sym[$i+1]); # contain all token=>value
    if (int($sym[$i+1]) != -1)         # only valid ones
      {
      push @$ss,int($sym[$i+1]);       # for regexp compiler
      $sm->{$sym[$i+1]} = $sym[$i];    # generate hash for value=>token
      ($bt,$bv) = ($sym[$i],int($sym[$i+1])) if (int($sym[$i+1]) > $bv);
      }
    }
  # sort symbols by name length (and if equal, by value)
  @$sl = sort { length $b <=> length $a || $sh->{$b} <=> $sh->{$a} } @$sl;
  # compile a big regexp for token parsing
  $re = join('|', @$sl);
  # print "regexp '$re'\n";
  # for converting Arabic => Roman
  @$ss = sort { $b <=> $a } @$ss;
  # return current token set
  return map { $_, $sh->{$_} } keys %$sh if (@_ == 0);
  }

BEGIN
  {
  tokens( qw(
        IIII            -1
        XXXX            -1
        CCCC            -1
        DD              -1
        LL              -1
        VV              -1
        C[MD][CDM]      -1
        X[LC][XLCDM]    -1
        I[VX][IVXLCDM]  -1
        LXL             -1
        III     3
        XXX     30
        CCC     300
        II      2
        XX      20
        CC      200
        IV      4
        IX      9
        XL      40
        XC      90
        CD      400
        CM      900
        I       1
        V       5
        X       10
        L       50
        C       100
        D       500
        M       1000
  ) );
  undef $err;
  }

  # check for illegal sequences (simple return, we are already NaN)
  # the following are not valid tokens according to rules:
  # IIII
  # XXXX
  # CCCC
  # only ICX as precede:
  # VX  5
  # VL  45
  # VC  95
  # VD  495
  # LM  995
  # LC  50
  # LD  450
  # LM  950
  # not smaller then 10 preceding:
  # IL  49
  # IC  99
  # ID  499
  # IM  999
  # XD  490
  # XM  990
  # illegal ones, smaller then following (several cases are already caught
  # by rule: token0 < token1)
  # CDD (C < D)
  # CDC (C = C)
  # XCD (X < D)
  # LXL (L = L)
  # They need to be checked separetely, the following regexps take care
  # of that:
  # C[MD][CDM]
  # X[LC][XLCDM]
  # I[VX][IVXLCDM]

sub _initialize
  {
  # set yourself to the value represented by the given string
  my $self = shift;
  my $value = shift;

  $self->bzero(); # start with 0

  # this is probably very inefficient...
  my $e = 0; my $last = -1; undef $err;
  while ((length($value) > 0) && ($e == 0))
    {
    # can't use /o since tokens might redefine $re
    $value =~ s/^($re)//;
    if (defined $1)
      {
      _symb($self,$1,\$e,\$last);
      }
    else
      {
      $err = "Math::Roman: Invalid part '$value' encountered.";
      $e = 4;
      }
    }
  $self->bnan() if ($e != 0);
  return;
  }

sub _symb
  {
  # current symbol, last symbole, error
  my ($self,$s,$error,$last) = @_;
  #print "$s => ";
  my $k = $sh->{$s}; # get value of token
  #print "$k" if defined $k;
  if (!defined $k)
    {
    $err = "Math::Roman: Undefined token '$s' encountered.";
    $$error = 1;
    }
  else
    {
    if ($k == -1)
      {
      $err = "Math::Roman: Invalid token '$s' encountered.";
      $$error = 2;
      }
    $$last = $k if $$last == -1;
    # next symbol must always be smaller then previous
    if ($k > $$last)
      {
      $err = "Math::Roman: Token '$s' ($k) is greater than last ('$$last').";
      $$error = 3;
      }
    }
  return if $$error != 0;
  $self->badd($k); $$last = $k;
  return;
  }

sub bstr
  {
  my ($x) = @_;
  return $x if !ref($x);
  return '' if $x->is_zero();
  return 'NaN' if $x->is_nan;

  # make sure that we calculate with Math::BigInt objects, otherwise objectify()
  # will try to make copies of us via bstr(), resulting in deep recursion
  my $rem = $x->as_number(); $rem->babs();
  ## get the biggest symbol
  #return $bt if $rem == $bv;

  my $es = ''; my $cnt;
  my $level = -1; # for all tokens
  while (($level < scalar @$ss) && (!$rem->is_zero()))
    {
    $level++;
    next if $ss->[$level] > $rem;               # this wont fit
    # calculate number of biggest token
    ($cnt,$rem) = $rem->bdiv($ss->[$level]);
    if ($rem->sign() eq 'NaN')
      {
      warn ("Something went wrong at token $ss->[$level].");
      return 'NaN';
      }
    # this limits $cnt to be < 65536, anyway 65536 Ms is impressive though)
    $cnt = int ($cnt);
    $es .= $sm->{$ss->[$level]} x $cnt if $cnt != 0;
    }
  return $es;
  # remove biggest token(s) so that only reminder is left
  #my $es = '';
  #my $cnt;
  #if ($rem > $bv)
  #  {
  #  # calculate number of biggest token
  #  ($cnt,$rem) = $rem->bdiv($bv);
  #  if ($rem->sign() eq 'NaN')
  #    {
  #    warn ("Something went wrong with bt='$bt' and bv='$bv'");
  ##    return 'NaN';
  #    }
  #  # this limits $cnt to be < 65536, anyway 65536 Ms is impressive though)
  #  $es = $bt x $cnt;
  #  }
  #return $es if $rem->is_zero();
  # find combination of tokens (with decreasing value) that matches reminder
  # restricted knappsack problem with symbols in @sym, sum 1...999
  #my $stack = []; my $value = 0;
  #_recurse(0,\$value,$stack,int($rem));
  #print "done $value $rem\n";
  # found valid combination? (should never fail if system is consistent!)
  #if ($value == $rem)
  #  {
  #  map { $es .= $_ } @$stack;
  #  # {
  #  # $es .= $_;
  ##  # }
  #  # $es .= join //,@$stack; # faster but gives error!?
  #  return $es;
  #  }
  #return 'NaN';
  }

sub _recurse
  {
  my ($level,$value,$stack,$rem) = @_;
  #print "level $level cur $$value target $rem ",scalar @$ss,"\n";

  return if $$value >= $rem;                 # early out, can not get smaller
  while ($level < scalar @$ss)
    {
    # get current value according to level
    my $s = $ss->[$level];
    # and try it
    push @$stack,$sm->{$s};                  # get symbol from value
    #print " "x$level."Trying $s $sm->{$s} at level $level\n";
    $$value += $s;                           # add to test value
    _recurse($level,$value,$stack,$rem);     # try to add more symbols
    #print " "x$level."back w/ $$value $rem\n";
    last if $$value == $rem;                 # keep this try
    $$value -= $s;                           # reverse try
    pop @$stack;
    $level ++;
    }
  return;
  }

sub as_number
  {
  my $self = shift;

  Math::BigInt->new($self->SUPER::bstr());
  }

1;

__END__

#############################################################################

=pod

=head1 NAME

Math::Roman - Arbitrary sized Roman numbers and conversion from and to Arabic.

=head1 SYNOPSIS

    use Math::Roman qw(roman);

    $a = new Math::Roman 'MCMLXXIII';  # 1973
    $b = roman('MCMLXI');              # 1961
    print $a - $b,"\n";                # prints 'XII'

    $d = Math::Roman->bzero();         # ''
    $d++;                              # 'I'
    $d += 1998;                        # 'MCMXCIX'
    $d -= 'MCM';                       # 'XCIX'

    print "$d\n";                      # string       "MCMIC"
    print $d->as_number(),"\n";        # Math::BigInt "+1999"

=head1 REQUIRES

perl5.005, Exporter, Math::BigInt

=head1 EXPORTS

Exports nothing on default, but can export C<as_number()>, C<roman()>,
and C<error()>.

=head1 DESCRIPTION

Well, it seems I have been infected by the Perligata-Virus, too. ;o)

This module lets you calculate with Roman numbers, as if they were big
integers. The numbers can have arbitrary length and all the usual functions
from Math::BigInt are available.

=head2 Input

The Roman single digits are as follows:

    I       1
    V       5
    X       10
    L       50
    C       100
    D       500
    M       1000

The following (quite modern) rules are in effect:

=over

Each of I, X and C can be repeated up to 3 times, V, L and D only once.
Technically, M could be used up to four times, but this module imposes
no limit on this to allow arbitrarily big numbers.

A Roman number consists of B<tokens>, each token is either a digit from
IVXLCDM or consist of two digits, whereas the first digit is smaller than
the second one. In the latter case the first digit is subtracted from the
second (e.g. IV means 4, not 6).

The smaller number must be a power of ten (I, X or C) and precede a
number no larger than 10 times its own value. The smaller number itself
can be preceded only by a number at least 10 times greater (e.g. LXC is
invalid) and it must also be larger than any numeral that follows the one
from which it is being subtracted (e.g. CMD is invalid).

Each token must be smaller than the token before (e.g. IIV is invalid,
since I is smaller than IV).

The input will be checked and the result will be a 'NaN' if the check
fails. You can get the cause with C<Math::Roman::error()> until you try
to create the next Roman number.

The default list of valid tokens a Roman number can consist of is thus:

        III     3
        XXX     30
        CCC     300
        II      2
        XX      20
        CC      200
        IV      4
        IX      9
        XL      40
        XC      90
        CD      400
        CM      900
        I       1
        V       5
        X       10
        L       50
        C       100
        D       500
        M       1000

The default list of invalid tokens is as follows:

        IIII            XXXX            CCCC
        DD              LL              VV
        C[MD][CDM]      X[LC][XLCDM]    I[VX][IVXLCDM]

=back

Thanx must go to http://netdirect.net/~charta/Roman_numerals.html for
clarifications.

=head2 Output

The output will always be of the shortest possible form, and the tokens
will be arranged in a decreasing order.

=head1 BENDING THE RULES

You can use C<Math::Roman::tokens()> to get an array with all the defined
tokens and their value. Tokens with a value of -1 are invalid, all others
are valid. The format is token0, value0, token1, value1...

You can create your own set and store it with C<Math::Roman::tokens()>.
The routine expects an array of the form token, value, token, value...
etc.  Each token can be a simple string or regular expresion. Values of
-1 indicate invalid tokens.

Here is an example that removes the subtraction (only addition is valid)
as well as most of the other rules. It then parses 'XIIII' to be 14, then
redefine the token set completely and parses 'AAB' to be 25:

=over

    use Math::Roman;

    Math::Roman::tokens( qw(I 1  V 5  X 10  L 50  C 100  D 500  M 1000));
    $r = Math::Roman::roman('XIIII');
    print "'$r' is ",$r->as_number(),"\n";
    $r = Math::Roman::roman('XV');
    print "'$r' is ",$r->as_number(),"\n";
    Math::Roman::tokens ( qw(A 10 B 5) );
    $r = Math::Roman::roman('AAB');
    print "'$r' is ",$r->as_number(),"\n";

=back

Another idea is to implement the dash over symbols, this indicates
multiplying by 1000. Since it is hard to do this in ASCII, lower-case
letters could be used like in the following:

    use Math::Roman;

    # will wrongly ommit the 'M's, but so much 'M's would not fit
    # on your screen anyway
    print 'old: ',new Math::Roman ('+12345678901234567890'),"\n";
    @a = Math::Roman::tokens();
    push @a, qw ( v 5000  x 10000  l 50000  c 100000  d 500000
                  m 1000000 );
    Math::Roman::tokens(@a);
    print 'new: ',new Math::Roman ('+12345678901234567890'),"\n";

=head1 USEFUL METHODS

=over

=item new()

    new();

Create a new Math::Roman object. Argument is a Roman number as string,
like 'MCMLXXIII' (1973) of the form /^[IVXLCDM]*$/ (see above for further
rules) or a string number as used by Math::BigInt.

=item roman()

    roman();

Just like new, but you can import it to write shorter code.

=item error()

    Math::Roman::error();

Return error of last number creation when result was NaN.

=item bstr()

    $roman->bstr();

Return a string representing the internal value as a Roman number
according to the aforementioned rules. A zero will be represented by
''.  The output will only consist of valid tokens, and not contain a
sign.  Use C<as_number()> if you need the sign.

This function always generates the shortest possible form.

=item as_number()

    $roman->as_number();

Return a string representing the internal value as a normalized arabic
number, including sign.

=back

=head1 DETAILS

Uses internally Math::BigInt to do the math, all with overloaded
operators.

Roman has neither negative numbers nor zero, but this module handles
these, too. You will get only the absolute value as Roman number, but
can look at the sign with C<sign()> or use C<as_number()>.

=head1 EXAMPLES

    use Math::Roman qw(roman);

    print Math::Roman->new('MCMLXXII')->as_number(),"\n";
    print Math::Roman->new('LXXXI')->as_number(),"\n";
    print roman('MDCCCLXXXVIII')->as_number(),"\n";

    $a = roman('1311');
    print "$a is ",$a->as_number(),"\n";

    $a = roman('MCMLXXII');
    print "\$a is now $a (",$a->as_number(),")\n";
    $a++; $a += 'MCMXII'; $a = $a * 'X' - 'I';
    print "\$a is now $a (",$a->as_number(),")\n";

=head1 LIMITS

=head2 Internal Number Length

For the actual math, the same limits as in Math::BigInt apply.

=head2 Output length

The output in Roman is limited to 65536 times the biggest symbol. With
the default set this is 'M', so the biggest Roman number you can print
is 65536000 - and it will give you 64 KBytes M's in a row. This could be
fixed, but who really needs it? ;)

=head2 Number Rules

The rule "Each token must be greater than the token before" is
hard-coded in and can not be overcome. So 'IIX' will be invalid for
subtraction-less numbers unless you define an 'IIX' token with a value
of 12.

=head1 BUGS

=head2 Importing functions

You can not import ordinary math functions like C<badd()> and write
things like:

    use Math::Roman qw(badd);               # will fail

    $a = badd('MCM','M');                   # does not work
    $a = Math::Roman::badd('MCM','M');      # neither

It is be possible to make this work, but this takes quite a lot of
Copy&Paste code, and some small overhead price for every calculation.
I think this is really not needed, since you can always use:

    use Math::Roman;

    $a = new Math::Roman 'MCM'; $a += 'M';  # neat isn't it?
    $a = Math::Roman->badd('MCM','M');      # or this

=head2 '0'-'9' as tokens

0-9 in the token set produce wrong results in new() if the given argument
consists only of 0-9. That is because first a Math::BigInt is tried to be
constructed, and in this case, would succeed.

=head2 Reporting bugs

Please report any bugs or feature requests to
C<bug-math-roman at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-Roman>
(requires login).
We will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Roman

You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/pjacklam/p5-Math-Roman>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Dist/Display.html?Name=Math-Roman>

=item * MetaCPAN

L<https://metacpan.org/release/Math-Roman>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-Roman>

=item * CPAN Ratings

L<https://cpanratings.perl.org/dist/Math-Roman>

=back

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

If you use this module in one of your projects, then please email me. I want
to hear about how my code helps you ;)

Copyright (C) MCMXCIX-MMIV by Tels L<http://bloodgate.com/>

=cut

1;
