#############################################################################
# Math/String/Charset.pm -- package which defines a charset for Math/String
#
# Copyright (C) 1999-2008 by Tels. All rights reserved.
#############################################################################

package Math::String::Charset;

require 5.008003;	# requires this Perl version or later
use strict;

use base 'Exporter';

our ($VERSION, @EXPORT_OK);
$VERSION   = '1.30';	# Current version of this package
@EXPORT_OK = qw/analyze/;

BEGIN
  {
  *analyze = \&study;
  }

use Math::BigInt;

our $CALC;
our $die_on_error;
$die_on_error = 1;		# set to 0 to not die

use Math::String::Charset::Nested;
use Math::String::Charset::Grouped;

# following hash values are used:
# _clen  : length of one character (all chars must have same len unless sep)
# _start : contains array of all valid start characters
# _ones  : list of one-character strings (cross of _end and _start)
# _end   : contains hash (for easier lookup) of all valid end characters
# _order : = 1 (1 = simple, 2 = nested)
# _type  : = 0 (0 = simple, 1 = grouped, 2 = wordlist)
# _error : error message or ""
# _count : array of count of different strings with length x
# _sum   : array of starting number for strings with length x
#          _sum[x] = _sum[x-1]+_count[x-1]
# _cnt   : number of elements in _count and _sum (as well as in _scnt & _ssum)
# _cnum  : number of characters in _ones as BigInt (for speed)
# _minlen: minimum string length (anything shorter is invalid), default -inf
# _maxlen: maximum string length (anything longer is invalid), default undef
# _scale : optional output/input scale

# simple ones:
# _sep  : separator string (undef for none)
# _map  : mapping character to number

# See the other Charset package files for the keys the higher-order charsets use.

my $ONE = Math::BigInt->bone();

BEGIN
  {
  # this will fail if Math::BigInt is loaded with a different lib afterwards!
  $CALC = Math::BigInt->config()->{lib} || 'Math::BigInt::Calc';
  }

#############################################################################

sub new
  {
  my $class = shift;
  $class = ref($class) || $class || __PACKAGE__;

  my $self = bless {}, $class;

  my $value;
  if (!ref($_[0]))
    {
    $value = [ @_ ];
    }
  else
    {
    $value = shift;
    }
  if (ref($value) !~ /^(ARRAY|HASH)$/)
    {
    # got an object, so make copy
    foreach my $k (keys %$value)
      {
      if (ref($value->{$k}) eq 'ARRAY')
        {
        $self->{$k} = [ @{$value->{$k}} ];
        }
      elsif (ref($value->{$k}) eq 'HASH')
        {
        foreach my $j (keys %{$value->{k}})
          {
          $self->{$k}->{$j} = $value->{$k}->{$j};
          }
        }
      else
        {
        $self->{$k} = $value->{$k};
        }
      }
    return $self;
    }

  # convert ARRAY ref into HASH ref in the same go
  $value = $self->_check_params($value);

#  print "new $class type $self->{_type} order $self->{_order} $self->{_error}\n";

  if ($self->{_error} eq '')
    {
    # now route request for initialization to subclasses if we are in baseclass
    if ($class eq 'Math::String::Charset')
      {
      return Math::String::Charset::Grouped->new($value)
        if ($self->{_type} == 1);
      if (($self->{_type} == 2) && ($self->{_order} == 1))
	{
	require Math::String::Charset::Wordlist;
        return Math::String::Charset::Wordlist->new($value);
	}
      return Math::String::Charset::Nested->new($value)
        if ($self->{_order} == 2);
      }
    $self->_strict_check($value);
    $self->_initialize($value);
    }
  die ($self->{_error}) if $die_on_error && $self->{_error} ne '';
  $self;
  }

#############################################################################
# private, initialize self

sub _strict_check
  {
  # a per class check, to be overwritten by subclasses
  my $self = shift;
  my $value = shift;

  my $class = ref($self);
  return $self->{_error} = "Wrong type '$self->{_type}' for $class"
    if $self->{_type} != 0;
  return $self->{_error} = "Wrong order'$self->{_order}' for $class"
    if $self->{_order} != 1;
  foreach my $key (keys %$value)
    {
    return $self->{_error} = "Illegal parameter '$key' for $class"
      if $key !~ /^(start|minlen|maxlen|sep|scale)$/;
    }
  }

sub _check_params
  {
  # check params
  my $self = shift;
  my $value = shift;

  $self->{_error} = ""; 			# no error
  $self->{_count} = [ ];

  # convert array ref to hash
  $value = { start => $value } if (ref($value) eq 'ARRAY');

  # from 1st take clen
  $self->{_clen} = $value->{charlen};
  $self->{_sep} = $value->{sep};

  return $self->{_error} = "Can not have both 'sep' and 'charlen' in new()"
    if ((exists $value->{charlen}) && (exists $value->{sep}));

  $self->{_order} = $value->{order};
  $self->{_type} = $value->{type};

  $self->{_scale} = Math::BigInt->new($value->{scale})
    if exists $value->{scale};

  return $self->{_error} = "Can not have both 'bi' and 'sets' in new()"
    if ((exists $value->{sets}) && (exists $value->{bi}));

  if (!defined $self->{_type})
    {
    $self->{_type} = 0;
    $self->{_type} = 1 if exists $value->{sets};
    }

  if (!defined $self->{_order})
    {
    $self->{_order} = 1;
    $self->{_order} = 2 if exists $value->{bi};
    }

  return $self->{_error} = "Illegal type '$self->{_type}' used with 'bi'"
    if ((exists $value->{bi}) && ($self->{_type} != 0));

  return $self->{_error} = "Illegal type '$self->{_type}' used with 'sets'"
    if ((exists $value->{sets}) && ($self->{_type} == 0));

  return $self->{_error} = "Illegal type '$self->{_type}'"
   if (($self->{_type} < 0) || ($self->{_type} > 2));

  return $self->{_error} =
   "Illegal combination of type '$self->{_type}' and order '$self->{_order}'"
    if (($self->{_type} == 1) && ($self->{_order} != 1));

  if ($self->{_order} == 1)
    {
    return $self->{_error} =
     "Illegal combination of order '$self->{_order}' and 'end'"
      if defined $value->{end};

    return $self->{_error} =
     "Illegal combination of order '$self->{_order}' and 'bi'"
      if defined $value->{bi};
    }

  return $self->{_error} = "Illegal order '$self->{_order}'"
   if (($self->{_order} < 1) || ($self->{_order} > 2));

  $self->{_sep} = $value->{sep};			# sep char or undef
  return $self->{_error} = "Field 'sep' must not be empty"
    if (defined $self->{_sep} && $self->{_sep} eq '');

  $self->{_minlen} = $value->{minlen};
  $self->{_maxlen} = $value->{maxlen};
  $self->{_minlen} = Math::BigInt->binf('-') if !defined $self->{_minlen};
  $self->{_maxlen} = Math::BigInt->binf() if !defined $self->{_maxlen};
  return $self->{_error} = 'Maxlen is smaller than minlen!'
   if ($self->{_minlen} > $self->{_maxlen});

  $value;
  }

sub _initialize
  {
  # init only for simple charsets, the rest is done in subclass
  my $self = shift;
  my $value = shift;

  $self->{_start} = [ ];
  $self->{_start} = [ @{$value->{start}} ] if defined $value->{start};

  $self->{_clen} = CORE::length($self->{_start}->[0])
   if !defined $self->{_sep};

  $self->{_ones} = $self->{_start};

# XXX TODO: remove
#  foreach (@{$self->{_start}}) { $self->{_end}->{$_} = 1; }

  # some more tests for validity
  if (!defined $self->{_sep})
    {
    foreach (@{$self->{_start}})
      {
      $self->{_error} = "Illegal char '$_', length not $self->{_clen}"
       if CORE::length($_) != $self->{_clen};
      }
    }
  # initialize array of counts for len of 0..1
  $self->{_cnt} = 1;				# cached amount of class-sizes
  $self->{_count}->[0] = 1;			# '' is one string
  $self->{_count}->[1] = Math::BigInt->new (scalar @{$self->{_ones}});	# 1

  # init _sum array
  $self->{_sum}->[0] = 0;
  $self->{_sum}->[1] = 1;
  $self->{_sum}->[2] = $self->{_count}->[1] + 1;

  # from _ones, make mapping name => number
  my $i = 1;
  foreach (@{$self->{_ones}})
    {
    $self->{_map}->{$_} = $i++;
    }
  $self->{_cnum} = Math::BigInt->new( scalar @{$self->{_ones}} );

  # _end contains entries for all valid end characters, and since these are the
  # same than in _map, we can reuse _map to save memory and construction time

  $self->{_end} = $self->{_map};

  return $self->{_error} = "Empty charset!"
   if ($self->{_cnum}->is_zero() && $self->{_minlen} > 0);

  $self;
  }

sub scale
  {
  my $self = shift;

  $self->{_scale} = Math::BigInt->new($_[0]) if @_ > 0;
  $self->{_scale};
  }

sub zero
  {
  # return the string representing zero. If no minlen is defined, this is
  # simple '', otherwise the first string of the first class after minlen which
  # is not empty
  my $self = shift;

  return $self->{_zero} if defined $self->{_zero};	# already known?

  return '' if $self->{_minlen} > 0;
  my $i = $self->{_minlen};
  while ($self->class($i) == 0) { $i++; }
  $self->{_minlen} = $i;				# adjust minlen
  $self->{_zero} = $self->first($i);
  $self->{_zero};
  }

sub one
  {
  # return the string representing one. If no minlen is defined, this is
  # simple the first string with length(1), otherwise the first string of the
  # first class after minlen which is not empty
  my $self = shift;

  return '' if $self->{_minlen} > 0;
  my $i = $self->{_minlen};
  while ($self->class($i) == 0) { $i++; }
  $self->{_minlen} = $i;				# adjust minlen
  $self->first($i)->next();
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
    if (ref($x->{$k}) eq 'SCALAR')
      {
      $self->{$k} = \${$x->{$k}};
      }
    elsif (ref($x->{$k}) eq 'ARRAY')
      {
      $self->{$k} = [ @{$x->{$k}} ];
      }
    elsif (ref($x->{$k}) eq 'HASH')
      {
      # only one level deep!
      foreach my $h (keys %{$x->{$k}})
        {
        $self->{$k}->{$h} = $x->{$k}->{$h};
        }
      }
    elsif (ref($x->{$k}))
      {
      my $c = ref($x->{$k});
      $self->{$k} = $c->new($x->{$k});  # no copy() due to deep rec
      }
    else
      {
      # simple scalar w/o reference
      $self->{$k} = $x->{$k};
      }
    }
  $self;
  }

sub count
  {
  # Return count of all possible strings described by in charset as positive
  # bigint. Returns 'inf' if no maxlen is defined, because there should be no
  # upper bound on how many strings are possible.
  # if maxlen is defined, forces a calculation of all possible class() values
  # and may therefore be slow on the first call, also caches possible lot's of
  # values.
  my $self = shift;
  my $count = Math::BigInt->bzero();

  return $count->binf() if $self->{_maxlen}->is_inf();

  for (my $i = 0; $i < $self->{_maxlen}; $i++)
    {
    $count += $self->class($i);
    }
  $count;
  }

sub dump
  {
  my $self = shift;
  my $indend = shift || '';

  my $txt = "type SIMPLE:\n";
  $txt .= $indend . "start: " . join(' ',@{$self->{_start}}) . "\n";
  my $e = $self->{_end};
  $txt .= $indend . "end  : " . join(' ', sort { $e->{$a} <=> $e->{$b} } keys %$e) . "\n";
  $txt .= $indend . "ones : " . join(' ',@{$self->{_ones}}) . "\n";
  $txt;
  }

sub error
  {
  my $self = shift;

  $self->{_error};
  }

sub order
  {
  # return charset's order/class
  my $self = shift;
  $self->{_order};
  }

sub type
  {
  # return charset's type
  my $self = shift;
  $self->{_type};
  }

sub charlen
  {
  # return charset's length of one character
  my $self = shift;
  $self->{_clen};
  }

sub length
  {
  # return number of characters in charset
  my $self = shift;

  scalar @{$self->{_ones}};
  }

sub _calc
  {
  # given count of len 1..x, calculate count for y (y > x) and all between
  # x and y
  my $self = shift;
  my $max = shift || 1; $max = 1 if $max < 1;
  return if $max <= $self->{_cnt};

  my $i = $self->{_cnt}; 		# last defined element
  my $last = $self->{_count}->[$i];
  my $size = Math::BigInt->new ( scalar @{$self->{_ones}} );
  while ($i <= $max)
    {
    $last = $last * $size;
    $self->{_count}->[$i+1] = $last;
    $self->{_sum}->[$i+1] = $self->{_sum}->[$i] + $self->{_count}->[$i];
    $i++;
    }
  $self->{_cnt} = $i-1;		# store new cache size
  }

sub class
  {
  # return number of all combinations with a certain length
  my $self = shift;
  my $len = shift; $len = 0 if !defined $len;
  $len = abs(int($len));

  return 0 if $len < $self->{_minlen} || $len > $self->{_maxlen};

  # print "$len $self->{_minlen}\n";
  $len -= $self->{_minlen} if $self->{_minlen} > 0;	# correct
  # not known yet, so calculate and cache
  $self->_calc($len) if $self->{_cnt} < $len;
  $self->{_count}->[$len];
  }

sub lowest
  {
  # return number of first string with $length characters
  # equivalent to $charset->first($length)->num2str();
  my $self = shift;
  my $len = abs(int(shift || 1));

  # not known yet, so calculate and cache
  $self->_calc($len) if $self->{_cnt} < $len;
  $self->{_sum}->[$len];
  }

sub highest
  {
  # return number of first string with $length characters
  # equivalent to $charset->first($length)->num2str();
  my $self = shift;
  my $len = abs(int(shift || 1));

  $len++;
  # not known yet, so calculate and cache
  $self->_calc($len) if $self->{_cnt} < $len;
  $self->{_sum}->[$len]-1;
  }

sub norm
  {
  # normalize a string by removing separator char at front/end
  my $self = shift;
  my $str = shift;

  return $str if !defined $self->{_sep};

  $str =~ s/$self->{_sep}\z//;		# remove at end
  $str =~ s/^$self->{_sep}//;		# remove at front
  $str;
  }

sub is_valid
  {
  # check wether a string conforms to the given charset set
  my $self = shift;
  my $str = shift;

  # print "$str\n";
  return 0 if !defined $str;
  if ($str eq '')
    {
    return $self->{_minlen} <= 0 ? 1 : 0;
    }

  #my $int = Math::BigInt->bzero();
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
  return 0 if scalar @chars < $self->{_minlen} || scalar @chars > $self->{_maxlen};

  # valid start char?
  my $map = $self->{_map};
  # XXX TODO: remove
  # return 0 unless exists $map->{$chars[0]};
  foreach (@chars)
    {
    return 0 unless exists $map->{$_};
    }
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
  # in list context return string and stringlen
  my ($self,$x) = @_;

  $x = Math::BigInt->new($x) unless ref $x;

  return undef if $x->{sign} !~ /^[+-]$/;

  my $j = $self->{_cnum};			# nr of chars

  if ($self->{_minlen} <= $ONE)
    {
    if ($x->is_zero())
      {
      return wantarray ? ('',0) : '';
      }

    # single character?
    if ($x <= $j && $self->{_minlen} <= $ONE)
      {
      my $c = $self->{_ones}->[$x->numify() - 1];
      return wantarray ? ($c,1) : $c; 		# string len == 1
      }
    }

  my $digits = $self->chars($x); my $d = $digits;

  # now treat the string as it were a zero-padded string of length $digits

  # length is not right (too short or too long)
  if ($digits < $self->{_minlen} || $digits > $self->{_maxlen})
    {
    return wantarray ? (undef,0) : undef;
    }

  my $es="";                    		# result
  # copy input, make positive number, correct to $digits and cater for 0
  my $y = Math::BigInt->new($x); $y->babs();
  #print "fac $j y: $y new: ";
  $y -= $self->{_sum}->[$digits];

  #print "y: $y\n";
  my $mod = 0; my $s = $self->{_sep}; $s = '' if !defined $s;
  while (!$y->is_zero())
    {
    #print "bfore:  y/fac: $y / $j \n";
    ($y,$mod) = $y->bdiv($j);
    $es = $self->{_ones}->[$mod] . $s . $es;
    #print "after:  div: $y rem: $mod \n";
    $digits --;				# one digit done
    }
  # padd the remaining digits with the zero-symbol
  $es = ($self->{_ones}->[0].$s) x $digits . $es if ($digits > 0);
  $es =~ s/$s\z//;				# strip last sep 'char'
  wantarray ? ($es,$d) : $es;
  }

sub str2num
  {
  # convert Math::String to Math::BigInt (does not take scale into account)
  my ($self,$str) = @_;

  my $int = Math::BigInt->bzero();
  my $i = CORE::length($str);

  return $int if $i == 0;
  my $map = $self->{_map};
  my $clen = $self->{_clen} || 0;	# len of one char

  if ($i == $clen)
    {
    $int->{value} = $CALC->_new( $map->{$str} );
    return $int;
    }

  my $cnum = $self->{_cnum}; my $j;
  if (ref($cnum))
    {
    $j = $cnum->{value};
    }
  else
    {
    $j = $CALC->_new($cnum);
    }

  if (!defined $self->{_sep})
    {
    # first step (mul = 1):
    # 0 + 1 * str => str
    $i -= $clen;
    $int->{value} = $CALC->_new( $map->{substr($str,$i,$clen)});
    my $mul = $CALC->_copy($j);

    # other steps:
    $i -= $clen;
    # while ($i >= 0)
    while ($i > 0)
      {
      $CALC->_add( $int->{value}, $CALC->_mul( $CALC->_copy($mul), $CALC->_new( $map->{substr($str,$i,$clen)} )));
      $CALC->_mul( $mul , $j);
      $i -= $clen;
#      print "s2n $int j: $j i: $i m: $mul c: ",
#      substr($str,$i+$clen,$clen),"\n";
      }
    # last step (no need to update $i or preserving/updating $mul)
    $CALC->_add( $int->{value}, $CALC->_mul( $CALC->_copy($mul), $CALC->_new( $map->{substr($str,$i,$clen)} )));
    }
  else
    {
    # with sep char
    my $mul = $CALC->_one();
    my @chars = split /$self->{_sep}/, $str;
    shift @chars if $chars[0] eq '';			# strip leading sep
    foreach (reverse @chars)
      {
      $CALC->_add( $int->{value}, $CALC->_mul( $CALC->_copy($mul), $CALC->_new( $map->{$_} )));
      $CALC->_mul( $mul , $j);
      }
    }

  $int;
  }

sub char
  {
  # return nth char from charset (see also map())
  my $self = shift;
  my $char = shift || 0;

  return undef if $char > scalar @{$self->{_ones}}; 	# dont create spurios elems
  $self->{_ones}->[$char];
  }

sub map
  {
  # map char to number (see also char())
  my ($self,$char) = @_;

  return undef unless defined $char && exists $self->{_map}->{$char};
  $self->{_map}->{$char} - 1;
  }

sub chars
  {
  # return number of characters in output string
  my ($self,$x) = @_;

  return 0 if $x->is_zero() || $x->is_nan() || $x->is_inf();
  my $i = 1;
  my $y = $x->as_number()->babs();

  while ($y >= $self->{_sum}->[$i])
    {
    $self->_calc($i) if $self->{_cnt} < $i;
    $i++;
    }
  --$i;			# correct for last ++
  }

sub first
  {
  my $self = shift;
  my $count = abs(shift || 0);

  return if $count < $self->{_minlen};
  return if defined $self->{_maxlen} && $count > $self->{_maxlen};
  return '' if $count == 0;

  my $t = ($self->{_sep}||'') . $self->{_ones}->[0];
  my $es = $t x $count;
  $es =~ s/^$self->{_sep}// if defined $self->{_sep};
  $es;
  }

sub last
  {
  my $self = shift;
  my $count = abs(shift || 0);

  return if $count < $self->{_minlen};
  return if defined $self->{_maxlen} && $count > $self->{_maxlen};
  return '' if $count == 0;

  my $t = ($self->{_sep}||'') . $self->{_ones}->[-1];
  my $es = $t x $count;
  $es =~ s/^$self->{_sep}// if defined $self->{_sep};
  $es;
  }

sub next
  {
  # take one string, and return the next string following it (without
  # converting the string to it's number form first for speed reasons)
  my ($self,$str) = @_;

  if ($str->{_cache} eq '')				# 0 => 1
    {
    #my $min = $self->{_minlen};
    #$str->{_cache} = $self->first($min) and return if $min->is_positive();
    $str->{_cache} = $self->{_ones}->[0];
    return;
    }

  # only the rightmost digit is adjusted. If this overflows, we simple
  # invalidate the cache. The time saved by updating the cache would be to
  # small to be of use, especially since updating the cache takes more time
  # then. Also, if the cached isn't used later, we would have spent the
  # update-time in vain.

  # simple charsets
  my $char;
  my $clen = $self->{_clen};
  my $s = \$str->{_cache};		# ref to cache contents
  my $sep = $self->{_sep};
  if (defined $sep)
    {
    # split last part
    $$s =~ /.*$sep(.*?)\z/; $char = $1;
    $char = $$s unless $$s =~ /$sep/;
    }
  else
    {
    # extract last char
    $char = substr($$s,-$clen,$clen);
    }
  my $old = $char;	# for seperator replacement
  $char = $self->{_map}->{$char};	# map is +1 by default
  $char -=2 if $str->{sign} eq '-';
  if ((!defined $char) || ($char >= @{$self->{_start}}) || ($char < 0))
    {
    # overflow
    $str->{_cache} = undef;		# invalidate cache
    return;
    }
  $char = $self->{_start}->[$char];	# num 2 char
  if (defined $sep)
    {
    # split last part and replace
    $$s =~ s/$old\z/$char/;
    }
  else
    {
    # replace the last char
    substr($$s,-$clen,$clen) = $char;
    }
  }

sub prev
  {
  my ($self,$str) = @_;

  if ($str->{_cache} eq '')				# 0 => -1
    {
    my $min = $self->{_minlen};
    $str->{_cache} = undef, and return if $min->is_positive(); # >= 0;
    $str->{_cache} = $self->{_ones}->[0];
    return;
    }

  # simple charsets
  my $char;
  my $clen = $self->{_clen};
  my $s = \$str->{_cache};
  my $sep = $self->{_sep};
  if (defined $sep)
    {
    # split last part and replace
    $$s =~ /.*$sep(.*?)\z/; $char = $1;
    $char = $$s unless $$s =~ /$sep/;
    }
  else
    {
    # extract last char and replace
    $char = substr($$s,-$clen,$clen);
    }

  my $old = $char;	# for seperator replacement
  if ((defined $char) && (exists $self->{_map}->{$char}))
    {
    $char = $self->{_map}->{$char} - 1;
    $char += $str->{sign} eq '-' ? 1 : -1;
    if ($char < 0 || $char >= @{$self->{_start}})
      {
      $str->{_cache} = undef;			# invalidate cache
      return; 					# under or overflow
      }
    }
  else
    {
    $str->{_cache} = undef;			# invalidate cache
    return; 					# underflow if char not defined
    }
  $char = $self->{_start}->[$char];		# map num back to char
  if (defined $self->{_sep})
    {
    $$s =~ s/$old\z/$char/; 			# split last part and replace
    }
  else
    {
    substr($$s,-$clen,$clen) = $char;		# simple replace
    }
  }

sub merge
  {
  # merge yourself with another simple charset
  my $self = shift;
  #my $other = shift;

  # TODO
  $self;
  }

###############################################################################

sub study
  {
  # study a list of words and return a hash describing them
  # study ( { order => $depth, words = \@words, sep => ''}, charlen => 1,
  # hist => 1, );

  my $arg;
  if (ref $_[0] eq 'HASH')
    {
    $arg = shift;
    }
  else
    {
    $arg = { @_ };
    }

  my $depth = abs($arg->{order} || $arg->{depth} || 1);
  my $words = $arg->{words} || [];
  #my $sep = $arg->{sep};
  my $charlen = $arg->{charlen} || 1;
  #my $cut = $arg->{cut} || 0;
  my $hist = $arg->{hist} || 0;

  die "depth of study must be between 1..2" if ($depth < 1 || $depth > 2);
  my $starts = {};              # word starts
  my $ends = {};                # word ends
  my $chars = {};               # for depth 1
  my $bi = { }; my ($l,$x,$y,$i);
  foreach my $word (@$words)
    {
    # count starting chars and ending chars
    $starts->{substr($word,0,$charlen)} ++;
    $ends->{substr($word,-$charlen,$charlen)} ++;
    $l = CORE::length($word) / $charlen;
    next if (int($l) != $l);			# illegal word
    if ($depth == 1)
      {
      for (my $i = 0; $i < $l; $i += $charlen)
        {
        $chars->{substr($word,$i,$charlen)} ++;
        }
      next;					# next word
      }
    $l = $l - $depth + 1;
    for ($i = 0; $i < $l; $i += $charlen)
      {
      $x = substr($word,$i,$charlen); $y = substr($word,$i+$charlen,$charlen);
      $bi->{$x}->{$y} ++;
      }
    }
  my $args = {};
  my (@end,@start);
  foreach (sort { $starts->{$b} <=> $starts->{$a} } keys %$starts)
    {
    push @start, $_;
    }
  $args->{start} = \@start;
  foreach (sort { $ends->{$b} <=> $ends->{$a} } keys %$ends)
    {
    push @end, $_;
    }
  $args->{end} = \@end;
  if ($depth > 1)
    {
    #my @sorted;
    foreach my $c (keys %$bi)
      {
      my $bc = $bi->{$c};
      $args->{bi}->{$c} = [
        sort { $bc->{$b} <=> $bc->{$a} or $a cmp $b } keys %$bc
        ];
      }
    }
  else
    {
    my @chars = ();
    foreach (sort { $chars->{$b} <=> $chars->{$a} } keys %$chars)
      {
      push @chars, $_;
      }
    $args->{chars} = \@chars;
    }
  if ($hist != 0)
    {
    # return histogram
    if ($depth > 1)
      {
      $args->{hist} = $bi;
      }
    else
      {
      $args->{hist} = $chars;
      }
    }
  $args;
  }

__END__

#############################################################################

=pod

=head1 NAME

Math::String::Charset - A simple charset for Math::String objects.

=head1 SYNOPSIS

    use Math::String::Charset;

    $a = new Math::String::Charset;		# default a-z
    $b = new Math::String::Charset ['a'..'z'];	# same
    $c = new Math::String::Charset
	{ start => ['a'..'z'], sep => ' ' };	# with ' ' between chars

    print $b->length();				# a-z => 26

    # construct a charset from bigram table, and an initial set (containing
    # valid start-characters)
    # Note: After an 'a', either an 'b', 'c' or 'a' can follow, in this order
    #       After an 'd' only an 'a' can follow
    $bi = new Math::String::Charset ( {
      start => 'a'..'d',
      bi => {
        'a' => [ 'b', 'c', 'a' ],
        'b' => [ 'c', 'b' ],
        'c' => [ 'a', 'c' ],
        'd' => [ 'a', ],
	'q' => [ ],			# 'q' will be automatically in end
        }
      end => [ 'a', 'b', ],
      } );
    print $bi->length();		# 'a','b' => 2 (cross of end and start)
    print scalar $bi->class(2);		# count of combinations with 2 letters
					# will be 3+2+2+1 => 8

    $d = new Math::String::Charset ( { start => ['a'..'z'],
      minlen => 2, maxlen => 4, } );

    print $d->first(0),"\n";		# undef, too short
    print $d->first(1),"\n";		# undef, to short
    print $d->first(2),"\n";		# 'aa'

    $d = new Math::String::Charset ( { start => ['a'..'z'] } );

    print $d->first(0),"\n";		# ''
    print $d->first(1),"\n";		# 'a'
    print $d->last(1),"\n";		# 'z'
    print $d->first(2),"\n";		# 'aa'

=head1 REQUIRES

perl5.005, Exporter, Math::BigInt

=head1 EXPORTS

Exports nothing on default, can export C<analyze>.

=head1 DESCRIPTION

This module lets you create an charset object, which is used to contruct
Math::String objects. This object knows how to handle simple charsets as well
as complex onex consisting of bi-grams (later tri and more).

In case of more complex charsets, a reference to a
L<Math::String::Charset::Nested> or L<Math::String::Charset::grouped> will be
returned.

=over 1

=item Default charset

The default charset is the set containing "abcdefghijklmnopqrstuvwxyz"
(thus producing always lower case output).

=back

=head1 ERORRS

Upon error, the field C<_error> stores the error message, then die() is called
with this message. If you do not want the program to die (f.i. to catch the
errors), then use the following:

	use Math::String::Charset;

	$Math::String::Charset::die_on_error = 0;

	$a = new Math::String::Charset ();	# error, empty set!
	print $a->error(),"\n";

=head1 INTERNAL DETAILS

This object caches certain calculation results (f.i. the number of possible
combinations for a certain string length), thus greatly speeding up
sequentiell Math::String conversations from string to number, and vice versa.

=head2 CHARACTER LENGTH

All characters used to construct the charset must have the same length, but
need not neccessarily be one byte/char long.

=head2 COMPLEXITY

The complexity for converting from number to string, and vice versa,
is O(N), with N beeing the number of characters in the string.

Actually, it is a bit higher, since the underlying Math::BigInt needs more
time for longer numbers than for shorts. But usually the practically string
length limit is reached before this effect shows up.

See BENCHMARKS in Math::String for run-time details.

=head2 STRING ORDERING

With a simple charset, converting between the number and string is relatively
simple and straightforward, albeit slow.

With bigrams, this becomes even more complex. But since all the information
on how to convert between number and string in inside the charset definition,
Math::String::Charset will produce (and sometimes cache) this information.
Thus Math::String is simple a hull around Math::String::Charset and
Math::BigInt.

=head2 SIMPLE CHARSETS

Depending on the charset, the order in which Math::String 'sees' the strings
is different. Example with charset 'A'..'D':

          A      1
          B      2
          C      3
          D      4
         AA      5
         AB      6
         AC      7
         AD      8
         BA      9
         BB     10
         BC     11
         ..
        AAA     20
        AAB     21 etc

The order of characters does not matter, 'B','D','C','A' will produce similiar
results, though in a different order inside Math::String:

          B      1
          D      2
          C      3
          A      4
         BB      5
         BD      6
         BC      7
         ..
        BBB     20
        BBD     21 etc

Here is an example with characters of length 3:

	foo	 1
	bar	 2
	baz	 3
     foofoo	 4
     foobar	 5
     foobaz	 6
     barfoo      7
     barbar      8
     barbaz      9
     bazfoo	10
     bazbar	11
     bazbaz	12
  foofoofoo	13 etc

All charset items must have the same length, unless you use a separator string:

	use Math::String;

        $a = Math::String->new('',
          { start => [ qw/ the green car a/ ], sep => ' ' } );

        while ($b ne 'the green car')
          {
	  $a ++;
          print "$a\t";         # print "a green car" etc
          }

The separator is a string, not a regexp and it must not be present in any
of the characters of the charset.

The old way was using a fill character, which is more complicated:

        use Math::String;

        $a = Math::String->new('', [ qw/ the::: green: car::: a:::::/ ]);

        while ($b ne 'the green car')
          {
          $a ++;
          print "$a\t";         # print "a:::::green:car:::" etc

          $b = "$a"; $b =~ s/:+/ /g; $b =~ s/\s+$//;
          print "$b\n";         # print "a green car" etc
          }

This produces:

	the:::  the
	green:  green
	car:::  car
	a:::::  a
	the:::the:::    the the
	the:::green:    the green
	the:::car:::    the car
	the:::a:::::    the a
	green:the:::    green the
	green:green:    green green
	green:car:::    green car
	green:a:::::    green a
	car:::the:::    car the
	car:::green:    car green
	car:::car:::    car car
	car:::a:::::    car a
	a:::::the:::    a the
	a:::::green:    a green
	a:::::car:::    a car
	a:::::a:::::    a a
	the:::the:::the:::      the the the
	the:::the:::green:      the the green
	the:::the:::car:::      the the car
	the:::the:::a:::::      the the a
	the:::green:the:::      the green the
	the:::green:green:      the green green
	the:::green:car:::      the green car

=head2 HIGHER ORDERS

Now imagine a charset that is defined as follows:

Starting characters for each string can be 'a','c','b' and 'd' (in that order).
Each 'a' can be followed by either 'b', 'c' or 'a' (again in that order),
each 'c can be followed by either 'c', 'd' (again in that order),
and each 'b' or 'd' can be followed by an 'a' (and nothing else).

The definition is thus:

        use Math::String::Charset;

        $cs = Math::String::Charset->new( {
                start => [ 'a', 'c', 'b', 'd' ],
                bi => {
                  'a' => [ 'b','c','a' ],
                  'b' => [ 'a', ],
                  'd' => [ 'a', ],
                  'c' => [ 'c','d' ],
                  }
                } );

This means that each character in a string depends on the previous character.
Please note that the probabilities on which characters follows how often which
character do not concern us here. We simple enumerate them all. Or put
differently: each probability is 1.

With the charset above, the string sequence runs as follows:

        string  number  count of strings
                        with length

          a       1
          c       2
          b       3
          d       4     1=4
         ab       5
         ac       6
         aa       7
         cc       8
         cd       9
         ba      10
         da      11     2=7
        aba      12
        acc      13
        acd      14
        aab      15
        aac      16
        aaa      17
        ccc      18
        ccd      19
        cda      20
        bab      21
        bac      22
        baa      23
        dab      24
        dac      25
        daa      26     3=15
       abab      27
       abac      28
       abaa      29
       accc      30
       accd      31
       acda      32
       aaba      33
       aacc      34
       aacd      35	etc


There are 4 strings with length 1, 7 with length 2, 15 with length 3 etc. Here
is an example for first() and last():

	$charset->first(3);	# gives aba
	$charset->last(3);	# gives daa

=head2 RESTRICTING STRING ENDINGS

Sometimes, you want to specify that a string can end only in certain
characters. There are two ways:

        use Math::String::Charset;

        $cs = Math::String::Charset->new( {
                start => [ 'a', 'c', 'b', 'd' ],
                bi => {
                  'a' => [ 'b','c','a' ],
                  'b' => [ 'a', ],
                  'd' => [ 'a', ],
                  'c' => [ 'c','d' ],
                  }
                end => [ 'a','b' ],
                } );

This defines any string ending not in 'a' or 'b' as invalid. The sequence runs
thus:

        string  number  count of strings
                        with length

          a       1
          b       2     2
         ab       4
         aa       5
         ba       6
         da       7     4
        aba       8
        aab       9
        aaa      10
        cda      11
        bab      12
        baa      13
        dab      14
        daa      15     8
       abab      16
       abaa      17	etc

There are now only 2 strings with length 1, 4 with length 2, 8 with length 3
etc.

The other way is to specify the (additional) ending restrictions implicit by
using chars that are not followed by other characters:

	use Math::String::Charset;

        $cs = Math::String::Charset->new( {
                start => [ 'a', 'c', 'b', 'd' ],
                bi => {
                  'a' => [ 'b','c','a' ],
                  'b' => [ 'a', ],
                  'd' => [ 'a', ],
                  'c' => [  ],
                  }
                } );

Since 'c' is not followed by any characters, there are no strings with a 'c'
in the middle (which means strings can end in 'c'):

        string  number  count of strings
                        with length

          a       1
          c       2
          b       3
          d       4     4
         ab       5
         ac       6
         aa       7
         ba       8
         da       9     5
        aba      10
        aab      11
        aac      12
        aaa      13
        bab      14
        bac      15
        baa      16
        dab      17
        dac      18
        daa      19     10
       abab      20
       abac      21 etc

There are now 4 strings with length 1, 5 with length 2, 10 with length 3
etc.

Any character that is not followed by another character is automatically
added to C<end>. This is because otherwise you would have created a rendundand
character which could never appear in any string:

Let's assume 'q' is not in the C<end> set, and not followed by any other
character:

=over 2

=item 1

There can no string "q", since strings of lenght 1 start B<and> end with their
only character. Since 'q' is not in C<end>, the string "q" is invalid (no
matter wether 'q' appears in C<start> or not).

=item 2

No string longer than 1 could start with 'q' or have a 'q' in the middle,
since 'q' is not followed by anything. This leaves only strings with length
1 and these are invalid according to rule 1.

=back

=head2 CONVERTING (STRING <=> NUMBER)

From now on, a 'class' refers to all strings with the same length.
The order or length of a class is the length of all strings in it.

With a simple charset, each class has exactly M times more strings than the
previous class (e.g. the class with a length - 1). M is in this case the length
of the charset.

=head2 SIMPLE CHARSET

To convert between string and number, we must simple know which string has
which number and which number is which string. Although this sounds very
difficult, it is not so. With 'simple' charsets, it only involves a bit of
math.

First we need to know how many string are in the class. From
this information we can determine the lenght of a string given it's number,
and get the range inside which the number to a string lies:

Let's stick to the example with 4 characters above, 'A'..'D':

        Stringlenght    strings with that length        first in range
        1               4                               1
        2               16 (4*4)                        5
        3               64 (4*4*4)                      21
        4               4**4                            85
        5               4**5 etc                        341

You see that this is easy to calculate. Now, given the number 66,
we can determine how long the string must be:

66 is greater than 21, but lower than 85, so the string must be 3 characters
long. This information is determined in O(N) steps, wheras N is the length
of the string by successive comparing the number to the elements in all
string of a certain length.

If we then subtract from 66 the 21, we get 45 and thus know it must be the
fourty-fifth string of the 3 character long ones.

The math involved to determine which 3 character-string it actually is
equally to converting between decimal and hexadecimal numbers. Please see
source for the gory, but boring details.

=head2 HIGHER ORDER CHARSETS

For charsets of higher order, even determining the number of all strings in a
class becomes more difficult. Fortunately, there is a way to do it in N steps
just like with a simple charset.

=head2 BASED ON ENDING COUNTS

The first way is based on the observation that the number of strings in class
n+1 only depends on the number of ending chars in class n, and nothing else.

This is, however, not used in the current implemenation, since there is a
slightly faster/simpler way based on the count of strings that start with a
given character in class n, n-1, n-2 etc. See below for a description.

Here is for reference the example with ending char counts:

        use Math::String::Charset;

        $cs = Math::String::Charset->new( {
                start => [ 'a', 'c', 'b', 'd' ],
                bi => {
                  'a' => [ 'b','c','a' ],
                  'c' => [ 'c','d' ],
                  'b' => [ 'a', ],
                  'd' => [ 'a', ],
                  }
                } );

        Class 1:
          a       1
          c       2
          b       3
          d       4     4

As you can see, there is one 'a', one 'c', one 'b' and one 'd'.
To determine how many strings are in class 2, we must multiply the occurances
of each character by the number of how many characters it is followed:

        a * 3 + c * 2 + d * 1 + b * 1

which equals

        1 * 3 + 1 * 2 + 1 * 1 + 1 * 1

If we summ this all up, we get 3+2+1+1 = 7, which is exactly the number of
strings in class 2. But to determine now the number of strings in class 3,
we must now how many strings in class 2 end on 'a', how many on 'b' etc.

We can do this in the same loop, by not only keeping a sum, but by counting
all the different endings. F.i. exactly one string ended in 'a' in class 1.
Since 'a' can be followed by 3 characters, for each character we know that it
will occure at least 1 time. So we add the 1 to the character in question.

        $new_count->{'b'} += $count->{'a'};

This yields the amounts of strings that end in 'b' in the next class.

We have to do this for every different starting character, and for each of the
characters that follows each starting character. In the worst case this means
M*M steps, while M is the length of the charset. We must repeat this for each
of the classes, so that the complexity becomes O(N*M*M) in the worst case.
For strings of higher order this gets worse, adding a *M for each higher order.

For our example, after processing 'a', we will have the following counts for
ending chars in class 2:

        b => 1
        c => 1
        a => 1

After processing 'c', it is:

        b => 1
        c => 2 (+1)
        a => 1
        d => 1 (+1)

because 'c' is followed by 'd' or 'c'. When we are done with all characters,
the following count's are in our $new_count hash:

        b => 1
        c => 2
        a => 3
        d => 1

When we sum them up, we get the count of strings in class 2. For class 3, we
start with an empty count hash again, and then again for each character
process the ones that follow it. Example for a:

        b => 0
        c => 0
        a => 0
        d => 0

3 times ending in 'a' followed by 'b','c' or 'd':

        b => 3  (+3)
        c => 3  (+3)
        a => 3  (+3)
        d => 0

2 times ending 'c' followed by 'c' or 'd':

        b => 3
        c => 5  (+2)
        a => 3
        d => 2  (+2)

After processing 'b' and 'd' in a similiar manner we get:

        b => 3
        c => 5
        a => 5
        d => 2

The sum is 15, and we know now that we have 15 different strings in class 3.
The process for higher classes is the same again, re-using the counts from the
lower class.

=head2 BASED ON STARTING COUNTS

The second, and implemented method counts for each class how many strings
start with a given character. This gives us two information at once:

=over 2

=item *

A string of length N and a starting char of X, which number it must have at
minimum (by summing up the counts of all strings that come before X) and how
many strings are there starting with X (although this is not used for X, but
only for all strings that come after X).

=item *

How many strings are there with a given length, by summing up all the counts
for the different starting chars.

=back

This method also has the advantage that it doesn't need to re-calculate
the count for each level. If we have cached the information for class 7,
we can calculate class 8 right-away. The old method would either need to start
at class 1, working up to 8 again, or cache additional information of the order
N (where N is the number of different characters in the charset).

Here is how the second method works, based on the example above:

                start => [ 'a', 'c', 'b', 'd' ],
                bi => {
                  'a' => [ 'b','c','a' ],
                  'c' => [ 'c','d' ],
                  'b' => [ 'a', ],
                  'd' => [ 'a', ],
                  }

The sequence runs as follows:

	String	Strings starting with
		this character in this level

	  a	1
	  c	1
	  b	1
	  d	1
	 ab
	 ac
	 aa	3	(1+1+1)
	 cc
	 cd	2	(1+1)
	 ba	1
	 da	1
	aba
	acc
	acd
	aab
	aac
	aaa	6	1 (b) + 2 (c) + 3 (a)
	ccc
	ccd
	cda	3	2 (c) + 1 (d)
	bab
	bac
	baa	3
	dab
	dac
	daa	3
       abab
       abac
       abaa
       accc	etc

As you can see, for length one, there is exactly one string for each starting
character.

For the next class, we can find out how many strings start with a given char,
by adding together all the counts of strings in the previous class.

F.i. in class 3, there are 6 strings starting with 'a'. We find this out by
adding together 1 (there is 1 string starting with 'b' in class 2), 2 (there
are two strings starting with 'c' in class 2) and 3 (three strings starting
with 'a' in class 2).

As a special case we must throw away all strings in class 2 that have invalid
ending characters. By doing this, we automatically have restricted B<all>
strings to only valid ending characters. Therefore, class 1 and 2 are setup
upon creating the charset object, the others are calculated on-demand and then
cached.

Since we are calculating the strings in the order of the starting characters,
we can sum up all strings up to this character.

	String	First string in that class

	  a	0
	  c	1
	  b	2
	  d	3

	 ab	0
	 ac
	 aa
	 cc	3
	 cd
	 ba	5
	 da	6

	aba	0
	acc
	acd
	aab
	aac
	aaa
	ccc	6
	ccd
	cda
	bab	9
	bac
	baa
	dab	12
	dac
	daa
       abab	0
       abac
       abaa
       accc	etc

When we add to the number of the last character (f.i. 12 in case of 'd' in
class 3) the amount of strings with that character (here 3), we end up with
the number of all strings in that class.

Thus in the same loop we calculate:

=over 2

=item how many stings start with a given character in this class

=item what is the first number of a string starting with 'x' in that class

=item how many strings are in this class at all

=back

That should be all we need to know to convert a string to it's number.

=head2 HIGHER ORDER CHARSETS, FINDING THE RIGHT NUMBER

From the section above we know that we can find out which number a string
of a certain class has at minimum and at maximum. But what number has the
string in that range, actually?

Well, given the information it is easy. First, find out which minimum number a
string has with the given starting
character in the class. Add this to it's base number. Then reduce the class by
one, look at the next character and repeat this.  In pseudo code:

	$class = length ($string); $base = base_number->[$class];
	foreach ($character)
	  {
	  $base += $sum->[$class]->{$character};
	  $class --;
	  }

So, after N simple steps (where N is the number of characters in the string),
we have found the number of the string.

=head2 HIGHER ORDER CHARSETS, FINDING THE RIGHT STRING

Section not ready yet.

=head2 MULTIPLE MULTIWAY TREES

It helps to imagine the strings like a couple of trees (ASCII art is crude):

        class:  1   2    3   etc

       number
        1       a
          5     +--ab
           12   |   +--aba
          6     +--ac
           13   |   +--acc
           14   |   +--acd
          7     +--aa
           15       +--aab
           16       +--aac
           17       +--aaa

        2       c
          8     +--cc
           18   |   +--ccc
           19   |   +--ccd
          9     +--cd
           20       +--cda

        3       b
         10     +--ba
           21       +--bab
           22       +--bac
           23       +--baa

        4       d
         11     +--da
           24       +--dab
           25       +--dac
           26       +--daa

As you can see, there is a (independend) tree for each of the starting
characters, which in turn contains independed sub-trees for each string in
the next class etc. It is interesting to note that each string deeper in the
tree starts with the same common starting string, aka 'd', 'da', 'dab' etc.

With a simple charset, all these trees contain the same number of nodes. With
higher order charsets, this is no longer true.

=head1 METHODS

=over

=item new()

            new();

Create a new Math::String::Charset object.

The constructor takes either an ARRAY or a HASH reference. In case of the
array, all elements in that array will be used as characters in the charset,
and the charset will be of order 0, type 0.

If given a HASH reference, the following keys can be used for all charsets:

	minlen		Minimum string length, -inf if not defined
	maxlen		Maximum string length, +inf if not defined

The following keys can only be used in certain combinations, which will be
explained below:

	bi		hash,  table with bi-grams
	sets		hash, table with charsets for the different places
	start		array ref to list of all valid (starting) characters
	end		array ref to list of all valid ending characters
	sep		separator character, none if undef (only for order 1)

If you use neither B<bi> nor B<sets>, the charset will be of order 1, type 0.
If you use a hash key named B<bi>, the charset will be of order 2, type 0.
If you use a hash key named B<sets>, the charset will be of order 1, type 1.

For a charset of type 0, order 1 (simpel set) the following keys are valid:

	start		required
	end		optional (to restrict number of 1-character strings)
	sep		optional

For a charset of type 0, order 2 (bi-gram set) the following keys are valid:

	start		optional
	end		optional
	bi		required

For a charset of type 1, order 1 (grouped set) the following keys are valid:

	sets		required

=over 2

=item start

C<start> contains an array reference to all valid starting
characters, e.g. no valid string can start with a character not listed here.

=item bi

C<bi> contains a hash reference, each key of the hash points to an array,
which in turn contains all the valid combinations of two letters.

=item sets

C<sets> contains a hash reference, each key of the hash indicates an index.
Each of the hash entries points either to an ARRAY reference or a
Math::String::Charset of order 1, type 0.

Positive indices count from the left side, negative from the right. 0 denotes
the default.

At each of the position indexed by a key, the appropriate charset will be used.

Example for specifying that strings must start with upper case letters,
followed by lower case letters and can end in either a lower case letter or a
number:

	sets => {
	  0 => ['a'..'z'],		# the default
	  1 => ['A'..'Z'],		# first character is always A..Z
	 -1 => ['a'..'z','0'..'9'],	# last is q..z,0..9
	}

=item end

C<start> contains an array reference to all valid ending
characters, e.g. no valid string can end with a character not listed here.
Note that strings of length 1 start B<and> end with their only
character, so the character must be listed in C<end> and C<start> to produce
a string with one character.
Also all characters that are not followed by any other character are added
silently to the C<end> set.

=item minlen

Optional minimum string length. Any string shorter than this will be invalid.
Must be shorter than a (possible defined) maxlen. If not given is set to -inf.
Note that the minlen might be adjusted to a greater number, if it is set to 1
or greater, but there are not valid strings with 2,3 etc. In this case the
minlen will be set to the first non-empty class of the charset.

=item maxlen

Optional maximum string length. Any string longer than this will be invalid.
Must be longer than a (possible defined) minlen. If not given is set to +inf.

=item scale

Optional input/output scale. See L</scale()>.

=back

=item copy()

	$copy = $charset->copy();

Create a new charset as a copy from an existing one.

=item scale()

        $scale = $charset->scale();
        $charset->scale(120);

Get/set the (optional) scale for all strings. A scale is an integer factor that
will be applied to each as_number() output. Also, all from_number() will
use the scale to modularize the input, e.g. dividing by the scale, then
taking the integer result, and the multiplying with the scale again.

E.g. for a scale of 3, the string to number mapping would be changed
from the left to the right column:

        string form             normal number   scaled number
        ''                      0               0
        'a'                     1               3
        'b'                     2               6
        'c'                     3               9

And so on. Input like 8 will be divided by 3, which results in 2 due to
rounding down to the nearest integer, this multiplied by 3 again gives 6. So:

        my $cs = Math::String::Charset->new(['a'..'z']); # a..z
        $string = Math::String->new( 'a',$cs );		 # a..z
        print $string->as_number();			 # 1
        $cs->scale(3);
        print $string->as_number();	 		 # 3
        $string = Math::String->from_number(10,$cs);	 # [10/3] => 3 *3 == 9

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
be no upper bound on how many strings are possible. (This might change if we
can calculate an upper bound - not sure if this is possible with bigrams).

If maxlen is defined, forces a calculation of all possible L</class()> values
and may therefore be very slow on the first call, it also caches possible
lot's of values.

=item class()

	$charset->class($order);

Return the number of items in a class.

	print $charset->class(5);	# how many strings with length 5?

=item map()

	$charset->map($char);

Map a character to it's number, counting from 0 .. N-1 where N is the length
of the charset:

	$charset = Math::String::Charset->new(['A'..'Z']);

	print $charset->map('A'),"\n";		# prints 0
	print $charset->map('Z'),"\n";		# prints 25

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

Return the order of the charset: 1 for simple charsets, 2 (bi-grams), 3 etc
for higher orders. See also L</type()>.

=item type()

	$type = $charset->type();

Return the type of the charset: 0 for simple charsets, 1 for grouped ones.
If the type is 0, the order can be 1,23 etc, with type 1 the order is always
1, too. See also L</order()>.

=item charlen()

	$character_length = $charset->charlen();

Return the length of one character in the set. 1 or greater.

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

Check wether a string conforms to the charset set or not. Returns 1 for okay, 0
for invalid strings.

=item norm()

	$charset->norm();

Normalize a string by removing separator char at front/end. Does nothing if
no separator is defined.

=item error()

	$charset->error();

Returns "" for no error or an error message that occured if construction of
the charset failed. Set C<$Math::String::Charset::die_on_error> to C<0> to
get the error message, otherwise the program will die.

=item start()

	$charset->start();

In list context, returns a list of all characters in the start set, for simple
charsets (e.g. no bi, tri-grams etc) simple returns the charset. In scalar
context returns the lenght of the start set.

Note that the returned end set can be differen from what you specified upon
constructing the charset, because characters that are not followed by any other
character will be excluded from the start set (they can't possible start a
string longer than one character).

Think of the start set as the set of all characters that can start a string
with more than one character. The set for one character strings is called
B<ones> and you can access if via C<ones()>.

=item end()

	$charset->end();

In list context, returns a list of all characters in the end set, aka all
characters a string can end with. For simple charsets (e.g. no bi, tri-grams
etc) simple returns the charset. In scalar context returns the lenght of the
end set.

Note that the returned end set can be differen from what you specified upon
constructing the charset, because characters that are not followed by any other
character will be included in the end set, too.

=item ones()

	$charset->ones();

In list context, returns a list of all strings consisting of one character,
for simple charsets (e.g. no bi, tri-grams etc) simple returns the charset.
In scalar context returns the lenght of the B<ones> set.

This list is the cross of B<start> and B<end> that is calculated after adding
characters with no followers to B<end>, but before removing the characters
with no followers from B<start>.

Think of a string of only one character as if it starts with and ends in this
character at the same time. For instance, if you have the following definition:

	cs = {
	  start => [ 'a', 'b', 'c', 'q' ],
	  end => [ 'b', 'c', 'x' ],
	  bi => {
	    q => [ ],
	    a => [ 'b', 'c' ]
	    b => [ 'a' ]
	  }
        }

The 'q' is not followed by any other character, so it can only end strings. And
since it is not in the B<end> set, it is first added to this set:

	cs = {
	  start => [ 'a', 'b', 'c', 'q' ],
	  end => [ 'b', 'c', 'x', 'q' ],
	  bi => {
	    q => [ ],
	    a => [ 'b', 'c' ]
	    b => [ 'a' ]
	  }
        }

Now the cross of C<start> and C<end> is build. Since only 'b', 'c' and 'q'
appear in both C<end> and C<start>, C<ones> consists of:

	_ones => [ 'b', 'c', 'q' ]

The order of the chars in C<ones> is the same ordering as in C<start>.

After this, any character that is not followed by an other character is removed
from C<start>:

	  start => [ 'a', 'b', ],

Thus a string with only one character can be 'b', 'c', or 'q', and any string
with more than one character must start with either 'a' or 'b'.

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

=item study()

	$hash = Math::String::Charset::study( {
          order => $order, words => \@words, sep => 'separator',
          charlen => 1, hist => 1 } );

Studies the given list of strings/words and builds a hash that you can use
to construct a charset of. The C<order> is 1 for simple charsets, 2 for bigrams
and so on. The key C<depth> is a synonym for C<order>.

C<separator> (can be undef) is the sting that separates characters.
C<charlen> is the length of a character, and defaults to 1. Use this if you
have characters longer than one and no separator string.

If you set the parameter C<hist> to a value different from zero, the returned
hash will contain a key C<hist>, too. This will be a reference to a hash
containing the histogram of letters or n-grams, depending on the depth of the
analysis.

Some example:

	use Math::String::Charset;
	use Data::Dumper;

	$hash = Math::String::Charset::study( {
          depth => 1, words => [ 'hocuspocus'], hist => 1 } );
	print Dumper ($hash),"\n";

This will produce (slightly contracted here):

	$VAR1 = {
          'end'   => [ 's' ],
          'hist'  => { 'u' => '2', 'o' => '2', 'p' => '1', 'h' => '1',
                      's' => '2', 'c' => '2' },
          'chars' => [ 'u', 'o', 's', 'c', 'p', 'h' ],
          'start' => [ 'h' ]
        };

Using C<- depth => 2 >>, you would get (slightly ontracted again):

	$VAR1 = {
          'end'  => [ 's' ],
          'hist' => { 'u' => { 's' => '2' },
                      'o' => { 'c' => '2' },
                      'p' => { 'o' => '1' },
                      'h' => { 'o' => '1' },
                      's' => { 'p' => '1' },
                      'c' => { 'u' => '2' }
                    },
          'bi'   => {
                    'u' => [ 's' ],
                    'o' => [ 'c' ],
                    'h' => [ 'o' ],
                    'p' => [ 'o' ],
                    'c' => [ 'u' ],
                    's' => [ 'p' ]
                  },
          'start' => [ 'h' ]
        };

Instead passing an ARRAY ref as words, you can as well pass a HASH ref. The
keys in the hash will be used as words then. This is so that you can clean out
doubles by using a hash and pass it to study without converting it back to an
array first.

=item analyze()

Is an exportable alias for L</study()>.

	use Math::String::Charset qw/analyze/;

	$hash = Math::String::Charset::analyze(
	  words => ['Perl','Hacker','Just','Another'], depth => 2,
	);

=back

=head1 EXAMPLES

    use Math::String::Charset;

    # construct a charset from bigram table, and an initial set (containing
    # valid start-characters)
    # Note: After an 'a', either an 'b', 'c' or 'a' can follow, in this order
    #       After an 'd' only an 'a' can follow
    #       There is no 'q' as start character, but 'q' can follow 'd'!
    #       You need to define followers for 'q'!
    $bi = new Math::String::Charset ( {
      start => 'a'..'d',
      bi => {
        'a' => [ 'b', ],
        'b' => [ 'c', 'b' ],
        'c' => [ 'a', 'c' ],
        'd' => [ 'a', 'q' ],
	'q' => [ 'a', 'b' ],
        }
      } );
    print $bi->length(),"\n";			# 4
    print scalar $bi->combinations(2),"\n";	# count of combos with 2 chars
						# will be 1+2+2+2+2 => 9
    my @comb = $bi->combinations(3);
    foreach (@comb)
      {
      print "$_\n";
      }

This will print:

	4
	7
	abc
	abb
	bca
	bcc
	bbc
	bbb
	cab
	cca
	ccc
	dab
	dqa
	dqb

Another example using characters of different lengths to find all combinations
of words in a list:

	#!/usr/bin/perl -w

	# test for Math::String and Math::String::Charset

	BEGIN { unshift @INC, '../lib'; }

	use Math::String;
	use Math::String::Charset;
	use strict;

	my $count = shift || 4000;

	my $words = {};
	open FILE, 'wordlist.txt' or die "Can't read wordlist.txt: $!\n";
	while (<FILE>)
	  {
	  chomp; $words->{lc($_)} ++;	# clean out doubles
	  }
	close FILE;
	my $cs = new Math::String::Charset ( { sep => ' ',
	   words => $words,
	  } );

	my $string = Math::String->new('',$cs);

	print "# Generating first $count strings:\n";
	for (my $i = 0; $i < $count; $i++)
	  {
	  print ++$string,"\n";
	  }
	print "# Done.\n";

=head1 TODO

=over 2

=item *

Currently only bigrams are supported. This should be generic and arbitrarily
deeply nested.

=item *

C<study()> does not yet work with separator chars and chars longer than 1.

=item *

str2num and num2str do not work fully for bigrams yet.

=back

=head1 BUGS

None doscovered yet.

=head1 AUTHOR

If you use this module in one of your projects, then please email me. I want
to hear about how my code helps you ;)

This module is (C) Copyright by Tels http://bloodgate.com 2000-2008.

=cut
