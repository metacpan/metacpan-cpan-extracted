use strict;
use warnings;

use Test::More;
use Test::File::ShareDir::Dist { 'Dist-Zilla-Plugin-Test-Compile-PerFile' => 'share' };
use Path::Tiny qw( path );
use Test::DZil qw( simple_ini Builder );
use Capture::Tiny qw( capture_merged );

# ABSTRACT: Basic test

my $ini = simple_ini( ['GatherDir'], ['Test::Compile::PerFile'], ['MakeMaker'], );
my $bad_sample = <<'EOF';
package Bad;

use strict;

*{"Some::Namespace"} = sub { };

1
EOF

my $tzil = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => {
      path( 'source', 'dist.ini' ) => $ini,
      path( 'source', 'lib', 'Bad.pm' ) => $bad_sample,
    },
  }
);
$tzil->chrome->logger->set_debug(1);

my $error;
my $merged = capture_merged {
  $error = eval { $tzil->test; };
};

like( $merged, qr/Result: FAIL/, 'Running tests gives fail' );
note explain $merged;
note explain $tzil->log_messages;
note explain $tzil->distmeta;

done_testing;
