#!/usr/bin/env perl
# The state of a case is plain data (k59), on an invented suite (ADR 0003).
# Claims: a code reference anywhere in a case's state -- in a world entry, a device,
# nested in hashes and lists -- is refused when the suite loads, by Structure, with
# the field path to it (suite.pl: case c1: state.cfg.hooks[1].run); so is any other
# reference that is not data (an object, a scalar reference). Before k59 the code
# reference passed the shape checks and died in the world's JSON copy without a
# field. A qr// is no refusal: the DSL stores it as its string form. Booleans
# (JSON::PP::Boolean) are data.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Path::Tiny qw( path );
use Test::More;

use Langertha::Holmgang::Error;
use Langertha::Holmgang::Loader;

my $tmp = Path::Tiny->tempdir;
my $n   = 0;

sub load_with {
  my ( $state ) = @_;
  my $dir = $tmp->child( 'plain-'.++$n );
  $dir->mkpath;
  $dir->child('suite.pl')->spew_utf8( <<"P" );
use Langertha::Holmgang;
use JSON::PP ();

suite 'plain-$n' => sub {
  title 'Plain state';
  version 1;
  topic 'probe';
  tool submit => (
    description => 'Hand in a value.',
    parameters  => { type => 'object', required => ['value'], properties => { value => { type => 'string' } } },
    handlers    => [ handler apply => [ { set => 'answer', value => '{value}' } ], output => 'ok' ],
  );
  case c1 => sub {
    title 'Hand in yes';
    ask 'Hand in yes.';
    world answer => 'no';
    $state
    rule handed => at 'answer', equals => 'yes';
    solution call submit => { value => 'yes' };
    alternative twice => call( submit => { value => 'yes' } ), call( submit => { value => 'yes' } );
    wrong 'no' => call submit => { value => 'no' };
  };
};
P
  my $suite = eval { Langertha::Holmgang::Loader->new->load("$dir") };
  return ( $suite, $suite ? undef : Langertha::Holmgang::Error->caught($@) // $@ );
}

my @refused = (
  [ q{world cfg => { hooks => [ 'a', { run => sub { 1 } } ] };}, 'suite.pl: case c1: state.cfg.hooks[1].run', qr/a code reference/, 'a code reference, nested' ],
  [ q{world cfg => sub { 1 };},                                  'suite.pl: case c1: state.cfg',              qr/a code reference/, 'a code reference as the entry' ],
  [ q{device web => linux => { hook => sub { 1 } };},            'suite.pl: case c1: state.web.hook',         qr/a code reference/, 'a code reference in a device' ],
  [ q{world cfg => { obj => bless( {}, 'Some::Thing' ) };},      'suite.pl: case c1: state.cfg.obj',          qr/a Some::Thing reference/, 'an object' ],
  [ q{world cfg => { ref => \\'x' };},                           'suite.pl: case c1: state.cfg.ref',          qr/a SCALAR reference/, 'a scalar reference' ],
);
for my $r (@refused) {
  my ( $suite, $err ) = load_with( $r->[0] );
  ok( !$suite && ref $err && $err->field eq $r->[1] && $err->reason =~ $r->[2], 'refused with its path: '.$r->[3] )
    or diag( $suite ? 'loaded' : "$err" );
}

my ( $suite, $err ) = load_with(q{world cfg => { pattern => qr/^a+$/, on => JSON::PP::true, list => [ 1, 'two', { three => undef } ] };});
ok( $suite, 'plain data loads: a qr// (stored as text), a boolean, nested lists and hashes, undef' ) or diag("$err");
is( ref $suite && $suite->cases->[0]->initial_state->{cfg}{pattern}, '(?^:^a+$)', '... the qr// as its string form' ) if $suite;

done_testing;
