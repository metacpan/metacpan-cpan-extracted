use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini );
use Dist::Zilla::Util::Test::KENTNL 1.003001 qw(dztest);
use Dist::Zilla::Plugin::Bootstrap::lib 0.04000000;
require Dist::Zilla::Plugin::Bootstrap::ShareDir::Module;
require File::ShareDir;
require Path::Tiny;

my $t   = dztest();
my $ini = simple_ini(
  { name => 'E' },
  [
    'Bootstrap::lib',
    {
      ':version' => '0.04000000',
      try_built  => 1,
      fallback   => 0,
    }
  ],    #
  [ 'Bootstrap::ShareDir::Module', { 'E' => 'share/E', try_built => 1, fallback => 0 } ],    #
  ['=E'],
);
my $epm = <<'EOF';
use strict;
use warnings;
package E;

use File::ShareDir qw( module_file );
use Path::Tiny qw( path );

sub register_component {}

our $content = path( module_file( 'E', 'example.txt' ) )->slurp;

1;
EOF
$t->add_file( 'dist.ini' => $ini );

$t->add_file( 'share/E/example.txt', q[ ] );
$t->add_file( 'lib/E.pm',            $epm );

isnt( $t->safe_build, undef, 'Build should fail' );

done_testing;
