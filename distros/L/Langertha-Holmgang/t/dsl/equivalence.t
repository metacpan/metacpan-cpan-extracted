#!/usr/bin/env perl
# One invented suite (ADR 0003) written twice -- as suite.yaml with cases/ and as
# suite.pl in the case DSL (ADR 0007) -- in two search directories under the same id.
# Claims: both load through the same structure checks and lint into identical
# internal structures (suite head, every case's own keys, initial state, what the
# model is sent, images, derived tier/weight/hardness), and the mock runs of every
# case -- replaying the reference solution, answering text only -- give identical
# results and send identical requests. Covers a linux device with run/put, an
# observation, a check rule, a handler world, tolerance beside equals (k49), a type
# list in a tool parameter (k48), images on a user message (k27), tier, weight and
# tags. Network-free: the mock model is Langertha::Engine::Virtual.
#
# One deliberate spelling: a false mark is written 0 in both (YAML false loads as
# '', which is the same to every check but not to is_deeply).
use strict;
use warnings;
use FindBin;
use Path::Tiny qw( path );
use Test::More;

use Langertha::Holmgang::Loader;
use Langertha::Holmgang::Runner;
use Langertha::Holmgang::Structure;
use Langertha::Holmgang::Target;

my $png = path( $FindBin::Bin, '..', '..', 'share', 'suites', 'demo-sehen', 'img', 'ablauf.png' );
plan skip_all => 'no share/suites/demo-sehen/img/ablauf.png next to t/' unless -f $png;

my $tmp = Path::Tiny->tempdir;
my %dir = map { $_ => $tmp->child( $_, 'eq-twin' ) } qw( yaml pl );
for my $d ( values %dir ) {
  $d->child('img')->mkpath;
  $png->copy( $d->child( 'img', $_ ) ) for qw( a.png b.png );
}

#### the suite as format 2

$dir{yaml}->child('suite.yaml')->spew_utf8(<<'Y');
format: 2
id: eq-twin
version: 2
title: "Twin: one suite in two forms"
description: Invented for the equivalence test of the DSL.
license: Perl_5
source: { title: holmgang tests, license: Perl_5 }
topic: probe
threshold: { pass_rate: 0.5, pass_k: 0.25 }
repeat: 2
defaults:
  system: "Work through the tools."
  temperature: 0
  max_turns: 6
tools:
  - name: run_command
    simulator: run_command
    description: Run a shell command on a host.
    parameters: { type: object, required: [host, command], properties: { host: { type: string }, command: { type: string } } }
  - name: write_file
    simulator: write_file
    description: Replace a file on a host.
    parameters: { type: object, required: [host, path, content], properties: { host: { type: string }, path: { type: string }, content: { type: string } } }
  - name: set_dimmer
    description: Dim a lamp, 0 to 1; a note is optional.
    parameters:
      type: object
      required: [lamp, level]
      properties:
        lamp: { type: string, enum: [hall, desk] }
        level: { type: number }
        note: { type: [string, "null"] }
    handlers:
      - match: { lamp: "^(?<room>hall|desk)$" }
        apply: [ { set: "lamps.{room}", value: "{level}" } ]
        output: ok
Y

my $cases = $dir{yaml}->child('cases');
$cases->mkpath;
$cases->child('dimmer.yaml')->spew_utf8(<<'Y');
id: dimmer
title: Dim the hall to half
difficulty: mittel
tags: [licht, stufe-16k]
weight: 2.5
messages:
  - { role: user, content: "Dim the hall lamp to half." }
state:
  lamps: { hall: 1, desk: 0 }
rules:
  - { title: hall at half, state: lamps.hall, equals: 0.5, tolerance: 0.05 }
  - { title: desk untouched, unchanged_except: [lamps.hall] }
  - { title: dimmer used, calls: [ { tool: set_dimmer, args: { lamp: "^hall$" } } ], required: 0 }
solution:
  - { tool: set_dimmer, args: { lamp: hall, level: 0.5 } }
alternatives:
  - title: with a note
    calls: [ { tool: set_dimmer, args: { lamp: hall, level: 0.52, note: about half } } ]
wrong_solutions:
  - title: the desk
    calls: [ { tool: set_dimmer, args: { lamp: desk, level: 0.5 } } ]
Y
$cases->child('motd.yaml')->spew_utf8(<<'Y');
id: motd
title: Announce the window
max_turns: 4
messages:
  - { role: user, content: "On web-1, make /etc/motd say: Window Sunday 05:00." }
state:
  web-1:
    type: linux
    files:
      /etc/motd: "Hello.\n"
observe:
  - match: { host: "^web-1$", command: "^uptime$" }
    output: " 05:00:00 up 3 days"
rules:
  - title: motd announces the window
    state: [web-1, files, /etc/motd, content]
    regex: "Window Sunday 05:00"
  - title: cat shows it
    check: { host: web-1, command: "cat /etc/motd" }
    expect: { exit: 0, output: { regex: Sunday } }
  - title: nothing else changed
    unchanged_except: [ [web-1, files, /etc/motd] ]
  - title: no reboot
    not_called: { tool: run_command, args: { host: "^web-1$", command: "^reboot" } }
solution:
  - { tool: write_file, args: { host: web-1, path: /etc/motd, content: "Window Sunday 05:00.\n" } }
alternatives:
  - title: look first, then echo into it
    calls:
      - { tool: run_command, args: { host: web-1, command: uptime } }
      - { tool: run_command, args: { host: web-1, command: "echo 'Window Sunday 05:00.' > /etc/motd" } }
wrong_solutions:
  - title: the wrong file
    calls: [ { tool: write_file, args: { host: web-1, path: /etc/issue, content: "Window Sunday 05:00.\n" } } ]
Y
$cases->child('picture.yaml')->spew_utf8(<<'Y');
id: picture
title: A picture, then the desk lamp
tags: [bild]
messages:
  - role: user
    content: "Two pictures of a flow chart. Read them, then wait."
    images:
      - { file: img/a.png }
      - { file: img/b.png, untrusted: 1 }
  - { role: assistant, content: "Read. What next?" }
  - { role: user, content: "Now set the desk lamp to full." }
state:
  lamps: { hall: 1, desk: 0 }
rules:
  - { title: desk at full, state: lamps.desk, equals: 1, tolerance: 0 }
  - { title: hall untouched, unchanged_except: [lamps.desk] }
solution: [ { tool: set_dimmer, args: { lamp: desk, level: 1 } } ]
alternatives:
  - title: half first
    calls: [ { tool: set_dimmer, args: { lamp: desk, level: 0.5 } }, { tool: set_dimmer, args: { lamp: desk, level: 1 } } ]
wrong_solutions:
  - title: the hall instead
    calls: [ { tool: set_dimmer, args: { lamp: hall, level: 0 } } ]
Y

#### the same suite in the DSL

$dir{pl}->child('suite.pl')->spew_utf8(<<'P');
use Langertha::Holmgang;

my %text = ( type => 'string' );

suite 'eq-twin' => sub {
  title       'Twin: one suite in two forms';
  version     2;
  description 'Invented for the equivalence test of the DSL.';
  license     'Perl_5';
  source      title => 'holmgang tests', license => 'Perl_5';
  topic       'probe';
  threshold   pass_rate => 0.5, pass_k => 0.25;
  repeat      2;
  system_prompt 'Work through the tools.';
  settings    temperature => 0, max_turns => 6;

  tool run_command => (
    simulator   => 'run_command',
    description => 'Run a shell command on a host.',
    parameters  => { type => 'object', required => [qw( host command )],
                     properties => { host => {%text}, command => {%text} } },
  );
  tool write_file => (
    simulator   => 'write_file',
    description => 'Replace a file on a host.',
    parameters  => { type => 'object', required => [qw( host path content )],
                     properties => { host => {%text}, path => {%text}, content => {%text} } },
  );
  tool set_dimmer => (
    description => 'Dim a lamp, 0 to 1; a note is optional.',
    parameters  => { type => 'object', required => [qw( lamp level )], properties => {
      lamp  => { type => 'string', enum => [qw( hall desk )] },
      level => { type => 'number' },
      note  => { type => [ 'string', 'null' ] },
    } },
    handlers => [ handler match => { lamp => '^(?<room>hall|desk)$' },
                          apply => [ { set => 'lamps.{room}', value => '{level}' } ],
                          output => 'ok' ],
  );

  # declared out of id order: cases load ordered by id, as format 2 files do
  case picture => sub {
    title 'A picture, then the desk lamp';
    tags  'bild';
    ask 'Two pictures of a flow chart. Read them, then wait.',
      images => [ 'img/a.png', image( 'img/b.png', untrusted => 1 ) ];
    message assistant => 'Read. What next?';
    ask 'Now set the desk lamp to full.';
    world lamps => { hall => 1, desk => 0 };
    rule 'desk at full'   => at 'lamps.desk', equals => 1, tolerance => 0;
    rule 'hall untouched' => unchanged_except ['lamps.desk'];
    solution call set_dimmer => { lamp => 'desk', level => 1 };
    alternative 'half first' =>
      call( set_dimmer => { lamp => 'desk', level => 0.5 } ), call( set_dimmer => { lamp => 'desk', level => 1 } );
    wrong 'the hall instead' => call set_dimmer => { lamp => 'hall', level => 0 };
  };

  case motd => sub {
    title 'Announce the window';
    settings max_turns => 4;
    ask 'On web-1, make /etc/motd say: Window Sunday 05:00.';
    device 'web-1' => linux => { files => { '/etc/motd' => "Hello.\n" } };
    observe match => { host => '^web-1$', command => '^uptime$' }, output => ' 05:00:00 up 3 days';
    rule 'motd announces the window' => at [ 'web-1', 'files', '/etc/motd', 'content' ], regex => 'Window Sunday 05:00';
    rule 'cat shows it'        => check { host => 'web-1', command => 'cat /etc/motd' }, expect => { exit => 0, output => { regex => 'Sunday' } };
    rule 'nothing else changed' => unchanged_except [ [ 'web-1', 'files', '/etc/motd' ] ];
    rule 'no reboot'           => not_called run '^web-1$' => '^reboot';
    solution put 'web-1' => '/etc/motd' => "Window Sunday 05:00.\n";
    alternative 'look first, then echo into it' =>
      run( 'web-1' => 'uptime' ), run( 'web-1' => "echo 'Window Sunday 05:00.' > /etc/motd" );
    wrong 'the wrong file' => put 'web-1' => '/etc/issue' => "Window Sunday 05:00.\n";
  };

  case dimmer => sub {
    title      'Dim the hall to half';
    difficulty 'mittel';
    tags       'licht';
    tier       '16k';
    weight     2.5;
    ask 'Dim the hall lamp to half.';
    world lamps => { hall => 1, desk => 0 };
    rule 'hall at half'   => at 'lamps.hall', equals => 0.5, tolerance => 0.05;
    rule 'desk untouched' => unchanged_except ['lamps.hall'];
    rule 'dimmer used'    => calls [ call set_dimmer => { lamp => '^hall$' } ], required => 0;
    solution call set_dimmer => { lamp => 'hall', level => 0.5 };
    alternative 'with a note' => call set_dimmer => { lamp => 'hall', level => 0.52, note => 'about half' };
    wrong 'the desk' => call set_dimmer => { lamp => 'desk', level => 0.5 };
  };
};
P

#### load both

my $loader = Langertha::Holmgang::Loader->new;
my %suite;
for my $form (qw( yaml pl )) {
  $suite{$form} = eval { $loader->load( $dir{$form}->stringify ) };
  ok( $suite{$form}, "the $form form loads (structure and lint, mock runs included)" ) or diag $@;
}
BAIL_OUT('a form does not load') unless $suite{yaml} && $suite{pl};
my ( $y, $p ) = @suite{qw( yaml pl )};

is_deeply( { map { $_ => $p->$_ } qw( id version title description license source topic threshold repeat defaults tools ) },
  { map { $_ => $y->$_ } qw( id version title description license source topic threshold repeat defaults tools ) },
  'suite head identical' );
is_deeply( [ map { $_->id } @{ $p->cases } ], [qw( dimmer motd picture )], 'DSL cases ordered by id' );
is_deeply( [ map { $_->id } @{ $p->cases } ], [ map { $_->id } @{ $y->cases } ], '... as the case files are' );
isnt( $p->digest, $y->digest, 'digests differ: the DSL digest is taken from its export, not these files (k19)' );

for my $i ( 0 .. $#{ $y->cases } ) {
  my ( $cy, $cp ) = ( $y->cases->[$i], $p->cases->[$i] );
  my $id = $cy->id;
  for my $k ( @Langertha::Holmgang::Structure::CASE_KEYS ) {
    is_deeply( $cp->$k, $cy->$k, "$id: $k identical" );
  }
  is_deeply( $cp->initial_state,   $cy->initial_state,   "$id: initial state identical" );
  is_deeply( $cp->prompt_messages, $cy->prompt_messages, "$id: what the model is sent identical" );
  my $strip = sub { my ( $c ) = @_; return { map { my %i = %{ $c->image_files->{$_} }; delete $i{path}; ( $_ => \%i ) } keys %{ $c->image_files } } };
  is_deeply( $strip->($cp), $strip->($cy), "$id: images identical (but the directory)" );
  is_deeply( [ map { $cp->$_ } qw( tier effective_weight is_hard has_untrusted has_images no_tool ) ],
    [ map { $cy->$_ } qw( tier effective_weight is_hard has_untrusted has_images no_tool ) ], "$id: derived values identical" );
  is_deeply( [ map { $cp->effective($_) } qw( system temperature max_tokens max_turns ) ],
    [ map { $cy->effective($_) } qw( system temperature max_tokens max_turns ) ], "$id: effective settings identical" );

  for my $mode (qw( solution text )) {
    my %r;
    for my $form (qw( yaml pl )) {
      my $case = $form eq 'yaml' ? $cy : $cp;
      my $e = Langertha::Holmgang::Runner->mock_engine( $case, $mode );
      my $res = Langertha::Holmgang::Runner->new( target => Langertha::Holmgang::Target->new( engine => $e ) )->run_case($case);
      $r{$form} = {
        ( map { $_ => $res->{$_} } qw( status score error rules diff sim_gaps forbidden_calls injection_held calls answer state transcript ) ),
        requests => $e->requests,
      };
    }
    is( $r{pl}{status}, $mode eq 'solution' ? 'passed' : 'failed', "$id: mock $mode is $r{pl}{status}" );
    is_deeply( $r{pl}, $r{yaml}, "$id: mock $mode run identical, requests included" );
  }
}

# a few spot checks that the twin covers what it claims
{
  my %c = map { $_->id => $_ } @{ $p->cases };
  is( $c{dimmer}->tier, '16k', 'tier from the DSL keyword' );
  is( $c{dimmer}->effective_weight, 2.5, 'weight' );
  is( $c{dimmer}->rules->[0]{tolerance}, 0.05, 'tolerance beside equals' );
  is_deeply( $p->tools->[2]{parameters}{properties}{note}{type}, [ 'string', 'null' ], 'type list in a tool parameter' );
  is( scalar keys %{ $c{picture}->image_files }, 2, 'two images on a user message' );
  ok( $c{picture}->has_untrusted, '... one of them untrusted' );
  is_deeply( $c{motd}->solution, [ { tool => 'write_file', args => { host => 'web-1', path => '/etc/motd', content => "Window Sunday 05:00.\n" } } ],
    'put resolved to the write_file tool' );
}

done_testing;
