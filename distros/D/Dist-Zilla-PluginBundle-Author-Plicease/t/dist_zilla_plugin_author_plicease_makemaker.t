use 5.014;
use Test2::V0 -no_srand => 1;
use Test::DZil;
use List::Util qw( first );

subtest 'basic' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          # [GatherDir]
          'GatherDir',
          [ 'Author::Plicease::MakeMaker' => {} ],
          [ 'MetaJSON' => {} ],
        )
      }
    }
  );

  $tzil->build;

  my $file = first { $_->name eq 'Makefile.PL' } @{ $tzil->files };

  ok $file, 'has Makefile.PL';

  my $content = $file->content;

  note $content;

  my $file2 = first { $_->name eq 'META.json' } @{ $tzil->files };

  ok $file2, 'has META.json';

  my $content2 = $file2->content;

  note $content2;

};

subtest 'with eumm.pl' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT2' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          # [GatherDir]
          'GatherDir',
          [ 'Author::Plicease::MakeMaker' => {} ],
          [ 'MetaJSON' => {} ],
        )
      }
    }
  );

  $tzil->build;

  my $file = first { $_->name eq 'Makefile.PL' } @{ $tzil->files };

  ok $file, 'has Makefile.PL';

  my $content = $file->content;

  note $content;

  my $file2 = first { $_->name eq 'META.json' } @{ $tzil->files };

  ok $file2, 'has META.json';

  my $content2 = $file2->content;

  note $content2;

};

done_testing;
