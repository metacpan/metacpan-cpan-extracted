use Test2::V1
  -pragmas,
  -target => { MODULE => 'Getopt::Guided' },
  qw( dies is imported_ok like lives ok plan subtest );
BEGIN { MODULE->import( 'readopts' ) }

use File::Basename        qw( dirname );
use File::Spec::Functions qw( catdir );

plan 4;

imported_ok 'readopts';

{
  local $ENV{ XDG_CONFIG_HOME } = catdir( dirname( __FILE__ ), 'data', '.config' );

  subtest 'rcfile is missing' => sub {
    plan tests => 2;

    local $0    = 'missing';
    local @ARGV = ();
    ok lives { readopts( @ARGV ) }, 'No exception';
    is \@ARGV, [], 'No defaults added';
  };

  subtest 'rcfile exists and is fine' => sub {
    plan tests => 3;

    local $0 = 'fine';

    subtest 'Hard defaults "set before" readopts defaults read (wrong semantics)' => sub {
      plan 2;

      local @ARGV = qw( -a baz );
      ok lives { readopts( @ARGV ) }, 'No exception';
      is \@ARGV, [ '-a', ' foo  bar	', '-b', '-a', 'baz' ], ## no critic ( ProhibitHardTabs )
        '@ARGV ok'
    };

    subtest 'Hard defaults "prepended after" readopts defaults read (correct semantics)' => sub {
      plan 2;

      local @ARGV = ();
      # Alternative test that puts the focus on the return value of readopts()
      # https://stackoverflow.com/questions/9307137/list-assignment-in-scalar-context
      ok not( () = readopts( @ARGV ) ), 'No exception'; ## no critic ( RequireTestLabels )
      unshift @ARGV, qw( -a baz );
      is \@ARGV, [ '-a', 'baz', '-a', ' foo  bar	', '-b' ], ## no critic ( ProhibitHardTabs )
        '@ARGV ok'
    };

    subtest 'Pass hard defaults to readopts() call (correct semantics)' => sub {
      plan 2;

      # Filled command-line argument list
      local @ARGV = qw( -a quux );
      ok lives { readopts( @ARGV, qw( -a baz -c ) ) }, 'No exception';
      is \@ARGV, [ '-a', 'baz', '-c', '-a', ' foo  bar	', '-b', '-a', 'quux' ], ## no critic ( ProhibitHardTabs )
        '@ARGV ok'
    }
  }
}

subtest 'rcfile exists and is broken' => sub {
  plan tests => 1;

  local $ENV{ XDG_CONFIG_HOME } = undef;
  local $ENV{ HOME }            = catdir( dirname( __FILE__ ), 'data' );
  local $0                      = 'broken';
  local @ARGV                   = ();
  like dies { readopts( @ARGV ) }, qr/\AFile '.*$0rc' contains the invalid line 'ba foo'/, 'Grouping is not allowed'
}
