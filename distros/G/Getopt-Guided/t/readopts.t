use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT is_deeply like ok plan subtest use_ok ) ], tests => 4;
use Test::Fatal qw( exception lives_ok );

use File::Basename        qw( dirname );
use File::Spec::Functions qw( catdir );

my $module;

BEGIN {
  $module = 'Getopt::Guided';
  use_ok $module, qw( readopts ) or BAIL_OUT "Cannot load module '$module'!"
}

local $ENV{ XDG_CONFIG_HOME } = catdir( dirname( __FILE__ ), 'data', '.config' );

subtest 'rcfile is missing' => sub {
  plan tests => 2;

  local $0    = 'missing';
  local @ARGV = ();
  lives_ok { readopts( @ARGV ) } 'No exception';
  is_deeply \@ARGV, [], 'No defaults added';
};

subtest 'rcfile exists and is fine' => sub {
  plan tests => 4;

  local $0    = 'fine';
  local @ARGV = ();
  lives_ok { readopts( @ARGV ) } 'No exception';
  is_deeply \@ARGV, [ '-a', ' foo  bar	', '-b' ], 'Defaults added'; ## no critic ( ProhibitHardTabs )

  # Alternative test that puts the focus on the return value of readopts()
  local @ARGV = ();
  # https://stackoverflow.com/questions/9307137/list-assignment-in-scalar-context
  ok not( () = readopts( @ARGV ) ), 'No exception'; ## no critic ( RequireTestLabels )
  is_deeply \@ARGV, [ '-a', ' foo  bar	', '-b' ], 'Defaults added' ## no critic ( ProhibitHardTabs )
};

subtest 'rcfile exists and is broken' => sub {
  plan tests => 1;

  local $0    = 'broken';
  local @ARGV = ();
  like exception { readopts( @ARGV ) }, qr/\AFile '.*$0rc' contains the invalid line 'ba foo'/, 'Grouping is not allowed'
}
