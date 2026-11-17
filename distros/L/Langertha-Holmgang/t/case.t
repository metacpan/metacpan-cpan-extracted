#!/usr/bin/env perl
# Langertha::Holmgang::Case and Suite: what derives from a case's own values
# (ADR 0005). Every case here is invented (ADR 0003). Claims: settings fall back
# own -> suite defaults -> built-in and are never copied in; the prompt carries
# role and content only, generated text resolved, no untrusted mark; the initial
# state has generated file contents resolved and is prepared, without touching
# the state as written; tier, hard, untrusted and the "no tool" family come from
# the values; an answer world's tools are checked by the loader.
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

use Holmgang::SuiteDir qw( try_load refused );
use Langertha::Holmgang::Case;
use Langertha::Holmgang::Haystack;
use Langertha::Holmgang::Report;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

my $C = 'Langertha::Holmgang::Case';

{
  my $c = $C->new( id => 'x', defaults => { max_turns => 4, system => 'Be brief.' }, temperature => 0.7 );
  is( $c->effective('temperature'), 0.7, 'own value first' );
  is( $c->effective('max_turns'), 4, 'then the suite default' );
  is( $c->effective('max_tokens'), 2000, 'then the built-in one' );
  is( $c->effective('system'), 'Be brief.', 'system prompt from the defaults' );
  is( $c->max_turns, undef, '... never copied into the case' );
  is( $c->effective('title'), undef, 'effective only knows settings' );
  is( $C->new( id => 'x', system => 'Own.', defaults => { system => 'Suite.' } )->effective('system'), 'Own.', 'own system prompt' );
  is( $C->new( id => 'x' )->effective('system'), '', 'no system prompt: empty' );
}
{
  my $c = $C->new( id => 'x', tags => [qw( injection stufe-160k other )] );
  is( $c->tier, '160k', 'tier from stufe-160k' );
  ok( $c->is_hard, 'injection is hard' );
  is( $C->new( id => 'x' )->tier, undef, 'no tags: no tier' );
  # k56: ctx-<N>k names the context window a case is meant for, not a length tier
  is( $C->new( id => 'x', tags => ['ctx-64k'] )->tier, undef, 'ctx-64k is no tier' );
  ok( !$C->new( id => 'x', tags => ['verboten'] )->is_hard, 'only injection and verbot are hard' );
  ok( $C->new( id => 'x', solution => [] )->no_tool, 'solution: [] is the "no tool" family' );
  ok( !$C->new( id => 'x', solution => [ { tool => 't' } ] )->no_tool, '... a solution with calls is not' );
  ok( !$C->new( id => 'x' )->no_tool, '... nor no solution at all' );
}
# k36: tier is one value in list context too, and report_meta is what Report takes
{
  my %h = ( tier => $C->new( id => 'x' )->tier, after => 1 );
  is_deeply( \%h, { tier => undef, after => 1 }, 'tier without a tag keeps a hash literal in pairs' );
  my @l = $C->new( id => 'x', tags => ['stufe-48k'] )->tier;
  is_deeply( \@l, ['48k'], '... and with one it is one value' );

  my $c = $C->new( id => 'x', title => 'T', tags => [qw( verbot stufe-16k )], weight => 3, difficulty => 'schwer',
    messages => [ { role => 'user', content => 'a', untrusted => 1 } ] );
  is_deeply( $c->report_meta, { case_id => 'x', title => 'T', tags => [qw( verbot stufe-16k )], tier => '16k',
    difficulty => 'schwer', weight => 3, hard => 1, untrusted => 1 }, 'report_meta (k57: with difficulty)' );
  is_deeply( $C->new( id => 'y' )->report_meta, { case_id => 'y', title => undef, tags => undef, tier => undef,
    difficulty => undef, weight => 1, hard => 0, untrusted => 0 }, 'report_meta: defaults, effective weight' );
  my $r = Langertha::Holmgang::Report->new;
  $r->add_run( target => { label => 't' }, variant => { name => 'v' }, suite => { id => 's' }, repeat => 1,
    status => 'complete', cases => [ $c->report_meta ], results => [] );
  is_deeply( { map { $_ => $r->runs->[0]{cases}[0]{$_} } keys %{ $c->report_meta } }, $c->report_meta, '... and Report takes it unchanged' );
}
{
  my $c = $C->new( id => 'x', messages => [ { role => 'user', content => 'a', untrusted => 1 } ], state => {} );
  ok( $c->has_untrusted, 'untrusted message' );
  is_deeply( $c->prompt_messages, [ { role => 'user', content => 'a' } ], '... the mark does not go out' );
  ok( $C->new( id => 'x', state => { a => [ { b => { untrusted => JSON::MaybeXS::true() } } ] } )->has_untrusted, 'untrusted deep in the state, as a JSON boolean' );
  ok( !$C->new( id => 'x', state => { a => { untrusted => 0 } } )->has_untrusted, 'untrusted: false is not foreign content' );
  ok( !$C->new( id => 'x', state => { a => { untrusted => { x => 1 } } } )->has_untrusted, 'untrusted must be a flag' );
}
{
  my $spec = { kind => 'syslog', tokens => 1000, seed => 9 };
  my $state = { h1 => { type => 'linux', files => { '/var/log/big' => { content => [ "head\n", { generate => $spec } ] }, '/etc/x' => "x\n" } } };
  my $c = $C->new( id => 'x', state => $state, messages => [ { role => 'user', content => { generate => { %$spec, seed => 10 } } } ] );
  my $text = Langertha::Holmgang::Haystack->new->generate($spec);
  is( $c->initial_state->{h1}{files}{'/var/log/big'}{content}, "head\n".$text, 'initial state: generated file content resolved' );
  is( ref $c->state->{h1}{files}{'/var/log/big'}{content}, 'ARRAY', '... the state as written keeps the spec' );
  is( $c->prompt_messages->[0]{content}, Langertha::Holmgang::Haystack->new->generate( { %$spec, seed => 10 } ), 'generated message content' );
  isnt( $c->initial_state, $c->state, 'the initial state is a copy' );
}

# an answer world: the loader checks the world's tool names and required parameters
my $HEAD = <<'Y';
format: 2
id: __ID__
version: 1
title: Kitchen
tools:
  - name: auf_liste_setzen
    description: Puts an ingredient on the shopping list.
    simulator: kueche
    parameters: { type: object, required: [zutat, menge], properties: { zutat: { type: string }, menge: { type: string } } }
  - name: liste_lesen
    description: Reads the shopping list.
    simulator: kueche
Y
my $CASE = <<'Y';
id: c1
title: Buy rice
messages: [ { role: user, content: "Put 500 g rice on the list." } ]
state: { k: { type: kueche, zutaten: { Reis: { einheit: g } }, liste: {} } }
rules:
  - { title: rice listed, state: k.liste.Reis, equals: 500 }
solution: [ { tool: auf_liste_setzen, args: { zutat: Reis, menge: 500 g } } ]
alternatives: [ { title: in two steps, calls: [ { tool: auf_liste_setzen, args: { zutat: Reis, menge: 200 g } }, { tool: auf_liste_setzen, args: { zutat: Reis, menge: 300 g } } ] } ]
wrong_solutions: [ { title: too little, calls: [ { tool: auf_liste_setzen, args: { zutat: Reis, menge: 50 g } } ] } ]
Y
{
  my ( $s, $err ) = try_load( $CASE, head => $HEAD );
  ok( $s, 'a suite on an answer world loads' ) or diag $err;
  is_deeply( [ map { $_->{name} } @{ $s->cases->[0]->tools } ], [qw( auf_liste_setzen liste_lesen )], '... with its tools' );
}
refused( $CASE, qr/tools\[1\]\.name\z/, qr/the world kueche has no tool liste_drucken/, 'unknown tool of the world',
  head => $HEAD =~ s/name: liste_lesen/name: liste_drucken/r );
refused( $CASE, qr/tools\[0\]\.parameters\z/, qr/required parameter menge/, 'a required parameter of the world missing',
  head => $HEAD =~ s/required: \[zutat, menge\]/required: [zutat]/r );
refused( $CASE, qr/tools\[0\]\.handlers\z/, qr/not both/, 'simulator and handlers',
  head => $HEAD =~ s/    simulator: kueche\n    parameters: \{ type: object, required/    simulator: kueche\n    handlers: [ { output: x } ]\n    parameters: { type: object, required/r );

done_testing;
