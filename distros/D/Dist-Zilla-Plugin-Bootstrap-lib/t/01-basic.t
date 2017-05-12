use strict;
use warnings;

use Test::More tests => 1;
use Test::DZil qw( simple_ini Builder );
require Dist::Zilla::Plugin::Bootstrap::lib;

my $files = {};
$files->{'source/dist.ini'} = simple_ini(
  { name => 'E' },
  [ 'Bootstrap::lib', ],    #
  ['=E'],
);
$files->{'source/lib/E.pm'} = <<'EOF';
use strict;
use warnings;
package E;

sub register_component {}

1;
EOF

my $test =
  Builder->from_config( { dist_root => 'invalid' }, { add_files => $files } );
$test->chrome->logger->set_debug(1);
$test->build;

pass("build ok");

note explain $test->log_messages;
