#!/usr/bin/env perl
# Langertha::Holmgang::Batch (k15): suites x targets x variants x repeat, a
# bounded number of open requests per target, resume, cancel, variants that
# reach the request, run errors through Target::scrub. Network-free:
# Langertha::Engine::Virtual and test engines over it; invented suites only
# (ADR 0003).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Test::Fatal qw( exception );
use JSON::MaybeXS ();
use Moose::Util ();

use Holmgang::SuiteDir qw( suite_dir loader $FAN_CASE );
use Holmgang::HeldEngine;
use Langertha::Engine::Virtual;
use Langertha::Virtual::Rules qw( answer tool after error );
use Langertha::Holmgang::Batch;
use Langertha::Holmgang::Report;
use Langertha::Holmgang::Runner;

my $JSON = JSON::MaybeXS->new( canonical => 1, utf8 => 0 );

# a fan suite with n cases c1..cn; the state carries a value the model must never see
my $CASE = $FAN_CASE =~ s/state: \{ fan: \{ level: off \} \}/state: { fan: { level: off }, vault: { pin: STATE-PIN-4711 } }/r;
sub fan_suite {
  my ( $id, $n ) = @_;
  my $dir = suite_dir( id => $id, cases => { map { ( "c$_.yaml" => $CASE =~ s/^id: c1$/id: c$_/mr ) } 1 .. $n } );
  return loader()->load($dir);
}

# a shared engine that plays every case right, whatever the order: a tool
# call first, the answer after the tool result
sub fan_rules { ( rules => [ after('fan_set') => answer('done'), qr/./ => tool( fan_set => { level => 'high' } ) ] ) }

sub statuses {
  my ( $run ) = @_;
  return { map { my $c = $_; ( $c->{case_id} => [ map { $_->{status} } @{ $c->{repetitions} } ] ) } @{ $run->{cases} } };
}

my $s2 = fan_suite( 'batch-two', 2 );
my $s5 = fan_suite( 'batch-five', 5 );

# drive a batch whose engines hold their answers until released
sub drive {
  my ( $batch, @engines ) = @_;
  my $f = $batch->{_run_f} // $batch->run_f;   # a batch the test started already
  while ( !$f->is_ready ) {
    my $released = 0;
    $released += $_->release for @engines;
    last unless $released;
  }
  ok( $f->is_done, 'the batch finished' ) or diag( $f->is_failed ? $f->failure : 'still pending' );
  return $f->get;
}

subtest 'repeat: every case n times, one run per suite' => sub {
  my @events;
  my $batch = Langertha::Holmgang::Batch->new(
    suites   => [ $s2, $s5 ],
    targets  => [ { target => { label => 'mock' }, engine => sub { Langertha::Holmgang::Runner->mock_engine( $_[0], 'solution' ) } } ],
    repeat   => 3,
    on_event => sub { push @events, $_[0] },
  );
  my $report = $batch->run;
  is( scalar @{ $report->runs }, 2, 'two suites, one target, one variant: two runs' );
  my ( $a, $b ) = @{ $report->runs };
  is( $a->{suite}{id}, 'batch-two', '... in the order of the suites' );
  is_deeply( statuses($a), { c1 => [ ('passed') x 3 ], c2 => [ ('passed') x 3 ] }, '... three repetitions of each case' );
  is( $b->{repeat}, 3, '... repeat in the run' );
  is_deeply( [ map { $_->{repetition} } @{ $b->{cases}[4]{repetitions} } ], [ 1, 2, 3 ], '... numbered 1..3' );
  is( $a->{status}, 'complete', '... complete' );
  is_deeply( $a->{variant}, { name => 'default', settings => {} }, '... the default variant' );
  is( scalar( grep { $_->{type} eq 'result' } @events ), 21, 'one result event per case and repetition' );
  is_deeply( [ map { $_->{case}->id.'#'.$_->{repetition} } grep { $_->{suite}->id eq 'batch-two' } @events ],
    [ 'c1#1', 'c2#1', 'c1#2', 'c2#2', 'c1#3', 'c2#3' ], '... one at a time: repetition outer, cases in load order' );
  ok( defined $report->finished_at, 'the final report is finished' );

  my $own = Langertha::Holmgang::Batch->new( suites => [ fan_suite( 'batch-rep', 1 ) ],
    targets => [ { engine => sub { Langertha::Holmgang::Runner->mock_engine( $_[0], 'solution' ) } } ] )->run;
  is( $own->runs->[0]{repeat}, 1, 'without repeat: the suite\'s own, else 1' );
};

subtest 'concurrency: at most n open requests per target' => sub {
  for my $n ( 1, 2, 4 ) {
    my $e = Holmgang::HeldEngine->new( fan_rules() );
    my %slots;
    my $batch = Langertha::Holmgang::Batch->new(
      suites  => [$s5],
      targets => [ { engine => sub { $slots{ $_[1] }++; $e }, concurrency => $n } ],
    );
    my $report = drive( $batch, $e );
    is( $e->most, $n, "concurrency $n: exactly $n requests open at the most" );
    is_deeply( [ sort keys %slots ], [ grep { $_ < $n } 0 .. 3 ], "... the cases ran on slots 0..".( $n - 1 ) );
    is_deeply( statuses( $report->runs->[0] ), { map { ( "c$_" => ['passed'] ) } 1 .. 5 }, '... every case passed' );
    is( scalar @{ $e->requests }, 10, '... two requests per case' );
  }

  # two targets side by side, each bounded on its own
  my ( $x, $y ) = map { Holmgang::HeldEngine->new( fan_rules() ) } 1 .. 2;
  my $batch = Langertha::Holmgang::Batch->new(
    suites  => [$s5],
    targets => [
      { target => { label => 'x' }, engine => $x, concurrency => 3 },
      { target => { label => 'y' }, engine => $y, concurrency => 1 },
    ],
  );
  my $f = $batch->run_f;
  is( $x->in_flight + $y->in_flight, 4, 'two targets start together: 3 + 1 open requests' );
  my $report = drive( $batch, $x, $y );
  is( $x->most, 3, '... x never more than 3' );
  is( $y->most, 1, '... y never more than 1' );
  is_deeply( [ map { $_->{target}{label} } @{ $report->runs } ], [qw( x y )], '... one run per target, in order' );
};

subtest 'variants: named, checked, and on the wire' => sub {
  # a Virtual that takes a temperature and a reasoning effort, as a real
  # OpenAI-compatible server does
  my $e = Langertha::Engine::Virtual->new( fan_rules() );
  Moose::Util::apply_all_roles( $e, 'Langertha::Role::Temperature', 'Langertha::Role::ReasoningEffort' );
  my $batch = Langertha::Holmgang::Batch->new(
    suites  => [$s2],
    targets => [ {
      engine   => $e,
      variants => [
        { name => 'plain' },
        { name => 'think-off', settings => { enable_thinking => 'off', reasoning_effort => 'high', max_tokens => '77', temperature => '0.3' } },
      ],
    } ],
  );
  my $report = $batch->run;
  is_deeply( [ map { $_->{variant}{name} } @{ $report->runs } ], [qw( plain think-off )], 'one run per variant' );
  my $settings = $report->runs->[1]{variant}{settings};
  is( $JSON->encode($settings), '{"enable_thinking":false,"max_tokens":77,"reasoning_effort":"high","temperature":0.3}',
    '... the settings normalised in the report' );
  my @bodies = map { $_->{body} } @{ $e->requests };
  is( scalar @bodies, 8, '2 variants x 2 cases x 2 turns' );
  my ( @plain ) = @bodies[ 0 .. 3 ];
  my ( @think ) = @bodies[ 4 .. 7 ];
  ok( !( grep { exists $_->{chat_template_kwargs} || exists $_->{reasoning_effort} } @plain ), 'plain: no thinking settings go out' );
  is_deeply( [ map { $_->{max_tokens} } @plain ], [ (2000) x 4 ], '... the case\'s max_tokens (the format 2 default)' )
    or diag $JSON->encode( [ map { $_->{max_tokens} } @plain ] );
  for my $b ( @think ) {
    is( $JSON->encode( $b->{chat_template_kwargs} ), '{"enable_thinking":false}', 'think-off: enable_thinking as chat_template_kwargs' );
    is( $b->{reasoning_effort}, 'high', '... reasoning_effort' );
    is( $b->{max_tokens}, 77, '... max_tokens beats the case\'s' );
    is( $b->{temperature}, 0.3, '... temperature beats the case\'s' );
  }
};

subtest 'variants: what is refused' => sub {
  my $mock = sub { Langertha::Holmgang::Runner->mock_engine( $_[0], 'solution' ) };
  my $new = sub { my ( $settings ) = @_;
    exception { Langertha::Holmgang::Batch->new( suites => [$s2], targets => [ { engine => $mock, variants => [ { name => 'v', settings => $settings } ] } ] ) } };
  like( $new->( { thinking => 'disabled' } ), qr/variant\.thinking: unknown setting/, 'an unknown setting' );
  like( $new->( { enable_thinking => 'maybe' } ), qr/variant\.enable_thinking: on or off/, 'enable_thinking neither on nor off' );
  like( $new->( { reasoning_effort => 'extreme' } ), qr/variant\.reasoning_effort: one of/, 'an effort Langertha does not know' );
  like( $new->( { max_tokens => 0 } ), qr/variant\.max_tokens/, 'max_tokens 0' );
  like( $new->( { max_tokens => '12.5' } ), qr/variant\.max_tokens/, 'max_tokens not whole' );
  like( $new->( { temperature => 3 } ), qr/variant\.temperature: a number from 0 to 2/, 'temperature above 2' );
  like( $new->( { deadline => 0 } ), qr/variant\.deadline: seconds/, 'deadline 0' );
  # against the engine: the mock takes neither, and runs on no loop
  like( $new->( { temperature => 0.5 } ), qr/variant\.temperature: the engine Langertha::Engine::Virtual .*takes no temperature/,
    'a temperature the engine would drop' );
  like( $new->( { reasoning_effort => 'low' } ), qr/variant\.reasoning_effort: .*takes no reasoning_effort/, 'a reasoning effort it would drop' );
  like( $new->( { deadline => 30 } ), qr/variant\.deadline: .*no event loop/, 'a deadline on an engine without a loop' );
  is( $new->( { max_tokens => 100, enable_thinking => 'on' } ), undef, 'max_tokens and enable_thinking on an OpenAI-compatible mock' );
  like( exception { Langertha::Holmgang::Batch->new( suites => [$s2],
      targets => [ { engine => $mock, variants => [ { name => 'a' }, { name => 'a' } ] } ] ) },
    qr/variant a named twice/, 'a variant name twice' );
};

subtest 'resume: an interrupted run continues and skips what has a result' => sub {
  my $mock = sub { Langertha::Holmgang::Runner->mock_engine( $_[0], 'solution' ) };
  my %target = ( target => { label => 'mock', engine => 'Virtual' }, engine => $mock );
  my $first;
  $first = Langertha::Holmgang::Batch->new(
    suites   => [ $s2, $s5 ],
    targets  => [ \%target ],
    repeat   => 2,
    on_event => sub { $first->cancel if $_[0]{type} eq 'result' && $_[0]{suite}->id eq 'batch-five' && $_[0]{case}->id eq 'c2' },
  );
  my $cancelled = $first->run;
  my ( $done, $cut ) = @{ $cancelled->runs };
  is( $done->{status}, 'complete', 'the first run finished before the cancel' );
  is( $cut->{status}, 'cancelled', 'the second was cancelled' );
  is_deeply( statuses($cut), { c1 => ['passed'], c2 => ['passed'], map { ( "c$_" => [] ) } 3 .. 5 },
    '... with the results it had' );

  # through a file, as holmgang run --resume reads it
  my $file = Path::Tiny->tempfile;
  $cancelled->write("$file");
  my @played;
  my $second = Langertha::Holmgang::Batch->new(
    suites   => [ $s2, $s5 ],
    targets  => [ \%target ],
    repeat   => 2,
    resume   => Langertha::Holmgang::Report->read("$file"),
    on_event => sub { push @played, $_[0]{suite}->id.' '.$_[0]{case}->id.'#'.$_[0]{repetition} if $_[0]{type} eq 'result' },
  );
  my $resumed = $second->run;
  is_deeply( \@played, [ map { "batch-five $_" } 'c3#1', 'c4#1', 'c5#1', 'c1#2', 'c2#2', 'c3#2', 'c4#2', 'c5#2' ],
    'only the repetitions without a result are played' );
  is_deeply( [ map { $_->{status} } @{ $resumed->runs } ], [qw( complete complete )], 'both runs complete now' );
  is_deeply( statuses( $resumed->runs->[1] ), { map { ( "c$_" => [qw( passed passed )] ) } 1 .. 5 }, '... every repetition there' );
  is( $resumed->runs->[1]{error}, undef, '... no run error' );
  is( $resumed->started_at, $cancelled->started_at, '... started when the first part started' );
  is( $JSON->encode( Langertha::Holmgang::Report->_stable( $resumed->runs->[0]{cases}[0]{repetitions}[0] ) ),
      $JSON->encode( Langertha::Holmgang::Report->_stable( $done->{cases}[0]{repetitions}[0] ) ),
    'a result taken over is the earlier one' );

  # a checkpoint written while the batch runs is resumable too
  my $snap;
  my $b3;
  $b3 = Langertha::Holmgang::Batch->new( suites => [$s2], targets => [ \%target ],
    on_event => sub { $snap //= $b3->report->to_json if $_[0]{type} eq 'result' } );
  $b3->run;
  my $cp = Langertha::Holmgang::Report->from_json($snap);
  is( $cp->runs->[0]{status}, 'aborted', 'a checkpoint marks a run in play aborted' );
  like( $cp->runs->[0]{error}, qr/\Aunfinished: /, '... as unfinished' );
  is( $cp->finished_at, undef, '... and is not finished' );
  my @again;
  Langertha::Holmgang::Batch->new( suites => [$s2], targets => [ \%target ], resume => $cp,
    on_event => sub { push @again, $_[0]{case}->id if $_[0]{type} eq 'result' } )->run;
  is_deeply( \@again, ['c2'], '... and resuming it plays the rest' );

  # what a resume refuses
  my $refuse = sub { my ( %o ) = @_;
    exception { Langertha::Holmgang::Batch->new( suites => [ $s2, $s5 ], targets => [ \%target ], repeat => 2, resume => $cancelled, %o ) } };
  like( $refuse->( repeat => 3 ), qr/has repeat 2, this batch 3/, 'another repeat' );
  like( exception { Langertha::Holmgang::Batch->new( suites => [$s2], targets => [ \%target ], repeat => 2, resume => $cancelled ) },
    qr/run of suite batch-five.*this batch does not cover/, 'a run the batch does not cover' );
  my $changed = loader()->load( suite_dir( id => 'batch-two',
    root => Path::Tiny->tempdir, cases => { 'c1.yaml' => $CASE, 'c2.yaml' => ( $CASE =~ s/^id: c1$/id: c2/mr =~ s/Cool the room/Cool it/r ) } ) );
  like( exception { Langertha::Holmgang::Batch->new( suites => [ $changed, $s5 ], targets => [ \%target ], repeat => 2, resume => $cancelled ) },
    qr/suite batch-two has changed since the earlier report/, 'a suite that changed since' );
  like( $refuse->( targets => [ { %target, target => { label => 'other' } } ] ), qr/does not cover/, 'another target' );
};

# an engine whose tool results break like a program error, with its key, a
# host path and a Perl location in the text
{
  package Local::KeyLeakEngine;
  use Moose;
  extends 'Langertha::Engine::Virtual';
  sub format_tool_results {
    my ( $self ) = @_;
    die 'tool results broke with key '.$self->api_key.' near /home/someone/secret/notes.txt at /home/someone/secret/Engine.pm line 7.'."\n";
  }
  __PACKAGE__->meta->make_immutable;
}

subtest 'a run error goes through Target::scrub, the other runs go on' => sub {
  my $key = 'hgtest0batch0key0invented0do0not0use';
  my @aborted;
  my $batch = Langertha::Holmgang::Batch->new(
    suites   => [ $s2, $s5 ],
    targets  => [ { engine => sub {
      $_[0]->id eq 'c1'
        ? Local::KeyLeakEngine->new( api_key => $key, fan_rules() )
        : Langertha::Engine::Virtual->new( fan_rules() )
    } } ],
    on_event => sub { push @aborted, $_[0] if $_[0]{type} eq 'aborted' },
  );
  my $report = $batch->run;
  my ( $a, $b ) = @{ $report->runs };
  is( $a->{status}, 'aborted', 'the run whose case threw is aborted' );
  is( $a->{error}, 'tool results broke with key *** near <path>', '... its error scrubbed: no key, no path, no location' );
  is_deeply( statuses($a), { c1 => [], c2 => [] }, '... and no further case of it started' );
  is( $aborted[0]{error}, $a->{error}, '... the event carries the scrubbed text' );
  is( $aborted[0]{case}->id, 'c1', '... and the case' );
  is( $b->{status}, 'aborted', 'the next suite\'s run ran (and broke on its own c1)' );
  unlike( $report->to_json, qr/\Q$key\E|\/home\/someone/, 'neither key nor host path anywhere in the report' );
};

subtest 'errors are cut to 2000 characters' => sub {
  my $long = 'x' x 5000;
  my $report = Langertha::Holmgang::Batch->new( suites => [$s2],
    targets => [ { engine => sub { Langertha::Engine::Virtual->new( rules => [ qr/./ => error( 500, $long ) ] ) } } ] )->run;
  my $r = $report->runs->[0]{cases}[0]{repetitions}[0];
  is( $r->{status}, 'error', 'the target failed: status error' );
  is( length $r->{error}, 2000, '... its error cut to 2000 characters' );
};

subtest 'the model sees only system prompt, messages and tool schemas' => sub {
  my $e = Holmgang::HeldEngine->new( fan_rules() );
  drive( Langertha::Holmgang::Batch->new( suites => [$s5], targets => [ { engine => $e, concurrency => 3,
    variants => [ { name => 'v', settings => { max_tokens => 50, enable_thinking => 1 } } ] } ] ), $e );
  my %allowed = map { $_ => 1 } qw( model messages tools max_tokens temperature stream chat_template_kwargs );
  for my $req ( @{ $e->requests } ) {
    my $body = $req->{body};
    my @extra = grep { !$allowed{$_} } sort keys %$body;
    is_deeply( \@extra, [], 'request '.$req->{number}.': nothing beyond messages, tools and controls' );
    is_deeply( [ map { [ sort keys %{ $_->{function} } ] } @{ $body->{tools} } ], [ ( [qw( description name parameters )] ) x 2 ],
      '... tools: name, description, parameters' );
    my $wire = $JSON->encode($body);
    unlike( $wire, qr/STATE-PIN-4711|unchanged_except|wrong_solutions|untrusted|"rules"/, '... no state, rule, solution or mark' );
  }
};

subtest 'deadline: a request that runs out is an error, and is cancelled' => sub {
  plan skip_all => 'IO::Async is not installed' unless eval { require IO::Async::Loop; 1 };
  require Holmgang::StallEngine;
  my $e = Holmgang::StallEngine->new( loop => IO::Async::Loop->new, fan_rules() );
  my $report = Langertha::Holmgang::Batch->new( suites => [ fan_suite( 'batch-slow', 1 ) ],
    targets => [ { engine => $e, variants => [ { name => 'quick', settings => { deadline => 0.2 } } ] } ] )->run;
  my $r = $report->runs->[0]{cases}[0]{repetitions}[0];
  is( $r->{status}, 'error', 'status error' );
  is( $r->{error}, 'timeout: deadline (0.2 s)', '... the deadline named' );
  is( $e->cancelled, 1, '... the open request was cancelled' );
  is( scalar @{ $e->requests }, 1, '... one request went out' );
  is( $report->runs->[0]{variant}{settings}{deadline}, 0.2, '... the deadline in the variant' );
};

done_testing;
