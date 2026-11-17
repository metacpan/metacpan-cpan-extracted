#!/usr/bin/env perl
# Building, writing and reading a report of format holmgang_report 1 (ADR 0006).
# All suites, cases and results here are invented (ADR 0003).
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS ();
use Path::Tiny qw( tempdir );

use Langertha::Holmgang::Report;

my $CLASS = 'Langertha::Holmgang::Report';

sub cases {
  return [
    { case_id => 'alpha-01', title => 'Open a port', tags => [ 'netz', 'stufe-16k' ], tier => '16k',
      difficulty => 'mittel', weight => 1, hard => 0, untrusted => 0, state => { secret => 'never' } },
    { case_id => 'alpha-02', title => 'Leave it alone', tags => ['injection'], tier => undef,
      weight => 2.5, hard => 1, untrusted => 1 },
  ];
}

sub results {
  return [
    { case_id => 'alpha-01', repetition => 1, seed => undef, status => 'uncertain', score => 0.5,
      error => undef,
      rules => [
        { title => 'port open', kind => 'state', required => 1, passed => 0, reason => 'missing', sim_gap => undef },
        { title => 'no reboot', kind => 'not_called', required => 1, passed => 1, reason => 'not called' },
      ],
      diff  => [ { path => 'gw.files./etc/x', before => undef, after => "a\n" } ],
      turns => [
        { input_tokens => 100, output_tokens => 10, reasoning_tokens => undef, duration_ms => 30,
          finish_reason => 'tool_calls', calls => 2 },
        { input_tokens => 180, output_tokens => 5, reasoning_tokens => undef, duration_ms => 12,
          finish_reason => 'stop', calls => 0 },
      ],
      calls => [
        { tool => 'run_command', args => { host => 'gw', command => 'ss -tln' }, succeeded => 1, sim_gap => undef },
        { tool => 'run_command', args => { host => 'gw', command => 'frobnicate' }, succeeded => 0,
          sim_gap => 'frobnicate' },
      ],
      forbidden_calls => 0, injection_held => undef,
      transcript => [
        { role => 'system', content => 'sys prompt' },
        { role => 'user', content => 'please', untrusted => 1 },
      ],
      solution => [ 'never in a report' ],
    },
    { case_id => 'alpha-02', repetition => 1, seed => undef, status => 'passed', score => 1,
      rules => [], diff => [], turns => [], calls => [], forbidden_calls => 0, injection_held => 1 },
  ];
}

sub run_args {
  my (%over) = @_;
  return (
    target  => { label => 'mock-a', engine => 'Virtual', model => 'mock-1',
                 url => 'https://user:hunter2@llm.example:8443/v1?api_key=sk-abc&x=1#frag', api_key => 'sk-abc' },
    variant => { name => 'plain', settings => { temperature => 0 } },
    suite   => { id => 'demo-suite', version => 2, topic => 'netz', digest => 'd1' },
    repeat  => 1, status => 'complete', error => undef,
    cases   => cases(), results => results(),
    %over,
  );
}

sub fixed_report {
  my (%arg) = @_;
  my $r = $CLASS->new( generator => { holmgang => '0.001', langertha => '0.504' },
    started_at => '2026-11-04T10:00:00Z', %arg );
  $r->add_run( run_args() );
  $r->finish('2026-11-04T10:05:00Z');
  return $r;
}

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

subtest 'build: fields, derived numbers, null not 0' => sub {
  my $doc = $json->decode( fixed_report()->to_json );
  is $doc->{holmgang_report}, 1, 'format version';
  my $run = $doc->{runs}[0];
  is_deeply [ sort keys %$run ], [qw( cases error repeat status suite target variant )], 'run fields';
  is_deeply $run->{target}, { label => 'mock-a', engine => 'Virtual', model => 'mock-1',
    url => 'https://llm.example:8443/v1?x=1' }, 'target: four fields, credentials gone';
  is $run->{suite}{version}, '2', 'version as text';
  my ( $c1, $c2 ) = @{ $run->{cases} };
  is_deeply [ map { $_->{case_id} } @{ $run->{cases} } ], [qw( alpha-01 alpha-02 )], 'load order';
  ok !exists $c1->{state}, 'case state not copied';
  ok JSON::MaybeXS::is_bool( $c2->{hard} ) && $c2->{hard}, 'hard is a boolean';
  is $c1->{difficulty}, 'mittel', 'difficulty (k57)';
  ok exists $c2->{difficulty} && !defined $c2->{difficulty}, 'no difficulty: null, present';
  my $r = $c1->{repetitions}[0];
  is_deeply [ sort keys %$r ], [ sort qw( repetition seed status score error finish_reason duration_ms rules diff
    turns tokens calls sim_gaps forbidden_calls injection_held transcript ) ], 'every repetition field';
  ok !exists $r->{solution}, 'unknown result key not copied';
  is_deeply $r->{tokens}, { input => 280, output => 15, reasoning => undef, input_max => 180 },
    'tokens summed, reasoning null not 0';
  is $r->{duration_ms}, 42, 'duration = sum of turns';
  is $r->{finish_reason}, 'stop', 'finish_reason of the last turn';
  is_deeply $r->{sim_gaps}, [ { call => 1, tool => 'run_command', gap => 'frobnicate' } ], 'gap with call index';
  ok exists $r->{rules}[1]{sim_gap} && !defined $r->{rules}[1]{sim_gap}, 'absent rule sim_gap is null';
  ok exists $r->{injection_held} && !defined $r->{injection_held}, 'injection_held null';
  ok exists $r->{seed} && !defined $r->{seed}, 'seed null';
  is $r->{transcript}, undef, 'transcript off by default';
  my $r2 = $c2->{repetitions}[0];
  is $r2->{duration_ms}, 0, 'no turns: duration 0';
  is_deeply $r2->{tokens}, { input => undef, output => undef, reasoning => undef, input_max => undef },
    'no turns: tokens null';
  is $r2->{finish_reason}, undef, 'no turns: finish_reason null';
  ok JSON::MaybeXS::is_bool( $r2->{injection_held} ) && $r2->{injection_held}, 'injection_held true';
  is $doc->{started_at}, '2026-11-04T10:00:00Z', 'started_at';
};

subtest 'null for unknown, never absent' => sub {
  my $r = $CLASS->new( started_at => undef );
  $r->add_run( run_args( results => [ { case_id => 'alpha-01', repetition => 1, status => 'error',
    turns => [ { input_tokens => undef, output_tokens => undef, duration_ms => 5 } ] } ] ) );
  my $text = $r->to_json;
  my $rep  = $json->decode($text)->{runs}[0]{cases}[0]{repetitions}[0];
  for my $f (qw( score rules diff calls sim_gaps forbidden_calls transcript )) {
    ok exists $rep->{$f} && !defined $rep->{$f}, $f.' null';
  }
  is_deeply $rep->{tokens}, { input => undef, output => undef, reasoning => undef, input_max => undef },
    'turn without usage: tokens null, not 0';
  ok exists $rep->{turns}[0]{reasoning_tokens} && !defined $rep->{turns}[0]{reasoning_tokens}, 'turn field null';
  like $text, qr/"started_at" : null/, 'started_at null';
  like $text, qr/"finished_at" : null/, 'finished_at null';
  is_deeply $json->decode($text)->{runs}[0]{cases}[1]{repetitions}, [], 'case without results';
  my $r2 = $CLASS->new;
  $r2->add_run( run_args( results => [ { case_id => 'alpha-01', repetition => 1, status => 'error' } ] ) );
  my $rep2 = $json->decode( $r2->to_json )->{runs}[0]{cases}[0]{repetitions}[0];
  ok exists $rep2->{duration_ms} && !defined $rep2->{duration_ms}, 'turns unknown: duration null';
  is $rep2->{turns}, undef, 'turns null';
};

subtest 'round trip and byte identity' => sub {
  my $a = fixed_report();
  my $bytes = $a->to_json;
  is $CLASS->from_json($bytes)->to_json, $bytes, 'from_json(to_json) identical';
  my $dir = tempdir;
  my $file = $dir->child('run.json');
  $a->write($file);
  is $file->slurp_raw, $bytes, 'write gives to_json';
  is $CLASS->read($file)->to_json, $bytes, 'read(write) identical';
  is fixed_report()->to_json, $bytes, 'same input, same bytes';

  # different volatile fields: only those differ
  my $b = $CLASS->new( started_at => '2026-11-05T08:00:00Z' );
  my %args = run_args();
  $_->{duration_ms} += 7 for map { @{ $_->{turns} || [] } } @{ $args{results} };
  $b->add_run(%args);
  $b->finish;
  my $da = $json->decode($bytes);
  my $db = $json->decode( $b->to_json );
  isnt $b->to_json, $bytes, 'bytes differ';
  for my $d ( $da, $db ) {
    delete @{$d}{qw( generator started_at finished_at )};
    for my $rep ( map { @{ $_->{repetitions} } } map { @{ $_->{cases} } } @{ $d->{runs} } ) {
      delete $rep->{duration_ms};
      delete $_->{duration_ms} for @{ $rep->{turns} || [] };
    }
  }
  is $json->encode($db), $json->encode($da), 'identical apart from volatile fields';
};

subtest 'transcript switch' => sub {
  my $r = $CLASS->new( with_transcript => 1 );
  $r->add_run( run_args() );
  my $t = $json->decode( $r->to_json )->{runs}[0]{cases}[0]{repetitions}[0]{transcript};
  is_deeply $t, [ { role => 'user', content => 'please' } ], 'system dropped, untrusted stripped';
  my $img = $CLASS->image_entry( 'scan.png', "\x89PNG\r\n\x1a\nxxxx" );
  is_deeply $img, { image => 'scan.png', bytes => 12,
    sha256 => Digest::SHA::sha256_hex("\x89PNG\r\n\x1a\nxxxx") }, 'image_entry';
  my %args = run_args();
  $args{results}[0]{transcript} = [ { role => 'user', content => [ { type => 'text', text => 'look' }, $img ] } ];
  my $r2 = $CLASS->new( with_transcript => 1 );
  $r2->add_run(%args);
  is_deeply $json->decode( $r2->to_json )->{runs}[0]{cases}[0]{repetitions}[0]{transcript}[0]{content}[1], $img,
    'placeholder kept';
};

subtest 'no image content' => sub {
  my $png64 = 'iVBORw0KGgo' . ( 'A' x 2000 );
  my @bad = (
    [ 'data: URL in call args', sub { $_[0]{results}[0]{calls}[0]{args}{url} = 'data:image/png;base64,iVBORw0KGgo=' } ],
    [ 'data: URL in a rule reason', sub { $_[0]{results}[0]{rules}[0]{reason} = 'saw data:text/plain;base64,aGk=' } ],
    [ 'base64 run in transcript', sub { $_[0]{results}[0]{transcript} = [ { role => 'user', content => $png64 } ] } ],
    [ 'anthropic image block', sub { $_[0]{results}[0]{transcript} = [ { role => 'user', content => [
      { type => 'image', source => { type => 'base64', media_type => 'image/png', data => 'iVBO' } } ] } ] } ],
    [ 'openai image_url', sub { $_[0]{results}[0]{transcript} = [ { role => 'user', content => [
      { type => 'image_url', image_url => { url => 'data:image/jpeg;base64,/9j/' } } ] } ] } ],
    [ 'gemini inline_data', sub { $_[0]{results}[0]{transcript} = [ { inline_data => { data => 'x' } } ] } ],
    [ 'object', sub { $_[0]{results}[0]{transcript} = [ { role => 'user', content => [ bless {}, 'Langertha::Content::Image' ] } ] } ],
  );
  for my $case (@bad) {
    my %args = run_args();
    $case->[1]->( \%args );
    my $r = $CLASS->new( with_transcript => 1 );
    ok !eval { $r->add_run(%args); 1 }, $case->[0].' refused';
    like $@, qr/data: URL|base64|object/, $case->[0].': says why';
  }
  my $doc = $json->decode( fixed_report()->to_json );
  $doc->{runs}[0]{cases}[0]{repetitions}[0]{calls}[0]{args}{x} = 'data:image/gif;base64,R0lG';
  ok !eval { $CLASS->from_json( $json->encode($doc) ); 1 }, 'read refuses a data: URL';
  like $@, qr/calls\[0\]\.args\.x holds a data: URL/, 'with the path';
};

subtest 'credentials stay out' => sub {
  my $text = fixed_report()->to_json;
  unlike $text, qr/hunter2|sk-abc|user:|frag/, 'no password, key, user info or fragment';
  my $r = $CLASS->new;
  $r->add_run( run_args( target => { label => 'x', url => 'http://10.0.0.5:8000/v1?token=t1&access_token=t2' } ) );
  is $json->decode( $r->to_json )->{runs}[0]{target}{url}, 'http://10.0.0.5:8000/v1', 'query of credentials dropped';
  ok exists $json->decode( $r->to_json )->{runs}[0]{target}{engine}, 'missing target field present as null';
};

subtest 'add_run refuses' => sub {
  my @bad = (
    [ 'unknown case', { results => [ { case_id => 'nope', repetition => 1, status => 'passed' } ] }, qr/unknown case nope/ ],
    [ 'repetition twice', { results => [ ( { case_id => 'alpha-01', repetition => 1, status => 'passed' } ) x 2 ] }, qr/given twice/ ],
    [ 'beyond repeat', { results => [ { case_id => 'alpha-01', repetition => 2, status => 'passed' } ] }, qr/beyond repeat 1/ ],
    [ 'unknown status', { results => [ { case_id => 'alpha-01', repetition => 1, status => 'ungraded' } ] }, qr/unknown value 'ungraded'/ ],
    [ 'score above 1', { results => [ { case_id => 'alpha-01', repetition => 1, status => 'passed', score => 2 } ] }, qr/at most 1/ ],
    [ 'bad run status', { status => 'done' }, qr/status: unknown value 'done'/ ],
    [ 'no target', { target => undef }, qr/target must not be null/ ],
    [ 'text tokens', { results => [ { case_id => 'alpha-01', repetition => 1, status => 'passed',
      turns => [ { input_tokens => 'many' } ] } ] }, qr/input_tokens must be an integer/ ],
  );
  for my $b (@bad) {
    ok !eval { $CLASS->new->add_run( run_args( %{ $b->[1] } ) ); 1 }, $b->[0];
    like $@, $b->[2], $b->[0].': message';
  }
  my $r = $CLASS->new;
  $r->add_run( run_args( repeat => 2, results => [
    { case_id => 'alpha-01', repetition => 2, status => 'failed' },
    { case_id => 'alpha-01', repetition => 1, status => 'passed' },
  ] ) );
  is_deeply [ map { $_->{repetition} } @{ $r->runs->[0]{cases}[0]{repetitions} } ], [ 1, 2 ], 'sorted by number';
};

subtest 'reading validates' => sub {
  my $doc = $json->decode( fixed_report()->to_json );
  my $try = sub {
    my ($mod) = @_;
    my $d = $json->decode( $json->encode($doc) );
    $mod->($d);
    return eval { $CLASS->from_json( $json->encode($d), source => 'x.json' ); 1 } ? '' : $@;
  };
  like $try->( sub { $_[0]{holmgang_report} = 2 } ), qr/x\.json: unknown report version 2 \(this reader knows up to 1\)/,
    'higher version refused';
  like $try->( sub { delete $_[0]{holmgang_report} } ), qr/not a Holmgang report/, 'no version';
  like $try->( sub { $_[0]{holmgang_report} = '1.5' } ), qr/positive integer/, 'odd version';
  like $try->( sub { delete $_[0]{runs}[0]{cases}[0]{repetitions}[0]{tokens}{reasoning} } ),
    qr/x\.json\.runs\[0\]\.cases\[0\]\.repetitions\[0\]\.tokens\.reasoning is missing/, 'missing field';
  # k57: difficulty came to format 1 later; a report written before it still reads
  is $try->( sub { delete $_[0]{runs}[0]{cases}[$_]{difficulty} for 0, 1 } ), '', 'report without difficulty reads';
  my $old = $json->decode( $json->encode($doc) );
  delete $_->{difficulty} for @{ $old->{runs}[0]{cases} };
  my $read = $CLASS->from_json( $json->encode($old) );
  ok exists $read->runs->[0]{cases}[0]{difficulty} && !defined $read->runs->[0]{cases}[0]{difficulty},
    '... and has it as null';
  like $try->( sub { delete $_[0]{runs}[0]{cases}[0]{tier} } ), qr/cases\[0\]\.tier is missing/,
    'other case fields still required';
  like $try->( sub { $_[0]{runs}[0]{cases}[0]{repetitions}[0]{rules}[0]{passed} = 0 } ),
    qr/passed must be a JSON boolean/, 'boolean as number refused';
  like $try->( sub { $_[0]{runs}[0]{cases}[0]{repetitions}[0]{status} = 'ungraded' } ),
    qr/unknown value 'ungraded'/, 'old status name refused';
  is $try->( sub { $_[0]{later_field} = 1; $_[0]{runs}[0]{cases}[0]{shiny} = [] } ), '', 'unknown fields ignored';
  ok !eval { $CLASS->from_json('{nope'); 1 }, 'not JSON';
};

done_testing;
