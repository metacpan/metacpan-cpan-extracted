use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini Builder );
use Path::Tiny qw( path );
use JSON::MaybeXS;

# ABSTRACT: Basic test

my $ini = simple_ini(
  [
    'Prereqs',
    'Before' => {
      'Dist::Zilla' => 0,
      -phase        => 'runtime',
      -type         => 'requires',
    }
  ],
  [ 'MetaData::BuiltWith::All' => {} ],
  [
    'Prereqs',
    'After' => {
      Moose  => 0,
      -phase => 'runtime',
      -type  => 'requires',
    }
  ],
  [ 'MetaJSON' => {} ],
);
my $tzil = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => {
      path( 'source', 'dist.ini' ) => $ini
    }
  }
);
$tzil->chrome->logger->set_debug(1);
$tzil->build;

## Note: this is required because MD:BW wraps the META.json
## file fromCode object to inject during write.
## I'm not sure I like that. But either way, it hides from distmeta!
my $json = path( $tzil->tempdir, 'build', 'META.json' );
ok( $json->exists, 'META.json exists' );

my $content = JSON::MaybeXS->new->decode( $json->slurp_raw );

ok( exists $content->{x_BuiltWith}, 'x_BuiltWith is there' );

my $xb = $content->{x_BuiltWith};

subtest 'platform' => sub {
  ok( exists $xb->{platform}, 'platform key exists' );
  ok( length $xb->{platform}, 'platform has length' );
};
subtest 'modules' => sub {
  return unless ok( exists $xb->{modules}, 'modules key exists' );
  for my $module (qw( Moose Dist::Zilla )) {
    ok( exists $xb->{modules}->{$module}, $module . ' is there' );
    like( $xb->{modules}->{$module}, qr/\d/, $module . ' has a number' );
  }
};
subtest 'perl' => sub {
  return unless ok( exists $xb->{perl}, 'perl key exists' );
  for my $field (qw( original qv version )) {
    ok( exists $xb->{perl}->{$field}, $field . ' is there' );
  }
};

done_testing;

