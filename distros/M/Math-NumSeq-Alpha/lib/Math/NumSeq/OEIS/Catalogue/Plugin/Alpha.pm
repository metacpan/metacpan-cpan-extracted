# Copyright 2012, 2013 Kevin Ryde

# This file is part of Math-NumSeq-Alpha.
#
# Math-NumSeq-Alpha is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq-Alpha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq-Alpha.  If not, see <http://www.gnu.org/licenses/>.

package Math::NumSeq::OEIS::Catalogue::Plugin::Alpha;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 3;
use Math::NumSeq::OEIS::Catalogue::Plugin;
@ISA = ('Math::NumSeq::OEIS::Catalogue::Plugin');

use constant::defer info_arrayref => sub {
  # Lingua::Any::Numbers prior to version 0.45 fails to load in "perl -T"
  # taint mode.  Might like to treat that as no languages available, but
  # can't trap a taint error with an eval{}.  If you're using taint mode
  # then get Lingua::Any::Numbers version 0.45.
  require Lingua::Any::Numbers;
  my @available = Lingua::Any::Numbers::available();

  my %available;
  @available{@available} = ();

  return [
          {
           # A005589 excludes conjunctions, so 101 = "one hundred one" = 13
           # letters.  Not explicitly noted, but can be seen in the
           # a000027.txt linked and in the Pari code by M. F. Hasler.
           #
           anum  => 'A005589',
           class => 'Math::NumSeq::AlphabeticalLength',
           parameters => [ i_start => 0, conjunctions => 0 ],
          },
          {
           anum  => 'A006944',
           class => 'Math::NumSeq::AlphabeticalLength',
           parameters => [ number_type => 'ordinal',
                           i_start => 1, conjunctions => 0 ],
          },
          {
           anum  => 'A016037',
           class => 'Math::NumSeq::AlphabeticalLengthSteps',
           parameters => [ i_start => 0, conjunctions => 0 ],
          },

          (exists $available{'ES'}
           ? {
              anum  => 'A011762',
              class => 'Math::NumSeq::AlphabeticalLength',
              parameters => [ lang => 'es', i_start => 0 ],
             }
           : ()),

          (exists $available{'EO'} # Esperanto
           ? {
              anum  => 'A057853',
              class => 'Math::NumSeq::AlphabeticalLength',
              parameters => [ lang => 'eo', i_start => 0 ],
             }
           : ()),

          # premiere ?
          # (exists $available{'FR'}
          #  ? {
          #     anum  => 'A006969',
          #     class => 'Math::NumSeq::AlphabeticalLength',
          #     parameters => [ lang => 'fr',
          #                     number_type => 'ordinal',
          #                     i_start => 1 ],
          #    }
          #  : ()),

          # egy ?
          # (exists $available{'HU'}
          #  ? {
          #     anum  => 'A007292',
          #     class => 'Math::NumSeq::AlphabeticalLength',
          #     parameters => [ lang => 'hu', i_start => 1 ],
          #    }
          #  : ()),

          # centottanta in A026858 vs centoottanta in Lingua
          # (exists $available{'IT'}
          #  ? {
          #     anum  => 'A026858',
          #     class => 'Math::NumSeq::AlphabeticalLength',
          #     parameters => [ lang => 'it', i_start => 0 ],
          #    }
          #  : ()),

          # (exists $available{'JA'}
          #  ? {
          #     anum  => 'A030166',
          #     class => 'Math::NumSeq::AlphabeticalLength',
          #     parameters => [ lang => 'ja', i_start => 0 ],
          #    }
          #  : ()),

          # pos=17 is n=18 is OEIS 8 for "achttien"
          # cf Lingua::NL::Numbers "achtien"
          # 1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
          # 3, 4, 4, 4, 4, 3, 5, 4, 5, 4, 3, 6, 7, 8, 8, 7, 9, 8, 9, 7,
          # (exists $available{'NL'}
          #  ? {
          #     anum  => 'A090589',
          #     class => 'Math::NumSeq::AlphabeticalLength',
          #     parameters => [ lang => 'nl', i_start => 1 ],
          #    }
          #  : ()),

          # (exists $available{'NO'}
          #  ? {
          #     anum  => 'A014656',
          #     class => 'Math::NumSeq::AlphabeticalLength',
          #     parameters => [ lang => 'no', i_start => 1 ],
          #    }
          #  : ()),

          # (exists $available{'PL'}
          #  ? {
          #     anum  => 'A008962',
          #     class => 'Math::NumSeq::AlphabeticalLength',
          #     parameters => [ lang => 'pl', i_start => 0 ],
          #    }
          #  : ()),

          # No, Brazilian Portuguese "catorze" cf PT "quatorze"
          # # A057696 values start n=1 but OFFSET=0
          # (exists $available{'PT'}
          #  ? {
          #     anum  => 'A057696',
          #     class => 'Math::NumSeq::AlphabeticalLength',
          #     parameters => [ lang => 'pt', i_start => 1 ],
          #    }
          #  : ()),

          # No, Lingua::RU::Number 0.05 is money amounts only.
          # (exists $available{'RU'}
          #  ? {
          #     anum  => 'A006994',
          #     class => 'Math::NumSeq::AlphabeticalLength',
          #     parameters => [ lang => 'ru', i_start => 0 ],
          #    }
          #  : ()),

          (exists $available{'SV'}
           ? {
              anum  => 'A059124',
              class => 'Math::NumSeq::AlphabeticalLength',
              parameters => [ lang => 'sv', i_start => 0 ],
             }
           : ()),

          (exists $available{'TR'}
           ? {
              anum  => 'A057435',
              class => 'Math::NumSeq::AlphabeticalLength',
              parameters => [ lang => 'tr', i_start => 1 ],
             }
           : ()),


          # SevenSegments
          {
           anum  => 'A063720',
           class => 'Math::NumSeq::SevenSegments',
           parameters => [ six => 5 ],
          },
          {
           anum  => 'A006942',
           class => 'Math::NumSeq::SevenSegments',
           parameters => [ nine => 6 ],
          },
          {
           anum  => 'A074458',
           class => 'Math::NumSeq::SevenSegments',
           parameters => [ seven => 4 ],
          },
          {
           anum  => 'A010371',
           class => 'Math::NumSeq::SevenSegments',
           parameters => [ seven => 4, nine => 6 ],
          },

         ];
};

1;
__END__
