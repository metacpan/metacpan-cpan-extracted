#############################################################################
# Math/String/Charset/Wordlist.pm -- a dictionary charset for Math/String

package Math::String::Charset::Wordlist;

use vars qw($VERSION @ISA);
use Math::BigInt;

require 5.008003;		# requires this Perl version or later
require DynaLoader;
require Math::String::Charset;
use strict;
@ISA = qw/Math::String::Charset  DynaLoader/;

$VERSION = 0.09;	# Current version of this package

bootstrap Math::String::Charset::Wordlist $VERSION;

use vars qw/$die_on_error/;
$die_on_error = 1;              # set to 0 to not die

# following hash values are used:
# _clen  : length of one character (all chars must have same len unless sep)
# _start : contains array of all valid start characters
# _end   : contains hash (for easier lookup) of all valid end characters
# _order : = 1
# _type  : = 2
# _error : error message or ""
# _minlen: minimum string length (anything shorter is invalid), default -inf
# _maxlen: maximum string length (anything longer is invalid), default +inf

# wordlist:
# _file : path/filename
# _len  : count of records (as BigInt)
# _len_s: count of records (as scalar)
# _scale: input/output scale
# _obj  : tied object (containing the record-offsets and giving us the records)

#############################################################################
# private, initialize self

sub _strict_check
  {
  # a per class check, to be overwritten by subclasses
  my ($self,$value) = @_;

  $self->{_type} ||= 2;
  $self->{_order} ||= 1;

  my $class = ref($self);
  return $self->{_error} = "Wrong type '$self->{_type}' for $class"
    if $self->{_type} != 2;
  return $self->{_error} = "Wrong order'$self->{_order}' for $class"
    if $self->{_order} != 1;
  foreach my $key (keys %$value)
    {
    return $self->{_error} = "Illegal parameter '$key' for $class"
      if $key !~ /^(start|order|type|minlen|maxlen|file|end|scale)$/;
    }
  }

sub _initialize
  {
  my ($self,$value) = @_;

  # sep char not used yet
  $self->{_sep} = $value->{sep};		# separator char

  $self->{_file} = $value->{file} || '';	# filename and path

  if (!-f $self->{_file} || !-e $self->{_file})
    {
    return $self->{_error} = "Cannot open dictionary '$self->{_file}': $!\n";
    }

  die ("Cannot find $self->{_file}: $!") unless -f $self->{_file};

  $self->{_obj} = _file($self->{_file});

  die ("Couldn't read $self->{_file}") unless defined $self->{_obj};

  $self->{_len_s} = _records($self->{_obj});
  $self->{_len} = Math::BigInt->new( $self->{_len_s} );

  # only one "char" for now
  $self->{_minlen} = 0;
  $self->{_maxlen} = 1;

  return $self->{_error} =
   "Minlen ($self->{_minlen} must be <= than maxlen ($self->{_maxlen})"
    if ($self->{_minlen} >= $self->{_maxlen});
  $self;
  }

sub offset
  {
  # return the offset of the n'th word into the file
  my ($self,$n) = @_;

  $n = $self->{_len_s} + $n if $n < 0;
  _offset($self->{_obj},$n);
  }

sub file
  {
  # return the dictionary list file
  my ($self) = @_;

  $self->{_file};
  }

sub is_valid
  {
  # check wether a string conforms to the given charset sets
  my $self = shift;
  my $str = shift;

  # print "$str\n";
  return 0 if !defined $str;
  return 1 if $str eq '' && $self->{_minlen} <= 0;

  my $int = Math::BigInt->bzero();
  my @chars;
  if (defined $self->{_sep})
    {
    @chars = split /$self->{_sep}/,$str;
    shift @chars if $chars[0] eq '';
    pop @chars if $chars[-1] eq $self->{_sep};
    }
  else
    {
    @chars = $str;
    # not supported yet
    #my $i = 0; my $len = CORE::length($str); my $clen = $self->{_clen};
    #while ($i < $len)
    #  {
    #  push @chars, substr($str,$i,$clen); $i += $clen;
    #  }
    }
  # length okay?
  return 0 if scalar @chars < $self->{_minlen};
  return 0 if scalar @chars > $self->{_maxlen};

  # further checks for strings longer than 1
  foreach my $c (@chars)
    {
    return 0 if !defined $self->str2num($c);
    }
  # all tests passed
  1;
  }

sub start
  {
  # this returns all the words (warning, this can eat a lot of memory)
  # in scalar context, returns length()
  my $self = shift;

  return $self->{_len} unless wantarray;

  my @words = ();
  my $OBJ = $self->{_obj};
  for (my $i = 0; $i < $self->{_len}; $i++)
    {
    push @words, _record($OBJ,$i);
    }
  @words;
  }

sub end
  {
  # this returns all the words (warning, this can eat a lot of memory)
  # in scalar context, returns length()
  my $self = shift;

  $self->start();
  }

sub ones
  {
  # this returns all the words (warning, this can eat a lot of memory)
  # in scalar context, returns length()
  my $self = shift;

  $self->start();
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
    elsif ($k eq '_obj')
      {
      # to save memory, don't make a full copy of the record set, just copy
      # the pointer around
      $self->{$k} = $x->{$k};
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

sub chars
  {
  my ($self,$x) = @_;

  # XXX return always 1 to signal that $x has only one character
  1;
  }

sub count
  {
  my $self = shift;

  $self->{_len};
  }

sub length
  {
  my $self = shift;

  $self->{_len};
  }

sub class
  {
  my $self = shift;
  my $class = shift; $class = 0 unless defined $class;

  # class(0) is 0
  return 0 if $class == 0;

  return $self->{_len} if $class == 1;

  $self->{_len}->copy()->bpow($class);
  }

sub num2str
  {
  # convert Math::BigInt/Math::String to string
  # in list context, return (string,stringlen)
  my ($self,$x) = @_;

  $x = new Math::BigInt($x) unless ref $x;
  return undef if ($x->sign() !~ /^[+-]$/);

  my $l = '';			# $x == 0 as default
  my $int = abs($x->numify());
  if ($int > 0)
    {
    $l = _record($self->{_obj}, $int-1);
    }
  wantarray ? ($l,1) : $l;
  }

sub str2num
  {
  # convert Math::String to Math::BigInt
  my ($self,$str) = @_;

  return Math::BigInt->bzero() if !defined $str || $str eq '';

  my $OBJ = $self->{_obj};

  # do a binary search for the string in the array of strings
  my $left = 0; my $right = $self->{_len_s} - 1;

  my $leftstr = _record($OBJ,$left);
  return Math::BigInt->new($left+1) if $leftstr eq $str;
  my $rightstr = _record($OBJ,$right);
  return Math::BigInt->new($right+1) if $rightstr eq $str;

  my $middle;
  while ($right - $left > 1)
    {
    # simple middle median computing
    $middle = int(($left + $right) / 2);

    # advanced middle computing:
    my $ll = ord(substr($leftstr,0,1));
    my $rr = ord(substr($rightstr,0,1));
    if ($rr - $ll > 1)
      {
      my $mm = ord(substr($str,0,1));
      $mm++ if $mm == $ll;
      $mm-- if $mm == $rr;

      # now make $middle so that :
      # $mm - $ll      $middle - $left
      # ----------- = ----------------- =>
      # $rr - $ll      $right - $left
      #
      #         ($mm - $ll) * ($right - $left)
      # $left + ----------------------------
      #            $rr - $ll
      $middle = $left +
        int(($mm - $ll) * ($right - $left) / ($rr - $ll));
      $middle++ if $middle == $left;
      $middle-- if $middle == $right;
      }

    my $middlestr = _record($OBJ,$middle);
    return Math::BigInt->new($middle+1) if $middlestr eq $str;

    # so it is neither left, nor right nor middle, so see in which half it
    # should be

    my $cmp = $middlestr cmp $str;
    # cmp != 0 here
    if ($cmp < 0)
      {
      $left = $middle; $leftstr = $middlestr;
      }
    else
      {
      $right = $middle; $rightstr = $middlestr;
      }
    }
  return if $right - $left == 1;        # not found
  Math::BigInt->new($middle+1);
  }

sub char
  {
  # return nth char from charset
  my $self = shift;
  my $char = shift || 0;

  $char = $self->{_len_s} + $char if $char < 0;
  _record($self->{_obj},$char);
  }

sub first
  {
  my $self = shift;
  my $count = abs(shift || 0);

  return if $count < $self->{_minlen};
  return if defined $self->{_maxlen} && $count > $self->{_maxlen};
  return '' if $count == 0;

  my $str = _record($self->{_obj},0);

  return $str if $count == 1;

  my $s = $self->{_sep} || '';
  my $res = '';
  for (my $i = 0; $i < $count; $i++)
    {
    $res .= $s . $str;
    }
  $s = quotemeta($s);
  $res =~ s/^$s// if $s ne '';		# remove first sep
  $res;
  }

sub last
  {
  my $self = shift;
  my $count = abs(shift || 0);

  return if $count < $self->{_minlen};
  return if defined $self->{_maxlen} && $count > $self->{_maxlen};
  return '' if $count == 0;

  my $str = _record($self->{_obj},$self->{_len_s}-1);
  return $str if $count == 1;

  my $res = '';
  my $s = $self->{_sep} || '';
  for (my $i = 1; $i <= $count; $i++)
    {
    $res .= $s . $str;
    }
  $s = quotemeta($s);
  $res =~ s/^$s// if $s ne '';		# remove first sep
  $res;
  }

sub next
  {
  my ($self,$str) = @_;

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

  # extract the current value
  #$str->{_cache} = _record($self->{_obj}, $str->numify()-1);
  $str->{_cache} = undef;
  }

sub prev
  {
  my ($self,$str) = @_;

  if ($str->{_cache} eq '')				# 0 => -1
    {
    my $min = $self->{_minlen}; $min = -1 if $min >= 0;
    $str->{_cache} = $self->first($min);
    return;
    }

  # extract the current value
  #$str->{_cache} = _record($self->{_obj}, $str->numify()-1);
  $str->{_cache} = undef;
  }

sub DELETE
  {
  my $self = shift;

  # untie and free our record-keeper
  _free($self->{_obj}) if $self->{_obj};
  }

__END__

#############################################################################

=pod

=head1 NAME

Math::String::Charset::Wordlist - A dictionary charset for Math::String

=head1 SYNOPSIS

    use Math::String::Charset::Wordlist;

    my $x = Math::String::Charset::Wordlist->new ( {
	file => 'path/dictionary.lst' } );

=head1 REQUIRES

perl5.005, DynaLoader, Math::BigInt, Math::String::Charset

=head1 EXPORTS

Exports nothing.

=head1 DESCRIPTION

This module lets you create an charset object, which is used to construct
Math::String objects.

This object maps an external wordlist (aka a dictionary file where one
line contains one word) to a simple charset, e.g. each word is one character
in the charset.

The wordlist file must be sorted alphabetically (just like C<sort -u> does),
otherwise the results from converting between string and number form are
unpredictable.


=head1 ERORRS

Upon error, the field C<_error> stores the error message, then die() is called
with this message. If you do not want the program to die (f.i. to catch the
errors), then use the following:

	use Math::String::Charset::Wordlist;

	$Math::String::Charset::Wordlist::die_on_error = 0;

	$a = Math::String::Charset::Wordlist->new();	# error, empty set!
	print $a->error(),"\n";

=head1 INTERNAL DETAILS

This object caches certain calculation results (f.i. which word is stored
at which offset in the file etc), thus greatly speeding up sequentiell
L<Math::String> conversations from string to number, and vice versa.

=head1 METHODS

=over

=item new()

            Math::String::Charset::Wordlist->new();

Create a new Math::String::Charset::Wordlist object.

The constructor takes a HASH reference. The following keys can be used:

	minlen		Minimum string length, for now always 0
	maxlen		Maximum string length, for now always 1
	file		path/filename of wordlist file
	sep		separator character, none if undef

The resulting charset will always be of order 1, type 2.

The wordlist file must be sorted alphabetically (just like C<sort -u> does),
otherwise the results from converting between string and number form are
unpredictable.

=over 2

=item minlen

Optional minimum string length. Any string shorter than this will be invalid.
Must be shorter than a (possible defined) maxlen. If not given is set to -inf.
Note that the minlen might be adjusted to a greater number, if it is set to 1
or greater, but there are not valid strings with 2,3 etc. In this case the
minlen will be set to the first non-empty class of the charset.

For wordlists, the minlen is always 0 (thus making '' the first valid string).

=item maxlen

Optional maximum string length. Any string longer than this will be invalid.
Must be longer than a (possible defined) minlen. If not given is set to +inf.

For wordlists, the maxlen is always 1 (thus making the last word in the
dictionary the last valid string).

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

If maxlen is defined, forces a calculation of all possible L<class()> values
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
See also L<type>.

=item type()

	$type = $charset->type();

Return the type of the charset: is always 1 for grouped charsets.
See also L<order>.

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

=item file()

	$file = $charset->file();

Return the path/name of the dictionary file beeing used in constructing this
character set.

=item num2str()

	my ($string,$length) = $charset->num2str($number);

Converts a Math::BigInt/Math::String to a string. In list context it returns
the string and the length, in scalar context only the string.

=item str2num()

	$number = $charset->str2num($str);

Converts a string (literal string or Math::String object) to the corrosponding
number form (as Math::BigInt).

=item offset()

	my $offset = $charset->offset($number);

Returns the offset of the n'th word into the dictionary file.

=back

=head1 EXAMPLES

	use Math::String;
	use Math::String::Charset::Wordlist;

	my $cs =
	  Math::String::Charset::Wordlist->new( { file => 'big.sorted' } );
	my $x =
	  Math::String->new('',$cs)->binc();	# $x is now the first word

	while ($x < Math::BigInt->new(10))	# Math::BigInt->new() necc.!
	  {
	  # print the first 10 words
	  print $x++,"\n";
	  }

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-string-charset-wordlist at rt.cpan.org>, or through the web
interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-String-Charset-Wordlist>
(requires login). We will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::String::Charset::Wordlist

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Dist/Display.html?Name=Math-String-Charset-Wordlist>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-String-Charset-Wordlist>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Math-String-Charset-Wordlist>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-String-Charset-Wordlist/>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-String-Charset-Wordlist>

=back

=head1 AUTHOR

If you use this module in one of your projects, then please email me. I want
to hear about how my code helps you ;)

This module is (C) Copyright by Tels http://bloodgate.com 2003-2008.

Copyright 2017- Peter John Acklam L<pjacklam@online.no>.

=cut
