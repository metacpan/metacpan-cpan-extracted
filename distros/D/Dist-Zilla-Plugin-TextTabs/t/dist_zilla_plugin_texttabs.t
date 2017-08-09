use 5.014;
use Test2::V0 -no_srand => 1;
use Dist::Zilla::Plugin::TextTabs;
use Test::DZil;

subtest 'expand' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT1' },
    {
      add_files => {
       'source/dist.ini' => simple_ini(
         {},
         # [GatherDir]
         'GatherDir',
         # [TextTabs]
         'TextTabs',
       ),
      },
    },
  );

  $tzil->build;

  my($file) = grep { $_->name =~ /DZT1\.pm/ } @{ $tzil->files };

  unlike $file->content, qr{\t}, "no tabs here!";
  note $file->content;
};

subtest 'installer' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT3' },
    {
      add_files => {
       'source/dist.ini' => simple_ini(
         {},
         # [GatherDir]
         'GatherDir',
         # [TextTabs]
         [ 'TextTabs', => { installer => 1 }, ],
       ),
      },
    },
  );

  $tzil->build;

  my($file) = grep { $_->name =~ /Makefile\.PL/ } @{ $tzil->files };

  unlike $file->content, qr{\t}, "no tabs here!";
  note $file->content;
};

subtest 'tabstop' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT1' },
    {
      add_files => {
       'source/dist.ini' => simple_ini(
         {},
         # [GatherDir]
         'GatherDir',
         # [TextTabs]
         [ 'TextTabs', => { tabstop => 4 }, ],
       ),
      },
    },
  );

  $tzil->build;

  my($file) = grep { $_->name =~ /DZT1\.pm/ } @{ $tzil->files };

  like $file->content, qr{^    print}m, "no tabs here!";
  note $file->content;

};

subtest 'unexpand' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT2' },
    {
      add_files => {
       'source/dist.ini' => simple_ini(
         {},
         # [GatherDir]
         'GatherDir',
         # [TextTabs]
         [ 'TextTabs', => { unexpand => 1 }, ],
       ),
      },
    },
  );

  $tzil->build;

  my($file) = grep { $_->name =~ /DZT2\.pm/ } @{ $tzil->files };

  like $file->content, qr{\t}, "tabs here!";
  note $file->content;

};

done_testing;
