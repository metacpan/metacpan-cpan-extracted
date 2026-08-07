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
    plan tests => 4;

    local $0    = 'fine';
    local @ARGV = ();
    ok lives { readopts( @ARGV ) }, 'No exception';
    is \@ARGV, [ '-a', ' foo  bar	', '-b' ], 'Defaults added'; ## no critic ( ProhibitHardTabs )

    # Alternative test that puts the focus on the return value of readopts()
    local @ARGV = ();
    # https://stackoverflow.com/questions/9307137/list-assignment-in-scalar-context
    ok not( () = readopts( @ARGV ) ), 'No exception'; ## no critic ( RequireTestLabels )
    is \@ARGV, [ '-a', ' foo  bar	', '-b' ], 'Defaults added' ## no critic ( ProhibitHardTabs )
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
