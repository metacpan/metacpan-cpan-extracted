use Test2::V0 -no_srand => 1;
use 5.020;
use experimental qw( postderef );
use Test::DZil;
use List::Util qw( first );

subtest MM => sub {
  my $tzil = Builder->from_config({ dist_root => 'corpus/Foo-Bar' }, { add_files => {
    'source/dist.ini' => simple_ini({ name => 'Alt-Alien-Foo-stuff' },
      [ 'GatherDir' => {} ],
      [ 'MakeMaker' => {} ],
      [ 'Alt' => {}       ],
    ),
  }});

  $tzil->build;

  my $plugin = first { $_->isa('Dist::Zilla::Plugin::Alt') } $tzil->plugins->@*;
  ok $plugin, 'plugin found';
  is $plugin->metadata, { no_index => { file => [ 'lib/Foo/Bar.pm' ] } }, 'metadata';

  is $plugin->provide_name, 'Alt-Foo-Bar-stuff', 'provide_name';

  my $file = first { $_->name eq 'Makefile.PL' } $tzil->files->@*;
  ok $file, 'Makefile.PL found';

  like $file->content, qr{^# begin inserted by Dist::Zilla::Plugin::Alt}m, 'code inserted';

};

subtest MB => sub {
  my $tzil = Builder->from_config({ dist_root => 'corpus/Foo-Bar' }, { add_files => {
    'source/dist.ini' => simple_ini({ name => 'Alt-Alien-Foo-stuff' },
      [ 'GatherDir' => {} ],
      [ 'ModuleBuild' => {} ],
      [ 'Alt' => {}       ],
    ),
  }});

  $tzil->build;

  my $plugin = first { $_->isa('Dist::Zilla::Plugin::Alt') } $tzil->plugins->@*;
  ok $plugin, 'plugin found';
  is $plugin->metadata, { no_index => { file => [ 'lib/Foo/Bar.pm' ] } }, 'metadata';

  is $plugin->provide_name, 'Alt-Foo-Bar-stuff', 'provide_name';

  my $file = first { $_->name eq 'Build.PL' } $tzil->files->@*;
  ok $file, 'Build.PL found';

  like $file->content, qr{^# begin inserted by Dist::Zilla::Plugin::Alt}m, 'code inserted';

};

done_testing;
