use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT is_deeply plan subtest use_ok ) ], tests => 3;
use Test::Fatal qw( lives_ok );

use File::Basename        qw( dirname );
use File::Spec::Functions qw( catdir );

my $module;

BEGIN {
  $module = 'Getopt::Guided';
  use_ok $module, qw( readopts ) or BAIL_OUT "Cannot load module '$module'!"
}

local $ENV{ XDG_CONFIG_HOME } = catdir( dirname( __FILE__ ), 'data', '.config' );
local @ARGV = ();

subtest 'rcfile is missing' => sub {
  plan tests => 2;

  local $0 = 'missing';
  lives_ok { readopts( @ARGV ) } 'No exception';
  is_deeply \@ARGV, [], 'No defaults added'
};

subtest 'rcfile exists' => sub {
  plan tests => 2;

  local $0 = 'fine';
  lives_ok { readopts( @ARGV ) } 'No exception';
  is_deeply \@ARGV, [ '-a', ' foo  bar	', '-b' ], 'Defaults added' ## no critic ( ProhibitHardTabs )
}
