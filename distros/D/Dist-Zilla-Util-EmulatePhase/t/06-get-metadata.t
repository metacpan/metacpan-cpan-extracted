use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal 0.003;
use Path::Tiny qw( path );
use Test::DZil qw( simple_ini Builder );
use Dist::Zilla::Util::EmulatePhase qw( -all );

# ABSTRACT: test get_metadata

my $zilla = Builder->from_config(
  {
    dist_root => 'invalid'
  },
  {
    add_files => {
      path('source/dist.ini') =>
        simple_ini( 'Prereqs', 'MetaConfig', [ 'MetaResources' => { homepage => 'http://example.org' } ] ),
    }
  }
);
$zilla->chrome->logger->set_debug(1);
$zilla->build;

my @plugins;
my $metadata;

is(
  exception {
    @plugins = get_plugins(
      {
        zilla => $zilla,
        with  => [qw( -MetaProvider )],
      }
    );
  },
  undef,
  'get_plugins does not fail'
);
is(
  exception {
    $metadata = get_metadata( { zilla => $zilla } );
  },
  undef,
  'get_metadata does not fail'
);
is( ref $metadata,                          'HASH',               'metadata is a hash' );
is( ref $metadata->{resources},             'HASH',               'metadata.resources is a hash' );
is( ref $metadata->{resources}->{homepage}, '',                   'resources.homepage is scalar' );
is( $metadata->{resources}->{homepage},     'http://example.org', 'resources.homepage is input value' );

done_testing;
