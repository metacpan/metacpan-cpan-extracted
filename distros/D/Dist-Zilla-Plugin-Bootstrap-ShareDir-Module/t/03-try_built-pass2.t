use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini );
use Dist::Zilla::Util::Test::KENTNL 1.003001 qw(dztest);
require Dist::Zilla::Plugin::Bootstrap::lib;
require Dist::Zilla::Plugin::Bootstrap::ShareDir::Module;
require File::ShareDir;
require Path::Tiny;

my $t   = dztest();
my $ini = simple_ini(
  { name => 'E' },
  [ 'Bootstrap::lib', { try_built => 1 } ],                                   #
  [ 'Bootstrap::ShareDir::Module', { 'E' => 'share/E', try_built => 1 } ],    #
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
$t->add_file( 'dist.ini'        => $ini );
$t->add_file( 'E-0.01/dist.ini' => $ini );
$t->add_file( 'share/E/example.txt',        q[ ] );
$t->add_file( 'lib/E.pm',                   $epm );
$t->add_file( 'E-0.01/lib/E.pm',            $epm );
$t->add_file( 'E-0.01/share/E/example.txt', q[ ] );

$t->build_ok;

note explain $t->builder->log_messages;

done_testing;
