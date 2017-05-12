use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use TestBundleHelpers;
use Test::DZil;

my $root = dir(qw( t data recovering_the_satellites ));
eval "use lib '${\ $root->subdir(q[lib])->as_foreign(q[Unix])->absolute->stringify }'";

sub new_plugin {
  my ($config) = @_;

  my $tzil = Builder->from_config(
    {
      dist_root => $root,
    },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [BundleInspector => BundleInspector => $config],
        )
      }
    },
  );

  return $tzil->plugin_named('BundleInspector');
}

{
  my $plug = new_plugin({
    file_name_re => '(?:^(fakelib|lib)/)?((?:[^/]+/)+PluginBundle/.+?)\.pm$',
  });
  is ref($plug->file_name_re), 'Regexp', 're coerced';
}

done_testing;
