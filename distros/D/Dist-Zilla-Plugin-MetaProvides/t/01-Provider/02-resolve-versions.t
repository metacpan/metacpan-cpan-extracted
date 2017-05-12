
use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Path::Tiny qw( path );
use Test::DZil qw( simple_ini Builder );

use lib 't/lib';

# Keepalive
my $builder;

sub make_plugin {
  my @args = @_;
  $builder = Builder->from_config(
    {
      dist_root => 'invalid',
    },
    {
      add_files => {
        path('source/dist.ini') => simple_ini( [ 'FakePlugin' => {@args} ] ),
      },
    }
  );
  return $builder->plugin_named('FakePlugin');
}

subtest 'default behaviour' => sub {
  my $plugin = make_plugin();
  is_deeply(
    [ $plugin->_resolve_version(4.0) ],
    [ 'version', '0.001' ],
    'By default, discovered versions ignored, dzils used instead'
  );
  is_deeply(
    [ $plugin->_resolve_version(undef) ],
    [ 'version', '0.001' ],
    'By default, undef versions dont matter, dzils used instead'
  );
};
subtest 'inherit_version => 0, inherit_missing => 0 behaviour' => sub {
  my $plugin = make_plugin( inherit_missing => 0, inherit_version => 0 );
  is_deeply(
    [ $plugin->_resolve_version('4.0') ],
    [ 'version', '4.0' ],
    'without version inheritance, defined versions pass-through'
  );
  is_deeply( [ $plugin->_resolve_version(undef) ], [], 'without version inheritance, undefined versions emit empty arrays' );
};
subtest 'inherit_version => 0, inherit_missing => 1 behaviour' => sub {
  my $plugin = make_plugin( inherit_missing => 1, inherit_version => 0 );
  is_deeply(
    [ $plugin->_resolve_version('4.0') ],
    [ 'version', '4.0' ],
    'with "only missing" version inheritance, defined versions pass-through'
  );
  is_deeply(
    [ $plugin->_resolve_version(undef) ],
    [ 'version', '0.001' ],
    'with "only missing" version inheritance, undefined versions default to package version'
  );
};
subtest 'inherit_version => 1, inherit_missing => 0 behaviour' => sub {
  my $plugin = make_plugin( inherit_version => 1, inherit_missing => 0 );
  is_deeply(
    [ $plugin->_resolve_version(4.0) ],
    [ 'version', '0.001' ],
    'with forced version inheritance, discovered versions ignored, dzils used instead'
  );
  is_deeply(
    [ $plugin->_resolve_version(undef) ],
    [ 'version', '0.001' ],
    'with forced version inheritance, undef versions dont matter, dzils used instead'
  );
};
subtest 'inherit_version => 1, inherit_missing => 1 behaviour' => sub {
  my $plugin = make_plugin( inherit_version => 1, inherit_missing => 0 );
  is_deeply(
    [ $plugin->_resolve_version(4.0) ],
    [ 'version', '0.001' ],
    'with forced version inheritance, inherit_missing has no impact'
  );
  is_deeply(
    [ $plugin->_resolve_version(undef) ],
    [ 'version', '0.001' ],
    'with forced version inheritance, inherit_missing has no impact'
  );
};

done_testing;
