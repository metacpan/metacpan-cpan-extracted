# Copyright 2011, 2012, 2013, 2014 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.


# http://oeis.org/wiki/Clear-cut_examples_of_keywords
#
# ENHANCE-ME: share most of the a-file/b-file reading with Math::NumSeq::File

package Math::NumSeq::OEIS::File;
use 5.004;
use strict;
use Carp;
use POSIX ();
use File::Spec;
use Symbol 'gensym';

use vars '$VERSION','@ISA';
$VERSION = 72;

use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_to_bigint = \&Math::NumSeq::_to_bigint;

use vars '$VERSION';
$VERSION = 72;

eval q{use Scalar::Util 'weaken'; 1}
  || eval q{sub weaken { $_[0] = undef }; 1 }
  || die "Oops, error making a weaken() fallback: $@";

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('OEIS File');
use Math::NumSeq::OEIS;
*parameter_info_array = \&Math::NumSeq::OEIS::parameter_info_array;

use constant::defer _HAVE_ENCODE => sub {
  eval { require Encode; 1 } || 0;
};

sub description {
  my ($class_or_self) = @_;
  if (ref $class_or_self && defined $class_or_self->{'description'}) {
    # instance
    return $class_or_self->{'description'};
  } else {
    # class
    return Math::NumSeq::__('OEIS sequence from file.');
  }
}

sub values_min {
  my ($self) = @_;
  ### OEIS-File values_min() ...
  return _analyze($self)->{'values_min'};
}
sub values_max {
  my ($self) = @_;
  ### OEIS-File values_max() ...
  return _analyze($self)->{'values_max'};
}

my %analyze_characteristics = (increasing            => 1,
                               increasing_from_i     => 1,
                               non_decreasing        => 1,
                               non_decreasing_from_i => 1,
                               smaller               => 1,
                              );
sub characteristic {
  my ($self, $key) = @_;
  if ($analyze_characteristics{$key}) {
    _analyze($self);
  }
  return shift->SUPER::characteristic(@_);
}

sub oeis_dir {
  require File::HomeDir;
  return File::Spec->catfile (File::HomeDir->my_home, 'OEIS');
}
sub anum_to_bfile {
  my ($anum, $prefix) = @_;
  $prefix ||= 'b';
  $anum =~ s/^A/$prefix/;
  return "$anum.txt";
}

#------------------------------------------------------------------------------
# Keep track of all instances which exist and on an ithread CLONE re-open
# any filehandles in the instances, so they have their own independent file
# positions in the new thread.

my %instances;
sub DESTROY {
  my ($self) = @_;
  delete $instances{$self+0};
}
sub CLONE {
  my ($class) = @_;
  foreach my $self (values %instances) {
    next unless $self;
    next unless $self->{'fh'};
    my $pos = _tell($self);
    my $fh = gensym;
    if (open $fh, "< $self->{'filename'}") {
      $self->{'fh'} = $fh;
      _seek ($self, $pos);
    } else {
      delete $self->{'fh'};
      delete $self->{'filename'};
    }
  }
}

#------------------------------------------------------------------------------

# The length in decimal digits of the biggest value which fits in a plain
# Perl integer.  For example on a 32-bit system this is 9 since 9 digit
# numbers such as "999_999_999" are the biggest which fit a signed IV
# (+2^31).
#
# The IV size is probed rather than using ~0 since under "perl -Minteger"
# have ~0 as -1 rather than the biggest UV ... except "use integer" is not
# normally global.
#
# The NV size is applied to the limit too since not sure should trust values
# to stay in IV or UV.  This means on a 64-bit integer with 53-bit NV
# "double" the limit is 53-bits.
#
use constant 1.02 _MAX_DIGIT_LENGTH => do {
  ### ~0 is: ~0

  my $iv = 0;
  for (1 .. 256) {
    my $new = ($iv << 1) | 1;
    unless ($new > $iv && ($new & 1) == 1) {
      last;
    }
    $iv = $new;
  }
  ### $iv

  require POSIX;
  my $nv = POSIX::FLT_RADIX() ** (POSIX::DBL_MANT_DIG()-5);
  ### $nv

  my $iv_len = length($iv) - 1;
  my $nv_len = length($nv) - 1;
  ($iv_len < $nv_len ? $iv_len : $nv_len)  # smaller of the two lengths;
};
### _MAX_DIGIT_LENGTH: _MAX_DIGIT_LENGTH()


#------------------------------------------------------------------------------

# special case a000000.txt files to exclude
#
my %afile_exclude
  = (
     # a003849.txt has replication level words rather than the individual
     # sequence values.
     'a003849.txt' => 1,

     # a027750.txt is unflattened divisors as lists.
     # Its first line is a correct looking "1 1" so _afile_is_good() doesn't
     # notice.
     'a027750.txt' => 1,
    );


# Fields:
#   fh          File handle ref, if reading B-file or A-file
#
#   next_seek   File pos to seek $fh for next() to read from.
#               ith() sets this when it moves the file position.
#
#   array       Arrayref of values if using .internal or .html.
#   array_pos   Index 0,1,2,... of next value of $array to return by next().
#
#   i           Next $i for next() to return.
#               When reading a file this is ignored, use the file i instead.

sub new {
  ### OEIS-File new() ...
  my $self = shift->SUPER::new(@_);

  delete $self->{'next_seek'}; # no initial seek
  $self->{'characteristic'}->{'integer'} = 1;

  my $anum = $self->{'anum'};
  (my $num = $anum) =~ s/^A//;
  foreach my $basefile ("a$num.txt",
                        "b$num.txt") {
    next if $afile_exclude{$basefile};

    next if $self->{'_dont_use_afile'} && $basefile =~ /^a/;
    next if $self->{'_dont_use_bfile'} && $basefile =~ /^b/;

    my $filename = File::Spec->catfile (oeis_dir(), $basefile);
    ### $filename
    my $fh = gensym();
    if (! open $fh, "< $filename") {
      ### cannot open: $!
      next;
    }

    $self->{'filename'} = $filename; # the B-file or A-file name
    $self->{'fh'} = $fh;
    if (! _afile_is_good($self)) {
      ### this afile not good ...
      close delete $self->{'fh'};
      delete $self->{'filename'};
      next;
    }
    $self->{'fh_i'} = $self->i_start;  # at first entry

    ### opened: $fh
    last;
  }

  my $have_info = (_read_internal_txt($self, $anum)
                   || _read_internal_html($self, $anum)
                   || _read_html($self, $anum));

  if (! $have_info && ! $self->{'fh'}) {
    croak 'OEIS file(s) not found for A-number "',$anum,'"';
  }

  weaken($instances{$self+0} = $self);
  return $self;
}

sub _analyze {
  my ($self) = @_;

  if ($self->{'analyze_done'}) {
    return $self;
  }
  $self->{'analyze_done'} = 1;

  ### _analyze() ...

  my $i_start = $self->i_start;
  my ($i, $value);
  my ($prev_i, $prev_value);

  my $values_min;
  my $values_max;
  my $increasing_from_i = $i_start;
  my $non_decreasing_from_i = $i_start;
  my $strictly_smaller_count = 0;
  my $smaller_count = 0;
  my $total_count = 0;

  my $analyze = sub {
    ### $prev_value
    ### $value
    if (! defined $values_min || $value < $values_min) {
      $values_min = $value;
    }
    if (! defined $values_max || $value > $values_max) {
      $values_max = $value;
    }

    if (defined $prev_value) {
      my $cmp = ($value <=> $prev_value);
      if ($cmp < 0) {
        # value < $prev_value
        $increasing_from_i = $i;
        $non_decreasing_from_i = $i;
      }
      if ($cmp <= 0) {
        # value <= $prev_value
        $increasing_from_i = $i;
      }
    }

    $total_count++;
    $smaller_count += (abs($value) <= $i);
    $strictly_smaller_count += ($value < $i);

    $prev_i = $value;
    $prev_value = $value;
  };

  if (my $fh = $self->{'fh'}) {
    my $oldpos = _tell($self);
    while (($i, $value) = _readline($self)) {
      $analyze->($value);
      last if $total_count > 200;
    }
    _seek ($self, $oldpos);
  } else {
    $i = $i_start;
    foreach (@{$self->{'array'}}) {
      $i++;
      $value = $_;
      $analyze->();
    }
  }

  my $range_is_small = (defined $values_max
                        && $values_max - $values_min <= 16);
  ### $range_is_small

  # "full" means whole sequence in sample values
  # "sign" means negatives in sequence
  if (! defined $self->{'values_min'}
      && ($range_is_small
          || $self->{'characteristic'}->{'OEIS_full'}
          || ! $self->{'characteristic'}->{'OEIS_sign'})) {
    ### set values_min: $values_min
    $self->{'values_min'} = $values_min;
  }
  if (! defined $self->{'values_max'}
      && ($range_is_small
          || $self->{'characteristic'}->{'OEIS_full'})) {
    ### set values_max: $values_max
    $self->{'values_max'} = $values_max;
  }

  $self->{'characteristic'}->{'smaller'}
    = ($total_count == 0
       || ($smaller_count / $total_count >= .9
           && $strictly_smaller_count > 0));
  ### decide smaller: $self->{'characteristic'}->{'smaller'}

  ### $increasing_from_i
  if (defined $prev_i && $increasing_from_i < $prev_i) {
    if ($increasing_from_i - $i_start < 20) {
      $self->{'characteristic'}->{'increasing_from_i'} = $increasing_from_i;
    }
    if ($increasing_from_i == $i_start) {
      $self->{'characteristic'}->{'increasing'} = 1;
    }
  }

  ### $non_decreasing_from_i
  if (defined $prev_i && $non_decreasing_from_i < $prev_i) {
    if ($non_decreasing_from_i - $i_start < 20) {
      $self->{'characteristic'}->{'non_decreasing_from_i'} = $non_decreasing_from_i;
    }
    if ($non_decreasing_from_i == $i_start) {
      $self->{'characteristic'}->{'non_decreasing'} = 1;
    }
  }

  return $self;
}

# # compare $x <=> $y but in strings in case they're bigger than IV or NV
# # my $cmp = _value_cmp ($value, $prev_value);
# sub _value_cmp {
#   my ($x, $y) = @_;
#   ### _value_cmp(): "$x  $y"
#   ### cmp: $x cmp $y
#
#   my $x_neg = substr($x,0,1) eq '-';
#   my $y_neg = substr($y,0,1) eq '-';
#   ### $x_neg
#   ### $y_neg
#
#   return ($y_neg <=> $x_neg
#           || ($x_neg ? -1 : 1) * (length($x) <=> length($y)
#                                   || $x cmp $y));
# }

sub _seek {
  my ($self, $pos) = @_;
  seek ($self->{'fh'}, $pos, 0)
    or croak "Cannot seek $self->{'filename'}: $!";
}
sub _tell {
  my ($self) = @_;
  my $pos = tell $self->{'fh'};
  if ($pos < 0) {
    croak "Cannot tell file position $self->{'filename'}: $!";
  }
  return $pos;
}

sub rewind {
  my ($self) = @_;
  ### OEIS-File rewind() ...

  $self->{'i'} = $self->i_start;
  $self->{'array_pos'} = 0;
  $self->{'next_seek'} = 0;
}

sub next {
  my ($self) = @_;
  ### OEIS-File next(): "i=$self->{'i'}"

  my $value;
  if (my $fh = $self->{'fh'}) {
    ### from readline ...
    if (defined (my $pos = delete $self->{'next_seek'})) {
      ### seek to: $pos
      _seek($self, $pos);
    }
    return _readline($self);

  } else {
    ### from array ...
    my ($value) = _array_value($self, $self->{'array_pos'}++)
      or return;
    return ($self->{'i'}++, $value);
  }
}

# Return $self->{'array'}->[$pos], or no values if $pos past end of array.
# Array values are promoted to BigInt if necessary.
sub _array_value {
  my ($self, $pos) = @_;
  ### _array_value(): $pos

  my $array = $self->{'array'};
  if ($pos > $#$array) {
    ### past end of array ...
    return;
  }
  my $value = $array->[$pos];

  # large values as Math::BigInt
  # initially $array has strings, make bigint objects when required
  if (! ref $value && length($value) > _MAX_DIGIT_LENGTH) {
    $value = $array->[$pos] = _to_bigint($value);
  }
  ### $value
  return $value;
}

# Read a line from an open B-file or A-file, return ($i,$value).
# At EOF return empty ().
#
sub _readline {
  my ($self) = @_;
  my $fh = $self->{'fh'};
  while (defined (my $line = <$fh>)) {
    chomp $line;
    $line =~ tr/\r//d;    # delete CR if CRLF line endings, eg. b009000.txt
    ### $line

    if ($line =~ /^\s*(#|$)/) {
      ### ignore blank or comment ...
      # comment lines with "#" eg. b002182.txt
      next;
    }

    # leading whitespace allowed as per b195467.txt
    if (my ($i, $value) = ($line =~ /^\s*
                                     ([0-9]+)      # i
                                     [ \t]+
                                     (-?[0-9]+)    # value
                                     [ \t]*
                                     $/x)) {
      ### _readline: "$i  $value"
      if (length($value) > _MAX_DIGIT_LENGTH) {
        $value = _to_bigint($value);
      }
      $self->{'fh_i'} = $i+1;
      return ($i, $value);
    }
  }
  undef $self->{'fh_i'};
  return;
}

# Return true if the a000000.txt file in $self->{'fh'} looks good.
# Various a-files are source code or tables rather than sequence values.
#
sub _afile_is_good {
  my ($self) = @_;
  my $fh = $self->{'fh'};
  my $good = 0;
  my $prev_i;
  while (defined (my $line = <$fh>)) {
    chomp $line;
    $line =~ tr/\r//d;    # delete CR if CRLF line endings, eg. b009000.txt
    ### $line

    if ($line =~ /^\s*(#|$)/) {
      ### ignore blank or comment ...
      next;
    }

    # Must have line like "0 123".  Can have negative OFFSET and so index i,
    # eg. A166242 (though that one doesn't have an A-file).
    my ($i,$value) = ($line =~ /^(-?[0-9]+)     # i
                                [ \t]+
                                (-?[0-9]+)    # value
                                [ \t]*
                                $/x)
      or last;

    if (defined $prev_i && $i != $prev_i+1) {
      ### bad A-file, initial "i" values not consecutive ...
      last;
    }
    $prev_i = $i;

    $good++;
    if ($good >= 3) {
      ### three good lines, A-file is good ...
      _seek ($self, 0);
      return 1;
    }
  }
  return 0;
}

sub _read_internal_txt {
  my ($self, $anum) = @_;
  ### _read_internal_txt(): $anum

  return 0 if $self->{'_dont_use_internal'};

  foreach my $basefile ("$anum.internal.txt") {
    my ($fullname, $contents) = _slurp_oeis_file($self,$basefile)
      or next;
    if (_HAVE_ENCODE) {
      # "Internal" text format is utf-8.
      $contents = Encode::decode('utf-8', $contents, Encode::FB_PERLQQ());
    }

    ### $contents

    # eg. "%O A007318 0,5"
    my $offset;
    if ($contents =~ /^%O\s+\Q$anum\E\s+(\d+)/im) {
      $offset = $1;
      ### %O line: $offset
    } else {
      $offset = 0;
    }

    # eg. "%N A007318 Pascal's triangle ..."
    if ($contents =~ m{^%N\s+\Q$anum\E\s+(.*)}im) {
      _set_description ($self, $1);
    } else {
      ### description not matched ...
    }

    # eg. "%K A007318 nonn,tabl,nice,easy,core,look,hear,changed"
    _set_characteristics ($self,
                          $contents =~ /^%K\s+\Q$anum\E\s+(.*)/im && $1);

    # the eishelp1.html says
    # %V,%W,%X lines for signed sequences
    # %S,%T,%U lines for non-negative sequences
    # though now %S is signed and unsigned both is it?
    #
    if (! $self->{'fh'}) {
      my @samples;
      # capital %STU etc, but any case <tt>
      while ($contents =~ m{^%[VWX]\s+\Q$anum\E\s+(.*)}mg) {
        push @samples, $1;
      }
      unless (@samples) {
        while ($contents =~ m{^%[STU]\s+\Q$anum\E\s+(.*)}mg) {
          push @samples, $1;
        }
        unless (@samples) {
          croak "Oops list of values not found in ",$self->{'filename'};
        }
      }
      # join multiple lines of samples
      _split_sample_values ($self, join(', ',@samples));
    }

    # %O "OFFSET" is subscript of first number.
    # Or for digit expansions it's the number of terms before the decimal
    # point, per http://oeis.org/eishelp2.html#RO
    #
    unless ($self->{'characteristic'}->{'digits'}) {
      $self->{'i'} = $self->{'i_start'} = $offset;
    }
    ### i: $self->{'i'}
    ### i_start: $self->{'i_start'}

    return 1; # success
  }

  return 0; # file not found
}

sub _read_internal_html {
  my ($self, $anum) = @_;
  ### _read_internal_html(): $anum

  return 0 if $self->{'_dont_use_internal'};

  foreach my $basefile ("$anum.internal.html") {
    my ($fullname, $contents) = _slurp_oeis_file($self,$basefile)
      or next;
    # "Internal" files are served as html with a <meta> charset indicator
    $contents = _decode_html_charset($contents);
    ### $contents

    my $offset;
    if ($contents =~ /(^|<tt>)%O\s+(\d+)/im) {
      $offset = $2;
      ### %O line: $offset
    } else {
      $offset = 0;
    }

    if ($contents =~ m{(^|<tt>)%N (.*?)(<tt>|$)}im) {
      _set_description ($self, $2);
    } else {
      ### description not matched ...
    }

    _set_characteristics ($self,
                          $contents =~ /(^|<tt>)%K (.*?)(<tt>|$)/im
                          && $2);

    # the eishelp1.html says
    # %V,%W,%X lines for signed sequences
    # %S,%T,%U lines for non-negative sequences
    # though now %S is signed and unsigned both is it?
    #
    if (! $self->{'fh'}) {
      my @samples;
      # capital %STU etc, but any case <tt>
      while ($contents =~ m{(^|<[tT][tT]>)%[VWX] (.*?)(</[tT][tT]>|$)}mg) {
        push @samples, $2;
      }
      unless (@samples) {
        while ($contents =~ m{(^|<[tT][tT]>)%[STU] (.*?)(</[tT][tT]>|$)}mg) {
          push @samples, $2;
        }
        unless (@samples) {
          croak "Oops list of values not found in ",$self->{'filename'};
        }
      }
      # join multiple lines of samples
      _split_sample_values ($self, join(', ',@samples));
    }

    # %O "OFFSET" is subscript of first number.
    # Or for digit expansions it's the number of terms before the decimal
    # point, per http://oeis.org/eishelp2.html#RO
    #
    unless ($self->{'characteristic'}->{'digits'}) {
      $self->{'i'} = $self->{'i_start'} = $offset;
    }
    ### i: $self->{'i'}
    ### i_start: $self->{'i_start'}

    return 1; # success
  }

  return 0; # file not found
}

# Fill $self with contents of ~/OEIS/A000000.html but various fragile greps
# of the html.
# Return 1 if .html or .htm file exists, 0 if not.
#
sub _read_html {
  my ($self, $anum) = @_;
  ### _read_html(): $anum

  return 0 if $self->{'_dont_use_html'};

  foreach my $basefile ("$anum.html", "$anum.htm") {
    my ($fullname, $contents) = _slurp_oeis_file($self,$basefile)
      or next;
    $contents = _decode_html_charset($contents);

    if ($contents =~
        m{$anum[ \t]*\n.*?       # target anum
          <td[^>]*>\s*(?:</td>)? # <td ...></td> empty
          <td[^>]*>              # <td ...>
          \s*
          (.*?)                  # text through to ...
          (<br>|</?td)           # <br> or </td> or <td>
       }isx) {
      _set_description ($self, $1);
    } else {
      ### description not matched ...
    }

    my $offset = ($contents =~ /OFFSET.*?<[tT][tT]>(\d+)/s
                  && $1);
    ### $offset

    # fragile grep out of the html ...
    my $keywords;
    if ($contents =~ m{KEYWORD.*?<[tT][tT][^>]*>(.*?)</[tT][tT]>}s) {
      ### html keywords match: $1
      $keywords = $1;
    } else {
      # die "Oops, KEYWORD not matched: $anum";
    }
    _set_characteristics ($self, $keywords);

    if (! $self->{'fh'}) {
      # fragile grep out of the html ...
      $contents =~ s{>graph</a>.*}{};
      $contents =~ m{.*<tt>([^<]+)</tt>}i;
      my $list = $1;
      _split_sample_values ($self, $list);
    }

    # %O "OFFSET" is subscript of first number, but for digit expansions
    # it's the position of the decimal point
    # http://oeis.org/eishelp2.html#RO
    if (! $self->{'characteristic'}->{'digits'}) {
      $self->{'i'} = $self->{'i_start'} = $offset;
    }
    ### i: $self->{'i'}
    ### i_start: $self->{'i_start'}

    return 1;
  }
  return 0;
}

# Return the contents of ~/OEIS/$filename.
# $filename is like "A000000.html" to be taken relative to oeis_dir().
# If $filename cannot be read then return undef.
sub _slurp_oeis_file {
  my ($self,$filename) = @_;
  $filename = File::Spec->catfile (oeis_dir(), $filename);
  ### $filename

  if (! open FH, "< $filename") {
    ### cannot open file: $!
    return;
  }
  my $contents = do { local $/; <FH> }; # slurp
  close FH
    or return;
  $self->{'filename'} ||= $filename;
  return ($filename, $contents);
}

sub _set_description {
  my ($self, $description) = @_;
  ### _set_description(): $description

  $description =~ s/\s+$//;       # trailing whitespace
  $description =~ s/\s+/ /g;      # collapse whitespace
  $description =~ s/<[^>]*?>//sg; # tags <foo ...>
  $description =~ s/&lt;/</ig;    # unentitize <
  $description =~ s/&gt;/>/ig;    # unentitize >
  $description =~ s/&amp;/&/ig;   # unentitize &
  $description =~ s/&#(\d+);/chr($1)/ge; # unentitize numeric ' and "

  # ENHANCE-ME: maybe __x() if made available, or an sprintf "... %s" would
  # be enough ...
  $description .= "\n";
  if ($self->{'fh'}) {
    $description .= sprintf(Math::NumSeq::__('Values from B-file %s'),
                            $self->{'filename'})
  } else {
    $description .= sprintf(Math::NumSeq::__('Values from %s'),
                            $self->{'filename'})
  }
  $self->{'description'} = $description;
}

sub _set_characteristics {
  my ($self, $keywords) = @_;
  ### _set_characteristics()
  ### $keywords

  if (! defined $keywords) {
    return; # if perhaps match of .html failed
  }

  $keywords =~ s{<[^>]*>}{}g;  # <foo ...> tags
  ### $keywords

  foreach my $key (split /[, \t]+/, ($keywords||'')) {
    ### $key
    $self->{'characteristic'}->{"OEIS_$key"} = 1;
  }

  # if ($self->{'characteristic'}->{'OEIS_cofr'}) {
  #   $self->{'characteristic'}->{'continued_fraction'} = 1;
  # }

  # "cons" means decimal digits of a constant
  # but don't reckon A000012 all-ones that way
  # "base" means non-decimal, it seems, maybe
  if ($self->{'characteristic'}->{'OEIS_cons'}
      && ! $self->{'characteristic'}->{'OEIS_base'}
      && $self->{'anum'} ne 'A000012') {
    $self->{'values_min'} = 0;
    $self->{'values_max'} = 9;
    $self->{'characteristic'}->{'digits'} = 10;
  }

  if (defined (my $description = $self->{'description'})) {
    if ($description =~ /expansion of .* in base (\d+)/i) {
      $self->{'values_min'} = 0;
      $self->{'values_max'} = $1 - 1;
      $self->{'characteristic'}->{'digits'} = $1;
    }
    if ($description =~ /^number of /i) {
      $self->{'characteristic'}->{'count'} = 1;
    }
  }
}

sub _split_sample_values {
  my ($self, $str) = @_;
  ### _split_sample_values(): $str
  unless (defined $str && $str =~ m{^([0-9,-]|\s)+$}) {
    croak "Oops list of sample values not recognised in ",$self->{'filename'},"\n",
      (defined $str ? $str : ());
  }
  $self->{'array'} = [ split /[, \t\r\n]+/, $str ];
}

sub _decode_html_charset {
  my ($contents) = @_;

  # eg. <META http-equiv="content-type" content="text/html; charset=utf-8">
  # HTTP::Message has a blob of code for this, using the full HTTP::Parser,
  # but a slack regexp should be enough for OEIS pages.
  #
  if (_HAVE_ENCODE
      && $contents =~ m{<META[^>]+
                        http-equiv=[^>]+
                        content-type[^>]+
                        charset=([a-z0-9-_]+)}isx) {
    return Encode::decode($1, $contents, Encode::FB_PERLQQ());
  } else {
    return $contents;
  }
}

#------------------------------------------------------------------------------

# Similar bsearch to Search::Dict, but Search::Dict doesn't allow for
# comment lines at the start of the file or blank lines at the end.
#
#use Smart::Comments;

sub ith {
  my ($self, $i) = @_;
  ### ith(): "$i  cf fh_i=".($self->{'fh_i'} || -999)

  if (my $fh = $self->{'fh'}) {
    if (! defined $self->{'next_seek'}) {
      $self->{'next_seek'} = tell($fh);
    }

    if (defined $self->{'fh_i'} && $i <= $self->{'fh_i'} + 20) {
      ### fh_i is target ...
      if (my ($line_i, $value) = _readline($self)) {
        if ($line_i == $i) {
          return $value;
        }
      }
    }

    my $lo = 0;
    my $hi = -s $fh;
    for (;;) {
      ### at: "lo=$lo hi=$hi  consider mid=".int(($lo+$hi)/2)
      my $mid = int(($lo+$hi)/2);
      _seek ($self, $mid);

      if (! defined(readline $fh)) {
        ### mid is EOF ...
        last;
      }
      ### skip partial line to: tell($fh)
      $mid = tell($fh);
      if ($mid >= $hi) {
        last;
      }

      my ($line_i,$value) = _readline($self)
        or last;  # only blank lines between $mid and EOF, go linear

      ### $line_i
      ### $value
      if ($line_i == $i) {
        ### found by binary search ...
        return $value;
      }
      if ($line_i < $i) {
        ### line_i before the target, advance lo ...
        $lo = tell($fh);
      } else {
        ### line_i after target, reduce hi ...
        $hi = $mid;
      }
    }

    _seek ($self, $lo);
    for (;;) {
      my ($line_i,$value) = _readline($self)
        or last;
      if ($line_i == $i) {
        ### found by linear search ...
        $self->{'fh_i'} = $line_i+1;
        return $value;
      }
      if ($line_i > $i) {
        return undef;
      }
    }
    return undef;

  } else {
    $i -= $self->i_start;
    unless ($i >= 0) {
      return undef; # negative or NaN
    }
    return $self->{'array'}->[$i];
  }
}

1;
__END__


#------------------------------------------------------------------------------

# foreach my $basefile (anum_to_html($anum), anum_to_html($anum,'.htm')) {
#   my $filename = File::Spec->catfile (oeis_dir(), $basefile);
#   ### $basefile
#   ### $filename
#   if (open FH, "<$filename") {
#     my $contents = do { local $/; <FH> }; # slurp
#     close FH or die;
#
#     # fragile grep out of the html ...
#     $contents =~ s{>graph</a>.*}{};
#     $contents =~ m{.*<tt>([^<]+)</tt>};
#     my $list = $1;
#     unless ($list =~ m{^([0-9,-]|\s)+$}) {
#       croak "Oops list of values not found in ",$filename;
#     }
#     my @array = split /[, \t\r\n]+/, $list;
#     ### $list
#     ### @array
#     return \@array;
#   }
#   ### no html: $!
# }




#------------------------------------------------------------------------------
# stripped.gz and names.gz
# no OFFSET, so i_start would be wrong, in general

# sub _read_stripped {
#   my ($self, $anum) = @_;
#   ### _read_stripped(): $anum
#
#   return 0 if $self->{'_dont_use_stripped'};
#   (my $num = $anum) =~ s/^A//;
#
#   my $filename = File::Spec->catfile (oeis_dir(), "stripped");
#   ### $filename
#   my $line;
#   my $cmpfunc = sub {
#     my ($line) = @_;
#     $line =~ /^A(\d+)/ or return -1;
#     return ($1 <=> $num);
#   };
#   if (open FH, "<$filename") {
#     $line = _bsearch_textfile (\*FH, $cmpfunc);
#   } else {
#     require IO::Zlib;
#     tie *FILE, 'IO::Zlib', $filename, "rb";
#     $line = _lsearch_textfile (\*FH, $cmpfunc);
#   }
#   if (! defined $line) {
#     return 0;
#   }
#
#   return 1; # success
# }
#
# sub _bsearch_textfile {
#   my ($fh, $cmpfunc) = @_;
#   my $lo = 0;
#   my $hi = -s $fh;
#   for (;;) {
#     my $mid = ($lo+$hi)/2;
#     seek $fh, $mid, 0
#       or last;
#
#     # skip partial line
#     defined(readline $fh)
#       or last; # EOF
#
#     # position start of line
#     $mid = tell($fh);
#     if ($mid >= $hi) {
#       last;
#     }
#
#     my $line = readline $fh;
#     defined $line
#       or last; # EOF
#
#     my $cmp = &$cmpfunc ($line);
#     if ($cmp == 0) {
#       return $line;
#     }
#     if ($cmp < 0) {
#       $lo = tell($fh);  # after
#     } else {
#       $hi = $mid;
#     }
#   }
#
#   seek $fh, $lo, 0;
#   while (defined (my $line = readline $fh)) {
#     my $cmp = &$cmpfunc($line);
#     if ($cmp == 0) {
#       return $line;
#     }
#     if ($cmp > 0) {
#       return undef;
#     }
#   }
#   return undef;
# }
