use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini );
use Dist::Zilla::Util::Test::KENTNL 1.003002 qw( dztest );

# ABSTRACT: Basic functionality test

my $test = dztest();
$test->add_file(
  'dist.ini' => simple_ini(
    { version     => undef },    #
    [ 'GatherDir' => {} ],       #
    [
      'RewriteVersion::Sanitized' => {
        normal_form => 'numify',
        manitssa    => 6,
      }
    ],                           #
  )
);
$test->add_file( 'lib/Example.pm' => <<'EOF' );
package Foo;

our $VERSION = '0.1.0';

1;
EOF

$test->build_ok;

my $built = $test->built_file('lib/Example.pm');

ok( $built, 'Has built file' ) and do {
  my (@v) = grep { $_ =~ /VERSION/ } $built->lines_raw( { chomp => 1 } );
  ok( ( scalar @v ), "Has a version" );
  like( $v[0], qr/'0.001000'/, 'Got Expanded Version' );
};

note explain $test->builder->log_messages;

done_testing;

