#############################################################################
# Math/String/Charset/Nested -- charsets for Math/String
#
# Copyright (C) 1999-2003 by Tels. All rights reserved.
#############################################################################

# todo: tri-grams etc
#       store counts for different end-chars at the max elemt of _count?
#       if we later need to calculate further, we could pick up there and need
#       not to re-calculate the lower numbers

package Math::String::Charset::Nested;

require  5.005;		# requires this Perl version or later
use strict;

use base 'Math::String::Charset';

our $VERSION;
$VERSION = '1.30';	# Current version of this package

use Math::BigInt;

our $die_on_error;
$die_on_error = 1;		# set to 0 to not die

# following hash values are used:
# _clen  : length of one character (all chars must have same len unless sep)
# _start : contains array of all valid start characters
# _ones  : list of one-character strings (cross of _end and _start)
# _end   : contains hash (for easier lookup) of all valid end characters
# _order : 1,2,3.. etc, 1 => simple, 2 => bigram etc
# _type  : 0 => simple or bi-gram, 1 => grouping
# _error : error message or ""
# _count : array of count of different strings with length x
# _sum   : array of starting number for strings with length x
#          _sum[x] = _sum[x-1]+_count[x-1]
# _cnt   : number of elements in _count and _sum (as well as in _scnt & _ssum)
# _cnum  : number of characters in _ones as BigInt (for speed)
# _minlen: minimum string length (anything shorter is invalid), default 0
# _maxlen: maximum string length (anything longer is invalid), default undef
# _scale : optional input/output scale

# simple ones:
# _sep  : separator string (undef for none)
# _map  : mapping character to number

# higher orders:
# _bi   : hash with refs to array of bi-grams
# _bmap : hash with refs to hash of bi-grams
# _scnt : array of hashes, count of strings starting with this character
# _sm	: hash w/ mapping of start characters for faster lookup

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
    if $self->{_order} != 2;
  foreach my $key (keys %$value)
    {
    return $self->{_error} = "Illegal parameter '$key' for $class"
      if $key !~ /^(start|minlen|maxlen|sep|bi|end|charlen|scale)$/;
    }
  }

sub _initialize
  {
  # set yourself to the value represented by the given string
  my $self = shift;
  my $value = shift;

  my $end = {}; 			# we make array later on
  # add the user-specified end set
  my $bi = $value->{bi} || {};
  return $self->{_error} = "Field 'bi' must be hash ref"
   if ref($bi) ne 'HASH';
  $self->{_order} = 2;
  # if no end set is defined, add all followers as default
  if (exists $value->{end})
    {
    $end = { map { $_ => 1 } @{$value->{end}} };
    }
  else
    {
    foreach my $c (keys %$bi)
      {
      foreach my $f (@{$bi->{$c}})
        {
        $end->{$f} = 1;
        }
      }
    }
  if (exists $value->{start})
    {
    $self->{_start} = [ @{$value->{start}} ];
    }
  else
    {
    # else all chars w/ followers can start a string (longer than 2)
    my $s = { };
    foreach my $c (keys %$bi)
      {
      $s->{$c} = 1 if @{$bi->{$c}} > 0;
      }
    $self->{_start} = [ sort keys %$s ];
    }

  # make copy
  foreach my $c (keys %$bi)
    {
    $self->{_bi}->{$c} = [ @{$bi->{$c}} ]; 	# make copy
    }
  if (!defined $self->{_sep})
    {
    foreach my $c (keys %$bi)
      {
      $self->{_clen} = CORE::length($c);
      last;
      }
    }
  # add empty array for chars with no followers
  $bi = $self->{_bi};
  my @keys = keys %$bi;		# make copy since keys may be modified (necc?)
  foreach my $c (@keys)
    {
    $end->{$c} = 1 if @{$bi->{$c}} == 0;	# no follower

    foreach my $f (@{$bi->{$c}})
      {
      $self->{_bi}->{$f} = [] if !defined $self->{_bi}->{$f};
      $end->{$f} = 1 if @{$bi->{$f}} == 0;
      if (!defined $self->{_sep})
        {
        return $self->{_error} = "Illegal char '$f', length not $self->{_clen}"
          if length($f) != $self->{_clen};
        }
      }
    }

  $self->{_end} = $end;
  # build _ones and _sm list (cross from start/end)
  $self->{_ones} = [];
  $self->{_sm} = {};
  foreach (@{$self->{_start}})
    {
    push @{$self->{_ones}}, $_ if exists $end->{$_};
    $self->{_sm}->{$_} = 1;
    }
#  print "ones => ",join(' ',@{$self->{_ones}}),"\n";
  # remove anything from start with no followers, but keep original order
  my @s;
  foreach my $c (@{$self->{_start}})
    {
    push @s, $c
     if ((!defined $self->{_bi}->{$c}) || (@{$self->{_bi}->{$c}} > 0));
    }
  $self->{_start} = \@s;

  # initialize array of counts for len of 0..1
  $self->{_cnt} = 1;				# cached amount of class-sizes
  $self->{_count}->[0] = 1;			# '' is one string
  $self->{_count}->[1] = Math::BigInt->new (scalar @{$self->{_ones}});	# 1

  # initialize array of counts for len of 2
  $end = $self->{_end};
  my $count = Math::BigInt::bzero();
  foreach my $c (keys %$bi)
    {
    $count += scalar @{$bi->{$c}} if exists $end->{$c};
    }
  $self->{_count}->[2] = $count;					# 2
  $self->{_cnt}++;	# adjust cache size

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
  # create mapping for is_valid (contains number of follower)
  foreach my $c (keys %{$self->{_bi}})	# for all chars
    {
    my $i = 0;
    foreach my $cf (@{$self->{_bi}->{$c}})	# for all followers
      {
      $self->{_bmap}->{$c}->{$cf} = $i++;	# make hash for easier lookup
      }
    }

  # init _scnt array ([0] not used in both)
  $self->{_scnt}->[1] = {};
  #foreach my $c (keys %{$self->{_map}})	# it's nearly the same
  #  {
  #  $self->{_ssum}->[1]->{$c} = $self->{_map}->{$c} - 1;
  #  }

  # class 1
  foreach my $c (@{$self->{_start}})
    {
    $self->{_scnt}->[1]->{$c} = 1		# exactly one for each char
     if exists $self->{_end}->{$c};		# but not for invalid's
    }
  # class 2
  my $last = Math::BigInt::bzero();
  foreach my $c (keys %{$self->{_bi}})		# for each possible character
    {
    my $cnt = 0;
    foreach my $cf (@{$bi->{$c}})		# for each follower
      {
      $cnt ++ if exists $self->{_end}->{$cf};	# that can end the string
      }
    $self->{_scnt}->[2]->{$c} = $cnt;		# store
    $last += $cnt				# next one is summed up
     if exists $self->{_sm}->{$c};		# if starting with valid char
    }
  # print $self->{_count}->[2]||0," should already be $last\n";
  $self->{_count}->[2] = $last;			# all in class #2
  $self->{_cnt} = 2;				# cache size for bi is one more
  $self->{_cnum} = Math::BigInt->new( scalar @{$self->{_ones}} );
  if ($self->{_cnum}->is_zero())
    {
    $self->{_minlen} = 2 if $self->{_minlen} == 1;	# no one's
    # check whether charset can have 2-character long strings
    if ($self->{_count}->[2] == 0)
      {
      $self->{_minlen} = 3 if $self->{_minlen} == 2;	# no two's
      # check whether some path from start to end set exists, if not: empty
      $self->_min_path_len();
      }
    }
  return $self;
  }

sub _min_path_len
  {
  # for n-grams calculate the minimum path len
  # Starting with each character in the start set, traverse the n-gram tree
  # until it arrives at one of the end characters. The count between is the
  # length of the shortes valid string.
  # This might be greater than the length the user specified, because it is
  # possible to have no shorter strings due to restrictions.
  my $self = shift;

  # these are already know, and if non-zero, we already have minlen
  return if $self->class(1) != 0 || $self->class(2) != 0;

  my $minlen = $self->{_minlen} || 3;	# either the defined min len, or 3
  }

sub dump
  {
  my $self = shift;

  print "type: BIGRAM:\n";
  my $bi = $self->{_bi};
  foreach my $c (keys %$bi)
    {
    print " $c => [";
    foreach my $f (@{$bi->{$c}})
      {
      print "'$f', ";
      }
    print "]\n";
    }
  print "start: ", join(' ',@{$self->{_start}}),"\n";
  print "end  : ", join(' ',keys %{$self->{_end}}),"\n";
  print "ones : ", join(' ',@{$self->{_ones}}),"\n";
  }

sub _calc
  {
  # given count of len 1..x, calculate count for y (y > x) and all between
  # x and y
  # currently re-calcs from 2 on, we could save the state and only calculate
  # the missing counts.

  my $self = shift;
  my $max = shift || 1; $max = 1 if $max < 1;
  return if $max <= $self->{_cnt};

#  my ($counts,$org_counts);
  # map to hash
#  my $end = $self->{_end};
#  %$counts = map { $_, $end->{$_} } keys %$end; 	# make copy

  my ($last,$count);
  my $i = $self->{_cnt}+1;		# start with next undefined level
  while ($i <= $max)
    {
    # take current level, calculate all possible ending characters
    # and count them (e.g. 2 times 'b', 2 times 'c' and 3 times 'a')
    # each of the ending chars has a number of possible bi-grams. For the next
    # length, we must add the count of the ending char to each of the possible
    # bi-grams. After this, we get the new count for all new ending chars.
  #  %$org_counts = map { $_, $counts->{$_} } keys %$counts; 	# make copy
  #  $counts = {};						# init to 0
  #  $cnt = Math::BigInt::bzero();
  #  # for each of the ending chars
  #  foreach my $char (keys %$org_counts)
  #    {
  #    # and for each of it's bigrams
  #    $c = $org_counts->{$char};			# speed up
  #    foreach my $ec ( @{$self->{_bi}->{$char}})
  #      {
  #      # add to the new ending char the number of possibilities
  #      $counts->{$ec} += $c;
  #      }
  #    # now sum them up by multiplying bi-grams times org_char count
  #    $cnt += @{$self->{_bi}->{$char}} * $org_counts->{$char};
  #    }
  #  $self->{_count}->[$i] = $cnt;	# store this level
    #print "$i => $self->{_count}->[$i]\n";

    #########################################################################
    # for each starting char, add together how many strings each follower
    # starts in level-1
    # print "level $i\n";
    $last = Math::BigInt::bzero();
    $count = Math::BigInt::bzero();		# all counts
    my $bi = $self->{_bi};
    foreach my $c (keys %$bi)			# for each possible char
      {
      my $cnt = 0;
      foreach my $cf (@{$bi->{$c}})		# for each follower
        {
        my $ci = $self->{_scnt}->[$i-1]->{$cf} || 0;
#	print "$c followed by $cf $ci times\n",
        $cnt += $ci;				# add count in level-1
        }
      $self->{_scnt}->[$i]->{$c} = $cnt;	# store
#      $self->{_ssum}->[$i]->{$c} = $last;	# store sum up to here
      $last += $cnt;				# next one is summed up
      $count += $cnt if exists $self->{_sm}->{$c};	# only valid starts
#      print "last $last count $count cnt $cnt\n";
      }
    $self->{_count}->[$i] = $count;		# all in class w/ valid starts
    $self->{_sum}->[$i] = $self->{_count}->[$i-1] + $self->{_sum}->[$i-1];

#    $last = Math::BigInt->bzero();		# set to 0
#    foreach $c (@{$self->{_start}})
#      {
#      $cnt = Math::BigInt->bzero();		# number of followers
#      foreach $cf (@{$self->{_bi}->{$c}})	# for each follower
#        {
#        my $ci = $self->{_scnt}->[$i-1]->{$cf} || 0;
#        print "$c $cnt += ",$ci," ($cf)\n";
#        $cnt += $ci;				# add count in level-1
#        }
#      $self->{_scnt}->[$i]->{$c} = $cnt;	# and store it
#      $self->{_ssum}->[$i]->{$c} = $last;	# store sum up to here
#      $last += $cnt;				# next one is summed up
#      }
#    $self->{_count}->[$i] = $last;		# sum of all strings
#    $self->{_sum}->[$i] = $self->{_count}->[$i-1] + $self->{_sum}->[$i-1];
    $i++;
    }
  $self->{_cnt} = $i-1;				# store new cache size
  }

sub is_valid
  {
  # check wether a string conforms to the given charset set
  my $self = shift;
  my $str = shift;

  # print "$str\n";
  return 0 if !defined $str;
  return 1 if $str eq '' && $self->{_minlen} <= 0;

  #my $int = Math::BigInt::bzero();
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
  my $map = $self->{_map};
  return 0 unless exists $map->{$chars[0]};
  # check if conforms to bi-grams
  return 1 if @chars == 1;
  # further checks for strings longer than 1
  my $i = 1; 				# start at second char
  $map = $self->{_bmap};
  while ($i < @chars)
    {
    #print "is valid $i $chars[$i-1] $chars[$i]\n";
#    print "$chars[$i-1] $chars[$i]: ",
 #     $map->{$chars[$i-1]} || 'undef'," ",
 #     $map->{$chars[$i-1]}->{$chars[$i]} || 'undef',"\n";
    return 0 unless exists $map->{$chars[$i-1]};
    return 0 unless exists $map->{$chars[$i-1]}->{$chars[$i]};
    $i++;
    }
  return 1;
  }

sub num2str
  {
  # convert Math::BigInt/Math::String to string
  my $self = shift;
  my $x = shift;

  $x = new Math::BigInt($x) unless ref $x;
  return undef if ($x->sign() !~ /^[+-]$/);
  if ($x->is_zero())
    {
    return wantarray ? ('',0) : '';
    }
  my $j = $self->{_cnum};                       # nr of chars

  if ($x <= $j)
    {
    my $c =  $self->{_ones}->[$x-1];
    return wantarray ? ($c,1) : $c;             # string len == 1
    }

  my $digits = $self->chars($x); my $d = $digits;

  # now treat the string as it were a zero-padded string of length $digits

  my $es = "num2str() for bi-grams not ready yet";
  return wantarray ? ($es,$d) : $es;
  }

sub str2num
  {
  # convert Math::String to Math::BigInt
  my $self = shift;
  my $str = shift;			# simple string

  my $int = Math::BigInt::bzero();
  my $i = CORE::length($str);

  return $int if $i == 0;
  my $map = $self->{_map};
  my $clen = $self->{_clen};		# len of one char
  return new Math::BigInt($map->{$str}) if $i == $clen;
  if (!defined $self->{_sep})
    {
    my $class = $i / $clen;
    $self->_calc($class) if $class > $self->{_cnt};	# not yet cached?
    $int = $self->{_sum}->[$class];			# base number
    # print "base $int class $class\n";
    $i = $clen; $class--;
    # print "start with pos $i, class $class\n";
    while ($class > 0)
      {
      $int += $self->{_ssum}->[$class]->{substr($str,$i,$clen)};
      # print "$i $class $int ",substr($str,$i,$clen)," ",
      # $self->{_ssum}->[$class]->{substr($str,$i,$clen)},"\n";
      $class --;
      $i += $clen;
      #print "s2n $int j: $j i: $i m: $mul c: ",
      #substr($str,$i+$clen,$clen),"\n";
      }
    # print "$int\n";
    }
  else
    {
    # sep char
    my @chars = split /$self->{_sep}/, $str;
    shift @chars if $chars[0] eq '';			# strip leading sep
    my $class = scalar @chars;
    foreach (@chars)
      {
      $int += $self->{_ssum}->[$class]->{$_};
      $class --;
      # print "$class $int\n";
      }
    }
  return $int;
  }

sub chars
  {
  # return number of characters in output string
  my $self = shift;
  my $x = shift;

  return 0 if $x->is_zero() || $x->is_nan() || $x->is_inf();

  my $i = 1;
  # not done yet
  return $i;
  }

sub first
  {
  my $self = shift;
  my $count = abs(shift || 0);

  return if $count < $self->{_minlen};
  return if defined $self->{_maxlen} && $count > $self->{_maxlen};
  return '' if $count == 0;

  return $self->{_ones}->[0] if $count == 1;
  my $f;
  foreach my $c (@{$self->{_start}})
    {
    $f = $self->_first('',$c,1,$count);
    return $f if defined $f;
    }
  return;
  }

sub _first
  {
  # recursively check followers whether they are okay, or not
  # $self, $f, $ending, $level, $count,

  my ($self,$f,$ending,$level,$count) = @_;

  if ($level >= $count)				# overshot
    {
    return $f.$ending if exists $self->{_end}->{$ending};
    return;
    }

  return if !exists $self->{_bi}->{$ending};
  foreach my $c (@{$self->{_bi}->{$ending}})
    {
    my $rc = $self->_first($f.$ending,$c,$level+1,$count);
    return $rc if defined $rc;
    }
  return;					# found nothing
  }

sub _last
  {
  # recursively check followers whether they are okay, or not
  # $self, $f, $ending, $level, $count,

  my ($self,$f,$ending,$level,$count) = @_;

  if ($level >= $count)				# overshot
    {
    return $f.$ending if exists $self->{_end}->{$ending};
    return;
    }

  return if !exists $self->{_bi}->{$ending};

  foreach my $c (reverse @{$self->{_bi}->{$ending}})
    {
    my $rc = $self->_last($f.$ending,$c,$level+1,$count);
    return $rc if defined $rc;
    }
  return;					# found nothing
  }

sub last
  {
  my $self = shift;
  my $count = abs(shift || 0);

  return if $count < $self->{_minlen};
  return if defined $self->{_maxlen} && $count > $self->{_maxlen};
  return '' if $count == 0;

 return $self->{_ones}->[-1] if $count == 1;
  my $f;
  foreach my $c (reverse @{$self->{_start}})
    {
    $f = $self->_last('',$c,1,$count);
    return $f if defined $f;
    }
  return;
  }

sub next
  {
  my $self = shift;
  my $str = shift;

  if ($str->{_cache} eq '')				# 0 => 1
    {
    $str->{_cache} = $self->first($self->minlen()||1);
    return;
    }

  # only the rightmost digit is adjusted. If this overflows, we simple
  # invalidate the cache. The time saved by updating the cache would be to
  # small to be of use, especially since updating the cache takes more time
  # then. Also, if the cached isn't used later, we would have spent the
  # update-time in vain.

  # for higher orders not ready yet
  $str->{_cache} = undef;

  $self;
  }

sub prev
  {
  my $self = shift;
  my $str = shift;

  if ($str->{_cache} eq '')				# 0 => 1
    {
    $str->{_cache} = $self->first($self->minlen()||1);
    return;
    }

  # for higher orders not ready yet
  $str->{_cache} = undef;

  $self;
  }


__END__

#############################################################################

=pod

=head1 NAME

Math::String::Charset::Nested - A charset for Math::String objects.

=head1 SYNOPSIS

    use Math::String::Charset;

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

=head1 REQUIRES

perl5.005, Exporter, Math::BigInt, Math::String::Charset

=head1 EXPORTS

Exports nothing.

=head1 DESCRIPTION

This module lets you create an charset object, which is used to contruct
Math::String objects. This object knows how to handle charsets with bi-grams.

=head1 ERORRS

Upon error, the field C<_error> stores the error message, then die() is called
with this message. If you do not want the program to die (f.i. to catch the
errors), then use the following:

	use Math::String::Charset::Nested;

	$Math::String::Charset::Nested::die_on_error = 0;

	$a = new Math::String::Charset::Nested ();	# error, empty set!
	print $a->error(),"\n";

=head1 INTERNAL DETAILS

This object caches certain calculation results (f.i. the number of possible
combinations for a certain string length), thus greatly speeding up
sequentiell Math::String conversations from string to number, and vice versa.

=head2 CHARACTER LENGTH

All characters used to construct the charset must have the same length, but
need not neccessarily be one byte/char long.

If a seperator string is used, the character length is not used.

=head2 STRING ORDERING

With a simple charset, converting between the number and string is relatively
simple and straightforward, albeit slow.

With bigrams, this becomes even more complex. But since all the information
on how to convert between number and string in inside the charset definition,
Math::String::Charset will produce (and sometimes cache) this information.
Thus Math::String is simple a hull around Math::String::Charset and it's subclasses and Math::BigInt.

=head2 SIMPLE CHARSETS

For a discussion of these see L<Math::String::Charset>.

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

See L<Math::String::Charset>.

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

Section not fully done yet.

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

Create a new Math::String::Charset::Grouped object.

The constructor takes a HASH reference.  The charset will be of order 2 or
greater and type 0.

The following keys can be used:

	minlen		Minimum string length, -inf if not defined
	maxlen		Maximum string length, +inf if not defined
	bi		hash,  table with bi-grams
	start		array ref to list of all valid (starting) characters
	end		array ref to list of all valid ending characters
	sep		separator character, none if undef (only for order 1)

=over 2

=item sep

C<sep> is a seperator string seperating the characters from each other. This
is used to make characters with different lengths possible.

=item start

C<start> contains an array reference to all valid starting
characters, e.g. no valid string can start with a character not listed here.

=item bi

C<bi> contains a hash reference, each key of the hash points to an array,
which in turn contains all the valid combinations of two letters.

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
Must be shorter than maxlen. If not given is set to -inf.

Note that the minlen might be adjusted to a greater number, if it is set to 1
or greater, but there are not valid strings with 2,3 etc. In this case the
minlen will be set to the first non-empty class of the charset.

=item maxlen

Optional maximum string length. Any string longer than this will be invalid.
Must be longer than minlen. If not given is set to +inf.

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
be no upper bound on how many strings are possible. (This might change if we
can calculate an upper bound - not sure if this is possible with bigrams).

If maxlen is defined, forces a calculation of all possible L</class()> values
and may therefore be very slow on the first call, it also caches possible
lot's of values.

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

Return the order of the charset: 2 (bi-grams), 3 etc for higher orders.
See also L</type()>.

=item type()

	$type = $charset->type();

Return the type of the charset and is always 0 for nested charsets.
See also L</order()>.

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

Check wether a string conforms to the charset set or not.

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
    print scalar $bi->class(2),"\n";		# count of combos with 2 chars
						# will be 1+2+2+2+2 => 9
    my @comb = $bi->class(3);
    print join ("\n", @comb);

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

str2num and num2str do not work fully yet.

=back

=head1 BUGS

None doscovered yet.

=head1 AUTHOR

If you use this module in one of your projects, then please email me. I want
to hear about how my code helps you ;)

This module is (C) Copyright by Tels http://bloodgate.com 2000-2003.

=cut
