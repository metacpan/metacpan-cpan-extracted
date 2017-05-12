use strict;
use warnings;

use Test::More;

# ABSTRACT: Test basic functionality

use Test::DZil qw( simple_ini Builder );
use Path::Tiny qw( path );

my $tzil_1;

SKIP: {
  note "Generating Initial Yaml File";

  my $tzil = $tzil_1 = Builder->from_config(
    { dist_root => 'invalid' },
    {
      add_files =>
        { path( 'source', 'dist.ini' ) => simple_ini( [ 'GatherDir' => { include_dotfiles => 1 }, ], [ 'TravisCI' => {}, ], ) }
    }
  );

  my ( $ok, $error );
  local $@;
  eval { $tzil->build; $ok = 1 };
  $error = $@;

  ok( $ok, "Build OK" ) or do {
    diag explain $error;
    skip "Build did not pass", 3;
  };

  my $gen_yaml = path( $tzil->tempdir, 'source', '.travis.yml' );

  ok( $gen_yaml->exists, '.travis.yml added' );
  ok( !path( $tzil->tempdir, 'build', '.travis.yml' )->exists, '.travis.yml not added to build dir' );
  cmp_ok( [ $gen_yaml->lines_utf8( { chomp => 1 } ) ]->[0], qw[eq], '---', 'Looks like a valid YAML file' );
}

SKIP: {

  note "Simulated rebuild on a dir with exisiting .yml file";
  my $tzil = Builder->from_config( { dist_root => path( $tzil_1->tempdir, 'source' ) } );
  my ( $ok, $error );
  local $@;
  eval { $tzil->build; $ok = 1 };
  $error = $@;

  ok( $ok, "Build OK" ) or do {
    diag explain $error;
    skip "Build did not pass", 3;
  };

  my $gen_yaml = path( $tzil->tempdir, 'source', '.travis.yml' );
  ok( $gen_yaml->exists, '.travis.yml in second generation' );
  ok( path( $tzil->tempdir, 'build', '.travis.yml' )->exists,
    '.travis.yml in second generation build dir ' . '( due to gatherdir + dotfiles )' );

  cmp_ok( [ $gen_yaml->lines_utf8( { chomp => 1 } ) ]->[0], qw[eq], '---', 'Looks like a valid YAML file' );
}
done_testing;

