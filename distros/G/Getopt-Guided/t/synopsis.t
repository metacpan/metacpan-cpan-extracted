use Test2::V1
  -target => { MODULE => 'Getopt::Guided' },
  -pragmas,
  qw( is imported_ok ok plan subtest );
BEGIN { MODULE->import( 'getopts' ) }

plan 4;

imported_ok 'getopts';

subtest 'POD synopsis (getopts processing)' => sub {
  plan tests => 3;

  local @ARGV = qw( -e ek1=ev1 -d dv1 -c -va av1 -ddv2 -a av2 -d -- -eek2=ev2 -vv v1 v2 );
  ok getopts( 'a:e=bcd,v+', my %got_opts ), 'Succeeded';
  is \%got_opts, { a => 'av2', c => 1, d => [ qw( dv1 dv2 -- ) ], e => { ek1 => 'ev1', ek2 => 'ev2' }, v => 3 },
    'Options properly set';
  is \@ARGV, [ qw( v1 v2 ) ], 'Options removed from @ARGV'
};

subtest 'POD synopsis (getopts three-parameter form processing with parenthesis)' => sub {
  plan tests => 3;

  # On purpose don't work with a localized @ARGV
  my @argv = qw( -e ek1=ev1 -d dv1 -c -va av1 -ddv2 -a av2 -d -- -eek2=ev2 -vv v1 v2 );
  ok getopts( 'a:e=bcd,v+', my %got_opts, @argv ), 'Succeeded';
  is \%got_opts, { a => 'av2', c => 1, d => [ qw( dv1 dv2 -- ) ], e => { ek1 => 'ev1', ek2 => 'ev2' }, v => 3 },
    'Options properly set';
  is \@argv, [ qw( v1 v2 ) ], 'Options removed from @argv'
};

subtest 'POD synopsis (getopts three-parameter form processing without parenthesis)' => sub {
  plan tests => 3;

  # On purpose don't work with a localized @ARGV
  my @argv = qw( -e ek1=ev1 -d dv1 -c -va av1 -ddv2 -a av2 -d -- -eek2=ev2 -vv v1 v2 );
  no warnings 'parenthesis'; ## no critic ( ProhibitNoWarnings )
  my $return_value = getopts 'a:e=bcd,v+', my %got_opts, @argv;
  ok $return_value, 'Succeeded';
  is \%got_opts, { a => 'av2', c => 1, d => [ qw( dv1 dv2 -- ) ], e => { ek1 => 'ev1', ek2 => 'ev2' }, v => 3 },
    'Options properly set';
  is \@argv, [ qw( v1 v2 ) ], 'Options removed from @argv'
}
