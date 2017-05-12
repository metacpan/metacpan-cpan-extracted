# -*- cperl -*-

use warnings;
use strict;

use Test::More tests => 15;
use Lingua::FreeLing3::Sentence;
use Lingua::FreeLing3::Word;

my $sentence = Lingua::FreeLing3::Sentence->new();

ok $sentence => "Sentence is defined";
isa_ok $sentence => 'Lingua::FreeLing3::Sentence';
isa_ok $sentence => 'Lingua::FreeLing3::Bindings::sentence';
ok !$sentence->is_parsed => "By default a tree is not parsed";
ok !$sentence->is_dep_parsed => "By default a tree is not dependency parsed";
is $sentence->length => 0;

my $other_sentence = Lingua::FreeLing3::Sentence->new(map {
    Lingua::FreeLing3::Word->new($_)
  } ('Hello',',','cruel','world','!'));

isa_ok $other_sentence => 'Lingua::FreeLing3::Sentence';
isa_ok $other_sentence => 'Lingua::FreeLing3::Bindings::sentence';
is $other_sentence->length => 5;
is $other_sentence->word(0)->form, "Hello", 'Checking first sentence word';
is $other_sentence->to_text => 'Hello , cruel world !';

my $yet_another = Lingua::FreeLing3::Sentence->new("Hey","my","old","friends");

isa_ok $yet_another => 'Lingua::FreeLing3::Sentence';
isa_ok $yet_another => 'Lingua::FreeLing3::Bindings::sentence';
is $yet_another->length => 4;

is $yet_another->to_text => 'Hey my old friends';


# my $it = $yet_another->iterator;
# use Data::Dumper;
# print Dumper $it;
