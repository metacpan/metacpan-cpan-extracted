use 5.014;
use Test2::V0 -no_srand => 1;
use lib '.';
use Test::DZil;

subtest basics => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    { 
      add_files => { 
        'source/dist.ini' => simple_ini(
          {},
          [ 'GatherDir', { exclude_filename => [ 'example/foo.pl' ] } ],
          [ 'InsertExample' => {} ],
        )
      }
    }
  );

  $tzil->build;

  my($pm) = grep { $_->name eq 'lib/DZT.pm' } @{ $tzil->files };
  ok $pm->content =~ m{^ say 'hello world';$}m, "module contains example file";
};

subtest 'from generated' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT2' },
    { 
      add_files => { 
        'source/dist.ini' => simple_ini(
          {},
          'GatherDir',
          '=corpus::Foo',
          [ 'InsertExample' => {} ],
        )
      }
    }
  );

  $tzil->build;

  my($pm) = grep { $_->name eq 'lib/DZT.pm' } @{ $tzil->files };
  
  ok $pm->content =~ m{^ here is a generated file$}m, "module contains example file";
};

subtest 'from generated' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT2' },
    { 
      add_files => { 
        'source/dist.ini' => simple_ini(
          {},
          'GatherDir',
          '=corpus::Foo',
          [ 'InsertExample' => { indent => 4 } ],
        )
      }
    }
  );

  $tzil->build;

  my($pm) = grep { $_->name eq 'lib/DZT.pm' } @{ $tzil->files };
  
  ok $pm->content =~ m{^    here is a generated file$}m, "module contains example file";
};

done_testing;
