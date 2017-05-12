use strict;
use warnings;

use Test::More;
use Test::File::ShareDir::Dist { 'Dist-Zilla-Plugin-Test-Compile-PerFile' => 'share' };
use Path::Tiny qw( path );
use Test::DZil qw( simple_ini Builder );

# ABSTRACT: Basic test

my $ini = simple_ini(
  ['GatherDir'],    #
  [ 'Test::Compile::PerFile', { skip => ['lib/Bad.pm'] } ],
  ['MetaConfig'],
  #
);
my $good_sample = <<'EOF';
package Good;

# This is a good file

1
EOF

my $bad_sample = <<'EOF';
package Bad

use strict;
# This is a bad file (no ; after package)

1
EOF

my $tzil = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => {
      path( 'source', 'dist.ini' ) => $ini,
      path( 'source', 'lib', 'Good.pm' ) => $good_sample,
      path( 'source', 'lib', 'Bad.pm' )  => $bad_sample,
    },
  }
);
$tzil->chrome->logger->set_debug(1);
$tzil->build;

ok( path( $tzil->tempdir, 'build', 't', '00-compile', 'lib_Good_pm.t' )->exists, "Generated file t/00-compile/lib_Good_pm.t" );
ok( !path( $tzil->tempdir, 'build', 't', '00-compile', 'lib_Bad_pm.t' )->exists,
  "Did not generated file t/00-compile/lib_Bad_pm.t" );

note explain $tzil->log_messages;
note explain $tzil->distmeta;
done_testing;
