#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use Lingua::EN::Alphabet::Shaw;

plan tests => 1;

my $shaw = Lingua::EN::Alphabet::Shaw->new();

# Please don't test for words being in the "C" (CMUdict)
# bank: these can go to being in the "W" bank at any time,
# which will break your test.
is_deeply([$shaw->transliterate_details('He does drink several ', 'tons', ' of contrafibularity milk a day')],
    [
          {
            'bank' => 'A',
            'text' => "\x{10463}\x{10470}",
            'src' => 'He'
          },
          {
            'bank' => 'L',
            'text' => ' '
          },
          {
            'bank' => 'W',
            'text' => "\x{1045b}\x{10473}\x{1045f}",
            'src' => 'does',
            'dab' => 1
          },
          {
            'bank' => 'L',
            'text' => ' '
          },
          {
            'bank' => 'A',
            'text' => "\x{1045b}\x{1046e}\x{10466}\x{10459}\x{10452}",
            'src' => 'drink'
          },
          {
            'bank' => 'L',
            'text' => ' '
          },
          {
            'bank' => 'W',
            'text' => "\x{10455}\x{10467}\x{1045d}\x{1047c}\x{10469}\x{10464}",
            'src' => 'several'
          },
          {
            'bank' => 'L',
            'text' => ' tons '
          },
          {
            'bank' => 'A',
            'text' => "\x{1045d}",
            'src' => 'of'
          },
          {
            'bank' => 'L',
            'text' => ' '
          },
          {
            'bank' => 'U',
            'text' => 'contrafibularity',
            'src' => 'contrafibularity'
          },
          {
            'bank' => 'L',
            'text' => ' '
          },
          {
            'bank' => 'A',
            'text' => "\x{10465}\x{10466}\x{10464}\x{10452}",
            'src' => 'milk'
          },
          {
            'bank' => 'L',
            'text' => ' '
          },
          {
            'bank' => 'A',
            'text' => "\x{10469}",
            'src' => 'a'
          },
          {
            'bank' => 'L',
            'text' => ' '
          },
          {
            'bank' => 'A',
            'text' => "\x{1045b}\x{10471}",
            'src' => 'day'
          }
        ],
    'basic details test');
