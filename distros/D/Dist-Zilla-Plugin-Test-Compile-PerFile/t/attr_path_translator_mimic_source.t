use strict;
use warnings;

use Test::More;
use Test::File::ShareDir::Dist { 'Dist-Zilla-Plugin-Test-Compile-PerFile' => 'share' };
use Path::Tiny qw( path );
use Test::DZil qw( simple_ini Builder );

# ABSTRACT: Basic test

my $ini = simple_ini(
  ['GatherDir'],
  [
    'Test::Compile::PerFile',
    {
      path_translator => 'mimic_source'
    }
  ],
);
my $sample = <<'EOF';
package Good;

# This is a good file

1
EOF

my $tzil = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => {
      path( 'source', 'dist.ini' ) => $ini,
      path( 'source', 'lib', 'Good.pm' ) => $sample,
    },
  }
);
$tzil->chrome->logger->set_debug(1);
$tzil->build;

ok( path( $tzil->tempdir, 'build', 't', '00-compile', 'lib', 'Good.pm.t' )->exists, "Generated file t/00-compile/lib/Good.pm.t" );

note explain $tzil->log_messages;
note explain $tzil->distmeta;
done_testing;
