#!/usr/bin/perl
##############################################################################
#
#  Exception::Sink usage tests
#
##############################################################################
use strict;
use warnings;
use Test::More;
use FindBin;
use Scalar::Util qw( refaddr );
use lib "$FindBin::Bin/../lib";

my @WARN;
$SIG{__WARN__} = sub { push @WARN, $_[0] };

use Exception::Sink qw( :DEFAULT get_stack_trace $DEBUG_SINK );

sub no_warnings
{
  my $name = shift;
  is( scalar @WARN, 0, "no warnings: $name" ) or diag( @WARN );
  @WARN = ();
}

##############################################################################
# helper classes

package My::Sink::Sub;
our @ISA = ( 'Exception::Sink::Class' );

package Other::Err;
sub new { my $c = shift; bless { @_ }, $c }
sub code { $_[0]{ 'code' } }

package Other::Str;
use overload '""' => sub { 'IO: disk full' };

package main;

##############################################################################
# exports

can_ok( 'main', qw( sink dive surface surface2 boom boom_skip get_stack_trace ) );
ok( defined $DEBUG_SINK, '$DEBUG_SINK exported on request' );
is( $DEBUG_SINK, 0, '$DEBUG_SINK is off by default' );

{
  package Import::None;
  use Exception::Sink qw( :none );
  ::ok( ! __PACKAGE__->can( 'sink' ), ':none imports nothing' );
}

{
  package Import::Surface;
  use Exception::Sink qw( :none surface );
  ::ok(   __PACKAGE__->can( 'surface' ), ':none surface imports surface' );
  ::ok( ! __PACKAGE__->can( 'sink'    ), ':none surface does not import sink' );
}

no_warnings( 'exports' );

##############################################################################
# sink(): exception object

eval { sink "FOO: BAR: message text" };
isa_ok( $@, 'Exception::Sink::Class', 'sink() throws' );
is( ref $@, 'Exception::Sink::Class', 'exact class' );
ok( $@, 'exception object is true' );
like( "$@", qr/^FOO: BAR: message text at t1-exception-sink\.pl line \d+\.\n$/, 'stringifies like die(): text plus origin' );
is( "$@", "FOO: BAR: message text at $@->{ 'FILE' } line $@->{ 'LINE' }.\n", 'stringification uses FILE and LINE' );
is( $@->{ 'CLASS' },   'FOO',                   'CLASS' );
is( $@->{ 'ID'    },   'BAR',                   'ID' );
is( $@->{ 'MSG'   },   'message text',          'MSG' );
is( $@->{ 'ORG'   },   'FOO: BAR: message text','ORG' );
is( $@->{ 'PACKAGE' }, 'main',                  'PACKAGE' );
is( $@->{ 'FILE' },    't1-exception-sink.pl',  'FILE has no directory' );
like( $@->{ 'LINE' },  qr/^\d+$/,               'LINE is a number' );
ok( ! exists $@->{ 'OBJ' },                     'no OBJ for sink()' );
{
  # text ending with newline stringifies bare, like die()
  eval { sink "FOO: eq test\n" };
  my $e = $@;
  is( "$e", "FOO: eq test\n",         'text with newline stringifies bare' );
  ok( $e eq "FOO: eq test\n",         'eq compares stringification' );
  ok( ! ( $e ne "FOO: eq test\n" ),   'ne compares stringification' );
  is( $e cmp "FOO: eq test\n", 0,     'cmp compares stringification' );
  ok( $e eq $e,                       'eq with itself' );
  is( $e . '!', "FOO: eq test\n!",    'concatenation' );
  ok( $e =~ /^FOO: /,                 'regex match' );
  is( length( $e ), 13,               'length' );
  my %h = ( $e => 1 );
  ok( exists $h{ "FOO: eq test\n" },  'usable as hash key' );
  is( ( sort { $a cmp $b } ( $e, 'AAA', 'ZZZ' ) )[1], "FOO: eq test\n", 'sorts as string' );

  # text without newline gets the origin appended
  eval { sink "FOO: no newline" };
  $e = $@;
  like( "$e", qr/^FOO: no newline at t1-exception-sink\.pl line \d+\.\n$/, 'text without newline gets origin' );
  is( $e->{ 'ORG' }, 'FOO: no newline', 'ORG stays bare' );
  ok( $e ne 'FOO: no newline', 'eq against bare text is false, use ORG' );

  eval { sink "FOO: two\nlines\n" };
  is( "$@", "FOO: two\nlines\n", 'multi line text with final newline stringifies bare' );
}
no_warnings( 'sink object' );

##############################################################################
# sink(): message parsing

my @PARSE =
  (
  # input                          CLASS     ID        MSG
  [ 'FOO: BAR: msg',              'FOO',    'BAR',    'msg'            ],
  [ 'FOO: msg',                   'FOO',    'UNKNOWN','msg'            ],
  [ 'FOO: two words',             'FOO',    'UNKNOWN','two words'      ],
  [ 'FOO: BAR',                   'FOO',    'UNKNOWN','BAR'            ],
  [ 'FOO',                        'FOO',    'UNKNOWN',''               ],
  [ 'FOO:',                       'FOO',    'UNKNOWN',''               ],
  [ 'FOO: BAR:',                  'FOO',    'BAR',    ''               ],
  [ 'no class here',              'SINK',   'UNKNOWN','no class here'  ],
  [ '',                           'SINK',   'UNKNOWN',''               ],
  [ 'foo: bar: lower case',       'FOO',    'BAR',    'lower case'     ],
  [ 'Foo_1: Id_2: mixed',         'FOO_1',  'ID_2',   'mixed'          ],
  [ 'FOO:BAR:tight',              'FOO',    'BAR',    'tight'          ],
  [ 'FOO  :  BAR  :  spaced',     'FOO',    'BAR',    'spaced'         ],
  [ 'FOO: BAR: with: colons: in', 'FOO',    'BAR',    'with: colons: in' ],
  [ "FOO: trailing newline\n",    'FOO',    'UNKNOWN','trailing newline' ],
  [ "FOO: line1\nline2",          'FOO',    'UNKNOWN',"line1\nline2"   ],
  [ 'FOO-BAR: dash is not class', 'SINK',   'UNKNOWN','FOO-BAR: dash is not class' ],
  [ 'FOO: 0',                     'FOO',    'UNKNOWN','0'              ],
  [ '0',                          '0',      'UNKNOWN',''               ],
  );

for my $t ( @PARSE )
  {
  my ( $in, $class, $id, $msg ) = @$t;
  eval { sink $in };
  ( my $label = $in ) =~ s/\n/\\n/g;
  is( $@->{ 'CLASS' }, $class, "parse [$label] CLASS" );
  is( $@->{ 'ID'    }, $id,    "parse [$label] ID"    );
  is( $@->{ 'MSG'   }, $msg,   "parse [$label] MSG"   );
  is( $@->{ 'ORG'   }, $in,    "parse [$label] ORG"   );
  }
eval { sink "Some::Pkg: colons" };
is( $@->{ 'CLASS' }, 'SINK', 'parse [Some::Pkg: colons] CLASS' );
is( $@->{ 'MSG'   }, 'Some::Pkg: colons', 'parse [Some::Pkg: colons] MSG' );
eval { sink "FOO: Some::Pkg: colons" };
is( $@->{ 'ID'  }, 'UNKNOWN', 'parse [FOO: Some::Pkg: colons] ID' );
is( $@->{ 'MSG' }, 'Some::Pkg: colons', 'parse [FOO: Some::Pkg: colons] MSG' );
eval { die "Some::Pkg: from die\n" };
surface( 'X' );
is( $@->{ 'CLASS' }, 'SINK', 'surface: Package::Name prefix in die string is not a class' );
is( $@->{ 'MSG' }, 'Some::Pkg: from die', 'surface: Package::Name die string MSG intact' );
no_warnings( 'parsing' );

##############################################################################
# sink(): die() location suffix stripping

my @STRIP =
  (
  [ "FOO: bar at /tmp/x.pl line 3.\n",                'bar' ],
  [ "FOO: bar at x.pl line 3.\n",                     'bar' ],
  [ "FOO: bar at -e line 1.\n",                       'bar' ],
  [ "FOO: bar at x.pl line 3, <STDIN> line 7.\n",     'bar' ],
  [ "FOO: bar at x.pl line 3, <\$fh> chunk 2.\n",     'bar' ],
  [ "FOO: bar at x.pl line 3",                        'bar' ],
  [ "FOO: line1\nline2 at x.pl line 9.\n",            "line1\nline2" ],
  [ "FOO: failed at /etc/passwd",                     'failed at /etc/passwd' ],
  [ "FOO: look at line 5 of the file",                'look at line 5 of the file' ],
  [ "FOO: at x.pl line 3. is not at the end",         'at x.pl line 3. is not at the end' ],
  );

for my $t ( @STRIP )
  {
  my ( $in, $msg ) = @$t;
  eval { sink $in };
  ( my $label = $in ) =~ s/\n/\\n/g;
  is( $@->{ 'MSG' }, $msg, "strip [$label]" );
  is( $@->{ 'ORG' }, $in,  "strip keeps ORG [$label]" );
  }

eval { die "plain die" };
my $die_text = $@;
like( $die_text, qr/ at .+ line \d+\.$/, 'real die() has location suffix' );
eval { sink "FOO: $die_text" };
is( $@->{ 'MSG' }, 'plain die', 'real die() suffix stripped' );
no_warnings( 'strip' );

##############################################################################
# sink(): empty and false messages are not lost

eval { sink "" };
ok( $@, 'empty message exception is true' );
is( $@->{ 'ORG' }, '', 'empty message ORG is empty' );
like( "$@", qr/^ at t1-exception-sink\.pl line \d+\.\n$/, 'empty message stringifies to origin only' );
eval { sink "0" };
ok( $@, 'message "0" exception is true' );
is( $@->{ 'ORG' }, '0', 'message "0" ORG' );
eval { sink undef };
isa_ok( $@, 'Exception::Sink::Class', 'sink(undef) throws' );
is( $@->{ 'CLASS' }, 'SINK', 'sink(undef) class' );
is( $@->{ 'ID'    }, 'UNKNOWN', 'sink(undef) id' );
is( $@->{ 'MSG'   }, '', 'sink(undef) MSG' );
is( $@->{ 'ORG'   }, '', 'sink(undef) ORG' );
ok( $@, 'sink(undef) exception is true' );
no_warnings( 'empty' );

##############################################################################
# surface(): basics

$@ = '';
is( surface( 'FOO' ), 0, 'surface: nothing sinking returns 0' );
is( surface(),        0, 'surface: nothing sinking, no args, returns 0' );

eval { sink "FOO: msg" };
is( surface(),                1, 'surface: no args catches all' );
is( surface( '*' ),           1, 'surface: * catches all' );
is( surface( 'FOO' ),         1, 'surface: exact class' );
is( surface( 'foo' ),         1, 'surface: class arg is case insensitive' );
is( surface( 'BAR', 'FOO' ),  1, 'surface: one of list' );
is( surface( 'BAR', '*' ),    1, 'surface: * inside list' );
is( surface( 'BAR' ),         0, 'surface: no match returns 0' );
is( surface( 'BAR', 'BAZ' ),  0, 'surface: no match in list returns 0' );
is( surface( 'F' ),           0, 'surface: no prefix matching' );
is( surface( 'FOO: msg' ),    0, 'surface: arg is class, not message' );
isa_ok( $@, 'Exception::Sink::Class', '$@ after unmatched surface' );
is( $@->{ 'CLASS' }, 'FOO', '$@ untouched after unmatched surface' );

eval { sink "" };
is( surface( '*' ),    1, 'surface: empty message is still caught' );
is( surface( 'SINK' ), 1, 'surface: empty message has class SINK' );
no_warnings( 'surface basics' );

##############################################################################
# surface(): re-sink of plain die() strings

eval { die "FOO: from die\n" };
ok( ! ref $@, 'die() gives a plain string' );
is( surface( 'FOO' ), 1, 'surface: die "CLASS: ..." string matches class' );
isa_ok( $@, 'Exception::Sink::Class', '$@ after surface of string' );
is( $@->{ 'CLASS' }, 'FOO',      're-sunk CLASS' );
is( $@->{ 'MSG'   }, 'from die', 're-sunk MSG' );
is( $@->{ 'ORG'   }, "FOO: from die\n", 're-sunk ORG is die text' );
ok( ! exists $@->{ 'OBJ' }, 'no OBJ for string' );

is( $@->{ 'FILE' }, 't1-exception-sink.pl', 're-sunk FILE is the surface() call site file' );
is( $@->{ 'PACKAGE' }, 'main', 're-sunk PACKAGE is the surface() caller' );
is( $@->{ 'LINE' }, __LINE__ - 9, 're-sunk LINE is the surface() call line' );

eval { die "FOO: ID: from die\n" };
surface( 'X' );
is( $@->{ 'ID' }, 'ID', 're-sunk ID from die string' );

eval { die "no class from die\n" };
is( surface( 'FOO' ),  0, 'surface: classless die string is not FOO' );
is( $@->{ 'CLASS' }, 'SINK',              'classless die string has class SINK' );
is( $@->{ 'MSG'   }, 'no class from die', 'classless die string MSG' );
eval { die "no class from die\n" };
is( surface( 'SINK' ), 1, 'surface: classless die string matches SINK' );

eval { die "foo: lower\n" };
surface( 'X' );
is( $@->{ 'CLASS' }, 'FOO',   'lower case class prefix in die string is a class' );
is( $@->{ 'MSG'   }, 'lower', 'lower case prefix MSG' );
eval { die "Foo_1: Id_2: mixed\n" };
surface( 'X' );
is( $@->{ 'CLASS' }, 'FOO_1', 'mixed case class prefix in die string' );
is( $@->{ 'ID'    }, 'ID_2',  'mixed case id prefix in die string' );
eval { die "foo bar: x\n" };
surface( 'X' );
is( $@->{ 'CLASS' }, 'SINK', 'prefix with space is not a class' );

eval { die "with location" };
surface( 'X' );
is( $@->{ 'MSG' }, 'with location', 'location suffix stripped from die string' );

eval { die "\n" };
ok( ! ref $@, 'die "\n" is a string' );
is( surface( '*' ), 1, 'surface: whitespace-only die is caught' );

eval { die "FOO: x\n" };
is( surface( 'BAR' ), 0, 'surface: unmatched string' );
isa_ok( $@, 'Exception::Sink::Class', 'unmatched string still re-sunk' );
no_warnings( 'surface strings' );

##############################################################################
# surface(): re-sink of foreign references

my $obj = Other::Err->new( code => 5 );
eval { die $obj };
is( surface( 'FOO' ), 0, 'surface: foreign object is not FOO' );
isa_ok( $@, 'Exception::Sink::Class', 'foreign object re-sunk' );
is( $@->{ 'CLASS' }, 'SINK',    'foreign object class SINK' );
is( $@->{ 'ID'    }, 'UNKNOWN', 'foreign object ID UNKNOWN' );
like( $@->{ 'MSG' }, qr/^Other::Err=HASH\(0x[0-9a-f]+\)$/, 'foreign object MSG is its stringification' );
is( refaddr $@->{ 'OBJ' }, refaddr $obj, 'OBJ is the original object' );
is( $@->{ 'OBJ' }->code, 5, 'OBJ is usable' );
eval { die $obj };
is( surface( 'SINK' ), 1, 'surface: foreign object matches SINK' );
eval { die $obj };
is( surface( '*' ), 1, 'surface: foreign object matches *' );

for my $t ( [ 'blessed array',  bless( [ 1 ], 'Other::Arr' ) ],
            [ 'blessed scalar', bless( \( my $s = 'x' ), 'Other::Sca' ) ],
            [ 'blessed code',   bless( sub { 1 }, 'Other::Code' ) ],
            [ 'plain hash ref', { code => 1 } ],
            [ 'plain array ref', [ 1, 2 ] ],
            [ 'plain scalar ref', \ 'x' ],
          )
  {
  my ( $name, $ref ) = @$t;
  eval { die $ref };
  my $r = surface( 'FOO' );
  is( $r, 0, "surface: $name does not match FOO" );
  isa_ok( $@, 'Exception::Sink::Class', "$name re-sunk" );
  is( $@->{ 'CLASS' }, 'SINK', "$name class SINK" );
  is( refaddr $@->{ 'OBJ' }, refaddr $ref, "$name kept in OBJ" );
  }

my $ov = bless {}, 'Other::Str';
eval { die $ov };
is( surface( 'IO' ), 1, 'surface: overloaded object matches its class prefix' );
is( $@->{ 'CLASS' }, 'IO',        'overloaded object class from stringification' );
is( $@->{ 'MSG'   }, 'disk full', 'overloaded object MSG' );
is( refaddr $@->{ 'OBJ' }, refaddr $ov, 'overloaded object kept in OBJ' );
no_warnings( 'surface foreign' );

##############################################################################
# surface(): subclasses of Exception::Sink::Class pass through

my $sub = My::Sink::Sub->new( CLASS => 'FOO', ID => 'X', MSG => 'm', ORG => 'FOO: X: m' );
eval { die $sub };
is( surface( 'FOO' ), 1, 'surface: subclass matches its class' );
is( refaddr $@, refaddr $sub, 'subclass object not replaced' );
is( ref $@, 'My::Sink::Sub', 'subclass keeps its package' );
ok( ! exists $@->{ 'OBJ' }, 'subclass gets no OBJ' );
no_warnings( 'surface subclass' );

##############################################################################
# surface() side effect: $@ is replaced only when re-sunk

eval { sink "FOO: original" };
my $orig = $@;
surface( 'BAR' );
is( refaddr $@, refaddr $orig, 'sink object identity preserved through surface' );
no_warnings( 'surface identity' );

##############################################################################
# dive()

$@ = '';
is( dive(), 0, 'dive: nothing sinking returns 0' );

eval
  {
  eval { sink "FOO: msg" };
  dive();
  fail( 'dive must not return' );
  };
isa_ok( $@, 'Exception::Sink::Class', 'dive: object reaches outer eval' );
is( $@->{ 'CLASS' }, 'FOO', 'dive: class preserved' );

eval
  {
  eval { die "FOO: from die\n" };
  dive();
  };
isa_ok( $@, 'Exception::Sink::Class', 'dive: die string re-sunk' );
is( $@->{ 'FILE' }, 't1-exception-sink.pl', 'dive: FILE is the dive() call site file' );
is( $@->{ 'LINE' }, __LINE__ - 4, 'dive: LINE is the dive() call line' );
is( $@->{ 'CLASS' }, 'SINK', 'dive: die string always class SINK' );
is( $@->{ 'ID'    }, 'FOO',  'dive: die string prefix becomes ID' );
is( $@->{ 'MSG'   }, 'from die', 'dive: die string MSG' );
ok( ! exists $@->{ 'OBJ' }, 'dive: no OBJ for string' );

eval
  {
  eval { die "with location" };
  dive();
  };
is( $@->{ 'MSG' }, 'with location', 'dive: location suffix stripped' );

eval
  {
  eval { die $obj };
  dive();
  };
isa_ok( $@, 'Exception::Sink::Class', 'dive: foreign object re-sunk' );
is( $@->{ 'CLASS' }, 'SINK',    'dive: foreign object class' );
is( $@->{ 'ID'    }, 'UNKNOWN', 'dive: foreign object ID' );
is( refaddr $@->{ 'OBJ' }, refaddr $obj, 'dive: OBJ is original object' );

eval
  {
  eval { die $ov };
  dive();
  };
is( $@->{ 'CLASS' }, 'SINK',    'dive: overloaded object still class SINK' );
is( $@->{ 'ID'    }, 'UNKNOWN', 'dive: overloaded object gets explicit UNKNOWN id' );
is( $@->{ 'MSG'   }, 'IO: disk full', 'dive: overloaded object MSG is its stringification' );
is( refaddr $@->{ 'OBJ' }, refaddr $ov, 'dive: overloaded object kept in OBJ' );

eval
  {
  eval { die [ 1 ] };
  dive();
  };
is( ref $@->{ 'OBJ' }, 'ARRAY', 'dive: plain array ref kept in OBJ' );

eval
  {
  eval { die $sub };
  dive();
  };
is( refaddr $@, refaddr $sub, 'dive: subclass passes through untouched' );

eval
  {
  eval { sink "" };
  dive();
  };
isa_ok( $@, 'Exception::Sink::Class', 'dive: empty message propagates' );

eval
  {
  eval { sink "0" };
  dive();
  };
isa_ok( $@, 'Exception::Sink::Class', 'dive: "0" message propagates' );
no_warnings( 'dive' );

##############################################################################
# surface2()

eval { sink "FOO: msg" };
is( surface2( 'FOO' ), 1, 'surface2: match returns 1' );
eval { sink "FOO: msg" };
is( surface2( 'foo', 'BAR' ), 1, 'surface2: match in list' );

eval
  {
  eval { sink "FOO: msg" };
  if( surface2( 'BAR' ) ) { fail( 'surface2 must not match BAR' ) }
  fail( 'surface2 must dive on mismatch' );
  };
isa_ok( $@, 'Exception::Sink::Class', 'surface2: dives on mismatch' );
is( $@->{ 'CLASS' }, 'FOO', 'surface2: dived object intact' );

eval
  {
  eval { die "FOO: str\n" };
  surface2( 'BAR' );
  };
is( $@->{ 'CLASS' }, 'FOO', 'surface2: string re-sunk by surface keeps class on dive' );

$@ = '';
is( surface2( 'FOO' ), 0, 'surface2: nothing sinking returns 0' );
no_warnings( 'surface2' );

##############################################################################
# nested handlers, as in the SYNOPSIS

sub run_synopsis
{
  my $what = shift;
  my @log;
  eval
    {
    eval
      {
      sink $what;
      };
    if( surface 'USUAL' )
      {
      push @log, 'local';
      }
    else
      {
      dive();
      }
    };
  dive if surface qw( FATAL STRANGE );
  if( surface '*' )
    {
    push @log, 'global';
    }
  return join ',', @log;
}

is( run_synopsis( 'USUAL: x' ),   'local',  'synopsis: USUAL handled locally' );
is( run_synopsis( 'BIG: x' ),     'global', 'synopsis: BIG handled globally' );
is( run_synopsis( 'usual: x' ),   'local',  'synopsis: class case insensitive' );
eval { run_synopsis( 'FATAL: EXAMPLE: x' ) };
isa_ok( $@, 'Exception::Sink::Class', 'synopsis: FATAL escapes both handlers' );
is( $@->{ 'ID' }, 'EXAMPLE', 'synopsis: FATAL keeps ID' );
eval { run_synopsis( 'STRANGE: x' ) };
is( $@->{ 'CLASS' }, 'STRANGE', 'synopsis: STRANGE escapes both handlers' );
no_warnings( 'synopsis' );

##############################################################################
# exceptions inside handlers

eval { sink "FOO: first" };
if( surface 'FOO' )
  {
  eval { sink "BAR: second" };
  is( $@->{ 'CLASS' }, 'BAR', 'new sink inside handler replaces $@' );
  }
no_warnings( 'handler' );

##############################################################################
# get_stack_trace()

sub level2 { return get_stack_trace( @_ ) }
sub level1 { return level2( @_ ) }

my @st = level1();
ok( @st >= 2, 'get_stack_trace: list context returns lines' );
like( $st[0], qr/^\s+\[$$\] 1: main::level2\s+\S+ line \d+\n$/, 'frame 1 is innermost sub' );
like( $st[1], qr/^\s+\[$$\] 2: main::level1\s+\S+ line \d+\n$/, 'frame 2 is next caller' );
like( $st[0], qr/t1-exception-sink\.pl line/, 'frame names this file' );

sub nolines { my @l = map { ( my $x = $_ ) =~ s/ line \d+/ line N/g; $x } @_; wantarray ? @l : join '', @l }

my $sts = level1();
is( scalar nolines( $sts ), scalar nolines( join '', @st ), 'get_stack_trace: scalar context joins lines' );

my @st0 = level1( 0 );
is_deeply( [ nolines( @st0 ) ], [ nolines( @st ) ], 'get_stack_trace(0) same as no argument' );

my @st1 = level1( 1 );
is( scalar @st1, scalar( @st ) - 1, 'get_stack_trace(1) skips one frame' );
like( $st1[0], qr/ 1: main::level1 /, 'skipped trace renumbers from 1' );

my @st_all = level1( scalar @st );
is( scalar @st_all, 0, 'skipping all frames gives empty trace' );

my @top = get_stack_trace();
is( scalar @top, 0, 'get_stack_trace at top level, no sub frames' );

my @neg = level1( -1 );
is( scalar @neg, scalar @st, 'negative skip clamped to 0' );
like( $neg[0], qr/ 1: main::level2 /, 'negative skip does not expose get_stack_trace frame' );
my @undef = level1( undef );
is( scalar @undef, scalar @st, 'undef skip same as no argument' );

my $ml = 0;
for ( @st ) { /^\s+\[\d+\] \d+: (\S+\s+)/ and length( $1 ) > $ml and $ml = length $1 }
my @cols = map { /^\s+\[\d+\] \d+: \S+\s+(\S)/ ? $-[1] : -1 } @st;
is( scalar( grep { $_ != $cols[0] } @cols ), 0, 'file names aligned in one column' );
no_warnings( 'get_stack_trace' );

##############################################################################
# boom() and boom_skip()

sub go_boom { boom "kaboom" }
sub call_boom { go_boom() }

eval { call_boom() };
isa_ok( $@, 'Exception::Sink::Class', 'boom throws' );
is( $@->{ 'CLASS' }, 'BOOM',    'boom class' );
is( $@->{ 'ID'    }, 'UNKNOWN', 'boom ID' );
like( $@->{ 'MSG' }, qr/^\[$$\] kaboom\n/, 'boom MSG starts with pid and text' );
like( $@->{ 'MSG' }, qr/ main::go_boom /,  'boom MSG has stack trace' );
like( $@->{ 'MSG' }, qr/ main::call_boom /, 'boom MSG has caller frame' );
like( $@->{ 'ORG' }, qr/^BOOM: \[$$\] kaboom\n/, 'boom ORG' );
is( $@->{ 'PACKAGE' }, 'main', 'boom PACKAGE is the caller, not Exception::Sink' );
is( $@->{ 'FILE' }, 't1-exception-sink.pl', 'boom FILE is the caller file, not Sink.pm' );
like( $@->{ 'MSG' }, qr/ 1: Exception::Sink::boom\s+\S+ line $@->{ 'LINE' }\n/, 'boom LINE is the boom() call line' );
is( "$@", $@->{ 'ORG' }, 'boom stringifies bare, trace ends with newline' );
is( surface( 'BOOM' ), 1, 'boom surfaces as BOOM' );

eval { boom "FOO: not a class" };
is( $@->{ 'CLASS' }, 'BOOM', 'boom class cannot be overridden' );
is( $@->{ 'ID' }, 'UNKNOWN', 'boom text prefix is not an ID' );

eval { boom "trailing\n" };
like( $@->{ 'MSG' }, qr/^\[$$\] trailing\n\s+\[/, 'boom chomps text once' );

eval { boom "" };
ok( $@, 'boom with empty text is true' );
is( $@->{ 'CLASS' }, 'BOOM', 'boom empty class' );

sub go_bs { boom_skip "skipped", 1 }
sub call_bs { go_bs() }
eval { call_bs() };
is( $@->{ 'CLASS' }, 'BOOM', 'boom_skip class' );
my @lines = grep { /^\s+\[\d+\] \d+:/ } split /\n/, $@->{ 'MSG' };
is( scalar( grep { /Exception::Sink::/ } @lines ), 0, 'boom_skip(1) hides the internal frame' );
like( $lines[0], qr/ 1: main::go_bs /, 'boom_skip trace renumbered from 1' );
like( $lines[1], qr/ 2: main::call_bs /, 'boom_skip trace continues with caller' );

eval { call_boom() };
my @full = grep { /^\s+\[\d+\] \d+:/ } split /\n/, $@->{ 'MSG' };
is( scalar( grep { /boom_skip/ } @full ), 0,   'boom() trace hides the internal boom_skip frame' );
like( $full[0], qr/ 1: Exception::Sink::boom /, 'boom() trace starts with the boom frame at its call site' );
like( $full[1], qr/ 2: main::go_boom /,         'boom() trace then shows the user frame' );
like( $full[2], qr/ 3: main::call_boom /,       'boom() trace continues with the caller' );
eval { call_bs() };
my @less = grep { /^\s+\[\d+\] \d+:/ } split /\n/, $@->{ 'MSG' };
is( scalar @full - scalar @less, 1, 'boom_skip(1) direct call has one frame fewer than boom()' );

sub go_bs0 { boom_skip "zero", 0 }
eval { go_bs0() };
my @zero = grep { /^\s+\[\d+\] \d+:/ } split /\n/, $@->{ 'MSG' };
like( $zero[0], qr/ 1: Exception::Sink::boom_skip /, 'boom_skip(0) shows its own frame' );
like( $zero[1], qr/ 2: main::go_bs0 /,               'boom_skip(0) then the user frame' );
is( scalar @zero, scalar @less, 'boom_skip(0) from one sub deep equals boom_skip(1) from two subs deep' );

sub go_bs2 { boom_skip "skipped", 2 }
eval { go_bs2() };
my @two = grep { /^\s+\[\d+\] \d+:/ } split /\n/, $@->{ 'MSG' };
unlike( $two[0], qr/go_bs2/, 'boom_skip(2) also hides the calling sub frame' );
like(   $two[0], qr/ 1: \(eval\) /, 'boom_skip(2) from a sub called in eval starts at the eval frame' );

eval { boom_skip "zero", 0 };
like( $@->{ 'MSG' }, qr/^\[$$\] zero\n/, 'boom_skip(0) works like boom' );
no_warnings( 'boom' );

##############################################################################
# $DEBUG_SINK

{
  my $err = '';
  local *STDERR;
  open STDERR, '>', \$err or die $!;
  local $Exception::Sink::DEBUG_SINK = 1; # local on the imported alias would break it
  eval { sink "FOO: dbg" };
  surface( 'BAR' );
  eval { dive() };
  close STDERR;
  like( $err, qr/^sink: FOO \(t1-exception-sink\.pl:\d+\)$/m, 'DEBUG_SINK: sink line' );
  like( $err, qr/^surface: enter: /m, 'DEBUG_SINK: surface line' );
  like( $err, qr/^surface: FOO -> continuing\.\.\.$/m, 'DEBUG_SINK: surface miss line' );
}
eval { sink "FOO: quiet" };
no_warnings( 'DEBUG_SINK' );

##############################################################################
# uncaught exception output

my $out = `$^X -I"$FindBin::Bin/../lib" -e 'use Exception::Sink; sink "FOO: uncaught"' 2>&1`;
isnt( $? >> 8, 0, 'uncaught sink exits non-zero' );
is( $out, "FOO: uncaught at -e line 1.\n", 'uncaught sink prints text with origin and newline' );

$out = `$^X -I"$FindBin::Bin/../lib" -e 'use Exception::Sink; sink "FOO: uncaught\\n"' 2>&1`;
is( $out, "FOO: uncaught\n", 'uncaught sink with newline prints bare text' );

$out = `$^X -I"$FindBin::Bin/../lib" -e 'use Exception::Sink; eval { sink "FOO: caught" }; print "ok\\n" if surface "FOO"' 2>&1`;
is( $out, "ok\n", 'caught sink in a fresh process' );

done_testing();
