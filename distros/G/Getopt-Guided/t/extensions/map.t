use Test2::V1
  -target => { MODULE => 'Getopt::Guided' },
  -pragmas,
  qw( is imported_ok like ok plan subtest warning );
BEGIN { MODULE->import( 'getopts' ) }

plan 8;

imported_ok 'getopts';

for (
  [ '=',        { '' => '' },      'neither key nor value' ],
  [ 'os=',      { os => '' },      'key only' ],
  [ '=linux',   { '' => 'linux' }, 'value only' ],
  [ 'os=linux', { os => 'linux' }, 'key and value' ]
  )
{
  subtest sprintf( 'Map option repeated once (%s)', $_->[ -1 ] ) => sub {
    plan tests => 3;
    my ( $value, $map ) = @_;

    local @ARGV = ( '-d', $value, qw(-a foo -c ) );
    ok getopts( 'a:d=c', my %got_opts ), 'Succeeded';
    is \%got_opts, { d => $map, a => 'foo', c => 1 }, 'Options properly set';
    is @ARGV, 0, '@ARGV is empty'
    },
    @$_
}

subtest 'Map option repeated 2 times' => sub {
  plan tests => 3;

  # -dos=linux is same as -d os=linux
  local @ARGV = qw( -b -dos=linux -a foo -d vendor=redhat );
  ok getopts( 'd=a:b', my %got_opts ), 'Succeeded';
  is \%got_opts, { d => { os => 'linux', vendor => 'redhat' }, a => 'foo', b => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Map option repeated 3 times; overwrite' => sub {
  plan tests => 3;

  # -dvendor=redhat is same as -d vendor=redhat
  local @ARGV = qw( -b -dos=linux -a foo -dvendor=redhat -d os=windows );
  ok getopts( 'd=a:b', my %got_opts ), 'Succeeded';
  is \%got_opts, { d => { os => 'windows', vendor => 'redhat' }, a => 'foo', b => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Map option repeated 2 times; 2nd option-argument is invalid' => sub {
  plan tests => 4;

  local @ARGV = qw( -d os=linux -a foo -c -d vendor );
  my %got_opts;
  like warning { ok !getopts( 'a:cd=', %got_opts ), 'Failed' }, qr/option requires a key=value argument -- d/,
    'Check warning';
  is \%got_opts, {}, '%got_opts is empty';
  is \@ARGV, [ qw( -d os=linux -a foo -c -d vendor ) ], '@ARGV restored'
}
