package Lingua::Stem::Snowball::Da;
use strict;
use bytes;
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License version 2,
#   *NOT* "earlier versions", as published by the Free Software Foundation.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#####

use constant DEBUG=>0;

use vars qw(%cache $VERSION);
$Lingua::Stem::Snowball::Da::VERSION = 1.01;

# special characters
my $aa = chr(229);              # &aring;
my $ae = chr(230);              # &aelig;
my $oe = chr(248);              # &oring;

# delete the s if a "s ending" is preceeded by one
# of these characters.
my %s_ending = (
                a => 1,
                b => 1,
                c => 1,
                d => 1,
                f => 1,
                g => 1,
                h => 1,
                j => 1,
                k => 1,
                l => 1,
                "m" => 1,
                n => 1,
                o => 1,
                p => 1,
                r => 1,
                t => 1,
                v => 1,
                "y" => 1,
                z => 1,
                $aa => 1,
               );

# danish vowels.
my $vowels = "aeiouy$ae$aa$oe";
my %vowels = (
              a=>1,
              e=>1,
              i=>1,
              o=>1,
              u=>1,
              "y"=>1,
              $ae=>1,
              $aa=>1,
              $oe=>1,
             );

# ####
# the endings in step 1
# XXX: these must be sorted by length
# to save time we've done it already.
my @endings = (
               ["erendes"],
               ["erende", "hedens"],
               ["erens", "endes", "heden", "ethed", "ernes", "erets", "heder", "erede"],
               ["ende", "enes", "ered", "eren", "erer", "eres", "eret", "erne", "heds"],
               ["hed", "ers", "ene", "ere", "ens", "ets"],
               ["er", "es", "et", "en"],
               ["e"],
              );

%Lingua::Stem::Snowball::Da::cache = ();

sub new {
  my $pkg = shift;
  $pkg = ref $pkg || $pkg;
  my %arg = @_;
  my $self = {};
  bless $self, $pkg;
  $self->{USE_CACHE} = $arg{use_cache} || 0;
  return $self;
}

sub step1 {
  my ($rs, $word) = @_;
  # ### STEP 1
  my $endinglen = 8;
  foreach (@endings) {
    $endinglen--;
    my $endingw = substr($rs, -$endinglen); # do this once.

    foreach (@$_) {
      # only continue if the word has this ending at all.
      next unless $endingw eq $_;
      warn "matched $_ in $word" if DEBUG;
      # a) delete the ending.
      return substr($word, 0, -$endinglen);
    }
  }

  if (substr($rs, -1) eq 's') {     # b)
    # check if it has a valid "s ending"...
    if ((length $rs == 1) ?
        exists $s_ending{substr($word, -2, -1)} :
        exists $s_ending{substr($rs, -2, -1)}) {
      warn "Valid s eding $word" if DEBUG;
      # ...delete the last character (which is a s)
      return substr($word, 0, -1);
    }
  }
  return $word;
}

sub stem {
  my ($self, $word) = @_;
  my $orig_word;
  warn " --- start : $word ---" if DEBUG;

  if ($self->{USE_CACHE}) {
    $orig_word = $word;
    return $cache{$word} if defined $cache{$word};
  }

  my ($rs, $lslen, $rslen) = getsides($word);
  return $word unless $lslen >= 3;

  $word = step1($rs, $word);

  # ### STEP 2
  warn "Step 2" if DEBUG;
  ($rs, $lslen, $rslen) = getsides($word);
  return $word unless $lslen >= 3;

  if (substr($rs, -2) =~ /gd|dt|gt|kt/) {
    warn "delete last letter $word in step 2" if DEBUG;
    $word = substr($word, 0, - 1);
    ($rs, $lslen, $rslen) = getsides($word);
    return $word unless $lslen >= 3;
  }

  # ### STEP 3
  if (substr($rs, -4) eq "igst") {
    warn "st as in igst deleted in $word" if DEBUG;
    $word = substr($word, 0, -2);
    ($rs, $lslen, $rslen) = getsides($word);
    return $word unless $lslen >= 3;
  }
  if (substr($rs, -4) eq "l${oe}st") {
    warn "t as in l${oe}st deleted in $word" if DEBUG;
    $word = substr($word, 0, -1);
    ($rs, $lslen, $rslen) = getsides($word);
    return $word unless $lslen >= 3;
  }
  for (qw/elig lig els ig/) {
    my $len = length;
    if (substr($rs, -$len) eq $_) {
      warn "delete $_ in $word" if DEBUG;
      $word = substr($word, 0, -$len);
      ($rs) = getsides($word);
      if (substr($rs, -2) =~ /gd|dt|gt|kt/) {
        warn "delete last letter $word in step 2 again" if DEBUG;
        $word = substr($word, 0, - 1);
        ($rs, $lslen, $rslen) = getsides($word);
      }
      last;
    }
  }

  return $word unless $lslen >= 3 && length $word > 3;

  # ### STEP 4
  if ($word =~ /([^$vowels])\1$/o) {
    warn "delete double konsonant in $word" if DEBUG;
    $word = substr($word, 0, -1);
  }

  if ($self->{USE_CACHE}) {
    $cache{$orig_word} = $word;
  }

  warn " --- end : $word ---" if DEBUG;
  return $word;
}

sub getsides {
  my $word = shift;
  # ###
  # find the first vowel with a non-vowel after it.
  my($found_vowel, $nonv_position, $curpos) = (0, -1, 0);
  #$found_vowel = 1 if exists $vowels{substr($word,0,1)};
  foreach (split//, $word) {
    $curpos++;
    if (exists $vowels{$_}) {
      $found_vowel = 1;
      next;
    } elsif ($found_vowel) {
      $nonv_position = $curpos;
      last;
    }
  }


  # got nothing: return false
  return undef if $nonv_position == -1;

  my($rs, $lslen); # left side and right side.
  # ###
  # length of the left side must be atleast 3 chars.
  if ($nonv_position < 3) {
    $lslen = length substr($word, 0, 3);
    $rs = substr($word, 3);
  } else {
    $lslen = $nonv_position;
    $rs = substr($word, $nonv_position);
  }
  return($rs, $lslen, length $rs);
}

1;

__END__

=head1 NAME

Lingua::Stem::Snowball::Da - Porters stemming algorithm for Denmark

=head1 SYNOPSIS

  use Lingua::Stem::Snowball::Da
  my $stemmer = new Lingua::Stem::Snowball::Da (use_cache => 1);

  foreach my $word (@words) {
	my $stemmed = $stemmer->stem($word);
	print $stemmed, "\n";
  }

=head1 DESCRIPTION

The stem function takes a scalar as a parameter and stems the word
according to Martin Porters Danish stemming algorithm,
which can be found at the Snowball website: L<http://snowball.tartarus.org/>.

It also supports caching if you pass the use_cache option when constructing
a new L:S:S:D object.

=head2 EXPORT

Lingua::Stem::Snowball::Da has nothing to export.

=head1 AUTHOR

Dennis Haney E<lt>davh@davh.dkE<gt>

Ask Solem Hoel, E<lt>ask@unixmonks.netE<gt>  (Swedish version)

=head1 SEE ALSO

L<perl>. L<Lingua::Stem::Snowball>. L<Lingua::Stem>. L<http://snowball.tartarus.org>.

=cut


