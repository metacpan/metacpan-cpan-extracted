use strict;
use warnings;
use Test::More 0.88;
use Test::DZil;

plan tests => 1;

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
