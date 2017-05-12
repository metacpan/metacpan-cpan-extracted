use strict;
use warnings;

use Test::More tests => 1;
use Test::DZil qw( simple_ini Builder );
require Dist::Zilla::Plugin::Bootstrap::lib;

my $files = {};
$files->{'source/dist.ini'} = simple_ini(
  { name => 'E' },
  [ 'Bootstrap::lib', { try_built => 1, fallback => 0, } ],    #
  ['=E'],
);
$files->{'source/lib/E.pm'} = <<'EOF';
use strict;
use warnings;
package E;

sub register_component {}

1;
EOF

my ( $test, $error, $ok );
{
  local $@;
  eval {
    $test = Builder->from_config( { dist_root => 'invalid' }, { add_files => $files } );
    $test->chrome->logger->set_debug(1);
    $test->build;
    $ok = 1;
  };
  $ok or $error = $@;
}

isnt( $ok, 1, 'Build should fail' );
note explain $error;
