use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT is is_deeply like ok plan subtest use_ok ) ], tests => 7;
use Test::Warn qw( warning_like );

my $module;

BEGIN {
  $module = 'Getopt::Guided';
  use_ok $module, qw( getopts ) or BAIL_OUT "Cannot loade module '$module'!"
}

subtest 'Logically negate flag value; exclamation mark ("!") flag indicator' => sub {
  plan tests => 3;

  local @ARGV = qw( -b -a foo -v -b -vv -c );
  ok getopts( 'a:b!cv', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => '', c => 1, v => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Increment flag value; plus ("+") flag indicator' => sub {
  plan tests => 3;

  local @ARGV = qw( -b -a foo -v -b -vv -c );
  ok getopts( 'a:bcv+', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1, c => 1, v => 3 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'List of option-arguments; comma (",") option-argument indicator' => sub {
  plan tests => 4;

  subtest 'List option specified but not used' => sub {
    plan tests => 3;

    local @ARGV = qw( -a foo -b );
    ok getopts( 'a:I,b', my %got_opts ), 'Succeeded';
    is_deeply \%got_opts, { a => 'foo', b => 1 }, 'Options properly set';
    is @ARGV, 0, '@ARGV is empty'
  };

  subtest 'List option repeated once' => sub {
    plan tests => 3;

    local @ARGV = qw( -I lib -a foo -c );
    ok getopts( 'a:I,c', my %got_opts ), 'Succeeded';
    is_deeply \%got_opts, { I => [ 'lib' ], a => 'foo', c => 1 }, 'Options properly set';
    is @ARGV, 0, '@ARGV is empty'
  };

  subtest 'List option repeated 2 times' => sub {
    plan tests => 3;

    local @ARGV = qw( -b -I lib -a foo -I local/lib/perl5 );
    ok getopts( 'I,a:b', my %got_opts ), 'Succeeded';
    is_deeply \%got_opts, { I => [ 'lib', 'local/lib/perl5' ], a => 'foo', b => 1 }, 'Options properly set';
    is @ARGV, 0, '@ARGV is empty'
  };

  subtest 'List option repeated 3 times; 3rd option-argument is undefined' => sub {
    plan tests => 4;

    local @ARGV = ( '-I', 'lib', '-a', 'foo', '-c', '-I' );
    my %got_opts;
    warning_like { ok !getopts( 'a:cI,', %got_opts ), 'Failed' } qr/option requires an argument -- I/, 'Check warning';
    is_deeply \%got_opts, {}, '%got_opts is empty';
    is_deeply \@ARGV, [ ( '-I', 'lib', '-a', 'foo', '-c', '-I' ) ], '@ARGV restored'
  }
};

subtest 'POD synopsis (getopts processing)' => sub {
  plan tests => 3;

  local @ARGV = qw( -d dv1 -c -va av1 -ddv2 -a av2 -d -- -vv v1 v2 );
  ok getopts( 'a:bcd,v+', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'av2', c => 1, d => [ 'dv1', 'dv2', '--' ], v => 3 }, 'Options properly set';
  is_deeply \@ARGV, [ qw( v1 v2 ) ], 'Options removed from @ARGV'
};

subtest 'POD synopsis (getopts three-parameter form processing with parenthesis)' => sub {
  plan tests => 3;

  # On purpose don't work with a localized @ARGV
  my @argv = qw( -d dv1 -c -va av1 -ddv2 -a av2 -d -- -vv v1 v2 );
  ok getopts( 'a:bcd,v+', my %got_opts, @argv ), 'Succeeded';
  is_deeply \%got_opts, { a => 'av2', c => 1, d => [ 'dv1', 'dv2', '--' ], v => 3 }, 'Options properly set';
  is_deeply \@argv, [ qw( v1 v2 ) ], 'Options removed from @argv'
};

subtest 'POD synopsis (getopts three-parameter form processing without parenthesis)' => sub {
  plan tests => 3;

  # On purpose don't work with a localized @ARGV
  my @argv = qw( -d dv1 -c -va av1 -ddv2 -a av2 -d -- -vv v1 v2 );
  no warnings 'parenthesis'; ## no critic ( ProhibitNoWarnings )
  my $return_value = getopts 'a:bcd,v+', my %got_opts, @argv;
  ok $return_value, 'Succeeded';
  is_deeply \%got_opts, { a => 'av2', c => 1, d => [ 'dv1', 'dv2', '--' ], v => 3 }, 'Options properly set';
  is_deeply \@argv, [ qw( v1 v2 ) ], 'Options removed from @argv'
}
