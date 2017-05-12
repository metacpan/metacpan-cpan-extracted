use strict;
use warnings;

use Test::More;

# ABSTRACT: A basic test
BEGIN {
  my $package = "Dist::Zilla::Plugin::MetaProvides::Package";
  eval "require $package; 1" or plan skip_all => "Requires $package";
}

use Dist::Zilla::Plugin::Prereqs;
use Dist::Zilla::Plugin::GatherDir;
use Dist::Zilla::Util::Test::KENTNL 1.005000 qw( dztest );
use Test::DZil qw( simple_ini );

my $t       = dztest();
my $package = 'BadName';

$t->add_file(
  'dist.ini' => simple_ini(
    ['GatherDir'],                #
    ['MetaProvides::Package'],    #
    [ 'Prereqs', { $package => 0 } ],    #
    ['RemovePrereqs::Provided'],         #
  )
);
$t->add_file( 'lib/BadName.pm' => <<"EOF" );
package ${package};

our \$VERSION = 0.001;
1;
EOF

$t->build_ok;

$t->prereqs_deeply( {} );                # No prereqs

note explain $t->builder->log_messages;
done_testing;
