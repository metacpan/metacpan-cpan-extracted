# -*- cperl -*-

use warnings;
use strict;

use Test::More tests => 10;
use Lingua::FreeLing3::Paragraph;
use Lingua::FreeLing3::Sentence;

my $paragraph = Lingua::FreeLing3::Paragraph->new();

ok $paragraph => 'Paragraph is defined';
isa_ok $paragraph => 'Lingua::FreeLing3::Paragraph';
isa_ok $paragraph => 'Lingua::FreeLing3::Bindings::paragraph';
is $paragraph->length => 0, 'Paragraph is empty';

my $sentence = Lingua::FreeLing3::Sentence->new();
$paragraph->push($sentence);
is $paragraph->length => 1, 'Paragraph has one sentence';

my $s = $paragraph->sentence(0);
isa_ok $s => 'Lingua::FreeLing3::Sentence';

my $ns = Lingua::FreeLing3::Sentence->new();
$paragraph->push($ns);

is $paragraph->length => 2, 'Paragraph has two sentence';

my $os = $paragraph->sentence(1);
isa_ok $os => 'Lingua::FreeLing3::Sentence';

my @x = $paragraph->sentences();
isa_ok $_ => 'Lingua::FreeLing3::Sentence' for @x;






