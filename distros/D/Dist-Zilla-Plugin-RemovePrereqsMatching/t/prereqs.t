# This file is more or less completely stolen from t/plugins/prereqs.t in the
# Dist-Zilla distribution.

use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal qw(exception);

use lib 't/lib';

use JSON 2;
use Test::DZil;

my @prereq_def = (
    [ Prereqs =>
      => {
          A             => 1,
          'A::Foo'      => 4,
          'Aother::Bar' => 1,
          'Boo'         => 3 ,
      },
    ],
    [ Prereqs => RuntimeRequires => { A => 2, B => 3 } ],
    [ Prereqs => DevelopSuggests => { C => 4 }         ],
    [ Prereqs => TestConflicts   => { C => 5, D => 6 } ],
    [ Prereqs => Recommends      => { E => 7 }         ],
);

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ GatherDir => ],
          [ MetaJSON  => ],
          @prereq_def,
        ),
      },
    },
  );

  $tzil->build;

  my $json = $tzil->slurp_file('build/META.json');

  my $meta = JSON->new->decode($json);

  is_deeply(
    $meta->{prereqs},
    {
      develop => { suggests  => { C => 4 } },
      runtime => {
        requires   => { A => 2, 'A::Foo' => 4, 'Aother::Bar' => 1, 'Boo' => 3, B => 3 },
        recommends => { E => 7 },
      },
      test    => { conflicts => { C => 5, D => 6 } },
    },
    "prereqs merged",
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ GatherDir => ],
          [ MetaJSON  => ],
          @prereq_def,
          [ RemovePrereqsMatching => { remove_matching => [ '^A::.*$' ] } ],
        ),
      },
    },
  );

  $tzil->build;

  my $json = $tzil->slurp_file('build/META.json');

  my $meta = JSON->new->decode($json);

  is_deeply(
    $meta->{prereqs},
    {
      develop => { suggests  => { C => 4 } },
      runtime => {
        requires   => { A => 2, 'Aother::Bar' => 1, B => 3, Boo => 3 },
        recommends => { E => 7 },
      },
      test    => { conflicts => { C => 5, D => 6 } },
    },
    "prereqs merged and pruned",
  );
}

done_testing;
