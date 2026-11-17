package Holmgang::SuiteDir;
# Test helpers for the loader tests: throw-away suite directories in format 2, and the
# refusal check. Every suite and case written through here is invented (ADR 0003).
use strict;
use warnings;
use Exporter qw( import );
use Path::Tiny ();
use Test::More ();

use Langertha::Holmgang::Error;
use Langertha::Holmgang::Loader;

our @EXPORT_OK = qw( suite_dir try_load refused loader $FAN_HEAD $FAN_CASE );

my $TMP = Path::Tiny->tempdir;
my $N   = 0;
my $LOADER;

sub loader { return $LOADER //= Langertha::Holmgang::Loader->new }

# a fan with three levels, a shell for linux devices
our $FAN_HEAD = <<'Y';
format: 2
id: __ID__
version: 1
title: Fan
tools:
  - name: fan_set
    description: Sets the fan level.
    parameters: { type: object, required: [level], properties: { level: { type: string, enum: [off, low, high] } } }
    handlers:
      - apply: [ { set: fan.level, value: '{level}' } ]
        output: "fan <: $state.fan.level :>"
  - name: run_command
    description: Shell.
    simulator: run_command
    parameters: { type: object, required: [host, command], properties: { host: { type: string }, command: { type: string } } }
Y

our $FAN_CASE = <<'Y';
id: c1
title: Cool the room
messages: [ { role: user, content: "It is hot in here." } ]
state: { fan: { level: off } }
rules:
  - { title: fan on high, state: fan.level, equals: high }
  - { title: nothing else, unchanged_except: [ fan.level ] }
solution: [ { tool: fan_set, args: { level: high } } ]
alternatives: [ { title: stepwise, calls: [ { tool: fan_set, args: { level: low } }, { tool: fan_set, args: { level: high } } ] } ]
wrong_solutions: [ { title: low only, calls: [ { tool: fan_set, args: { level: low } } ] } ]
Y

# suite_dir( head => $yaml, cases => { 'c1.yaml' => $yaml }, id => 'x' ) -> ( $dir, $id )
sub suite_dir {
  my ( %o ) = @_;
  my $id   = $o{id} // 's'.++$N;
  my $root = $o{root} // $TMP;
  my $dir  = Path::Tiny::path( $root, $id );
  $dir->child('cases')->mkpath;
  $dir->child('suite.yaml')->spew_utf8( ( $o{head} // $FAN_HEAD ) =~ s/__ID__/$id/gr );
  my $cases = $o{cases} // { 'c1.yaml' => $FAN_CASE };
  $dir->child( 'cases', $_ )->spew_utf8( $cases->{$_} ) for sort keys %$cases;
  return wantarray ? ( "$dir", $id ) : "$dir";
}

sub try_load {
  my ( $case, %o ) = @_;
  my $dir = suite_dir( %o, cases => { 'c1.yaml' => $case, %{ $o{more} || {} } } );
  my $s = eval { ( $o{loader} // loader() )->load($dir) };
  return ( $s, $@ );
}

sub refused {
  my ( $case, $field_re, $why_re, $name, %o ) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ( $s, $err ) = try_load( $case, %o );
  my $r = Langertha::Holmgang::Error->caught($err);
  Test::More::ok( !$s && $r && $r->field =~ $field_re && $r->reason =~ $why_re, $name )
    or Test::More::diag( $s ? 'loaded' : "$err" );
}

1;
