#############################################################################
# Math/String.pm -- package which defines a base class for calculating
# with big integers that are defined by arbitrary char sets.
#
# Copyright (C) 1999 - 2008 by Tels.
#############################################################################

# see:
# http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2000-05/msg00974.html
# http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/1999-02/msg00812.html

# the following hash values are used
# _set			  : ref to charset object
# sign, value, _a, _f, _p : from BigInt
# _cache		  : caches string form for speed

package Math::String;
my $class = "Math::String";

use Exporter;
use Math::BigInt;
@ISA = qw(Exporter Math::BigInt);
@EXPORT_OK = qw(
   as_number last first string from_number bzero bone binf bnan
  );
use Math::String::Charset;
use strict;
use vars qw($VERSION $AUTOLOAD $accuracy $precision $div_scale $round_mode);
$VERSION = '1.29';	# Current version of this package
require 5.008003;	# requires this Perl version or later

$accuracy   = undef;
$precision  = undef;
$div_scale  = 0;
$round_mode = 'even';

use overload
'cmp'   =>      sub {
 		 my $str = $_[0]->bstr();
 		 return undef if !defined $str;
 		 my $str1 = $_[1]; $str1 = $str1->bstr() if ref $str1;
 		 return undef if !defined $str1;
	        $_[2] ?  $str1 cmp $str : $str cmp $str1;
	        },
# can modify arg of ++ and --, so avoid a new-copy for speed
'++'    =>      \&binc,
'--'    =>      \&bdec,
;

my $CALC = 'Math::BigInt::Calc';

sub import
  {
  my $self = shift;

  $CALC = Math::BigInt->config()->{lib} || 'Math::BigInt::Calc';

  # register us with MBI to get notified of future lib changes
  Math::BigInt::_register_callback( $self, sub { $CALC = $_[0]; } );

  Math::BigInt::import($self, @_);
  }

sub string
  {
  # exportable version of new
  $class->new(@_);
  }

sub from_number
  {
  # turn an integer into a string object
  # catches also Math::String->from_number and make it work
  my $val = shift;

  $val = "" if !defined $val;
  $val = shift if !ref($val) && $val eq $class;
  my $set = shift;

  # make a new bigint (or copy the existing one)
  my $self = Math::BigInt->new($val);
  if (ref($set) && (
    ref($set) eq 'HASH' || UNIVERSAL::isa($set,'Math::String::Charset'))
   )
    {
    $self->bdiv($set->{_scale}) if defined $set->{_scale};  # input is scaled?
    }
  bless $self, $class;         					# rebless
  $self->_set_charset($set);
  $self;
  }

sub scale
  {
  # set/get the scale of the string (from the set)
  my $self = shift;

  $self->{_set}->scale(@_);
  }

sub bzero
  {
  my $self = shift;
  if (defined $self)
    {
    # $x->bzero();	(x) (M::S)
    # $x->bzero();	(x) (M::bi or something)
    $self = $self->SUPER::bzero();
    bless $self, $class if ref($self) ne $class;	# convert aka rebless
    }
  else
    {
    # M::S::bzero();	()
    $self = Math::BigInt->bzero();
    bless $self, $class;				# rebless
    $self->_set_charset(shift);
    }
  $self->{_cache} = undef;				# invalidate cache
  $self;
  }

sub bone
  {
  my $self = shift;
  if (defined $self)
    {
    # $x->bzero();	(x) (M::S)
    # $x->bzero();	(x) (M::bi or something)
    $self->SUPER::bone();
    bless $self, $class if ref($self) ne $class;	# convert aka rebless
    }
  else
    {
    # M::S::bzero(undef,charset);
    $self = Math::BigInt->bone();
    bless $self, __PACKAGE__;
    $self->_set_charset($_[0]);
    }
  my $min = $self->{_set}->minlen();
  $min = 1 if $min <= 0;
  $self->{_cache} = $self->{_set}->first($min);		# first of minlen
  $self;
  }

sub bnan
  {
  my $self = shift;
  if (defined $self)
    {
    # $x->bnan();	(x) (M::S)
    # $x->bnan();	(x) (M::bi or something)
    $self->SUPER::bnan();
    bless $self, $class if ref($self) ne $class;         # convert aka rebless
    }
  else
    {
    # M::S::bnan();	()
    $self = $class->SUPER::bnan();
    bless $self, __PACKAGE__;
    $self->_set_charset(shift);
    }
  $self->{_cache} = undef;
  $self;
  }

sub binf
  {
  my $self = shift;
  if (defined $self)
    {
    # $x->bzero();	(x) (M::S)
    # $x->bzero();	(x) (M::bi or something)
    $self->SUPER::binf(shift);
    bless $self, $class if ref($self) ne $class;         # convert aka rebless
    }
  else
    {
    # M::S::bzero();	()
    $self = $class->SUPER::binf(shift);
    bless $self, __PACKAGE__;
    $self->_set_charset(shift);
    }
  $self->{_cache} = undef;
  $self;
  }

###############################################################################
# constructor

sub new
  {
  my $class = shift;
  $class = ref($class) || $class;
  my $value = shift; $value = '' if !defined $value;

  my $self = {};
  if (ref($value) eq 'HASH')
    {
    $self = Math::BigInt->new($value->{num});	# number form
    bless $self, $class;			# rebless
    $self->_set_charset(shift);			# if given charset, copy over
    $self->bdiv($self->{_set}->{_scale})
      if defined $self->{_set}->{_scale};  	# input is scaled?
    $self->{_cache} = $value->{str};		# string form
    }
  elsif (ref($value))
    {
    $self = $value->copy(); 			# got an object, so make copy
    bless $self, $class;			# rebless
    $self->_set_charset(shift) if defined $_[0];# if given charset, copy over
    $self->{_cache} = undef;
    }
  else
    {
    bless $self, $class;
    $self->_set_charset(shift);			# if given charset, copy over
    $self->_initialize($value);
    }
  $self;
  }

sub _set_charset
  {
  # store reference to charset object, or make one if given array/hash ref
  # first method should be prefered for speed/memory reasons
  my $self = shift;
  my $cs = shift;

  $cs = ['a'..'z'] if !defined $cs;		# default a-z
  $cs = Math::String::Charset->new( $cs ) if ref($cs) =~ /^(ARRAY|HASH)$/;
  die "charset '$cs' is not a reference" unless ref($cs);
  $self->{_set} = $cs;
  $self;
  }

#############################################################################
# private, initialize self

sub _initialize
  {
  # set yourself to the value represented by the given string
  my $self = shift;
  my $value = shift;

  my $cs = $self->{_set};

  return $self->bnan() if !$cs->is_valid($value);

  my $int = $cs->str2num($value);
  if (!ref($int))
    {
    require Carp;
    Carp::croak ("$int is not a reference to a Big* object");
    }
  foreach my $c (keys %$int) { $self->{$c} = $int->{$c}; }

  $self->{_cache} = $cs->norm($value);		# caching normalized form
  $self;
  }

sub copy
  {
  # for speed reasons, do not make a copy of a charset, but share it instead
  my ($c,$x);
  if (@_ > 1)
    {
    # if two arguments, the first one is the class to "swallow" subclasses
    ($c,$x) = @_;
    }
  else
    {
    $x = shift;
    $c = ref($x);
    }
  return unless ref($x); # only for objects

  my $self = {}; bless $self,$c;
  foreach my $k (keys %$x)
    {
    my $ref = ref($x->{$k});
    if ($k eq 'value')
      {
      $self->{$k} = $CALC->_copy($x->{$k});
      }
    #elsif (ref($x->{$k}) eq 'SCALAR')
    elsif ($ref eq 'SCALAR')
      {
      $self->{$k} = \${$x->{$k}};
      }
    #elsif (ref($x->{$k}) eq 'ARRAY')
    elsif ($ref eq 'ARRAY')
      {
      $self->{$k} = [ @{$x->{$k}} ];
      }
    #elsif (ref($x->{$k}) eq 'HASH')
    elsif ($ref eq 'HASH')
      {
      # only one level deep!
      foreach my $h (keys %{$x->{$k}})
        {
        $self->{$k}->{$h} = $x->{$k}->{$h};
        }
      }
    #elsif (ref($x->{$k}) =~ /^Math::String::Charset/)
    elsif ($ref =~ /^Math::String::Charset/)
      {
      $self->{$k} = $x->{$k};           # for speed reasons share this
      }
    #elsif (ref($x->{$k}))
    elsif ($ref)
      {
      # my $c = ref($x->{$k});
      $self->{$k} = $ref->new($x->{$k});  # no copy() due to deep rec
      }
    else
      {
      $self->{$k} = $x->{$k};
      }
    }
  $self;
  }

sub charset
  {
  my $self = shift;
  $self->{_set};
  }

sub class
  {
  my $self = shift;
  $self->{_set}->class(@_);
  }

sub minlen
  {
  my $x = shift;
  $x->{_set}->minlen();
  }

sub maxlen
  {
  my $x = shift;
  $x->{_set}->minlen();
  }

sub length
  {
  # return number of characters in output
  my $x = shift;

  $x->{_set}->chars($x);
  }

sub bstr
  {
  my $x = shift;

  return $x unless ref $x;			# scalars get simple returned
  return undef if $x->{sign} !~ /^[+-]$/;	# short cut

  return $x->{_cache} if defined $x->{_cache};

  # num2str needs (due to overloading "$x-1") a Math::BigInt object, so make it
  # positively happy
  my $int = Math::BigInt->bzero();
  $int->{value} = $x->{value};
  $x->{_cache} = $x->{_set}->num2str($int);

  $x->{_cache};
  }

sub as_number
  {
  # return yourself as MBI
  my $self = shift;

  # make a copy of us and delete any specific (non-MBI) keys
  my $x = $self->copy();
  delete $x->{_cache};
  delete $x->{_set};
  bless $x, 'Math::BigInt';	# convert it to the new religion
  $x->bmul($self->{_set}->{_scale})
    if exists $self->{_set}->{_scale}; 	# scale it?
  $x;
  }

sub order
  {
  my $x = shift;
  $x->{_set}->order();
  }

sub type
  {
  my $x = shift;
  $x->{_set}->type();
  }

sub last
  {
  my $x = $_[0];
  if (!ref($_[0]) && $_[0] eq __PACKAGE__)
    {
    # Math::String length charset
    $x = Math::String->new('',$_[2]);	# Math::String->first(3,$set);
    }
  my $es = $x->{_set}->last($_[1]);
  $x->_initialize($es);
  }

sub first
  {
  my $x = $_[0];
  if (!ref($_[0]) && $_[0] eq __PACKAGE__)
    {
    # Math::String length charset
    $x = Math::String->new('',$_[2]);	# Math::String->first(3,$set);
    }
  my $es = $x->{_set}->first($_[1]);
  $x->_initialize($es);
  }

sub error
  {
  my $x = shift;
  $x->{_set}->error();
  }

sub is_valid
  {
  my $x = shift;

  # What does charset say to string?
  if (defined $x->{_cache})
    {
    # XXX TODO: cached string should always be valid?
    return $x->{_set}->is_valid($x->{_cache});
    }
  else
    {
    $x->{_cache} = $x->bstr();		# create cache
    }
  my $l = $x->length();
  return 0 if ($l < $x->minlen() || $l > $x->maxlen());
  1;					# all okay
  }

#############################################################################
# binc/bdec for caching

sub binc
  {
  my ($self,$x,$a,$p,$r) = ref($_[0]) ?
   (ref($_[0]),@_) : (Math::BigInt::objectify(1,@_));

  # binc calls modify, and thus destroys the cache, so store it
  my $str = $x->{_cache};
  $x->SUPER::binc();

  # if old value cached and no rounding happens
 if ((defined $str)
#   && (!defined $a) && (!defined $p)
#   && (!defined $x->accuracy()) && (!defined $x->precision())
   )
    {
    $x->{_cache} = $str;		# restore cache
    $x->{_set}->next($x);		# update string cache
    }
  $x;
  }

sub bdec
  {
  my ($self,$x,$a,$p,$r) = ref($_[0]) ?
   (ref($_[0]),@_) : (Math::BigInt::objectify(1,@_));

  # bdec calls modify, and thus destroys the cache, so store it
  my $str = $x->{_cache};
  $x->SUPER::bdec();

  # if old value cached and no rounding happens
  if ((defined $str)
#   && (!defined $a) && (!defined $p)
 #  && (!defined $x->accuracy()) && (!defined $x->precision())
   )
    {
    $x->{_cache} = $str;		# restore cache
    $x->{_set}->prev($x);		# update string cache
    }
  $x;
  }

#############################################################################
# cache management

sub modify
  {
  $_[0]->{_cache} = undef;	# invalidate cache
  0;				# go ahead, modify
  }

__END__

#############################################################################

=pod

=head1 NAME

Math::String - Arbitrary sized integers having arbitrary charsets to calculate with key rooms

=head1 SYNOPSIS

    use Math::String;
    use Math::String::Charset;

    $a = new Math::String 'cafebabe';  	# default a-z
    $b = new Math::String 'deadbeef';  	# a-z
    print $a + $b;                     	# Math::String ""

    $a = new Math::String 'aa';        	# default a-z
    $b = $a;
    $b++;
    print "$b > $a" if ($b > $a);      	# prove that ++ makes it greater
    $b--;
    print "$b == $a" if ($b == $a);    	# and that ++ and -- are reverse

    $d = Math::String->bzero( ['0'...'9'] );   	# like Math::Bigint
    $d += Math::String->new ( '9999', [ '0'..'9' ] );
					# Math::String "9999"

    print "$d\n";                      	# string       "00000\n"
    print $d->as_number(),"\n";        	# Math::BigInt "+11111"
    print $d->last(5),"\n";            	# string       "99999"
    print $d->first(3),"\n";           	# string       "111"
    print $d->length(),"\n";           	# faster than length("$d");

    $d = Math::String->new ( '', Math::String::Charset->new ( {
      minlen => 2, start => [ 'a'..'z' ], } );

    print $d->minlen(),"\n";            # print 2
    print ++$d,"\n";			# print 'aa'

=head1 REQUIRES

perl5.005, Exporter, Math::BigInt, Math::String::Charset

=head1 EXPORTS

Exports nothing on default, but can export C<as_number()>, C<string()>,
C<first()>, C<digits()>, C<from_number>, C<bzero()> and C<last()>.

=head1 DESCRIPTION

This module lets you calculate with strings (specifically passwords, but not
limited to) as if they were big integers. The strings can have arbitrary
length and charsets. Please see L<Math::String::Charset> for full documentation
on possible character sets.

You can thus quickly determine the number of passwords for brute force
attacks, divide key spaces etc.

=over

=item Default charset

The default charset is the set containing "abcdefghijklmnopqrstuvwxyz"
(thus producing always lower case output).

=back

=head1 INTERNAL DETAILS

Uses internally Math::BigInt to do the math, all with overloaded operators. For
the character sets, Math::String::Charset is used.

Actually, the 'numbers' created by this module are NOT equal to plain
numbers.  It works more than a counting sequence. Oh, well, example coming:

Imagine a charset from a-z (26 letters). The number 0 is defined as '', the
number one is therefore 'a' and two becomes 'b' and so on. And when you reach
'z' and increment it, you will get 'aa'. 'ab' is next and so on forever.

That works a little bit like the automagic in ++, but more consistent and
flexible. The following example 'breaks' (no, >= instead of gt won't help ;)

	$a = 'z'; $b = $a; $a++; print ($a gt $b ? 'greater' : 'lower');

With Math::String, it does work as intended, you just have to use '<' or
'>' etc for comparing. That was also the main reason for this module ;o)

incidentily, '--' as well most other mathematical operations work as you
expected them to work on big integers.

Compare a Math::String of charset '0-9' sequence to that of a 'normal' number:

    ''   0                       0
    '0'  1                       1
    '1'  2                       2
    '2'  3                       3
    '3'  4                       4
    '4'  5                       5
    '5'  6                       6
    '6'  7                       7
    '7'  8                       8
    '8'  9                       9
    '9'  10                     10
   '00'  11                1*10+ 1
   '01'  12                1*10+ 2
       ...
   '98'  109               9*10+ 9
   '99'  110               9*10+10
  '000'  111         1*100+1*10+ 1
  '001'  112         1*100+1*10+ 2
       ...
 '0000'  1111  1*1000+1*100+1*10+1
       ...
 '1234'  2345  2*1000+3*100+4*10+5

And so on. Here is another example that shows how it works with a number
having 4 digits in each place (named "a","b","c", and "d"):

     a    1           1
     b    2           2
     c    3           3
     d    4           4
    aa    5       1*4+1
    ab    6       1*4+2
    ac    7       1*4+3
    ad    8       1*4+4
    ba    9       2*4+1
    bb   10       2*4+2
    bc   11       2*4+3
    bd   12       2*4+4
    ca   13       3*4+1
    cb   14       3*4+2
    cc   15       3*4+3
    cd   16       3*4+4
    da   17       4*4+1
    db   18       4*4+2
    dc   19       4*4+3
    dd   20       4*4+4
   aaa   21  1*16+1*4+1

Here is one with a charset containing 'characters' longer than one, namely
the words 'foo', 'bar' and 'fud':

	   foo		 1
	   bar		 2
	   fud		 3
	foofoo		 4
	foobar		 5
	foofud		 6
	barfoo		 7
	barbar		 8
	barfud		 9
	fudfoo		10
	fudbar		11
	fudfud		12
     foofoofoo		13 etc

The number sequences are symmetrical to 0, e.g. 'a' is both 1 and -1.
Internally the sign is stored and honoured, only on conversation to string it
is lost.

The caveat is that you can NOT use Math::String to work, let's say with
hexadecimal numbers. If you do calculate with Math::String like you would
with 'normal' hexadecimal numbers (any base would or rather, would not do),
the result may not mean anything and can not nesseccarily compared to plain
hexadecimal math.

The charset given upon creation need not be a 'simple' set consisting of all
the letters. You can, actually, give a set consisting of bi-, tri- or higher
grams.

See Math::String::Charset for examples of higher order charsets and charsets
with more than one character per, well, character.

=head1 USEFUL METHODS

=over

=item new()

	Math::String->new();

Create a new Math::String object. Arguments are the value, and optional
charset. The charset is set to 'a'..'z' as default.

Since the charset caches some things, it is much better to give an already
existing Math::String::Charset object to the contructor, instead of creating
a new one for each Math::String. This will save you memory and computing power.
See http://bloodgate.com/perl/benchmarks.html for details, and
L<Math::String::Charset> for how to construct charsets.

=item error()

	$string->error();

Return the last error message or ''. The error message stems primarily from the
underlying charset, and is created when you create an illegal charset.

=item order()

	$string->order();

Return the order of the string derived from the underlying charset.
1 for SIMPLE (or order 1), 2 for bi-grams etc.

=item type()

	$string->type();

Return the type of the string derived from the underlying charset.
0 for simple and nested charsets, 1 for grouped ones.

=item first()

	$string->first($length);

It is a bit tricky to get the first string of a certain length, because you
need to consider the charsets at each digit. This method sets the given
Math::String object to the first possible string of the given length.
The length defaults to 1.

=item last()

	$string->last($length);

It is a bit tricky to get the last string of a certain length, because you
need to consider the charsets at each digit. This method sets the given
Math::String object to the last possible string of the given length.
The length defaults to 1.

=item as_number()

	$string->as_number();

Return internal number as normalized string including sign.

=item from_number()

	$string = Math::String::from_number(1234,$charset);

Create a Math::String from a given integer value and a charset.

If you want to use big integers as input, quote them:

	$string = Math::String::from_number('12345678901234567890',$set);

This avoids loosing precision due to intermidiate storage of the number as
Perl scalar.

=item scale()

	$scale = $string->scale();
	$string->scale(120);

Get/set the (optional) scale of the characterset (thus setting it for all
strings of that set from this point onwards). A scale is an integer factor
that will be applied to each as_number() output as well as each from_number()
input. E.g. for a scale of 3, the string to number mapping would be changed
from the left to the right column:

	string form		normal number	scaled number
	''			0		0
	'a'			1		3
	'b'			2		6
	'c'			3		9

And so on. Input like 8 will be divided by 3, which results in 2 due to
rounding down to the nearest integer. So:

	$string = Math::String->new( 'a' );		# a..z
	print $string->as_number();			# 1
	$string->scale(3);
	print $string->as_number();			# 3
	$string = Math::String->from_number(9,3);	# 9/3 => 3

=item bzero()

	$string = Math::String->bzero($charset);

Create a Math::String with the number value 0 (evaluates to '').
The following would set $x to '':

        $x = Math::String->new('cafebabe');
	$x->bzero();

=item bone()

	$string = Math::String->bone($charset);

Create a Math::String with the number value 1 and the given charset

The following would set $x to the number 1 (and it's respective string):

        $x = Math::String->new('cafebabe');
	$x->bone();

=item binf()

	$string = Math::String->binf($sign);

Create a Math::String with the number infinity.

The following would set $x to -infinity (and it's respective string):

        $x = Math::String->new('deadbeef');
	$x->binf('-');

=item bnan()

	$string = Math::String->bnan();

Create a Math::String as a NotANumber.

The following would set $x to NaN (and it's respective string):

        $x = Math::String->new('deadbeef');
	$x->bnan();

=item is_valid()

	print $string->error(),"\n" if !$string->is_valid();

Returns 0 if the string is valid (according to it's charset and string
representation) and the cached string value matches the string's internal
number represantation. Costly operation, but usefull for tests.

=item class()

	$count = $string->class($length);

Returns the number of possible strings with the given length, aka so many
characters (not bytes or chars!).

	$count = $string->class(3);	# how many strings with len 3

=item minlen()

	$string->minlen();

Return the minimum length of a valid string as defined by it's charset.
Note that the string '' has a length of 0, and thus is not valid if C<minlen>
is greater than 0.
Returns 0 if no minimum length is required. The minimum length must be smaller
or equal to the C<maxlen>.

=item maxlen()

	$string->maxlen();

Return the maximum length of a valid string as defined by it's charset.
Returns 0 if no maximum length is required. The maximum length must be greater
or equal to the C<minlen>.

=item length()

	$string->length();

Return the number of characters in the resulting string (aka it's length). The
zero string '' has a length of 0.

This is faster than doing C<length("$string");> because it doesn't need to do
the costly creation of the string version from the internal number
representation.

Note: The length() will be always in characters. If your characters in the
charset are longer than one byte/character, you need to multiply the length
by the character length to find out how many bytes the string would have.

This is nearly impossible if your character set has characters with different
lengths (aka if it has a separator character). In this case you need to
construct the string to find out the actual length in bytes.

=item bstr()

	$string->bstr();

Return a string representing the internal number with the given charset.
Since this omitts the sign, you can not distinguish between negative and
positiv values. Use C<as_number()> or C<sign()> if you need the sign.

This returns undef for 'NaN', since with a charset of
[ 'a', 'N' ] you would not be able to tell 'NaN' from true 'NaN'!
'+inf' or '-inf' return undef for the same reason.

=item charset()

	$string->charset();

Return a reference to the charset of the Math::String object.

=item string()

	Math::String->string();

Just like new, but you can import it to save typing.

=back

=head1 LIMITS

For the actual math, the same limits as in L<Math::BigInt> apply. Negative
Math::Strings are possible, but produce no different output than positive.
You can use C<as_number()> or C<sign()> to get the sign, or do math with
them, of course.

Also, the limits detailed in L<Math::String::Charset> apply, like:

=over

=item No doubles

The sets must not contain doubles. With a set of "eerr" you would not
be able to tell the output "er" from "er", er, if you get my drift...

=item Charset items

All charset items must have the same length, unless you specify a separator
string:

	use Math::String;

	$b = Math::String->new( '',
           { start => [ qw/ the green car a/ ], sep => ' ', }
	   );

	while ($b ne 'the green car')
          {
	  print ++$b,"\n";	# print "a green car" etc
	  }

=item Objectify

Writing things like

        $a = Math::String::bsub('hal', 'aaa');

does not work, unlike with Math::BigInt (which just knows how to treat
the arguments to become BigInts). The first argument must be a
reference to a Math::String object.

The following two lines do what you want and are more or less (except output)
equivalent:

        $a = new Math::String 'vms'; $a -= 'aaa';
        $a = new Math::String 'ibm'; $a->badd('aaa');

Also, things like

        $a = Math::String::bsub('hal', 5);

does not work, since Math::String can not decide whether 5 is the number 5,
or the string '5'. It could, if the charset does not contain '0'..'9', but
this would lead to confusion if you change the charset. So, the second paramter
must always be a Math::String object, or a string that is valid with the
charset of the first parameter. You can use C<Math::String::from_number()>:

        $a = Math::String::bsub('hal', Math::String::from_number(5) );

=back

=head1 EXAMPLES

Fun with Math::String:

	use Math::String;

	$ibm = new Math::String ('ibm');
	$vms = new Math::String ('vms');
	$ibm -= 'aaa';
	$vms += 'aaa';
	print "ibm is now $ibm\n";
	print "vms is now $vms\n";

Some more serious examples:

        use Math::String;
        use Math::BigFloat;

        $a = new Math::String 'henry';                  # default a-z
        $b = new Math::String 'foobar';                 # a-z

        # Get's you the amount of passwords between 'henry' and 'foobar'.
        print "a  : ",$a->as_numbert(),"\n";
        print "b  : ",$b->as_bigint(),"\n";
        $c = $b - $a; print $c->as_bigint(),"\n";

        # You want to know what is the first or last password of a certain
        # length (without multiple charsets this looks a bit silly):
        print $a->first(5),"\n";                        # aaaaa
        print Math::String::first(5,['a'..'z']),"\n";	# aaaaa
        print $a->last(5),"\n";                         # zzzzz
        print Math::String::last(5,['A'..'Z']),"\n";	# ZZZZZ

        # Lets assume you had a password of length 4, which contained a
        # Capital, some lowercase letters, somewhere either a number, or
        # one of '.,:;', but you forgot it. How many passwords do you need
        # to brute force in the worst case, testing every combination?
        $a = new Math::String '', ['a'..'z','A'..'Z','0'..'9','.',',',':',';'];
        # produce last possibility ';;;;;' and first 'aaaaa'
        $b = $a->last(4);   # last possibility of length 4
        $c = $a->first(4);  # whats the first password of length 4

        $c->bsub($b);
        print $c->as_bigint(),"\n";		# all of length 4
        print $b->as_bigint(),"\n";             # testing length 1..3 too

        # Let's say your computer can test 100.000 passwords per second, how
        # long would it take?
        $d = $c->bdiv(100000);
        print $d->as_bigint()," seconds\n";	#

        # or:
        $d = new Math::BigFloat($c->as_bigint()) / '100000';
        print "$d seconds\n";			#

        # You want your computer to run for one hour and see if the password
        # is to be found. What would be the last password to be tested?
        $c = $b + (Math::BigInt->new('100000') * 3600);
        print "Last tested would be: $c\n";

        # You want to know what the 10.000th try would be
        $c = Math::String->from_number(10000,
         ['a'..'z','A'..'Z','0'..'9','.',',',':',';']);
	print "Try #10000 would be: $c\n";

=head1 PERFORMANCE

For simple things, like generating all passwords from 'a' to 'zzz', this
is expensive and slow. A custom, table-driven generator or the build-in
automagic of ++ (if it would work correctly for all cases, that is ;) would
beat it anytime. But if you want to do more than just counting, then this
code is what you want to use.

=head2 BENCHMARKS

See http://bloodgate.com/perl/benchmarks.html

=head1 BUGS

=over

=item *

Charsets with bi-grams do not work fully yet.

=item *

Adding/subtracting etc Math::Strings with different charsets treats the
second argument as it had the charset of the first. This is thought as a
feature, not a bug.

Only if the first charset contains all the characters of second string, you
could convert the second string to the first charset, but whether this is
usefull is questionable:

	use Math::String;

	$a = new Math::String ( 'a',['a'..'z']);	# is 1
	$z = new Math::String ( 'z',['z'..'a']);	# is 1, too

	$b = $a + $z;					# is 2, with set a..z
	$y = $z + $a;					# is 2, with set z..a

If you convert $z to $a's charset, you would get either an 1 ('a'),
or a 26 ('z'), and which one is the right one is unclear.

=item *

Please report any bugs or feature requests to
C<bug-math-string at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-String> (requires login).
We will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::String

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Dist/Display.html?Name=Math-String>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-String>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Math-String>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-String/>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-String>

=back

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

If you use this module in one of your projects, then please email me. I want
to hear about how my code helps you ;)

Tels http://bloodgate.com 2000 - 2005.

=cut

1;
