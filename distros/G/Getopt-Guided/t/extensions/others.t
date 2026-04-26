use Test2::V1
  -target => { MODULE => 'Getopt::Guided' },
  -pragmas,
  qw( is imported_ok ok plan subtest );
BEGIN { MODULE->import( 'getopts' ) }

plan 3;

imported_ok 'getopts';

subtest 'Logically negate flag value; exclamation mark ("!") flag indicator' => sub {
  plan tests => 3;

  local @ARGV = qw( -b -a foo -v -b -vv -c );
  ok getopts( 'a:b!cv', my %got_opts ), 'Succeeded';
  is \%got_opts, { a => 'foo', b => '', c => 1, v => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Increment flag value; plus ("+") flag indicator' => sub {
  plan tests => 3;

  local @ARGV = qw( -b -a foo -v -b -vv -c );
  ok getopts( 'a:bcv+', my %got_opts ), 'Succeeded';
  is \%got_opts, { a => 'foo', b => 1, c => 1, v => 3 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
}
