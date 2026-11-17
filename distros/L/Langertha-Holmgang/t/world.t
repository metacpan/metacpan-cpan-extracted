#!/usr/bin/env perl
# Langertha::Holmgang::World, ported from cai-platform t/eval_world.t and
# t/eval_world_observe_error.t onto invented worlds (ADR 0003).
# Claims: tools read and CHANGE the state, a change is visible to the next read;
# the first fitting handler wins (match, when, named captures); arguments go
# against the schema; a failing change leaves the state untouched; apply
# operations are read as format 2 writes them; diff and path coverage compute
# right; the case's state is never changed; observations answer before the
# simulator, link by link in a chain, and error: true fails the command.
use strict;
use warnings;
use utf8;
use Test::More;

use Langertha::Holmgang::World;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

my $W = 'Langertha::Holmgang::World';

my @tools = (
  { name       => 'list_shelf',
    parameters => { type => 'object', required => ['room'], properties => { room => { type => 'string' } } },
    handlers   => [
      { match => { room => '^(?<r>lab\d)$' }, when => [ { path => '{r}', exists => 1 } ],
        output => ": for \$state[\$args.r].shelf -> \$b {\n<: \$b.title :> by <: \$b.author :>\n: }\n" },
      { error => 1, output => "Fehler: no room <: \$args.room :>" },
    ],
  },
  { name       => 'add_book',
    parameters => { type => 'object', required => [qw( room title )],
      properties => { room => { type => 'string' }, title => { type => 'string' }, author => { type => 'string' },
        pages => { type => 'integer' } } },
    handlers => [
      { when  => [ { path => '{room}.shelf', exists => 1 } ],
        apply => [ { push => '{room}.shelf', value => { title => '{title}', author => '{author}', pages => '{pages|int}' } } ],
        output => 'ok' },
    ],
  },
  { name => 'drop_book',
    parameters => { type => 'object', properties => { room => { type => 'string' }, title => { type => 'string' } } },
    handlers => [ { apply => [ { remove => '{room}.shelf', where => { title => '^{title}$' } } ] } ],
  },
  { name => 'reorder',
    parameters => { type => 'object', properties => { from => { type => 'integer' }, to => { type => 'integer' } } },
    handlers => [ { apply => [ { move => 'lab1.shelf', from => '{from}', to => '{to}' } ] } ],
  },
  { name => 'tag_keys',
    parameters => { type => 'object', properties => { key => { type => 'string' }, tags => { type => 'string' } } },
    handlers => [ { when => [ { path => [ 'lab1', 'keys', '{key}' ], exists => 1 } ],
      apply => [ { set => [ 'lab1', 'keys', '{key}' ], value => '{tags|split}' } ] } ],
  },
  { name => 'two_steps',
    parameters => { type => 'object', properties => {} },
    handlers => [ { apply => [ { set => 'lab2.note', value => 'x' }, { delete => 'lab2.missing' } ] } ],
  },
);
my $start = { lab1 => { shelf => [ { title => 'Optics', author => 'Ada' } ], keys => { 'door.main' => ['k1'] } },
  lab2 => { shelf => [] } };

{
  my $w = $W->new( state => $start, tools => \@tools );
  my ( $out ) = $w->call( list_shelf => '{"room":"lab1"}' );
  is( $out, "Optics by Ada\n", 'a read renders from the state' );
  my ( undef, undef, $ok ) = $w->call( add_book => { room => 'lab1', title => 'Waves', author => 'Bo', pages => '320' } );
  ok( $ok, 'change succeeded' );
  is_deeply( $w->state->{lab1}{shelf}[1], { title => 'Waves', author => 'Bo', pages => 320 },
    'push with arguments put in, |int makes a number' );
  ( $out ) = $w->call( list_shelf => { room => 'lab1' } );
  like( $out, qr/^Waves by Bo$/m, 'the change is visible in the next read' );
  is( scalar @{ $start->{lab1}{shelf} }, 1, 'the case state stays unchanged (copy)' );

  my ( $e, undef, $eok ) = $w->call( list_shelf => { room => 'attic' } );
  is( $e, 'Fehler: no room attic', 'next handler when match does not fit' );
  ok( !$eok, 'error handler: the call counts as failed' );
  ( $e ) = $w->call( list_shelf => { room => 'lab3' } );
  like( $e, qr/no room lab3/, 'when (path missing) falls through to the next handler' );

  ( $e ) = $w->call( add_book => { room => 'lab1' } );
  like( $e, qr/\AFehler: Argumente passen nicht zum Schema: \$\.title: fehlt/, 'required argument missing' );
  ( $e ) = $w->call( add_book => { room => 'lab1', title => 'x', pages => 'many' } );
  like( $e, qr/\$\.pages: erwartet integer/, 'wrong type' );
  ( $e ) = $w->call( add_book => 'no json' );
  is( $e, 'Fehler: Argumente sind kein JSON-Objekt.', 'broken JSON' );
  ( $e ) = $w->call( fly => {} );
  like( $e, qr/unbekanntes Werkzeug 'fly'/, 'unknown tool' );

  my $before = $W->clone( $w->state );
  ( $e, undef, $eok ) = $w->call( drop_book => { room => 'lab1', title => 'Poetry' } );
  like( $e, qr/\AFehler: kein passender Eintrag/, 'remove without a hit fails' );
  ok( !$eok, '... as failed' );
  is_deeply( $w->state, $before, '... state unchanged' );
  ( $e ) = $w->call( two_steps => {} );
  like( $e, qr/\AFehler: nicht vorhanden/, 'the second change fails' );
  is_deeply( $w->state, $before, '... and the first one is not kept either' );
  ( $e ) = $w->call( reorder => { from => 5, to => 0 } );
  like( $e, qr/Eintrag 5 gibt es nicht \(0 bis 1\)/, 'move out of range' );
  $w->call( reorder => { from => 1, to => 0 } );
  is( $w->state->{lab1}{shelf}[0]{title}, 'Waves', 'move: the entry moves up' );
  $w->call( drop_book => { room => 'lab1', title => 'Optics' } );
  is_deeply( [ map { $_->{title} } @{ $w->state->{lab1}{shelf} } ], ['Waves'], 'remove with a literally put-in pattern' );

  $w->call( tag_keys => { key => 'door.main', tags => 'k1, k2' } );
  is_deeply( $w->state->{lab1}{keys}{'door.main'}, [ 'k1', 'k2' ], 'path as a list (key with a dot), |split' );
  ( $e, undef, $eok ) = $w->call( tag_keys => { key => 'gate', tags => 'k9' } );
  like( $e, qr/nicht vorgesehen/, 'no handler fits: a hint' );
  ok( !$eok, '... failed' );

  my @d  = $W->diff( $start, $w->state );
  my @dp = map { $W->path_text( $_->{path} ) } @d;
  is( $dp[0], 'lab1.keys["door.main"]', 'diff: key with a dot' );
  ok( @dp > 1 && !grep( { !/\Alab1\.shelf\.0\.\w+\z/ } @dp[ 1 .. $#dp ] ), 'diff: list of the same length entry by entry (index, field)' )
    or diag explain \@dp;
}

# --- diff and coverage --------------------------------------------------------
{
  my $p = sub { [ map { $W->path_text( $_->{path} ) } $W->diff(@_) ] };
  is_deeply( $p->( { l => [ { a => 1 } ] }, { l => [ { a => 1 }, { a => 2 } ] } ), ['l'], 'diff: list of another length as a whole' );
  is_deeply( $p->( { l => [ 1, 2 ] }, { l => [ 2, 1 ] } ), ['l'], 'diff: list of plain values as a whole' );
  is_deeply( $p->( { a => 1, _trace => 1 }, { a => 1, _trace => 2 } ), [], 'diff: keys with _ are bookkeeping' );
  is_deeply( [ $W->diff( { a => { b => 1 } }, {} ) ], [ { path => [ 'a', 'b' ], before => 1 } ], 'diff: a removed hash key by key' );
  is_deeply( [ $W->diff( {}, { n => 2 } ) ], [ { path => ['n'], after => 2 } ], 'diff: new value without before' );
  ok( $W->covered( [qw( lab1 shelf )], [ [qw( lab1 )] ] ), 'path under an allowed prefix' );
  ok( $W->covered( [qw( lab1 keys x )], [ [qw( * keys )] ] ), '* fits one segment' );
  ok( !$W->covered( [qw( lab2 shelf )], [ [qw( lab1 shelf )] ] ), 'another path is not covered' );
  ok( !$W->covered( [qw( lab1 )], [ [qw( lab1 shelf )] ] ), 'a shorter path is not covered' );
  my $conf = [ 'h', 'files', '/etc/app/conf.d/*.ini' ];
  ok( $W->covered( [ 'h', 'files', '/etc/app/conf.d/limits.ini' ], [$conf] ), '* inside a segment' );
  ok( !$W->covered( [ 'h', 'files', '/etc/app/conf.d/x/y.ini' ], [$conf] ), '... not across /' );
  ok( !$W->covered( [ 'h', 'files', '/etc/app/main.ini' ], [$conf] ), '... nothing else' );
  is( $W->path_text( [ 'a', '', 'b c' ] ), 'a[""]["b c"]', 'path_text: empty and spaced segments' );
}

# --- determinism and offer ------------------------------------------------------
{
  my @outs;
  for ( 1 .. 2 ) {
    my $w = $W->new( state => $start, tools => \@tools );
    push @outs, [ map { ( $w->call(@$_) )[0] }
      [ add_book => { room => 'lab1', title => 'Heat', author => 'Cy' } ], [ list_shelf => { room => 'lab1' } ] ];
    push @outs, $w->state;
  }
  is_deeply( $outs[0], $outs[2], 'same calls, same outputs' );
  is_deeply( $outs[1], $outs[3], 'same calls, same state' );
  my $offer = $W->new( state => {}, tools => \@tools )->offer;
  is_deeply( [ sort map { keys %$_ } @$offer ], [ sort( (qw( name description parameters )) x @tools ) ],
    'offer: only name, description, parameters — no handlers' );
}

# --- observations ----------------------------------------------------------------
my $SHELL = [ { name => 'run_command', simulator => 'run_command',
  parameters => { type => 'object', required => [qw( host command )],
    properties => { host => { type => 'string' }, command => { type => 'string' } } } } ];

# an observation at the start of a chain answers only its link
{
  my $w = $W->new(
    state   => { h => { type => 'linux', files => { '/srv/d/a' => "1\n" } } },
    tools   => $SHELL,
    observe => [ { match => { host => '^h$', command => '\A\s*ps\b' }, output => "root 1 init\n" } ],
  );
  my ( $o ) = $w->call( run_command => { host => 'h', command => 'ps aux; ls /srv/d' } );
  is( $o, "root 1 init\n\na", 'chain: observation for ps, simulator for ls' );
  ( $o ) = $w->call( run_command => { host => 'h', command => 'ps aux | grep init' } );
  is( $o, "root 1 init", 'without a chain: observation with a pipe filter' );
  ( $o ) = $w->call( run_command => { host => 'h', command => 'ps aux | grep nothing-here' } );
  is( $o, '', '... the filter drops what does not match' );
}

# a pattern without an end anchor answers only its link
{
  my $w = $W->new(
    state   => { h => { type => 'linux', interfaces => {}, files => { '/etc/motd' => "hello\n" } } },
    tools   => $SHELL,
    observe => [ { match => { host => '^h$', command => '\bping\b' }, output => 'PONG' } ],
  );
  my ( $o ) = $w->call( run_command => { host => 'h', command => 'cat /etc/motd; ping -c1 192.0.2.7; hostname' } );
  is( $o, "hello\nPONG\nh", 'every link of the chain answers itself' );
  ( $o ) = $w->call( run_command => { host => 'h', command => 'ping -c1 192.0.2.7' } );
  is( $o, 'PONG', 'single command: observation' );
  ( $o ) = $w->call( run_command => { host => 'other', command => 'ping -c1 192.0.2.7' } );
  like( $o, qr/Could not resolve hostname other/, 'no observation fits: unknown host answers like ssh' );
}

# error: true ends with a failing status (a blocked connection that times out)
{
  my $w = $W->new(
    state   => { h => { type => 'linux', interfaces => {} } },
    tools   => $SHELL,
    observe => [
      { match => { host => '^h$', command => '\A\s*nc\b' }, output => 'nc: connect to 192.0.2.9 port 7000 (tcp) timed out', error => 1 },
      { match => { host => '^h$', command => '\A\s*probe open\s*\z' }, output => '' },
    ],
  );
  my ( $o, undef, $ok ) = $w->call( run_command => { host => 'h', command => 'nc -zv -w2 192.0.2.9 7000' } );
  is( $o, 'nc: connect to 192.0.2.9 port 7000 (tcp) timed out', 'output of the observation' );
  ok( !$ok, 'error: failing status' );
  ( $o ) = $w->call( run_command => { host => 'h', command => 'nc -zv -w2 192.0.2.9 7000 && echo open; echo next' } );
  is( $o, "nc: connect to 192.0.2.9 port 7000 (tcp) timed out\nnext", 'chain: && after error does not run' );
  ( $o ) = $w->call( run_command => { host => 'h', command => 'nc -zv -w2 192.0.2.9 7000 || echo closed' } );
  is( $o, "nc: connect to 192.0.2.9 port 7000 (tcp) timed out\nclosed", 'chain: || after error runs' );
  ( $o ) = $w->call( run_command => { host => 'h', command => 'nc -zv -w2 192.0.2.9 7000; echo "rc=$?"' } );
  like( $o, qr/\nrc=1\z/, 'chain: $? after error is 1' );
  ( $o ) = $w->call( run_command => { host => 'h', command => 'false; nc -zv -w2 192.0.2.9 7000 || true; echo "rc=$?"' } );
  like( $o, qr/\nrc=0\z/, 'chain: $? after || true is 0' );
  ok( !exists $w->state->{h}{_rc}, 'no _rc trace left in the state' );
  ( $o, undef, $ok ) = $w->call( run_command => { host => 'h', command => 'probe open && echo open' } );
  ok( $ok, 'without error the observation succeeds' );
  is( $o, 'open', '... and the chain goes on' );
}

# an observation never changes the state
{
  my $w = $W->new(
    state   => { h => { type => 'linux', files => {} } },
    tools   => $SHELL,
    observe => [ { match => { host => '^h$', command => 'tail' }, output => "<: \$state.h.type :>\n" } ],
  );
  my $before = $W->clone( $w->state );
  my ( $o ) = $w->call( run_command => { host => 'h', command => 'tail -n 1 /var/log/x' } );
  is( $o, "linux\n", 'an observation renders from the state' );
  is_deeply( $w->state, $before, '... and leaves it as it was' );
}

# a file entry with attributes counts with its text against equals/in, like regex
{
  use Langertha::Holmgang::Expectation qw( condition );
  my $st = { h => { files => { '/a' => { content => "x\n", owner => 'root', mode => '0644' }, '/b' => "x\n" } } };
  my $cond = sub { ( condition( $st, $_[0] ) )[0] };
  ok( $cond->( { path => [ 'h', 'files', '/a' ], equals => "x\n" } ), 'equals: entry with attributes against text' );
  ok( $cond->( { path => [ 'h', 'files', '/b' ], equals => "x\n" } ), 'equals: bare text' );
  ok( !$cond->( { path => [ 'h', 'files', '/a' ], equals => "y\n" } ), 'equals: other text fails' );
  ok( $cond->( { path => [ 'h', 'files', '/a' ], in => [ "y\n", "x\n" ] } ), 'in: entry with attributes against texts' );
}

done_testing;
