use Test2::V1
  -target => { MODULE => 'Getopt::Guided' },
  -pragmas,
  qw( is imported_ok like ok plan subtest warning );
BEGIN { MODULE->import( 'getopts' ) }

plan 5;

imported_ok 'getopts';

subtest 'List option specified but not used' => sub {
  plan tests => 3;

  local @ARGV = qw( -a foo -b );
  ok getopts( 'a:I,b', my %got_opts ), 'Succeeded';
  is \%got_opts, { a => 'foo', b => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'List option repeated once' => sub {
  plan tests => 3;

  local @ARGV = qw( -I lib -a foo -c );
  ok getopts( 'a:I,c', my %got_opts ), 'Succeeded';
  is \%got_opts, { I => [ 'lib' ], a => 'foo', c => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'List option repeated 2 times' => sub {
  plan tests => 3;

  local @ARGV = qw( -b -I lib -a foo -I local/lib/perl5 );
  ok getopts( 'I,a:b', my %got_opts ), 'Succeeded';
  is \%got_opts, { I => [ 'lib', 'local/lib/perl5' ], a => 'foo', b => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'List option repeated 2 times; 2nd option-argument is undefined' => sub {
  plan tests => 4;

  local @ARGV = qw( -I lib -a foo -c -I );
  my %got_opts;
  like warning { ok !getopts( 'a:cI,', %got_opts ), 'Failed' }, qr/option requires an argument -- I/, 'Check warning';
  is \%got_opts, {}, '%got_opts is empty';
  is \@ARGV, [ qw( -I lib -a foo -c -I ) ], '@ARGV restored'
}
