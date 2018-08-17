use Test2::V0 -no_srand => 1;
use Test::DZil;
use Dist::Zilla::Plugin::FFI::Build;
use JSON::PP qw( decode_json );
use List::Util qw( first );

subtest 'basic' => sub {

  my $tzil = Builder->from_config({ dist_root => 'corpus/Foo-FFI' }, {
    add_files => {
      'source/dist.ini' => simple_ini(
        { name => 'Foo-FFI' },
        [ GatherDir    => {} ],
        [ MakeMaker    => {} ],
        [ MetaJSON     => {} ],
        [ 'FFI::Build' => {} ],
      ),
    },
  });

  $tzil->build;

  foreach my $file (@{ $tzil->files })
  {
    note "@{[ $file->name ]}";
    note $file->content;
  }
  
  my $meta = decode_json((first { $_->name eq 'META.json' } @{ $tzil->files })->content);
  
  is(
    $meta->{dynamic_config},
    T(),
    'dynamic config is set in META.json',
  );

};

done_testing
