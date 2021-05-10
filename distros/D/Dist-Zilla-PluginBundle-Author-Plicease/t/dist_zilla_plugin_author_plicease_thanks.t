use 5.020;
use Test2::V0 -no_srand => 1;
use Test::DZil;

subtest 'one' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          # [GatherDir]
          'GatherDir',
          # [Author::Plicease::Thanks]
          [ 'Author::Plicease::Thanks' => {
            original => 'Mr. Original',
            current  => 'Few Nangled',
            contributor => [ qw( one two three ) ],
          } ],
        )
      }
    }
  );

  $tzil->build;

  my($file) = grep { $_->name eq 'lib/DZT.pm' } @{ $tzil->files };

  like $file->content, qr{this is the description}, 'still has a description';
  like $file->content, qr{Graham THE Ollis}, 'still has copyright';

  like $file->content, qr{Mr\. Original}, 'has original';
  like $file->content, qr{Few Nangled}, 'has current';
  like $file->content, qr{one\s+two\s+three}, 'has contributors';
};

subtest 'two' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
       'source/dist.ini' => simple_ini(
          {},
          # [GatherDir]
          'GatherDir',
          # [Author::Plicease::Thanks]
          [ 'Author::Plicease::Thanks' => {
            current  => 'Few Nangled',
            contributor => [ qw( one two three ) ],
          } ],
        )
      }
    }
  );

  $tzil->build;

  my($file) = grep { $_->name eq 'lib/DZT.pm' } @{ $tzil->files };

  like $file->content, qr{this is the description}, 'still has a description';
  like $file->content, qr{Graham THE Ollis}, 'still has copyright';

  like $file->content, qr{Few Nangled}, 'has current';
  like $file->content, qr{one\s+two\s+three}, 'has contributors';
};

subtest 'three' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          # [GatherDir]
          'GatherDir',
          # [Author::Plicease::Thanks]
          [ 'Author::Plicease::Thanks' => {
            current  => 'Few Nangled',
          } ],
        )
      }
    }
  );

  $tzil->build;

  my($file) = grep { $_->name eq 'lib/DZT.pm' } @{ $tzil->files };

  like $file->content, qr{this is the description}, 'still has a description';
  like $file->content, qr{Graham THE Ollis}, 'still has copyright';

  like $file->content, qr{Few Nangled}, 'has current';

};

subtest 'four' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          # [GatherDir]
          'GatherDir',
          # [Author::Plicease::Thanks]
          [ 'Author::Plicease::Thanks' => {
            original => 'Mr. Original',
            current  => 'Few Nangled',
          } ],
        )
      }
    }
  );

  $tzil->build;

  my($file) = grep { $_->name eq 'lib/DZT.pm' } @{ $tzil->files };

  like $file->content, qr{this is the description}, 'still has a description';
  like $file->content, qr{Graham THE Ollis}, 'still has copyright';

  like $file->content, qr{Mr\. Original}, 'has original';
  like $file->content, qr{Few Nangled}, 'has current';

};

done_testing;

