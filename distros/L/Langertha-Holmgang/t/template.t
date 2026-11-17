#!/usr/bin/env perl
# Langertha::Holmgang::Template, with cai-platform t/eval_world_cap.t ported onto
# invented data (ADR 0003). Claims: plain text and no template pass through;
# $state and $args render; re, cap, has, pad compute as documented (cap gives the
# first capture group, empty without a hit); nft_verdict asks the device's
# simulator through the registry and is empty where it cannot answer; a template
# that does not compile dies.
use strict;
use warnings;
use utf8;
use Test::More;
use Test::Fatal qw( exception );

use Langertha::Holmgang::Template qw( render );

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

is( render( undef, {}, {} ), 'ok', 'no template: ok' );
is( render( "plain <text> & more\n", {}, {} ), "plain <text> & more\n", 'no Kolon markers: as it is' );
is( render( '<: $state.a.b :>/<: $args.x :>', { a => { b => '<1>' } }, { x => 'y&z' } ), '<1>/y&z', '$state and $args, not escaped' );
is( render( ': for $state.l -> $i {'."\n".'<: $i :>'."\n".': }'."\n", { l => [ 1, 2 ] } ), "1\n2\n", 'line code' );

is( render( '<: re($args.v, "^ab") :><: re($args.w, "^ab") :>', {}, { v => 'abc', w => 'xab' } ), '10', 're' );
is( render( '<: has($state.l, "2") :><: has($state.l, 3) :><: has($state.x, 1) :>', { l => [ 1, 2 ] }, {} ), '100', 'has: numbers compared numerically' );
is( render( '[<: pad("ab", 5) :>]', {}, {} ), '[ab   ]', 'pad' );
is( render( '[<: pad("abcdef", 3) :>]', {}, {} ), '[abcdef]', 'pad: longer text stays' );

# cap: numbers from the state compared (eval_world_cap.t)
{
  my $st = { a => { conf => "x\n    weight 100\n" }, b => { conf => "x\n    weight 150\n" } };
  my $t = ': my $pa = cap($state["a"].conf, "weight ([0-9]+)") + 0; my $pb = cap($state["b"].conf, "weight ([0-9]+)") + 0;'."\n"
    .'<: $pb > $pa ? "b" : "a" :> <: $pa :> <: $pb :>'."\n";
  is( render( $t, $st, {} ), "b 100 150\n", 'numbers captured and compared' );
  $st->{b}{conf} = "weight 90\n";
  is( render( $t, $st, {} ), "a 100 90\n", 'after a change of the state' );
  is( render( '[<: cap("abc", "z([0-9])") :>]', $st, {} ), '[]', 'without a hit: empty' );
  is( render( '[<: cap($state.missing, "([0-9])") :>]', $st, {} ), '[]', 'without text: empty' );
}

# nft_verdict through the registry
{
  my $fw = { type => 'linux', nft => { 'inet filter' => { chains => { input => { type => 'filter', hook => 'input',
    priority => '0', policy => 'drop', rules => [ 'iifname "eth1" tcp dport 22 accept' ] } } } } };
  my $st = { fw => $fw, plain => { x => 1 } };
  my $t = '<: nft_verdict($state["fw"], { hook => "input", iif => $args.iif, saddr => "10.1.0.7", daddr => "10.1.0.1", proto => "tcp", dport => 22 }) :>';
  is( render( $t, $st, { iif => 'eth1' } ), 'accept', 'nft_verdict: accept' );
  is( render( $t, $st, { iif => 'eth0' } ), 'drop', 'nft_verdict: policy drop' );
  ( my $t2 = $t ) =~ s/\$state\["fw"\]/\$state["plain"]/;
  is( render( $t2, $st, { iif => 'eth1' } ), '', 'nft_verdict: a device without a packet filter gives empty' );
  is( render( '[<: nft_verdict($state.none, {}) :>]', $st, {} ), '[]', 'nft_verdict: no device gives empty' );
}

like( exception { render( '<: $state.a ', {}, {} ) }, qr/./, 'a template that does not compile dies' );

done_testing;
