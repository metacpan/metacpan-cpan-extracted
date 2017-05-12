use strict;
use warnings;

use Test::More;

# ABSTRACT: Test subclassing the plugin

use Test::DZil qw( simple_ini Builder );
use Path::Tiny qw( path );
use YAML qw();

{

  package T::Plugin;
  use Moose;
  extends 'Dist::Zilla::Plugin::TravisCI';

  sub modify_travis_yml {
    my ( $self, %config ) = @_;
    $config{this_key_is_bogus} = 'a value';
    return %config;
  }
}

my $tzil = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => {
      path( 'source', 'dist.ini' ) => simple_ini( [ 'GatherDir' => { include_dotfiles => 1 }, ], [ '=T::Plugin' => {}, ], ),
    }
  }
);

my ( $ok, $error );
local $@;
eval { $tzil->build; $ok = 1 };
$error = $@;
ok( $ok, "Build OK" ) or do {
  diag explain $error;
};

my $gen_yaml = path( $tzil->tempdir, 'source', '.travis.yml' );

ok( $gen_yaml->exists, '.travis.yml added' );

my $content = YAML::Load( $gen_yaml->slurp_utf8 );
ok( exists $content->{this_key_is_bogus}, 'Modified key emitted' );

cmp_ok( $content->{this_key_is_bogus}, 'eq', 'a value', 'Modified key has expected value' );

done_testing;
