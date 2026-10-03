#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IPC::Open3 qw( open3 );
use JSON::MaybeXS;
use Path::Tiny;
use XML::LibXML;
use XML::LibXML::XPathContext;

use Kubernetes::Comb::SVG;

# bin/comb-svg, SPEC 9: the script is run as a process on fixtures, its
# output parsed with a real XML parser.

my $root   = path(__FILE__)->parent->parent;
my $script = $root->child( 'bin', 'comb-svg' );
my $svg    = $root->child( 't', 'data', 'svg' );
my $cli    = $root->child( 't', 'data', 'cli' );
my $tmp    = Path::Tiny->tempdir;

# Runs the script; stdin comes from a file (an empty one by default), stdout
# and stderr go to files, so nothing can block. Returns exit code, stdout and
# stderr as bytes.
sub run {
  my ( $args, $stdin ) = @_;
  my $in_file = defined $stdin ? path($stdin) : $tmp->child('empty');
  $in_file->touch;
  my ( $out_file, $err_file ) = ( $tmp->child('out'), $tmp->child('err') );
  open( my $in,  '<', $in_file->stringify )  or die 'open '.$in_file.': '.$!;
  open( my $out, '>', $out_file->stringify ) or die 'open '.$out_file.': '.$!;
  open( my $err, '>', $err_file->stringify ) or die 'open '.$err_file.': '.$!;
  my $pid = open3( '<&'.fileno($in), '>&'.fileno($out), '>&'.fileno($err),
    $^X, '-I'.$root->child('lib'), $script->stringify, @$args );
  waitpid( $pid, 0 );
  my $exit = $? >> 8;
  close $_ for $in, $out, $err;
  return ( $exit, $out_file->slurp_raw, $err_file->slurp_raw );
}

sub parse {
  my ( $bytes ) = @_;
  my $xpc = XML::LibXML::XPathContext->new( XML::LibXML->load_xml( string => $bytes ) );
  $xpc->registerNs( s => 'http://www.w3.org/2000/svg' );
  return $xpc;
}

# Runs the script expecting a picture; returns it parsed.
sub picture {
  my ( $name, $args, $stdin ) = @_;
  my ( $exit, $out, $err ) = run( $args, $stdin );
  is( $exit, 0,  $name.': exit 0' );
  is( $err,  '', $name.': nothing on stderr' );
  my $xpc = eval { parse($out) };
  ok( $xpc, $name.': stdout is well-formed XML' ) or diag $@;
  return $xpc;
}

# Runs the script expecting a failure: exit 1, empty stdout, one line on
# stderr with the prefix and without a location.
sub failure {
  my ( $name, $args, $like, $stdin ) = @_;
  my ( $exit, $out, $err ) = run( $args, $stdin );
  is( $exit, 1,  $name.': exit 1' );
  is( $out,  '', $name.': nothing on stdout' );
  like( $err, qr/\Acomb-svg: [^\n]+\n\z/, $name.': one line on stderr, prefixed' );
  unlike( $err, qr/ line \d+|\.pm\b|Moo|isa check/, $name.': no location, no stack trace' );
  like( $err, $like, $name.': says what is wrong' );
  return $err;
}

sub has_class { 'contains(concat(" ",@class," ")," '.$_[0].' ")' }

my $COMB = '//s:g[ '.has_class('comb').' ]';

sub names { [ map { $_->getAttribute('data-name') } $_[0]->findnodes($COMB) ] }

sub library {
  my ( $file, %opt ) = @_;
  return Kubernetes::Comb::SVG->new(
    combs => JSON::MaybeXS->new( utf8 => 1 )->decode( path($file)->slurp_raw ), %opt
  )->render;
}

#### Input

{
  my ( $exit, $out, $err ) = run( [ $svg->child('chain.json')->stringify ] );
  is( $exit, 0,  'file argument: exit 0' );
  is( $err,  '', 'file argument: nothing on stderr' );
  is( $out, library( $svg->child('chain.json') ), 'file argument: the bytes the library renders' );
  is_deeply( [ sort @{ names( parse($out) ) } ], [qw( api db web )], 'array of CRs: three cells' );
}

for my $case ( [ 'stdin, no argument', [] ], [ 'stdin, -', ['-'] ] ) {
  my ( $name, $args ) = @$case;
  my ( $exit, $out ) = run( $args, $svg->child('chain.json') );
  is( $exit, 0, $name.': exit 0' );
  is( $out, library( $svg->child('chain.json') ), $name.': same bytes as the file argument' );
}

{
  my $xpc = picture( 'List', [ $svg->child('list.json')->stringify ] );
  is_deeply( names($xpc), [qw( one two )], 'List: its items are the cells' );
}

{
  my $xpc = picture( 'single CR', [ $cli->child('single.json')->stringify ] );
  is_deeply( names($xpc), ['one'], 'single CR: one cell' );
  is( $xpc->findvalue( $COMB.'/@data-phase' ), 'Running', 'single CR: its phase' );
}

{
  my ( $exit, $out ) = run( [ '--no-legend', $svg->child('chain.json')->stringify ] );
  my ( undef, $after ) = run( [ $svg->child('chain.json')->stringify, '--no-legend' ] );
  is( $exit, 0, 'options before the file: exit 0' );
  is( $out, $after, 'options before and after the file give the same picture' );
}

#### Options

{
  my $plain = picture( 'defaults', [ $svg->child('groups.json')->stringify ] );
  is( $plain->findvalue('/s:svg/s:title'), 'Combs', 'defaults: title Combs' );
  is( $plain->findnodes('//s:g[@data-group]')->size, 0, 'defaults: no groups' );
  ok( $plain->findnodes('//s:g[ '.has_class('legend').' ]')->size, 'defaults: a legend' );

  my $xpc = picture( '--title', [ $svg->child('groups.json')->stringify, '--title', 'Lab <1>' ] );
  is( $xpc->findvalue('/s:svg/s:title'), 'Lab <1>', '--title: the <title>' );
  is( $xpc->findvalue('//s:text[ '.has_class('heading').' ]'), 'Lab <1>', '--title: the heading' );

  $xpc = picture( '--group-label',
    [ $svg->child('groups.json')->stringify, '--group-label', 'tier' ] );
  is_deeply(
    [ map { $_->getAttribute('data-group') } $xpc->findnodes('//s:g[@data-group]') ],
    [qw( backend frontend )],
    '--group-label: the groups of that label'
  );

  $xpc = picture( '--group-label=', [ $svg->child('groups.json')->stringify, '--group-label=tier' ] );
  is( $xpc->findnodes('//s:g[@data-group]')->size, 2, '--group-label=KEY: same' );
}

{
  my $file = $svg->child('wrap.json')->stringify;
  for my $case ( [ [ '--columns', 2 ], columns => 2 ], [ [ '--size', 20 ], size => 20 ],
    [ [ '--size', '33.5' ], size => 33.5 ] ) {
    my ( $args, %opt ) = @$case;
    my ( $exit, $out, $err ) = run( [ $file, @$args ] );
    my $name = join( ' ', @$args );
    is( $exit, 0, $name.': exit 0' ) or diag $err;
    is( $out, library( $file, %opt ), $name.': the picture of that option' );
    isnt( $out, library($file), $name.': not the default picture' );
  }
  my $rows = sub {
    my ( $xpc ) = @_;
    my %y = map { ( $xpc->findvalue( 's:text[1]/@y', $_ ) => 1 ) } $xpc->findnodes($COMB);
    return scalar keys %y;
  };
  my $wide   = picture( 'columns default', [$file] );
  my $narrow = picture( '--columns 1', [ $file, '--columns', 1 ] );
  cmp_ok( $rows->($narrow), '>', $rows->($wide), '--columns 1: more rows than the default' );
  is( $rows->($narrow), scalar @{ names($narrow) }, '--columns 1: one cell per row' );
}

{
  my $file = $svg->child('chain.json')->stringify;
  my $DEP  = '//s:path[ '.has_class('dep').' ]';
  my $LEG  = '//s:g[ '.has_class('legend').' ]';

  my $xpc = picture( 'edges default', [$file] );
  is( $xpc->findnodes($DEP)->size, 2, 'default: the dependency edges' );
  is( $xpc->findnodes($LEG)->size, 1, 'default: the legend' );

  $xpc = picture( '--no-edges', [ $file, '--no-edges' ] );
  is( $xpc->findnodes($DEP)->size,  0, '--no-edges: no edge' );
  is( $xpc->findnodes($LEG)->size,  1, '--no-edges: legend stays' );
  is( $xpc->findnodes($COMB)->size, 3, '--no-edges: cells stay' );

  $xpc = picture( '--no-legend', [ $file, '--no-legend' ] );
  is( $xpc->findnodes($LEG)->size, 0, '--no-legend: no legend' );
  is( $xpc->findnodes($DEP)->size, 2, '--no-legend: edges stay' );

  $xpc = picture( 'both', [ $file, '--no-edges', '--no-legend' ] );
  is( $xpc->findnodes($DEP)->size + $xpc->findnodes($LEG)->size, 0, 'both: neither' );
}

{
  my ( $exit, $out, $err ) = run( ['--version'] );
  is( $exit, 0,  '--version: exit 0' );
  is( $err,  '', '--version: nothing on stderr' );
  like( $out, qr/\Acomb-svg \d+\.\d+\n\z/, '--version: name and version' );
  like( $script->slurp_raw, qr/^our \$VERSION = '[\d.]+';$/m, 'the script carries its own $VERSION' );

  ( $exit, $out, $err ) = run( ['--help'] );
  is( $exit, 0,  '--help: exit 0' );
  is( $err,  '', '--help: nothing on stderr' );
  like( $out, qr/\Q$_\E/, '--help: names '.$_ )
    for qw( --title --group-label --layout --columns --rows --aspect --size --no-edges --no-legend
      --color --blink --blink-seconds --help --version );
}

#### Colours and blink

{
  my $file = $svg->child('phases.json')->stringify;
  for my $case (
    [ [ "--color", "Error=#ff0033" ], theme => { Error => '#ff0033' } ],
    [ [ "--color", "Error=#ff0033,#ff6677" ], theme => { Error => { light => '#ff0033', dark => '#ff6677' } } ],
    [ [ '--color', 'Error=rgb(1,2,3)' ], theme => { Error => 'rgb(1,2,3)' } ],
    [ [ '--color', 'bg=rgb(1,2,3),hsl(0, 0%, 5%)' ],
      theme => { bg => { light => 'rgb(1,2,3)', dark => 'hsl(0, 0%, 5%)' } } ],
    [ [ '--color', 'fg=black,rgba(255,255,255,.9)' ],
      theme => { fg => { light => 'black', dark => 'rgba(255,255,255,.9)' } } ],
    [ [ "--color", "Error=,#ff6677" ], theme => { Error => { dark => '#ff6677' } } ],
    [ [ "--color", "Error=#ff0033," ], theme => { Error => { light => '#ff0033' } } ],
    [ [ "--color", "Error=red", "--color", "bg=#000", "--color", "Error=blue" ], theme => { Error => 'blue', bg => '#000' } ],
    [ [ "--color=edge=teal" ], theme => { edge => 'teal' } ],
    [ [ "--color", "Stopped=#ff0033" ], theme => { Stopped => '#ff0033' } ],
    [ [ "--color", "NotDeployed=#ff0033,#ff6677" ],
      theme => { NotDeployed => { light => '#ff0033', dark => '#ff6677' } } ],
    [ [ "--blink", "Stopped,NotDeployed" ], blink => [qw( Stopped NotDeployed )] ],
    [ [ "--blink", "Error,Blocked" ], blink => [qw( Error Blocked )] ],
    [ [qw( --blink Error --blink Blocked )], blink => [qw( Error Blocked )] ],
    [ [qw( --blink Error --blink-seconds 2.5 )], blink => ['Error'], blink_seconds => 2.5 ],
    [ [qw( --blink Error --blink-seconds .5 )], blink => ['Error'], blink_seconds => 0.5 ]
  ) {
    my ( $args, %opt ) = @$case;
    my ( $exit, $out, $err ) = run( [ $file, @$args ] );
    my $name = join( ' ', @$args );
    is( $exit, 0, $name.': exit 0' ) or diag $err;
    is( $out, library( $file, %opt ), $name.': the picture of those options' );
    isnt( $out, library($file), $name.': not the default picture' );
  }

  my $css = picture( 'rgb with commas', [ $file, '--color', 'Error=rgb(1,2,3),rgb(4,5,6)' ] )
    ->findvalue('//s:style');
  like( $css, qr/\A\.comb-svg\{[^}]*--comb-error:rgb\(1,2,3\)[;}]/, 'rgb(1,2,3),rgb(4,5,6): light' );
  like( $css, qr/prefers-color-scheme:dark\)\{\.comb-svg\{[^}]*--comb-error:rgb\(4,5,6\)[;}]/,
    'rgb(1,2,3),rgb(4,5,6): dark' );

  # What the module ignores gives the default picture, not an error.
  for my $args (
    [ '--color', 'Error=red;}</style><script>x</script>' ],
    [ "--color", "Bogus=#ff0033" ],
    [ "--color", "Error=url(x)" ],
    [ "--blink", "Bogus" ],
    [ "--blink", "," ],
    [qw( --blink-seconds 3 )]
  ) {
    my ( $exit, $out, $err ) = run( [ $file, @$args ] );
    my $name = join( ' ', @$args );
    is( $exit, 0, $name.': exit 0' ) or diag $err;
    is( $out, library($file), $name.': ignored, the default picture' );
  }
  my ( undef, $mixed ) = run( [ $file, "--blink", "Error,Bogus,,error" ] );
  is( $mixed, library( $file, blink => ['Error'] ), '--blink Error,Bogus,,error: only Error blinks' );
  unlike( library($file), qr/animation|keyframes/, 'no --blink: no animation CSS' );

  failure( '--color without =',   [ $file, '--color', 'red' ],        qr/--color needs KEY=COLOUR/ );
  failure( '--color without key', [ $file, '--color', '=red' ],       qr/--color needs KEY=COLOUR/ );
  failure( '--color without colour', [ $file, '--color', 'Error=' ],  qr/--color needs KEY=COLOUR/ );
  failure( '--color three colours', [ $file, '--color', 'Error=a,b,c' ], qr/--color needs KEY=COLOUR/ );
  failure( '--blink-seconds 0',   [ $file, '--blink-seconds', 0 ],    qr/--blink-seconds needs a positive number/ );
  failure( '--blink-seconds fast', [ $file, '--blink-seconds', 'fast' ], qr/--blink-seconds needs a positive number/ );
  failure( '--blink-seconds -1',  [ $file, '--blink-seconds=-1' ],    qr/--blink-seconds needs a positive number/ );
  failure( '--blink-seconds 1e3', [ $file, '--blink-seconds', '1e3' ], qr/--blink-seconds needs a positive number/ );
  failure( '--blink without value', [ $file, '--blink' ],             qr/blink requires an argument/ );
}

#### Packed layout

{
  my $file = $svg->child('wrap.json')->stringify;
  my $DEP  = '//s:path[ '.has_class('dep').' ]';
  for my $case (
    [ [qw( --layout packed )], layout => 'packed' ],
    [ [qw( --layout depth )], layout => 'depth' ],
    [ [qw( --layout packed --columns 2 )], layout => 'packed', columns => 2 ],
    [ [qw( --layout packed --rows 2 )], layout => 'packed', rows => 2 ],
    [ [qw( --layout packed --aspect 16:9 )], layout => 'packed', aspect => 16 / 9 ],
    [ [qw( --layout packed --aspect 16/9 )], layout => 'packed', aspect => 16 / 9 ],
    [ [qw( --layout packed --aspect 9:16 )], layout => 'packed', aspect => 9 / 16 ],
    [ [qw( --layout packed --aspect 0.5 )], layout => 'packed', aspect => 0.5 ],
    [ [qw( --layout packed --edges )], layout => 'packed', edges => 1 ],
    [ [qw( --layout packed --no-edges )], layout => 'packed', edges => 0 ]
  ) {
    my ( $args, %opt ) = @$case;
    my ( $exit, $out, $err ) = run( [ $file, @$args ] );
    my $name = join( ' ', @$args );
    is( $exit, 0, $name.': exit 0' ) or diag $err;
    is( $out, library( $file, %opt ), $name.': the picture of those options' );
  }
  my ( undef, $depth ) = run( [ $file, qw( --layout depth ) ] );
  is( $depth, library($file), '--layout depth: the default picture' );
  my ( undef, $wide ) = run( [ $file, qw( --layout packed --aspect 16:9 ) ] );
  my ( undef, $tall ) = run( [ $file, qw( --layout packed --aspect 9:16 ) ] );
  isnt( $wide, $tall, '--aspect: a wide and a tall screen give different pictures' );

  my $chain = $svg->child('chain.json')->stringify;
  is( picture( 'packed', [ $chain, qw( --layout packed ) ] )->findnodes($DEP)->size, 0,
    '--layout packed: no edges by default' );
  is( picture( 'packed --edges', [ $chain, qw( --layout packed --edges ) ] )->findnodes($DEP)->size,
    2, '--layout packed --edges: the edges' );
}

#### Non-ASCII

{
  my $name = "k\x{e4}se-\x{6771}";
  my ( $exit, $out, $err ) = run(
    [ $cli->child('unicode.json')->stringify, '--group-label', 'tier', '--title', "L\xc3\xa4b" ] );
  is( $exit, 0, 'non-ASCII: exit 0' ) or diag $err;
  unlike( $out, qr/[^\x00-\x7F]/, 'non-ASCII: the output is pure ASCII' );
  my $xpc = parse($out);
  is( $xpc->findvalue( $COMB.'/@data-name' ), $name, 'non-ASCII: the name arrives as characters' );
  is( $xpc->findvalue( $COMB.'/s:text[ '.has_class('name').' ]' ), $name,
    'non-ASCII: and is drawn as such' );
  is( $xpc->findvalue('//s:g/@data-group'), "\x{fc}ber", 'non-ASCII: label value' );
  is( $xpc->findvalue('/s:svg/s:title'), "L\x{e4}b", 'non-ASCII: --title is read as UTF-8' );

  ( $exit, $out ) = run( [], $cli->child('unicode.json') );
  is( parse($out)->findvalue( $COMB.'/@data-name' ), $name, 'non-ASCII: the same from stdin' );
}

#### Errors

failure( 'bad JSON', [ $cli->child('bad.json')->stringify ], qr/invalid JSON in \S*bad\.json: \S/ );
failure( 'bad JSON on stdin', [], qr/invalid JSON in standard input/, $cli->child('bad.json') );
failure( 'empty stdin', [], qr/invalid JSON in standard input/ );
failure( 'neither hash nor array', [ $cli->child('scalar.json')->stringify ], qr/neither/ );
failure( 'missing name', [ $svg->child('no-name.json')->stringify ], qr/without metadata\.name/ );
failure( 'missing file', [ $tmp->child('nope.json')->stringify ],
  qr/cannot read \S*nope\.json: \S/ );
failure( 'directory', [ $tmp->stringify ], qr/cannot read/ );
failure( 'two files', [ ( $svg->child('chain.json')->stringify ) x 2 ], qr/more than one/ );

my $chain = $svg->child('chain.json')->stringify;
failure( 'unknown option', [ $chain, '--frobnicate' ], qr/Unknown option: frobnicate/ );
failure( '--columns 0',    [ $chain, '--columns', 0 ],     qr/--columns needs a positive integer/ );
failure( '--columns 2.5',  [ $chain, '--columns', '2.5' ], qr/--columns needs a positive integer/ );
failure( '--columns -1',   [ $chain, '--columns=-1' ],     qr/--columns needs a positive integer/ );
failure( '--size abc',     [ $chain, '--size', 'abc' ],    qr/--size needs a positive number/ );
failure( '--size 0',       [ $chain, '--size', 0 ],        qr/--size needs a positive number/ );
failure( '--layout spiral', [ $chain, '--layout', 'spiral' ], qr/--layout needs depth or packed/ );
failure( '--rows 0',       [ $chain, '--rows', 0 ],        qr/--rows needs a positive integer/ );
failure( '--rows 1.5',     [ $chain, '--rows', '1.5' ],    qr/--rows needs a positive integer/ );
failure( '--aspect wide',  [ $chain, '--aspect', 'wide' ], qr/--aspect needs a positive number/ );
failure( '--aspect 16:0',  [ $chain, '--aspect', '16:0' ], qr/--aspect needs a positive number/ );
failure( '--aspect 0',     [ $chain, '--aspect', 0 ],      qr/--aspect needs a positive number/ );
failure( '--aspect 16:9:1', [ $chain, '--aspect', '16:9:1' ], qr/--aspect needs a positive number/ );
failure( '--title without value',[ $chain, '--title' ],   qr/title requires an argument/ );

done_testing;
