# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

# This file is part of Math-OEIS.
#
# Math-OEIS is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-OEIS is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-OEIS.  If not, see <http://www.gnu.org/licenses/>.

package Math::OEIS::Grep;
use 5.006;
use strict;
use warnings;
use Carp 'croak';
use Math::OEIS::Names;
use Math::OEIS::Stripped;

our $VERSION = 12;

# uncomment this to run the ### lines
# use Smart::Comments;


my $stripped_mmap;

sub import {
  my $class = shift;
  my $arg = shift;
  if ($arg && $arg eq '-search') {
    ### Grep import() -search

    # Encode::Locale output coding if available, otherwise utf8 since that
    # is the coding of the names file so we become a pass-through.
    eval {
      require Encode;
      require PerlIO::encoding;
      my $coding = 'utf8';
      eval { require Encode::Locale; $coding = 'console_out'; };
      $coding = ":encoding($coding)";
      {
        local $PerlIO::encoding::fallback = Encode::PERLQQ();
        binmode(STDOUT, $coding);
        # Not sure coding on STDERR is a good idea, could loop trying to print.
        # binmode(STDERR, $coding);
      }
      ### $coding
    };
    $class->search(array=>\@_);
    exit 0;
  }
}

sub search {
  ### Grep search() ...
  my $class = shift;
  my %h = (try_abs     => 1,
           verbose     => 0,
           use_mmap    => 'if_possible',
           max_matches => 10,
           @_);
  ### $class

  my $verbose = $h{'verbose'} || 0;

  my $values_min = $h{'values_min'};
  my $values_max = $h{'values_max'};
  ### $values_min
  ### $values_max

  my $name = $h{'name'};
  if (defined $name) {
    $name = "$name: ";
  } else {
    $name = '';
  }
  ### $name

  my %exclude;
  if (my $aref = $h{'exclude_list'}) {
    @exclude{@$aref} = ();  # hash slice
  }
  ### %exclude

  my $array = $h{'array'};
  if (! $array) {
    my $string = $h{'string'};
    $string =~ s/\s+/,/;
    $array = [ grep {defined} split /,+/, $string ];
  }
  unless ($array) {
    croak 'search() missing array=>[] parameter';
  }
  if (@$array == 0) {
    ### empty ...
    print "${name}no match empty list of values\n\n";
    return;
  }

  my $use_mmap = $h{'use_mmap'};

  if ($use_mmap && ! defined $stripped_mmap) {
    my $stripped_obj = Math::OEIS::Stripped->instance;
    my $stripped_filename = $stripped_obj->filename;
    if (eval {
      require File::Map;
      File::Map::map_file ($stripped_mmap, $stripped_filename);
      1;
    }) {
      if ($verbose) {
        print "mmap stripped file, length ",length($stripped_mmap),"\n";
      }
    } else {
      my $err = $@;
      if ($use_mmap eq 'if_possible') {
        if ($verbose >= 2) {
          print "cannot mmap, fallback to open: $err\n";
        }
        $use_mmap = 0;
      } else {
        croak "Cannot mmap $stripped_filename: $err";
      }
    }
  }

  my $fh;
  if (! $use_mmap) {
    # ENHANCE-ME: show the reason ENOENT etc here
    $fh = Math::OEIS::Stripped->fh
      || croak "Cannot open ~/OEIS/stripped file";
  }

  {
    my $str = $array->[0];
    for (my $i = 1; $i <= $#$array; $i++) {
      $str .= ','.$array->[$i];
      if (length($str) > 50 && $i != $#$array) {
        $str .= ',...';
        last;
      }
    }
    $name .= "match $str\n";
  }

  if (defined (my $value = _constant_array(@$array))) {
    if ($value != 0 && abs($value) <= 1000) {
      print "${name}constant $value\n\n";
      return;
    }
  }

  if (defined (my $diff = _constant_diff(@$array))) {
    if (abs($diff) < 20 && abs($array->[0]) < 100) {
      print "${name}constant difference $diff\n\n";
      return;
    }
  }

  if ($verbose) {
    print $name;
    $name = '';
  }
  ### $use_mmap

  my $max_matches = $h{'max_matches'};
  my $count = 0;

  my $orig_array = $array;
  my $mung_desc = '';
 MUNG: foreach my $mung ('none',
                         ($h{'_EXPERIMENTAL_exact'}
                          ? ()
                          : ('trim',
                             'negate',
                             ($h{'try_abs'} ? 'abs' : ()),
                             'half',
                             'quarter',
                             'double')),
                        ){
    ### $mung
    last if $count;  # no more munging when found a match

    if ($mung eq 'none') {

    } elsif ($mung eq 'trim') {
      my $count = 0;
      $array = [ @$orig_array ]; # copy
      while (@$array && $array->[0] == 0) {  # leading zeros
        shift @$array;
        $count++;
      }
      if (@$array) {   # plus one more
        shift @$array;
        $count++;
      }
      ### trimmed to: join(',',@$array)
      $mung_desc = "[TRIMMED START $count VALUES]\n";
      if (_aref_any_nonzero($array) &&
          (@$array >= 3 || length(join(',',@$array)) >= 5)) {
        $orig_array = $array;
      } else {
        ### too few values to trim ...
        next MUNG;
      }

    } elsif ($mung eq 'negate') {
      $mung_desc = "[NEGATED]\n";
      $array = [ map { my $value = $_;
                       unless ($value eq '0' || $value =~ s/^-//) {
                         $value = "-$value";
                       }
                       $value
                     } @$orig_array ];

    } elsif ($mung eq 'half') {
      $mung_desc = "[HALF]\n";
      $array = [ map {
        my $value = _to_bigint($_);
        if ($value % 2) {
          if ($verbose) {
            print "not all even, skip halving\n";
          }
          next MUNG;
        }
        $value/2
      } @$orig_array ];

    } elsif ($mung eq 'quarter') {
      $mung_desc = "[QUARTER]\n";
      $array = [ map {
        my $value = _to_bigint($_);
        if ($value % 4) {
          if ($verbose) {
            print "not all multiple of 4, skip quartering\n";
          }
          next MUNG;
        }
        $value/4
      } @$orig_array ];

    } elsif ($mung eq 'double') {
      $mung_desc = "[DOUBLE]\n";
      $array = [ map {2*_to_bigint($_)} @$orig_array ];

    } elsif ($mung eq 'abs') {
      $mung_desc = "[ABSOLUTE VALUES]\n";
      my $any_negative = 0;
      $array = [ map { my $abs = $_;
                       $any_negative |= ($abs =~ s/^-//);
                       $abs
                     } @$orig_array ];
      if (! $any_negative) {
        if ($verbose) {
          print "no negatives, skip absolutize\n";
        }
        next;
      }
      if (_constant_array(@$array)) {
        if ($verbose) {
          print "abs values all equal, skip absolutize\n";
        }
        next;
      }
    }

    my $re = $class->array_to_regexp($array);
    if ($h{'_EXPERIMENTAL_exact'}) {
      $re = ' '.$re;
    }

    if ($use_mmap) {
      pos($stripped_mmap) = 0;
      ### mmap total length: length($stripped_mmap)
    } else {
      seek $fh, 0, 0
        or croak "Error seeking stripped file: ",$!;
    }
    my $block = '';
    my $extra = '';
  SEARCH: for (;;) {
      my $line;
      if ($use_mmap) {

        # using regexp only
        $stripped_mmap =~ /$re/g or last SEARCH;
        my $found_pos = pos($stripped_mmap);

        # my $found_whole = $&;
        # ### $found_whole

        # $re matches , or \n at end
        # $found_pos may be after \n of matched line
        # So for $end look from $found_pos-1 onwards.
        # For $start look from $found_pos-2 since don't want rindex() to
        # give the \n which is at $found_pos-1.
        my $start = rindex($stripped_mmap,"\n",$found_pos-2) + 1;
        my $end = index($stripped_mmap,"\n",$found_pos-1);
        pos($stripped_mmap) = $end;
        $line = substr($stripped_mmap, $start, $end-$start);

        ### $found_pos
        ### char at found_pos: substr($stripped_mmap,$found_pos,1)
        ### $start
        ### $end
        ### found_pos from line end: $end-$found_pos
        ### $line
        ### assert: $end >= $start

        # my $pos = 0;
        # using combination index() and regexp
        # for (;;) {
        #   $stripped_mmap =~ /$re/g or last SEARCH;
        #   my $found_pos = pos($stripped_mmap)-1;
        #   # my $found_pos = index($stripped_mmap,$fixed,$pos);
        #   # if ($found_pos < 0) { last SEARCH; }
        #
        #   my $start = rindex($stripped_mmap,"\n",$found_pos) + 1;
        #   my $end = index($stripped_mmap,"\n",$found_pos);
        #   $pos = $end;
        #   $line = substr($stripped_mmap, $start, $end-$start);
        #   last if $line =~ $re;
        # }

      } else {
        ### block reads ...

        for (;;) {
          if ($block =~ /$re/g) {
            # same $found_pos logic as the mmap case above
            my $found_pos = pos($block);
            my $start = rindex($block,"\n",$found_pos-2) + 1;
            my $end = index($block,"\n",$found_pos-1);
            pos($block) = $end;
            $line = substr($block, $start, $end-$start);
            last;
          }
          $block = _read_block_lines($fh, $extra);
          defined $block or last SEARCH;

          # or line by line
          # $line = readline $fh;
          # defined $line or last SEARCH;
        }
      }

      my ($anum,$found_values_str)
        = Math::OEIS::Stripped->line_split_anum($line)
        or die "oops, A-number not matched in line: ",$line;
      ### $anum

      if (exists $exclude{$anum}) {
        ### exclude ...
        next;
      }

      # enforce values_min, values_max on the found sequence
      if (defined $values_min || defined $values_max) {
        my @found_values =Math::OEIS::Stripped->values_split($found_values_str);
        if ((defined $values_min && grep {$_ < $values_min} @found_values)
            || (defined $values_max && grep {$_ > $values_max} @found_values)) {
          ### skip due to found values out of range ...
          next;
        }
      }

      if (defined $max_matches && $count >= $max_matches) {
        print "... and more matches\n";
        last SEARCH;
      }

      print $name;
      $name = '';

      print $mung_desc;
      $mung_desc = '';

      my $anum_name = Math::OEIS::Names->anum_to_name($anum);
      if (! defined $anum_name) { $anum_name = '[unknown name]'; }
      print "$anum $anum_name\n";

      print "$line\n";
      $count++;
    }
  }
  if ($count == 0) {
    if ($verbose) {
      print "no matches\n";
    }
  }
  if ($count || $verbose) {
    print "\n";
  }
}

# Read a block of multiple lines from $fh.
# The return is a string $block, or undef at EOF.
# $extra in $_[1] is used to hold a partial line.
sub _read_block_lines {
  my ($fh, $extra) = @_;
  my $block = $extra;
  for (;;) {
    my $len = read($fh, $block, 65536,
                   length($block)); # append to $block
    if (! defined $len) {
      croak "Error seeking stripped file: ",$!;
    }
    if (! $len) {
      # EOF
      $_[1] = '';
      if (length ($block)) {
        return $block;
      } else {
        return undef;
      }
    }
    my $end = rindex $block, "\n";
    if ($end >= 0) {
      # keep partial line in $extra
      $_[1] = substr ($block, $end);                  # partial line
      substr($block, $end, length($block)-$end, '');  # truncate block
      return $block;
    }
    # no end of line in $block, keep reading to find one
  }
}

use constant _MIN_MATCH_COUNT => 15;
use constant _MIN_MATCH_CHARS => 40;
use constant _MAX_REGEXP_LENGTH => 400;

# Return a regexp (a string) which matches the numbers in $array.
# $str =~ s/^\s+//;
# $str =~ s/\s+$//;
# split /\s*,\s*/, $str
sub array_to_regexp {
  my ($self, $array) = @_;
  ### array_to_regexp(): join(',',@$array)
  my $re = ',';
  my $close = 0;
  foreach my $i (0 .. $#$array) {
    my $value = $array->[$i];
    if (length($re) > _MAX_REGEXP_LENGTH) {  # don't make a huge regexp
      last;
    }

    # Mandatory match of numbers or chars, whichever comes first,
    # after that OEIS can end.
    # Most OEIS samples are nice and long, with even hard ones going to
    # limits of reasonable computing, but some are shorter.  For example
    # A109680 circa July 2016 had only 19 values 46 chars.
    # ENHANCE-ME: take a parameter for these minimums.
    #
    if ($i >= _MIN_MATCH_COUNT || length($re) > _MIN_MATCH_CHARS) {
      $re .= '(?:[\r\n]|';
      $close++;
    }
    $re .= $value . ',';
  }
  $re .= ')' x $close;
#  $re .= "[,\r\n]";
  ### $re
  return $re;
}

# constant_diff($a,$b,$c,...)
# If all the given values have a constant difference then return that amount.
# Otherwise return undef.
#
sub _constant_diff {
  my $diff = shift;
  unless (@_) {
    return undef;
  }
  my $value = shift;
  $diff = $value - $diff;
  while (@_) {
    my $next_value = shift;
    if ($next_value - $value != $diff) {
      return undef;
    }
    $value = $next_value;
  }
  return $diff;
}

# _constant_array($a,$b,$c,...)
# If all the given values are all equal then return that value.
# Otherwise return undef.
#
sub _constant_array {
  my $value = shift;
  while (@_) {
    my $next_value = shift;
    if ($next_value != $value) {
      return undef;
    }
  }
  return $value;
}

# return true if the array in $aref has any non-zero entries
sub _aref_any_nonzero {
  my ($aref) = @_;
  foreach my $value (@$aref) {
    if ($value) { return 1; }
  }
  return 0;
}

{
  my $bigint_class;
  my $length_limit = length(~0) - 2;
  sub _to_bigint {
    my ($n) = @_;
    if (length($n) < $length_limit) {
      return $n;
    }
    $bigint_class ||= do {
      # Crib note: don't change the back-end if already loaded
      require Math::BigInt;
      'Math::BigInt'
    };
    # stringize as a workaround for a bug where Math::BigInt::GMP
    # incorrectly converts UV numbers bigger than IV
    return $bigint_class->new("$n");
  }
}

1;
__END__

=for stopwords Math OEIS mmap Mmap arrayref Eg Ryde programmatic stringized GCD

=head1 NAME

Math::OEIS::Grep - search for numbers in OEIS F<stripped> file

=head1 SYNOPSIS

 use Math::OEIS::Grep;
 Math::OEIS::Grep->search (array => [ 8,13,21,34,55,89 ]);
 # prints matches found

 # command line
 # perl -MMath::OEIS::Grep=-search,123,456,789

=head1 DESCRIPTION

This module searches for numbers in a downloaded copy of the OEIS
F<stripped> file.  See L<Math::OEIS::Stripped> on how to get that file.

This grep is an alternative to the OEIS web site search and is good if
offline or for mechanically trying a large numbers of searches.

The exact form of the results printout and transformations is not settled.
The intention is to do something sensible to find given numbers.

The OEIS F<names> file, if available, is used to show the name of a matched
sequence (see L<Math::OEIS::Names>).

=head2 Details

When a match is found it's usually necessary to examine the sequence
definition manually to check the relevance.  It might be any of exactly what
you're seeking, an interesting unexpected connection, a middle match only,
or mere coincidence of a few values.

If the given array of values is longer than the OEIS samples then it will
still match.  Matching stops at the end of the given values or the end of
the OEIS samples, whichever comes first.  A minimum match length is
demanded, and it's possible this is at the end of the sample values.  (Small
values like 0,1 tend to hit various false matches under this rule.  The
intention is to tighten in some way.)

Values can be either numbers or strings and are stringized for the grep.
For numbers, be careful of round-off if exceeding a Perl integer.
C<Math::BigInt> or anything similar can be used in the usual way if desired.

An array of constant values or small constant difference is noticed and not
searched since there's usually too many matches and the first is often not
the relevant OEIS sequence.

C<File::Map> is used to read the F<stripped> file if that module is
available.  This is recommended since C<mmap()> is roughly a 2x speedup over
plain reading (by blocks).

The OEIS search hints L<http://oeis.org/hints.html> note that it can be
worth skipping some initial values in case you have a different idea of a
start but then a known sequence.  There's a slight attempt to automate that
here by stripping leading zeros and one initial value if no full match.

It may be worth dividing out a small common factor.  There's attempts here
to automate that here by searching for /2 and /4 if no exact match (and
doubling *2 too).  Maybe more divisions could be attempted, even a full GCD.
In practice OEIS sequences with common factors are often present when they
arise naturally from a sequence definition.

Non-integer constants appear in the OEIS as sequences of decimal digits (and
sometimes other bases).  Digits should be given here as values 0 to 9 etc.
For angles, the OEIS is usually radians but sometimes degrees so it can be
worth trying both.  There's no attempt here to automate that.

=head1 FUNCTIONS

=over

=item C<Math::OEIS::Grep-E<gt>search (array =E<gt> $aref, ...)>

Print matches of the given C<array> values in the OEIS F<stripped> file.
The key/value pairs can be

    array        => $arrayref (mandatory)
    name         => $string
    max_matches  => $integer (default 10)
    values_min   => $integer or undef
    values_max   => $integer or undef
    exclude_list => arrayref of A-number strings

C<array> is an arrayref of values to search for.  This parameter must be
given.

C<name> is optional and is printed as a name of the values if matches are
found.  When doing many searches this can identify which one has matched, if
not obvious from the values.  Eg.

    name => "case d=123",

C<max_matches> limits the number of sequences returned.  This is intended as
a protection against a large number of matches from a small array or
frequently occurring values.

C<values_min>, C<values_max> specify the range of values permitted in the
matched sequence.  Default C<undef> means no limits.  These limits can be
used when the range of the target values is known and so sequences with
bigger or smaller should be skipped.

    values_min => 0,
    values_max => 2,

C<exclude_list> is an arrayref of A-numbers which should be excluded from
matching.  This can be used to avoid sequences close enough to match but
which you have reviewed and know to be different.

    exclude_list => [ "A123456", "A234567" ],

=back

=head1 COMMAND LINE

The module C<import> accepts a C<-search> option which is designed for use
from the command line

    perl -MMath::OEIS::Grep=-search,123,456,789
    # search and then exit perl

This C<-search> prints non-ASCII characters in sequence names with
C<Encode::Locale> if that module (and C<PerlIO::encoding>) is available.
(The module calls don't touch output encoding, that's left to application
mainline setups.)

From within Emacs, see the author's C<oeis.el> to run a search on numbers
entered or at point in the buffer

=over

L<http://user42.tuxfamily.org/oeis-el/index.html>

=back

F<examples/grep-not-in-oeis.pl> in the sources is a way to keep searches in
a document.

=head1 SEE ALSO

L<Math::OEIS>,
L<Math::OEIS::Stripped>,
L<Math::OEIS::Names>,
L<File::Map>

L<Encode::Locale>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-oeis/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

Math-OEIS is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-OEIS is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-OEIS.  If not, see L<http://www.gnu.org/licenses/>.

=cut
