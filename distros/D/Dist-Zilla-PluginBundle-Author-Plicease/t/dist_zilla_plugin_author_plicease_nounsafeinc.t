use 5.014;
use Test2::V0 -no_srand => 1;
use Test::DZil;

delete $ENV{PERL_USE_UNSAFE_INC};

subtest basic => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          # [GatherDir]
          'GatherDir',
          [ 'Author::Plicease::NoUnsafeInc' => {} ],
          #[ 'MetaJSON' => {} ],
        )
      }
    }
  );

  is $ENV{PERL_USE_UNSAFE_INC}, undef;

  $tzil->build;

  is $ENV{PERL_USE_UNSAFE_INC}, 0;

  is(
    $tzil->distmeta,
    hash {
      field x_use_unsafe_inc => 0;
      etc;
    },
  );

};

done_testing;
