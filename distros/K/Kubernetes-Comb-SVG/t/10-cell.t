#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;
use Path::Tiny;

use Kubernetes::Comb::SVG::Cell;

my $CELL = 'Kubernetes::Comb::SVG::Cell';
my $data = path(__FILE__)->parent->child( 'data', 'cell' );
my $json = JSON::MaybeXS->new( utf8 => 1 );

sub cr { $json->decode( $data->child( $_[0].'.json' )->slurp_raw ) }

sub dies_like {
  my ( $code, $re, $name ) = @_;
  my $ok = eval { $code->(); 1 };
  my $error = $@;
  ok( !$ok, $name.' dies' );
  like( $error, $re, $name.' says why' );
}

#### One fixture per row of the SPEC §3 table

subtest 'metadata.name' => sub {
  my $cell = $CELL->from_cr( cr('name') );
  isa_ok( $cell, $CELL );
  is( $cell->name, 'nats', 'name' );
  is( $cell->namespace, undef, 'no namespace' );
  is( $cell->id, 'nats', 'id is the name without a namespace' );
  is_deeply( $cell->dependencies, [], 'no resolved dependencies' );
  is_deeply( $cell->missing,      [], 'nothing missing' );
  is( $cell->class,     undef, 'no class' );
  is( $cell->phase, 'Unknown', 'missing status is Unknown' );
  is( $cell->raw_phase, undef, 'no raw phase' );
  ok( $cell->enabled, 'enabled when spec.enabled is unset' );
  is_deeply( $cell->depends_on, [], 'no dependencies' );
  is_deeply( $cell->endpoints,  [], 'no endpoints' );
  ok( !$cell->borrowed, 'not borrowed' );
  ok( !$cell->upstream_recorded, 'no upstream recorded' );
  is( $cell->upstream_class,   undef, 'no upstream class' );
  is( $cell->upstream_context, undef, 'no upstream context' );
  is_deeply( $cell->upstream_via, [], 'no upstream via' );
  is( $cell->group,   undef, 'no group' );
  is( $cell->message, undef, 'no message' );
};

subtest 'metadata.namespace' => sub {
  my $cell = $CELL->from_cr( cr('namespace') );
  is( $cell->namespace, 'platform', 'namespace' );
  is( $cell->id, 'platform/'.$cell->name, 'id is namespace/name' );
};

subtest 'metadata.labels.<group_label>' => sub {
  my $cr = cr('group-label');
  is( $CELL->from_cr( $cr, group_label => 'app.kubernetes.io/part-of' )->group,
    'messaging', 'group from the configured label' );
  is( $CELL->from_cr( $cr, group_label => 'tier' )->group,
    'backend', 'another label key' );
  is( $CELL->from_cr($cr)->group, undef, 'no group without group_label' );
  is( $CELL->from_cr( $cr, group_label => 'absent' )->group,
    undef, 'no group when the label is absent' );
  is( $CELL->from_cr( cr('name'), group_label => 'tier' )->group,
    undef, 'no group without labels' );
};

subtest 'spec.class' => sub {
  is( $CELL->from_cr( cr('class') )->class, 'MyApp::Comb::NATS', 'class' );
};

subtest 'spec.enabled' => sub {
  my $cell = $CELL->from_cr( cr('disabled') );
  ok( !$cell->enabled, 'not enabled' );
  is( $cell->phase, 'Disabled', 'Disabled without a status' );
  is( $cell->raw_phase, undef, 'no raw phase' );

  $cell = $CELL->from_cr( cr('disabled-with-status') );
  is( $cell->phase, 'Disabled', 'Disabled wins over the status phase' );
  is( $cell->raw_phase, 'Running', 'status phase kept' );
  is( $cell->message, 'switched off', 'message of a disabled Comb' );

  $cell = $CELL->from_cr( cr('enabled') );
  ok( $cell->enabled, 'enabled: true' );
  is( $cell->phase, 'Running', 'phase from the status' );

  for my $false ( 0, '', 'false', 'False' ) {
    my $cr = cr('enabled');
    $cr->{spec}{enabled} = $false;
    is( $CELL->from_cr($cr)->phase, 'Disabled', 'enabled "'.$false.'" is off' );
  }
  my $cr = cr('enabled');
  $cr->{spec}{enabled} = undef;
  is( $CELL->from_cr($cr)->phase, 'Running', 'enabled null is automatic' );
};

subtest 'spec.dependsOn' => sub {
  is_deeply( $CELL->from_cr( cr('depends-on') )->depends_on,
    [ 'db', 'nats' ], 'names in order, duplicates dropped' );
  my $cell = $CELL->from_cr( cr('depends-on') );
  is_deeply( $cell->dependencies, [], 'a cell built alone resolves nothing' );
  is_deeply( $cell->missing,      [], 'a cell built alone misses nothing' );
};

subtest 'status.phase' => sub {
  for my $phase ( $CELL->known_phases ) {
    my $cr = cr('phase');
    $cr->{status}{phase} = $phase;
    my $cell = $CELL->from_cr($cr);
    is( $cell->phase,     $phase, $phase );
    is( $cell->raw_phase, $phase, $phase.' raw' );
  }
  is_deeply( [ $CELL->known_phases ],
    [qw( Running Pending Blocked NeedsConfig Disabled Error Stopped NotDeployed )],
    'known phases, in the order of CombStatus' );
  for my $phase (qw( Stopped NotDeployed )) {
    ok( $CELL->is_known_phase($phase), $phase.' is a known phase' );
    my $cr = cr('disabled-with-status');
    $cr->{status}{phase} = $phase;
    my $cell = $CELL->from_cr($cr);
    is( $cell->phase,     'Disabled', $phase.': spec.enabled false still gives Disabled' );
    is( $cell->raw_phase, $phase,     $phase.': status phase kept' );
  }

  my $cell = $CELL->from_cr( cr('phase-unknown') );
  is( $cell->phase, 'Unknown', 'unknown string is Unknown' );
  is( $cell->raw_phase, 'Hibernating', 'original text kept' );

  my $cr = cr('phase');
  $cr->{status}{phase} = 'running';
  is( $CELL->from_cr($cr)->phase, 'Unknown', 'phases are case-sensitive' );
};

subtest 'status.conditions[].message' => sub {
  is( $CELL->from_cr( cr('conditions') )->message,
    "waiting for db\nnothing deployed yet",
    'messages in order, one per line, duplicates dropped' );
  is( $CELL->from_cr( cr('conditions-running') )->message,
    undef, 'no message while Running' );
};

subtest 'status.conditions[].reason' => sub {
  my $crs    = cr('reasons');
  my $reason = sub { $CELL->from_cr( $crs->{ $_[0] } )->reason };

  is( $CELL->from_cr( cr('conditions') )->reason, 'DependencyNotReady', 'the reason of the Ready condition' );
  is( $CELL->from_cr( cr('conditions-running') )->reason, undef, 'no reason while Running' );
  is( $reason->('running'), undef, 'Running: none, whatever the conditions say' );
  is( $CELL->from_cr( cr('name') )->reason, undef, 'no status: none' );
  is( $reason->('no-conditions'), undef, 'no conditions: none' );

  is( $reason->('ready-first'), 'DeployFailed', 'Ready wins over an earlier condition that is not True' );
  is( $reason->('ready-true'), 'Deployed', 'Ready is taken even when it is True' );
  is( $reason->('needs-config'), 'MissingPrerequisites', 'NeedsConfig as Kubernetes::Comb writes it' );
  is( $reason->('first-not-true'), 'UpstreamUnreachable', 'without Ready: the first condition that is not True' );
  is( $reason->('all-true'), undef, 'without Ready and all True: none' );

  is( $reason->('not-checked'), 'dependencies not looked at yet', 'NotChecked tells nothing: the message stands in' );
  is( $reason->('not-checked-alone'), undef, 'NotChecked without a message: none, no other condition is asked' );

  is( $reason->('disabled'), 'disabled by spec.enabled', 'a reason that repeats the phase: the message stands in' );
  is( $reason->('stopped'), undef, 'reason and message both repeat the phase: none' );
  is( $reason->('not-deployed'), undef, 'repeating is judged without case and punctuation, on the first line' );
  is( $reason->('raw-phase'), 'asleep until Monday', 'a reason that repeats the raw phase' );
  is( $reason->('unknown-repeated'), undef, 'and one that repeats the phase the cell is drawn in' );

  is( $reason->('multi-line'), 'helm upgrade failed', 'the first line of the message that says something, trimmed' );
  is( $reason->('padded-reason'), 'DeployFailed', 'a reason is trimmed too' );

  my $long = cr('conditions');
  $long->{status}{conditions}[0]{reason} = 'R' x 300;
  is( $CELL->from_cr($long)->reason, 'R' x 300, 'not cut here' );

  is( $reason->('odd-not-a-list'), undef, 'conditions not a list: none' );
  is( $reason->('odd-entries'), 'DeployFailed', 'entries that are no conditions are passed over' );
  is( $reason->('odd-refs'), undef, 'references as values count as absent' );
  is( $reason->('odd-number'), '42', 'a number is a string' );
  is( $CELL->from_cr( cr('odd') )->reason, undef, 'the odd fixture: none' );
  is( $CELL->from_cr( cr('odd-nested') )->reason, undef,
    'the nested odd fixture: its first condition has no string, a later one is not asked' );
};

subtest 'status.endpoints[]' => sub {
  is_deeply(
    $CELL->from_cr( cr('endpoints') )->endpoints,
    [ { name => 'client', port => '4222' }, { name => 'monitor', port => '8222' } ],
    'name and port'
  );
};

subtest 'status.upstream' => sub {
  my $cell = $CELL->from_cr( cr('upstream') );
  ok( $cell->borrowed, 'borrowed' );
  ok( $cell->upstream_recorded, 'upstream recorded' );
  is( $cell->upstream_class, 'Kubernetes::Comb::Upstream::K8s', 'class' );
  is( $cell->upstream_context, 'dev', 'context' );
  is_deeply( $cell->upstream_via, [ 'dev', 'prod' ], 'via' );

  my $cr = cr('upstream');
  $cr->{status}{upstream} = undef;
  ok( !$CELL->from_cr($cr)->borrowed, 'upstream null is not borrowed' );
  ok( !$CELL->from_cr($cr)->upstream_recorded, 'and not recorded' );
  $cr->{status}{upstream} = {};
  ok( !$CELL->from_cr($cr)->borrowed, 'empty upstream is not borrowed' );
  ok( !$CELL->from_cr($cr)->upstream_recorded, 'and not recorded' );
  $cr->{status}{upstream} = { class => [ 'not', 'a', 'string' ] };
  is( $CELL->from_cr($cr)->upstream_class, undef, 'class not a string' );
};

subtest 'borrowed: recorded, reachable, Running or Pending' => sub {
  is_deeply( [ $CELL->borrowing_phases ], [qw( Running Pending )], 'borrowing_phases' );

  my $cell = sub {
    my ( $phase, $upstream, $enabled ) = @_;
    return $CELL->from_cr( {
      metadata => { name => 'db' },
      defined $enabled ? ( spec => { enabled => $enabled } ) : (),
      status   => { defined $phase ? ( phase => $phase ) : (), upstream => $upstream }
    } );
  };

  # reachable as it may arrive, and what it counts as
  my @reachable = (
    [ 'missing',        1 ],
    [ 'JSON true',      1, JSON::MaybeXS->true ],
    [ '1',              1, 1 ],
    [ '"true"',         1, 'true' ],
    [ 'null',           1, undef ],
    [ 'JSON false',     0, JSON::MaybeXS->false ],
    [ '0',              0, 0 ],
    [ '"false"',        0, 'false' ],
    [ '"False"',        0, 'False' ],
    [ 'empty string',   0, '' ]
  );
  for my $phase ( $CELL->known_phases, 'Starting', undef ) {
    my $borrowing = defined $phase && ( $phase eq 'Running' || $phase eq 'Pending' );
    my $label     = defined $phase ? $phase : 'no phase';
    for my $case (@reachable) {
      my ( $name, $reachable, @value ) = @$case;
      my $got = $cell->( $phase, { context => 'dev', @value ? ( reachable => $value[0] ) : () } );
      is( !!$got->borrowed, !!( $borrowing && $reachable ), $label.', reachable '.$name );
      ok( $got->upstream_recorded, $label.', reachable '.$name.': recorded all the same' );
      is( $got->upstream_context, 'dev', $label.', reachable '.$name.': context kept' );
    }
    for my $none ( undef, {} ) {
      my $got = $cell->( $phase, $none );
      ok( !$got->borrowed && !$got->upstream_recorded,
        $label.', '.( $none ? 'empty' : 'no' ).' upstream: neither borrowed nor recorded' );
    }
  }

  for my $off ( JSON::MaybeXS->false, 0, 'false' ) {
    my $got = $cell->( 'Running', { context => 'dev', reachable => JSON::MaybeXS->true }, $off );
    is( $got->phase, 'Disabled', 'spec.enabled '.$off.': Disabled' );
    ok( !$got->borrowed, 'spec.enabled '.$off.': not borrowed' );
    ok( $got->upstream_recorded, 'spec.enabled '.$off.': the record stays' );
  }

  # Odd upstream values: nothing recorded, nothing borrowed, no exception.
  for my $odd ( 'prod', '', 0, 1, [], [ 'dev' ], [ { context => 'dev' } ], JSON::MaybeXS->true, \'ref' ) {
    my $got = eval { $cell->( 'Running', $odd ) };
    ok( $got, 'odd upstream '.( ref $odd || '"'.$odd.'"' ).': no exception' ) or diag $@;
    ok( !$got->borrowed && !$got->upstream_recorded, '... neither borrowed nor recorded' );
    is( $got->upstream_class, undef, '... no class' );
  }
  # Odd values inside the record.
  my $got = $cell->( 'Running', { reachable => [], class => {}, context => [ 'dev' ] } );
  ok( $got->borrowed, 'reachable a list: not an explicit false' );
  ok( !defined $got->upstream_class && !defined $got->upstream_context, 'class and context not strings' );
};

#### Odd data

subtest 'wrong types degrade quietly' => sub {
  my $cell = $CELL->from_cr( cr('odd'), group_label => 'team' );
  is( $cell->name, 'odd', 'name' );
  is( $cell->namespace, undef, 'namespace not a string' );
  is( $cell->class,     undef, 'class not a string' );
  is( $cell->group,     undef, 'labels not a hash' );
  ok( $cell->enabled, 'enabled "yes"' );
  is( $cell->phase, 'Unknown', 'phase not a string' );
  is( $cell->raw_phase, undef, 'no raw phase' );
  is_deeply( $cell->depends_on, ['db'], 'dependsOn a string is one name' );
  is( $cell->message, undef, 'conditions not an array' );
  is_deeply(
    $cell->endpoints,
    [ { name => 'web', port => undef }, { name => 'dns', port => '53' } ],
    'endpoints without a name dropped, odd port undef'
  );
  ok( !$cell->borrowed, 'upstream not a hash' );
  ok( !$cell->upstream_recorded, 'so none is recorded' );

  $cell = $CELL->from_cr( cr('odd-nested'), group_label => 'team' );
  is( $cell->group, undef, 'label value not a string' );
  is( $cell->class, undef, 'spec not a hash' );
  is_deeply( $cell->depends_on, [], 'no dependencies' );
  is( $cell->phase,   'Error', 'phase' );
  is( $cell->message, 'boom',  'only string messages' );
  is_deeply( $cell->endpoints, [], 'endpoints not an array' );
  ok( $cell->upstream_recorded, 'upstream recorded' );
  ok( !$cell->borrowed, 'but an Error cell does not borrow' );
  is( $cell->upstream_context, undef, 'context not a string' );
  is_deeply( $cell->upstream_via, ['prod'], 'via a string is one name' );

  my $cr = cr('name');
  $cr->{$_} = 'text' for qw( spec status );
  $cr->{spec} = [];
  is( $CELL->from_cr($cr)->phase, 'Unknown', 'spec and status not hashes' );
};

subtest 'nothing is escaped here' => sub {
  my $cr = cr('conditions');
  $cr->{metadata}{name} = '</svg><script>';
  $cr->{status}{conditions} = [ { message => 'a < b & "c"' } ];
  my $cell = $CELL->from_cr($cr);
  is( $cell->name, '</svg><script>', 'name as it came' );
  is( $cell->message, 'a < b & "c"', 'message as it came' );
  is( $cell->reason,  'a < b & "c"', 'reason as it came' );
};

subtest 'missing name is the only error' => sub {
  dies_like( sub { $CELL->from_cr( cr('no-name') ) },
    qr/Comb without metadata\.name/, 'no metadata.name' );
  my $cr = cr('name');
  $cr->{metadata}{name} = '';
  dies_like( sub { $CELL->from_cr($cr) }, qr/metadata\.name/, 'empty name' );
  $cr->{metadata}{name} = { a => 1 };
  dies_like( sub { $CELL->from_cr($cr) }, qr/metadata\.name/, 'name not a string' );
  dies_like( sub { $CELL->from_cr($_) }, qr/metadata\.name/,
    'not a CR: '.( defined $_ ? ( ref $_ || $_ ) : 'undef' ) )
    for undef, 'text', [], {};
  my $error = eval { $CELL->from_cr( {} ); 1 } ? '' : $@;
  like( $error, qr/\Q${\ __FILE__ }\E/, 'reported at the caller' );
};

#### TO_JSON

{
  package Local::CR;
  sub new { my ( $class, $data ) = @_; bless { data => $data }, $class }
  sub TO_JSON { $_[0]{data} }
}

subtest 'object answering TO_JSON' => sub {
  my $cell = $CELL->from_cr( Local::CR->new( cr('upstream') ) );
  is( $cell->name, 'db', 'name' );
  ok( $cell->borrowed, 'borrowed' );

  my $cr = cr('endpoints');
  $cr->{metadata}          = Local::CR->new( $cr->{metadata} );
  $cr->{status}{endpoints} = [ map { Local::CR->new($_) } @{ $cr->{status}{endpoints} } ];
  $cr->{status}            = Local::CR->new( $cr->{status} );
  $cell = $CELL->from_cr( Local::CR->new($cr) );
  is( $cell->name, 'nats', 'nested objects: name' );
  is( scalar @{ $cell->endpoints }, 2, 'nested objects: endpoints' );

  my $loop = bless {}, 'Local::Loop';
  no warnings 'once';
  *Local::Loop::TO_JSON = sub { $_[0] };
  dies_like( sub { $CELL->from_cr($loop) }, qr/metadata\.name/,
    'TO_JSON answering itself does not hang' );
};

#### cells_from

subtest 'cells_from' => sub {
  my @cells = $CELL->cells_from( [ cr('upstream'), cr('conditions') ] );
  is_deeply( [ map { $_->name } @cells ], [ 'db', 'api' ], 'array, input order' );

  @cells = $CELL->cells_from( cr('list') );
  is_deeply( [ map { $_->name } @cells ], [ 'db', 'api' ], 'List with items' );
  is( $cells[0]->id, 'one/db', 'first of a duplicate id is kept' );
  is( $cells[0]->phase, 'Running', 'first of a duplicate id is kept: phase' );
  is_deeply( $cells[1]->dependencies, ['one/db'], 'dependencies are resolved' );

  @cells = $CELL->cells_from( cr('group-label'), group_label => 'tier' );
  is( scalar @cells, 1, 'single CR' );
  is( $cells[0]->group, 'backend', 'options reach from_cr' );

  @cells = $CELL->cells_from( Local::CR->new( cr('list') ) );
  is( scalar @cells, 2, 'List object answering TO_JSON' );
  @cells = $CELL->cells_from( [ Local::CR->new( cr('name') ) ] );
  is( $cells[0]->name, 'nats', 'array of objects' );

  is_deeply( [ $CELL->cells_from( [] ) ], [], 'empty array' );
  is_deeply( [ $CELL->cells_from( { kind => 'List', items => [] } ) ], [], 'empty List' );
  is_deeply( [ $CELL->cells_from( { items => undef } ) ], [], 'items null' );
  is_deeply( [ $CELL->cells_from( { items => 'x' } ) ], [], 'items not an array' );
  is_deeply( [ $CELL->cells_from(undef) ], [], 'undef' );

  dies_like( sub { $CELL->cells_from( [ cr('name'), cr('no-name') ] ) },
    qr/metadata\.name/, 'element without a name' );
  dies_like( sub { $CELL->cells_from( [ cr('name'), 'text' ] ) },
    qr/metadata\.name/, 'element that is not a CR' );
};

#### Identity

subtest 'identity is namespace/name' => sub {
  my @cells = $CELL->cells_from( cr('identity') );
  my %cell  = map { $_->id => $_ } @cells;
  is_deeply( [ map { $_->id } @cells ],
    [ 'one/db', 'two/db', 'two/cache', 'one/api', 'three/web' ],
    'same name in two namespaces both kept, same id only once' );
  is( $cell{'two/db'}->phase, 'Unknown', 'first of a duplicate id is kept' );

  my $api = $cell{'one/api'};
  is_deeply( $api->depends_on,
    [ 'db', 'cache', 'two/db', 'one/db', 'ghost', 'three/db', 'api' ],
    'depends_on stays raw' );
  is_deeply( $api->dependencies,
    [ 'one/db', 'two/cache', 'two/db', 'one/api' ],
    'own namespace first, unique elsewhere, ns/name, self; no duplicates' );
  is_deeply( $api->missing, [ 'ghost', 'three/db' ], 'unknown name and unknown id' );

  my $web = $cell{'three/web'};
  is_deeply( $web->dependencies, [ 'two/cache', 'one/api' ],
    'bare name unique in another namespace, ns/name' );
  is_deeply( $web->missing, ['db'], 'ambiguous bare name is missing' );

  is_deeply( $cell{'one/db'}->dependencies, [], 'no dependencies' );
  is_deeply( $cell{'one/db'}->missing,      [], 'nothing missing' );
};

subtest 'identity without a namespace' => sub {
  my @cells = $CELL->cells_from( cr('identity-no-namespace') );
  my %cell  = map { $_->id => $_ } @cells;
  is_deeply( [ map { $_->id } @cells ], [ 'db', 'one/db', 'api', 'two/job' ],
    'id is the name without a namespace' );
  is_deeply( $cell{api}->dependencies, [ 'db', 'one/db' ],
    'bare name prefers the cell without a namespace too' );
  is_deeply( $cell{api}->missing, ['nats'], 'unknown' );
  is_deeply( $cell{'two/job'}->dependencies, ['api'],
    'bare name reaches the only cell of that name' );
  is_deeply( $cell{'two/job'}->missing, ['db'], 'ambiguous across namespaces' );

  my @again = $CELL->cells_from( cr('identity-no-namespace') );
  is_deeply( [ map { [ $_->id, $_->dependencies, $_->missing ] } @again ],
    [ map { [ $_->id, $_->dependencies, $_->missing ] } @cells ], 'same again' );

  my $cell = $CELL->new( name => 'x', id => 'y', dependencies => ['z'], missing => ['z'] );
  is( $cell->id, 'x', 'id is not a constructor argument' );
  is_deeply( [ $cell->dependencies, $cell->missing ], [ [], [] ],
    'dependencies and missing are not constructor arguments' );
};

subtest 'real CR classes' => sub {
  plan skip_all => 'Kubernetes::Comb::CRD::Comb not installed'
    unless eval { require Kubernetes::Comb::CRD::Comb; 1 };
  my $comb = eval {
    Kubernetes::Comb::CRD::Comb->new(
      metadata => { name => 'nats', namespace => 'platform' },
      spec     => { class => 'MyApp::Comb::NATS', dependsOn => ['db'] },
      status   => { phase => 'Pending' }
    );
  };
  plan skip_all => 'Kubernetes::Comb::CRD::Comb not constructible this way'
    unless $comb;
  my $cell = $CELL->from_cr($comb);
  is( $cell->name,      'nats',     'name' );
  is( $cell->namespace, 'platform', 'namespace' );
  is( $cell->phase,     'Pending',  'phase' );
  is_deeply( $cell->depends_on, ['db'], 'depends_on' );
};

done_testing;
