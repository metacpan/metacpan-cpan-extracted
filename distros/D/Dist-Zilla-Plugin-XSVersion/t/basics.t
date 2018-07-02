use strict;
use warnings;
use Test2::V0;
use Test::DZil;

my $tzil = Builder->from_config(
  { dist_root => 'corpus/DZT' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        {
          version => '0.42_03',
        },
        'GatherDir',
        'PkgVersion',
        'XSVersion',
      ),
    },
  },
);

$tzil->build;

my $contents = $tzil->slurp_file('build/lib/DZT.pm');
like $contents, qr/\$DZT::XS_VERSION = \$DZT::VERSION = '0.42_03'/sm, '$XS_VERSION defined from correct $VERSION';
like $contents, qr/XSLoader::load\('DZT', \$DZT::XS_VERSION\)/sm, 'XSLoader::load() updated to use $XS_VERSION';

done_testing;
