#############################################################################
# Math/String/Charset/Grouped.pm -- a charset of charsets for Math/String
#
# Copyright (C) 1999-2003 by Tels. All rights reserved.
#############################################################################

package Math::String::Charset::Grouped;

require 5.005;		# requires this Perl version or later
use strict;

use base 'Math::String::Charset';

our $VERSION;
$VERSION = '1.30';	# Current version of this package

use Math::BigInt;

our $die_on_error;
$die_on_error = 1;              # set to 0 to not die

# following hash values are used:
# _clen  : length of one character (all chars must have same len unless sep)
# _ones  : list of one-character strings (cross of _end and _start)
# _start : contains array of all valid start characters
# _end   : contains hash (for easier lookup) of all valid end characters
# _order : = 1
# _type  : = 1
# _error : error message or ""
# _count : array of count of different strings with length x
# _sum   : array of starting number for strings with length x
#          _sum[x] = _sum[x-1]+_count[x-1]
# _cnt   : number of elements in _count and _sum (as well as in _scnt & _ssum)
# _cnum  : number of characters in _ones as BigInt (for speed)
# _minlen: minimum string length (anything shorter is invalid), default -inf
# _maxlen: maximum string length (anything longer is invalid), default +inf
# _scale : optional input/output scale

# simple ones:
# _sep  : separator string (undef for none)
# _map  : mapping character to number

# higher orders:
# _bi   : hash with refs to array of bi-grams
# _bmap : hash with refs to hash of bi-grams
# _scnt : array of hashes, count of strings starting with this character

# grouped:
# _spat	: array with pattern of charsets 8for each stirnglen one ARRAY ref)

#############################################################################
# private, initialize self

sub _strict_check
  {
  # a per class check, to be overwritten by subclasses
  my $self = shift;
  my $value = shift;

  my $class = ref($self);
  return $self->{_error} = "Wrong type '$self->{_type}' for $class"
    if $self->{_type} != 1;
  return $self->{_error} = "Wrong order'$self->{_order}' for $class"
    if $self->{_order} != 1;
  foreach my $key (keys %$value)
    {
    return $self->{_error} = "Illegal parameter '$key' for $class"
      if $key !~ /^(start|minlen|maxlen|sep|sets|end|charlen|scale)$/;
    }
  }

sub _initialize
  {
  # set yourself to the value represented by the given string
  my $self = shift;
  my $value = shift;

  $self->{_clen} = $value->{charlen};
  $self->{_sep}  = $value->{sep};	# separator char

  return $self->{_error} = "Need HASH ref as 'sets'"
    if (ref($value->{sets}) ne 'HASH');

  # make copy at same time
  foreach my $key (keys %{$value->{sets}})
    {
    $self->{_sets}->{$key} = $value->{sets}->{$key};
    }

  # start/end are sets 1 and -1, respectively, and overwrite 'sets'
  $self->{_sets}->{1} = $value->{start} if exists $value->{start};
  $self->{_sets}->{-1} = $value->{end} if exists $value->{end};
  $self->{_sets}->{0} = $value->{chars} if exists $value->{chars};
  # default set
  $self->{_sets}->{0} = ['a'..'z'] if !defined $self->{_sets}->{0};

  my $sets = $self->{_sets};	# shortcut
  foreach my $set (keys %$sets)
    {
    return $self->{_error} =
      "Entries in 'sets' must be ref to Math::String::Charset or ARRAY"
     if ((ref($sets->{$set}) ne 'ARRAY') &&
      (ref($sets->{$set}) ne 'Math::String::Charset'));

    # so for each set, make a Math::String::Charset
    $sets->{$set} = Math::String::Charset->new($sets->{$set})
      if ref($sets->{$set}) eq 'ARRAY';
    }
  $self->{_start} = $sets->{1} || $sets->{0};
  $self->{_end} = $sets->{-1} || $sets->{0};

  $self->{_clen} = $self->{_start}->charlen() if
   ((!defined $self->{_clen}) && (!defined $self->{_sep}));

  # build _ones list (cross from start/end)
  $self->{_ones} = [];

  # _end is a simple charset, so use it's map directly
  my $end = $self->{_end}->{_map};
  my $o = $self->{_ones};
  foreach ($self->{_start}->start())
    {
    push @$o, $_ if exists $end->{$_};
    }
  #print "\n";

  # some tests for validity
  if (!defined $self->{_sep})
    {
    foreach (keys %{$self->{_sets}})
      {
      my $l = $self->{_sets}->{$_}->charlen();
      return $self->{_error} =
        "Illegal character length '$l' for charset '$_', expected '$self->{_clen}'"
          if $self->{_sets}->{$_}->charlen() != $self->{_clen};

      }
    }
  $self->{_cnum} = Math::BigInt->new( scalar @{$self->{_ones}} );
  # initialize array of counts for len of 0..1
  $self->{_cnt} = 2;				# cached amount of class-sizes
  if ($self->{_minlen} <= 0)
    {
    $self->{_count}->[0] = 1;			# '' is one string
    my $sl = $self->{_start}->length();
    my $el = $self->{_end}->length();
    $self->{_count}->[1] = $self->{_cnum};
    $self->{_count}->[2] = $sl * $el;
    # init _sum array
    $self->{_sum}->[0] = Math::BigInt->bzero();
    $self->{_sum}->[1] = Math::BigInt->bone();		# '' is 1 string
    $self->{_sum}->[2] = $self->{_count}->[1] + $self->{_sum}->[1];
    $self->{_sum}->[3] = $self->{_count}->[2] + $self->{_sum}->[2];
    # init set patterns
    $self->{_spat}->[1] = [ undef, $self->{_sets}->{0} ];
    $self->{_spat}->[2] = [ undef, $self->{_start}, $self->{_end} ];
    }
  else
    {
    $self->{_cnt} = 0;				# cached amount of class-sizes
    }

  # from _ones, make mapping name => number
  my $i = Math::BigInt->bone();
  foreach (@{$self->{_ones}})
    {
    $self->{_map}->{$_} = $i++;
    }

  if ($self->{_cnum}->is_zero())
    {
    $self->{_minlen} = 2 if $self->{_minlen} == 1;	# no one's
    # check whether charset can have 2-character long strings
    if ($self->{_count}->[2] == 0)
      {
      $self->{_minlen} = 3 if $self->{_minlen} == 2;	# no two's
      # check whether some path from start to end set exists, if not: empty
      }
    }
  return $self->{_error} =
   "Minlen ($self->{_minlen} must be smaller than maxlen ($self->{_maxlen})"
    if ($self->{_minlen} > $self->{_maxlen});
  return $self;
  }

sub dump
  {
  my $self = shift;

  my $txt = "type: GROUPED\n";

  foreach my $set (sort { $b<=>$a } keys %{$self->{_sets}})
    {
    $txt .= " $set => ". $self->{_sets}->{$set}->dump('   ');
    }
  $txt .= "ones : " . join(' ',@{$self->{_ones}}) . "\n";
  $txt;
  }

sub _calc
  {
  # given count of len 1..x, calculate count for y (y > x) and all between
  # x and y
  # currently re-calcs from 2 on, we could save the state and only calculate
  # the missing counts.

#  print "calc ",caller(),"\n";
  my $self = shift;
  my $max = shift || 1; $max = 1 if $max < 1;
  return if $max <= $self->{_cnt};

#  print "in _calc $self $max\n";
  my $i = $self->{_cnt};                # last defined element
  my $last = $self->{_count}->[$i];
  while ($i++ <= $max)
    {
    # build list of charsets for this length
    my $spat = [];			# set patterns
    my $sets = $self->{_sets};		# shortcut
    for (my $j = 1; $j <= $i; $j++)
      {
      my $r = $j-$i-1;			# reverse
#      print "$j reversed $r (for $i)\n";
      $spat->[$j] = $sets->{$j} || $sets->{$r};			# one of both?
      $spat->[$j] = $sets->{$j}->merge($sets->{$r}) if
	exists $sets->{$j} && exists $sets->{$r};		# both?
      $spat->[$j] = $sets->{0} unless defined $spat->[$j];	# none?
#      print $spat->[$j]->dump(),"\n";
      }
    $self->{_spat}->[$i] = $spat;				# store
    # for each charset, take size and mul together
    $last = Math::BigInt->bone();
    for (my $j = 1; $j <= $i; $j++)
      {
#      print "$i $spat->[$j]\n";
      $last *= $spat->[$j]->length();
#      print "last $last ",$spat->[$j]->length()," ($spat->[$j])\n";
      }
    $self->{_count}->[$i] = $last;
#    print "$i: count $last ";
    $self->{_sum}->[$i] = $self->{_sum}->[$i-1] + $self->{_count}->[$i-1];
#    print "sum $self->{_sum}->[$i]\n";
    }
  $self->{_cnt} = $i-1;         # store new cache size
  return;
  }

sub is_valid
  {
  # check wether a string conforms to the given charset sets
  my $self = shift;
  my $str = shift;

  # print "$str\n";
  return 0 if !defined $str;
  return 1 if $str eq '' && $self->{_minlen} <= 0;

  my @chars;
  if (defined $self->{_sep})
    {
    @chars = split /$self->{_sep}/,$str;
    shift @chars if $chars[0] eq '';
    pop @chars if $chars[-1] eq $self->{_sep};
    }
  else
    {
    my $i = 0; my $len = CORE::length($str); my $clen = $self->{_clen};
    while ($i < $len)
      {
      push @chars, substr($str,$i,$clen); $i += $clen;
      }
    }
  # length okay?
  return 0 if scalar @chars < $self->{_minlen};
  return 0 if scalar @chars > $self->{_maxlen};

  # valid start char?
  return 0 unless defined $self->{_start}->map($chars[0]);
  return 1 if @chars == 1;
  # further checks for strings longer than 1
  my $k = 1;
  my $d = scalar @chars;
  $self->_calc($d) if ($self->{_cnt} < $d);
  my $spat = $self->{_spat}->[$d];
  foreach my $c (@chars)
    {
    return 0 if !defined $spat->[$k++]->map($c);
    }
  # all tests passed
  1;
  }

sub minlen
  {
  my $self = shift;

  $self->{_minlen};
  }

sub maxlen
  {
  my $self = shift;

  $self->{_maxlen};
  }

sub start
  {
  # this returns all the starting characters in a list, or in case of a simple
  # charset, simple the charset
  # in scalar context, returns length of starting set, for simple charsets this
  # equals the length
  my $self = shift;

  wantarray ? @{$self->{_start}} : scalar @{$self->{_start}};
  }

sub end
  {
  # this returns all the end characters in a list, or in case of a simple
  # charset, simple the charset
  # in scalar context, returns length of end set, for simple charsets this
  # equals the length
  my $self = shift;

  wantarray ? sort keys %{$self->{_end}} : scalar keys %{$self->{_end}};
  }

sub ones
  {
  # this returns all the one-char strings (in scalar context the count of them)
  my $self = shift;

  wantarray ? @{$self->{_ones}} : scalar @{$self->{_ones}};
  }

sub num2str
  {
  # convert Math::BigInt/Math::String to string
  # in list context, return (string,stringlen)
  my $self = shift;
  my $x = shift;

  $x = new Math::BigInt($x) unless ref $x;
  return undef if ($x->sign() !~ /^[+-]$/);
  if ($x->is_zero())
    {
    return wantarray ? ('',0) : '';
    }
  my $j = $self->{_cnum};			# nr of chars

  if ($x <= $j)
    {
    my $c =  $self->{_ones}->[$x-1];
    return wantarray ? ($c,1) : $c;             # string len == 1
    }

  my $digits = $self->chars($x); my $d = $digits;
  # now treat the string as it were a zero-padded string of length $digits

  my $es="";                                    # result
  # copy input, make positive number, correct to $digits and cater for 0
  my $y = Math::BigInt->new($x); $y->babs();
  #print "fac $j y: $y new: ";
  $y -= $self->{_sum}->[$digits];

  $self->_calc($d) if ($self->{_cnt} < $d);
  #print "y: $y\n";
  my $mod = 0; my $s = $self->{_sep}; $s = '' if !defined $s;
  my $spat = $self->{_spat}->[$d];		# set pattern
  my $k = $d;
  while (!$y->is_zero())
    {
    #print "bfore:  y/fac: $y / $j \n";
    ($y,$mod) = $y->bdiv($spat->[$k]->length());
    #$es = $self->{_ones}->[$mod] . $s.$es;
    $es = $spat->[$k--]->char($mod) . $s.$es;	# find mod'th char
    #print "after:  div: $y rem: $mod \n";
    $digits --;                         # one digit done
    }
  # padd the remaining digits with the zero-symbol
  while ($digits-- > 0)
    {
    $es = $spat->[$k--]->char(0) . $s . $es;
    }
  $es =~ s/$s$//;                               # strip last sep 'char'
  wantarray ? ($es,$d) : $es;
  }

sub str2num
  {
  # convert Math::String to Math::BigInt
  my $self = shift;
  my $str = shift;			# simple string

  my $int = Math::BigInt->bzero();
  my $i = CORE::length($str);

  return $int if $i == 0;
  # print "str2num $i $clen '$str'\n";
  my $map = $self->{_map};
  my $clen = $self->{_clen};		# len of one char

  if ((!defined $self->{_sep}) && ($i == $clen))
    {
    return $int->bnan() if !exists $map->{$str};
    return $map->{$str}->copy();
    }

  my $mul = Math::BigInt->bone();
  my $cs;					# charset at pos i
  my $k = 1;					# position
  my $c = 0;					# chars in string
  if (!defined $self->{_sep})
    {
    return $int->bnan() if $i % $clen != 0;	# not multiple times clen
    $c = int($i/$clen);
    $self->_calc($c) if ($self->{_cnt} < $c);
    my $spat = $self->{_spat}->[$c];
#    print "$c ($self->{_cnt}) spat: ",scalar @$spat,"\n";
    $i -= $clen;
    $k = $c;
    while ($i >= 0)
      {
      $cs = $spat->[$k--];			# charset at pos k
#      print "$i $k $cs nr $int ";
#      print "mapped ",substr($str,$i,$clen)," => ",
#       $cs->map(substr($str,$i,$clen)) || 0;
#      print " mul $mul => ";
      $int += $mul * $cs->map(substr($str,$i,$clen));
      $mul *= $cs->length();
#     print "mul $mul\n";
      $i -= $clen;
      }
    }
  else
    {
    # with sep char
    my @chars = split /$self->{_sep}/, $str;
    shift @chars if $chars[0] eq '';                    # strip leading sep
    pop @chars if $chars[-1] eq $self->{_sep}; 		# strip trailing sep
    $c = scalar @chars;
    $self->_calc($c) if ($self->{_cnt} < $c);
    my $spat = $self->{_spat}->[$c];
    $k = $c;
    foreach (reverse @chars)
      {
      $cs = $spat->[$k--];				# charset at pos k
      $int += $mul * $cs->map($_);
      $mul *= $cs->length();
      }
    }
  $int + $self->{_sum}->[$c];				# add base sum
  }

#sub char
#  {
#  # return nth char from charset
#  my $self = shift;
#  my $char = shift || 0;
#
#  return undef if $char > scalar @{$self->{_ones}}; # dont create spurios elems
#  return $self->{_ones}->[$char];
#  }

sub first
  {
  my $self = shift;
  my $count = abs(shift || 0);

  return if $count < $self->{_minlen};
  return if defined $self->{_maxlen} && $count > $self->{_maxlen};
  return '' if $count == 0;

  return $self->{_ones}->[0] if $count == 1;

  $self->_calc($count);
  my $spat = $self->{_spat}->[$count];
  my $es = '';
  my $s = $self->{_sep} || '';
  for (my $i = 1; $i <= $count; $i++)
    {
    $es .= $s . $spat->[$i]->char(0);
    }
  $s = quotemeta($s);
  $es =~ s/^$s// if $s ne '';		# remove first sep
  $es;
  }

sub last
  {
  my $self = shift;
  my $count = abs(shift || 0);

  return if $count < $self->{_minlen};
  return if defined $self->{_maxlen} && $count > $self->{_maxlen};
  return '' if $count == 0;

  return $self->{_ones}->[-1] if $count == 1;

  $self->_calc($count);
  my $spat = $self->{_spat}->[$count];
  my $es = '';
  my $s = $self->{_sep} || '';
  for (my $i = 1; $i <= $count; $i++)
    {
    $es .= $s . $spat->[$i]->char(-1);
    }
  $s = quotemeta($s);
  $es =~ s/^$s// if $s ne '';		# remove first sep
  $es;
  }

sub next
  {
  my $self = shift;
  my $str = shift;

  if ($str->{_cache} eq '')				# 0 => 1
    {
    my $min = $self->{_minlen}; $min = 1 if $min <= 0;
    $str->{_cache} = $self->first($min);
    return;
    }

  # only the rightmost digit is adjusted. If this overflows, we simple
  # invalidate the cache. The time saved by updating the cache would be to
  # small to be of use, especially since updating the cache takes more time
  # then. Also, if the cached isn't used later, we would have spent the
  # update-time in vain.

  # for higher orders not ready yet
  $str->{_cache} = undef;
  }

sub prev
  {
  my $self = shift;
  my $str = shift;

  if ($str->{_cache} eq '')				# 0 => -1
    {
    my $min = $self->{_minlen}; $min = -1 if $min >= 0;
    $str->{_cache} = $self->first($min);
    return;
    }

  # for higher orders not ready yet
  $str->{_cache} = undef;
  }

__END__

#############################################################################

=pod

=head1 NAME

Math::String::Charset::Grouped - A charset of simple charsets for Math::String objects.

=head1 SYNOPSIS

    use Math::String::Charset::Grouped;

=head1 REQUIRES

perl5.005, Exporter, Math::BigInt, Math::String::Charset

=head1 EXPORTS

Exports nothing.

=head1 DESCRIPTION

This module lets you create an charset object, which is used to construct
Math::String objects.

This object can assign for each position in a Math::String a different simple
charset (aka a Math::String::Charset object of order => 1, type => 0).

=over 1

=item Default charset

The default charset is the set containing "abcdefghijklmnopqrstuvwxyz"
(thus producing always lower case output).

=back

=head1 ERORRS

Upon error, the field C<_error> stores the error message, then die() is called
with this message. If you do not want the program to die (f.i. to catch the
errors), then use the following:

	use Math::String::Charset::Grouped;

	$Math::String::Charset::Grouped::die_on_error = 0;

	$a = new Math::String::Charset::Grouped ();	# error, empty set!
	print $a->error(),"\n";

=head1 INTERNAL DETAILS

This object caches certain calculation results (f.i. the number of possible
combinations for a certain string length), thus greatly speeding up
sequentiell Math::String conversations from string to number, and vice versa.

=head1 METHODS

=over

=item new()

            new();

Create a new Math::Charset::Grouped object.

The constructor takes a HASH reference. The following keys can be used:

	minlen		Minimum string length, -inf if not defined
	maxlen		Maximum string length, +inf if not defined
	sets		hash, table with charsets for the different places
	start		array ref to list of all valid (starting) characters
	end		array ref to list of all valid ending characters
	sep		separator character, none if undef

C<start> and C<end> are synomyms for C<< sets->{1} >> and C<< sets->{-1} >>,
respectively. The will override what you specify in sets and are only for
convienence.

The resulting charset will always be of order 1, type 1.

=over 2

=item start

C<start> contains an array reference to all valid starting
characters, e.g. no valid string can start with a character not listed here.

The same can be acomplished by specifying C<< sets->{1} >>.

=item sets

C<sets> contains a hash reference, each key of the hash indicates an index.
Each of the hash entries B<MUST> point either to an ARRAY reference or a
Math::String::Charset of order 1, type 0.

Positive indices (greater than one) count from the left side, negative from
the right. 0 denotes the default charset to be used for unspecified places.

The index count will be used for all string length, so that C<< sets->{2} >> always
refers to the second character from the left, no matter how many characters
the string actually has.

At each of the position indexed by a key, the appropriate charset will be used.

Example for specifying that strings must start with upper case letters,
followed by lower case letters and can end in either a lower case letter or a
number:

	sets => {
	  0 => ['a'..'z'],		# the default
	  1 => ['A'..'Z'],		# first character is always A..Z
	 -1 => ['a'..'z','0'..'9'],	# last is q..z,0..9
	}

In case of overlapping, a cross between the two charsets will be used, that
contains all characters from both of them. The default charset will only
be used when none of the charsets counting from left or right matches.

Given the definition above, valid strings with length 1 consist of:

	['A'..'Z','0'..'9']

Imagine having specified a set at position 2, too:

	sets => {
	  0 => ['a'..'z'],		# the default
	  1 => ['A'..'Z'],		# first character is always A..Z
	  2 => ['-','+','2'],		# second character is - or +
	 -1 => ['a'..'z','0'..'9'],	# last is q..z,0..9
	}

For strings of length one, this character set will not be used. For strings
with length 2 it will be crossed with the set at -1, so that the two-character
long strings will start with ['A'..'Z'] and end in the characters
['-','+','2','0','1','3'..'9'].

The cross is build from left to right, that is first come all characters that
are in the set counting from left, and then all characters in the set
counting from right, except the ones that are in both (since no doubles must be
used).

=item end

C<end> contains an array reference to all valid ending
characters, e.g. no valid string can end with a character not listed here.
Note that strings of length 1 start B<and> end with their only
character, so the character must be listed in C<end> and C<start> to produce
a string with one character.
The same can be acomplished by specifying C<< sets->{-1} >>.

=item minlen

Optional minimum string length. Any string shorter than this will be invalid.
Must be shorter than a (possible defined) maxlen. If not given is set to -inf.
Note that the minlen might be adjusted to a greater number, if it is set to 1
or greater, but there are not valid strings with 2,3 etc. In this case the
minlen will be set to the first non-empty class of the charset.

=item maxlen

Optional maximum string length. Any string longer than this will be invalid.
Must be longer than a (possible defined) minlen. If not given is set to +inf.

=back

=item minlen()

	$charset->minlen();

Return minimum string length.

=item maxlen()

	$charset->maxlen();

Return maximum string length.

=item length()

	$charset->length();

Return the number of items in the charset, for higher order charsets the
number of valid 1-character long strings. Shortcut for
C<< $charset->class(1) >>.

=item count()

Returns the count of all possible strings described by the charset as a
positive BigInt. Returns 'inf' if no maxlen is defined, because there should
be no upper bound on how many strings are possible.

If maxlen is defined, forces a calculation of all possible L</class()> values
and may therefore be very slow on the first call, it also caches possible
lot's of values if maxlen is very high.

=item class()

	$charset->class($order);

Return the number of items in a class.

	print $charset->class(5);	# how many strings with length 5?

=item char()

	$charset->char($nr);

Returns the character number $nr from the set, or undef.

	print $charset->char(0);	# first char
	print $charset->char(1);	# second char
	print $charset->char(-1);	# last one

=item lowest()

	$charset->lowest($length);

Return the number of the first string of length $length. This is equivalent
to (but much faster):

	$str = $charset->first($length);
	$number = $charset->str2num($str);

=item highest()

	$charset->highest($length);

Return the number of the last string of length $length. This is equivalent
to (but much faster):

	$str = $charset->first($length+1);
	$number = $charset->str2num($str);
        $number--;

=item order()

	$order = $charset->order();

Return the order of the charset: is always 1 for grouped charsets.
See also L</type()>.

=item type()

	$type = $charset->type();

Return the type of the charset: is always 1 for grouped charsets.
See also L</order()>.

=item charlen()

	$character_length = $charset->charlen();

Return the length of one character in the set. 1 or greater. All charsets
used in a grouped charset must have the same length, unless you specify a
seperator char.

=item seperator()

	$sep = $charset->seperator();

Returns the separator string, or undefined if none is used.

=item chars()

	$chars = $charset->chars( $bigint );

Returns the number of characters that the string would have, when you would
convert $bigint (Math::BigInt or Math::String object) back to a string.
This is much faster than doing

	$chars = length ("$math_string");

since it does not need to actually construct the string.

=item first()

	$charset->first( $length );

Return the first string with a length of $length, according to the charset.
See C<lowest()> for the corrospending number.

=item last()

	$charset->last( $length );

Return the last string with a length of $length, according to the charset.
See C<highest()> for the corrospending number.

=item is_valid()

	$charset->is_valid();

Check wether a string conforms to the charset set or not.

=item error()

	$charset->error();

Returns "" for no error or an error message that occured if construction of
the charset failed. Set C<$Math::String::Charset::die_on_error> to C<0> to
get the error message, otherwise the program will die.

=item start()

	$charset->start();

In list context, returns a list of all characters in the start set, that is
the ones used at the first string position.
In scalar context returns the lenght of the B<start> set.

Think of the start set as the set of all characters that can start a string
with one or more characters. The set for one character strings is called
B<ones> and you can access if via C<< $charset->ones() >>.

=item end()

	$charset->end();

In list context, returns a list of all characters in the end set, aka all
characters a string can end with.
In scalar context returns the lenght of the B<end> set.

=item ones()

	$charset->ones();

In list context, returns a list of all strings consisting of one character.
In scalar context returns the lenght of the B<ones> set.

This list is the cross of B<start> and B<end>.

Think of a string of only one character as if it starts with and ends in this
character at the same time.

The order of the chars in C<ones> is the same ordering as in C<start>.

=item prev()

	$string = Math::String->new( );
	$charset->prev($string);

Give the charset and a string, calculates the previous string in the sequence.
This is faster than decrementing the number of the string and converting the
new number to a string. This routine is mainly used internally by Math::String
and updates the cache of the given Math::String.

=item next()

	$string = Math::String->new( );
	$charset->next($string);

Give the charset and a string, calculates the next string in the sequence.
This is faster than incrementing the number of the string and converting the
new number to a string. This routine is mainly used internally by Math::String
and updates the cache of the given Math::String.

=back

=head1 EXAMPLES

    use Math::String::Charset::Grouped;

    # not ready yet

=head1 BUGS

None doscovered yet.

=head1 AUTHOR

If you use this module in one of your projects, then please email me. I want
to hear about how my code helps you ;)

This module is (C) Copyright by Tels http://bloodgate.com 2000-2003.

=cut
