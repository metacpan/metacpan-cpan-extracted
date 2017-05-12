use strict;
use warnings;
use 5.008001;
use Test::More tests => 4;
use Test::DZil;

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
