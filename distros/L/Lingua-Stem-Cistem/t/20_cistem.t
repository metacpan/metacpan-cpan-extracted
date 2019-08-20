#!perl

use strict;
use warnings;

use utf8;

binmode(STDOUT,":encoding(UTF-8)");
binmode(STDERR,":encoding(UTF-8)");

use lib qw(../lib/);

use Test::More;
use Test::More::UTF8;

#use Lingua::Stem::Cistem qw(stem segment stem_robust segment_robust);
use Lingua::Stem::Cistem (':all');

#my $cistem = Lingua::Stem::Cistem->new();

my $examples0 = [
  [ qw(inhaltsleerer inhaltsleer) ],
  [ qw(Hast has) ],
  [ qw(Geangeheiratetem angeheirat) ],
  [ qw(Leheröööör leheroooor) ],
  [ qw(geheilwässert heilwass) ],
  [ qw(heißwässert heißwass) ],
  [ qw(Geborcherndt borcherndt) ],

];

my $tests = [
# format: [ in, out, casing, ge-remove ]
[ 'transliterate', [
  #[,''], # TODO
  ['ABC','abc'],
  ['ÄÖÜ','aou'],
  ['äöü','aou'],
  ['ß','ss'],
  ['ßß','ssss'],

  ['sch','sch'],
  ['ei','ei'],
  ['ie','ie'],
  ['aa','aa'],

]],

[ 'transliterate_segment', [
  #[,''], # TODO
  ['ABC','abc'],
  ['ÄÖÜ','äöü'],
  ['äöü','äöü'],
  ['ß','ß'],
  ['ßß','ßß'],

  ['sch','sch'],
  ['ei','ei'],
  ['ie','ie'],
  ['aa','aa'],

]],

#[ 'unwordy', [
#  ['$','sch'],
#  ['%','ei'],
#  ['&','ie'],
#]],

[ 'wordy', [
  ['$','$'],
  ['%','%'],
  ['&','&'],

]],

[ 'prefix', [
  ['ge123','ge123'],
  ['ge123','ge123',0,0],
  ['ge123','ge123',0,1],
  ['ge1234','1234'],
  ['ge1234','1234',0,0],
  ['ge1234','1234',0,1],

]],

[ 'prefix_keepers', [
  ['ge123','ge123'],
  ['ge123','ge123',0,0],
  ['ge123','ge123',0,1],
  ['ge1234','1234'],
  ['ge1234','1234',0,0],
  ['ge1234','ge1234',0,1],

]],

[ 'suffix', [
  ['123em','123em'],
  ['1234em','1234'],

  ['123er','123er'],
  ['1234er','1234'],

  ['123nd','123nd'],
  ['1234nd','1234'],

  ['12e','12e'],
  ['123e','123'],

  ['12s','12s'],
  ['123s','123'],

  ['12n','12n'],
  ['123n','123'],

]],

[ 'suffix_t', [
  ['12t','12t'],
  ['123t','123t'],
  ['123t','123t',0],
  ['123t','123',1],

  ['Hut','hut'],
  ['Hut','hut',0],
  ['Hut','hut',1],

  ['Hast','hast'],
  ['Hast','hast',0],
  ['Hast','has',1],

  ['hat','hat'],
  ['hat','hat',0],
  ['hat','hat',1],

  ['hast','has'],
  ['hast','has',0],
  ['hast','has',1],

]],


# U+0308 COMBINING DIAERESIS
# \N{COMBINING DIARESIS}
# U+00EB LATIN SMALL LETTER E WITH DIAERESIS
[ 'unicode', [

  ["a\N{U+0308}",'a'],

  ["\N{U+00EB}","\N{U+00EB}"],
  ["e\N{U+0308}","e\N{U+0308}"],
  ["Citro\N{U+00EB}n","citro\N{U+00EB}"],
  ["Citroe\N{U+0308}n","citroe\N{U+0308}"],

]],
];



#################################

my @stem_cases = qw(transliterate unwordy prefix suffix suffix_t);

if (1) {
for my $sample (@stem_cases) {
  for my $test_group (@{$tests}) {
    my $test_name = $test_group->[0];
    next if ($sample ne $test_name);
    my $group_tests = $test_group->[1];
      for my $test (@{$group_tests}) {
        my ($word,$expect,$casing,$ge_remove) =
          @{$test};
        my $casing_string = (defined $casing) ? "$casing" : '';
        my $ge_remove_string = (defined $ge_remove) ? "$ge_remove" : '';
        is(stem($word,$casing,$ge_remove),$expect
          ,
          $test_name
          . ' '
          . 'stem('
          . $word
          . ','
          . $casing_string
          . ','
          . $ge_remove_string
          . ') => '
          . $expect
        );
      }
  }
}
}

my @stem_robust_cases = qw(transliterate wordy prefix_keepers suffix suffix_t unicode);

if (1) {
for my $sample (@stem_robust_cases) {
  for my $test_group (@{$tests}) {
    my $test_name = $test_group->[0];
    next if ($sample ne $test_name);
    my $group_tests = $test_group->[1];
      for my $test (@{$group_tests}) {
        my ($word,$expect,$casing,$ge_remove) =
          @{$test};
        my $casing_string = (defined $casing) ? "$casing" : '';
        my $ge_remove_string = (defined $ge_remove) ? "$ge_remove" : '';
        is(stem_robust($word,$casing,$ge_remove),$expect
          ,
          $test_name
          . ' '
          . 'stem_robust('
          . $word
          . ','
          . $casing_string
          . ','
          . $ge_remove_string
          . ') => '
          . $expect
        );
      }
  }
}
}

my @segment_cases = qw(transliterate_segment unwordy suffix suffix_t);
if (1) {
for my $sample (@segment_cases) {
  for my $test_group (@{$tests}) {
    my $test_name = $test_group->[0];
    next if ($sample ne $test_name);
    my $group_tests = $test_group->[1];
      for my $test (@{$group_tests}) {
        my ($word,$expect,$casing,$ge_remove) =
          @{$test};
        my $casing_string = (defined $casing) ? "$casing" : '';
        my $ge_remove_string = (defined $ge_remove) ? "$ge_remove" : '';
        is([segment($word,$casing,$ge_remove)]->[0],$expect
          ,
          $test_name
          . ' '
          . 'segment('
          . $word
          . ','
          . $casing_string
          . ','
          . $ge_remove_string
          . ') => '
          . $expect
        );
      }
  }
}
}

my @segment_robust_cases = qw(transliterate wordy prefix_keepers suffix suffix_t unicode);
if (1) {
for my $sample (@segment_robust_cases) {
  for my $test_group (@{$tests}) {
    my $test_name = $test_group->[0];
    next if ($sample ne $test_name);
    my $group_tests = $test_group->[1];
      for my $test (@{$group_tests}) {
        my ($word,$expect,$casing,$ge_remove) =
          @{$test};
        my $casing_string    = (defined $casing) ? "$casing" : '';
        my $ge_remove_string = (defined $ge_remove) ? "$ge_remove" : '';
        is([segment_robust($word,$casing,$ge_remove)]->[1],$expect
          ,
          $test_name
          . ' '
          . 'segment_robust('
          . $word
          . ','
          . $casing_string
          . ','
          . $ge_remove_string
          . ') => '
          . $expect
        );
      }
  }
}
}

if (0) {
  for my $example (@$examples0) {
    is(stem($example->[0]),$example->[1],"$example->[0] -> $example->[1]");
  }
}

=pod

for my $word (@words) {
  for my $case_sensitive (0..1) {
    print 'Cistem::stem(',$word,',',$case_sensitive,'): ',
    Cistem::stem($word,$case_sensitive),"\n";
  }

  for my $case_sensitive (0..1) {
    print 'Cistem::segment(',$word,',',$case_sensitive,'): ',
    join('-',Cistem::segment($word,$case_sensitive)),"\n";
  }
}

=cut

done_testing;
